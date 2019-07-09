# -*- mode: qore; indent-tabs-mode: nil -*-

%requires qore >= 0.9

%requires SftpPoller

%new-style
%require-types
%strict-args
%enable-all-warnings

public namespace SftpModule {

    /** Basic SFTP Poller.

        If there already is an active (not canceled) workflow order created for the file that is currently being polled
        and the file has not been grabbed by the workflow order yet, the file is ignored on SFTP (no new WF order) for
        the time being. If the file has been grabbed already the job goes into error unless 'ignore_duplicate_error'
        flag is set.

        Checking whether a WF order exists for the file uses workflow unique key which is configurable. It's therefore
        possible to create a WF order for each file and never have any duplicates, by not setting 'workflow_unique_key'
        config item.

        This poller is not supposed to be used directly by building blocks as it doesn't guarantee atomicity in
        file processing. It's supposed to be subclassed and/or used in some way that ensures the atomicity.
    */
    class BBSftpPoller inherits SftpPoller {
        private {
            # configuration received in constructor
            hash conf_rcvd;
            # configuration actually used (including defaults)
            hash conf;
        }

        static hash confDefault() {
            return {
                "skip_file_content_retrieval": True,
                "start_thread": NULL, # must be like this in order to work within jobs
                "writable": True,
                "ignore_duplicate_error": False, # fail by default when there is a file that has already been processed
            };
        }

        static hash confEnforced() {
            return {
                "sleep": \UserApi::sleep(),
            };
        }

        static list confRequired() {
            return (
                "wf_name",
                "ignore_duplicate_error"
            );
        }

        constructor(SFTPClient sftp, hash conf, bool run=False): SftpPoller(
            sftp,
            BBSftpPoller::confDefault() + conf + BBSftpPoller::confEnforced()
        ) {
            self.conf_rcvd = conf;
            self.conf = confDefault() + conf + confEnforced();

            foreach string conf_key in (confRequired()) {
                if (!exists self.conf{conf_key}) {
                    throw "IMPROPERLY-CONFIGURED", sprintf("Configuration option '%s' is required.", conf_key);
                }
            }
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
        hash replaceVariables(hash config, hash file) {
            hash<auto> local_context = {
                "filename": file.name,
                "filepath": file.filepath,
                "jobiid": string(self.conf.job_info.job_instanceid),
            };

            foreach string k in (keys config) {
                config{k} = UserApi::expandTemplatedString(config{k}, local_context);
            }

            return config;
        }

        #! Return parameters for workflow order creation as a hash.
        /** @param fh hash containing information about the file that triggered this order creation

            @return hash with create order parameters
        */
        hash getCreateOrderParams(hash fh) {
            return {
                "orderkeys": self.replaceVariables(self.conf.order_keys, fh),
                "staticdata": self.replaceVariables(self.conf.static_data, fh),
                "workflow_unique_key": self.replaceVariables(self.conf.wf_unique_key, fh),
            };
        }

        #! Process a file -> create a workflow order unless the file has already been processed.
        singleFileEvent(hash fh) {
            logInfo("handling remote file %y", fh.name);
            self.createOrder(fh, self.getCreateOrderParams(fh));
        }

        #! There is nothing to do after a file is processed
        postSingleFileEvent(hash fh) {
        }

        #! Create a new workflow order for the file (unless it has already been processed)
        /** @param fh hash containing information about the file that triggered this order creation
            @param create_order_params hash containing static data, order keys and workflow unique key

            @return wfiid or NOTHING is the file has already been processed and duplicates are ignored

            @throws DUPLICATE-ORDER-KEY if the file has already been processed and duplicates are not ignored

            Workflow name and the flag whether duplicates should be ignored are both taken from self.conf.
        */
        *int createOrder(hash fh, hash create_order_params, string status = OMQ::StatReady) {
            softint wfiid;
            try {
                hash<auto> wf_info = SftpJobModule::splitWfNameVersion(self.conf.wf_name);
                wfiid = UserApi::createOrder(wf_info.name, wf_info.version, create_order_params, status);
                logInfo("created order %s (wfiid %d) with status %s", self.conf.wf_name, wfiid, status);
            } catch (hash ex) {
                if (ex.err == "DUPLICATE-ORDER-KEY") {
                    if (self.conf.ignore_duplicate_error) {
                        logInfo("Ignoring file %s, a workflow order for it already exists.", fh.name);
                        return NOTHING;
                    }
                } else {
                    logInfo("failed to create order for file %y: %s: %s; the job will try again in the next poll cycle",
                            fh.name, ex.err, ex.desc);
                    rethrow;
                }
            }
            return wfiid;
        }
    }
} # namespace SftpModule
