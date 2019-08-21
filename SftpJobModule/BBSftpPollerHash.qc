# -*- mode: qore; indent-tabs-mode: nil -*-

%requires qore >= 0.9

%new-style
%require-types
%strict-args
%enable-all-warnings

public namespace SftpModule {
    /** SFTP Poller that checks file meta data to decide whether this particular file has already been processed.

        This poller doesn't rely solely on file name to identify a file but also uses meta data like modification time,
        size, etc. to create a unique identifier for the file.

        If a file has never been processed yet (no active WF order associated to the file's identifier), a new order is
        created. Otherwise the file is ignored by the poller (there is already a WF order that will process it sooner or
        later). It may happen that multiple orders are created for the same file name (e.g. if the file was
        changed/replaced in the meantime). The workflow therefore needs to check that the identifier is still valid for
        the file. If it is, the WF order can grab and process the file, otherwise it needs to leave it be and finish
        (either as completed or an error, depending on the use case), because there is (or will be) another WF order
        associated to the file.

        A rejection WF order still makes sense here and may be created - e.g. when a file is "grabbed" by a WF order
        (i.e. dd.file_name is set) but the file is still on the SFTP for some weird reason, or if the same ID is
        assigned to different files (this shouldn't happen though).
        Therefore if there already is an active (not canceled) workflow order created for the file that is currently
        being polled and the file has not been grabbed by the workflow order yet, the file is ignored on SFTP (no new
        WF order) for the time being. If the file has been grabbed already a rejection WF order is created for the file.
        Checking whether a WF order exists for the file relies on "file_name" order key. To find out whether the file
        has already been grabbed, "file_name" in the WF order's dynamic data is checked (which should be set in
        the first step of the WF after the file is moved to a local file system).

        The unique identifier is created as a hash computed from the file's meta data (see getFileUniqueID() method).
    */
    class BBSftpPollerHash inherits BBSftpPoller {
        constructor(SFTPClient sftp, hash conf, bool run = False): BBSftpPoller(
            sftp,
            BBSftpPoller::confDefault() + conf + BBSftpPoller::confEnforced()
        ) {
            self.conf_rcvd = conf;
            self.conf = confDefault() + conf + confEnforced();
            self.sftp = sftp;

            foreach string conf_key in (confRequired()) {
                if (!exists self.conf{conf_key}) {
                    throw "IMPROPERLY-CONFIGURED", sprintf("Configuration option '%s' is required.", conf_key);
                }
            }
        }

        static list<string> confRequired() {
            return (
                "wf_name",
                "rejection_wf_name",
            );
        }

        #! Compute hash from the file's metadata.
        /** @param fh hash containing information about the file that triggered this order creation

            @return unique identifier for the file

            The following keys are used from fh and therefore need to be present there:
            - name: the name of the file, link, or directory
            - size: the size of the file in bytes
            - mtime: the last modified date/time of the file
            - type: the type of file (e.g. "REGULAR", "DIRECTORY", "SYMBOLIC-LINK", etc.)
        */
        static string getFileUniqueID(hash<auto> fh) {
            return SHA512(join(":", fh.name, fh.size, fh.mtime, fh.type));
        }

        #! Replace supported variables with their values in a config hash
        /** @param config hash to scan for variables (only values are scanned, keys are not touched)
            @param file hash containing file info

            @return hash with values updated with variables' values

            Currently are supported these variables:
            - $filename - name of the polled file
            - $filepath - path to the polled file
            - $jobiid - instance id of the polling job
        */
        hash replaceVariables(hash config, hash<auto> file) {
            string filepath;
            if (self.conf.processing_path) {
                filepath = join_paths(self.conf.processing_path, file.filepath);
            } else {
                filepath = file.filepath;
            }

            hash<auto> local_context = {
                "filename": file.name,
                "orig_filename": regex_subst(file.name, "^(.*)\\..*$", "$1"),
                "filepath": filepath,
                "jobiid": string(self.conf.job_info.job_instanceid),
            };

            foreach string k in (keys config) {
                config{k} = UserApi::expandTemplatedValue(config{k}, local_context);
            }

            return config;
        }

        #! Return parameters for workflow order creation as a hash.
        /** @param fh hash containing information about the file that triggered this order creation

            @return hash with create order parameters
        */
        hash<auto> getCreateOrderParams(hash<auto> fh) {
            return {
                "orderkeys": self.replaceVariables(self.conf.order_keys, fh),
                "staticdata": self.replaceVariables(self.conf.static_data, fh),
                "workflow_unique_key": {"file_id": self.getFileUniqueID(fh)},
            };
        }

        #! Create a new workflow order for the file (unless it has already been processed)
        /** @param fh hash containing information about the file that triggered this order creation
            @param create_order_params hash containing static data, order keys and workflow unique key

            @return wfiid or NOTHING is the file has already been processed and duplicates are ignored

            @throws DUPLICATE-ORDER-KEY if the file has already been processed and duplicates are not ignored

            Workflow name and the flag whether duplicates should be ignored are both taken from self.conf.
        */
        *int createOrder(hash<auto> fh, hash<auto> create_order_params, string status = OMQ::StatReady) {
            softint wfiid;
            hash<auto> wf_info;
            try {
                wf_info = SftpJobModule::splitWfNameVersion(self.conf.wf_name);
                wfiid = UserApi::createOrder(wf_info.name, wf_info.version, create_order_params, status);
                logInfo("created order %s (wfiid %d) with status %s", self.conf.wf_name, wfiid, status);
            } catch (hash ex) {
                if (ex.err == "DUPLICATE-ORDER-KEY") {
                    # find if a WF order has already grabbed local file copy, i.e. we can safely create duplicate order
                    # (validation through all potential workflow versions -> do not use info.getOrderInfoFromKey() here)
                    list all = OMQ::omqservice.system.info.getOrdersFromKey("file_id", self.getFileUniqueID(fh));

                    ListIterator it(all);
                    while (it.next()) {
                        if (it.getValue().name == wf_info.name) {
                            if (!inlist(it.getValue().workflows[0].workflowstatus, (StatCanceled)) &&
                                !exists it.getValue().dynamicdata.file_name) {
                                # when a workflow grabs file, it should set dd.file_name to its local copy of the file
                                # i.e. SFTP file is not related to that order
                                logInfo("skipping file %y as it has not yet been grabbed but an order for it exists",
                                        fh.name);
                                return NOTHING;
                            }
                        }
                    }

                    # rejection here
                    create_order_params.orderkeys += {
                        "workflow_unique_key": self.replaceVariables(self.conf.rejection_wf_unique_key, fh)
                    };
                    create_order_params.static_data += {"error": "duplicate file -> rejected"};
                    hash<auto> rej_wf_info = SftpJobModule::splitWfNameVersion(self.conf.rejection_wf_name);
                    wfiid = UserApi::createOrder(rej_wf_info.name, rej_wf_info.version, create_order_params, status);
                    logInfo("created rejection order %s (wfiid %d) with status %s", self.conf.wf_name, wfiid, status);
                } else {
                    logInfo("failed to create order for file %y: %s: %s; the job will try again in the next poll cycle",
                            fh.name, ex.err, ex.desc);
                    rethrow;
                }
            }
            return wfiid;
        }
    }
}
