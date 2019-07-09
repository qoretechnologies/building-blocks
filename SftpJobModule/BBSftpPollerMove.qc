# -*- mode: qore; indent-tabs-mode: nil -*-

%requires qore >= 0.9

%requires FsUtil
%requires uuid

%new-style
%require-types
%strict-args
%enable-all-warnings


public namespace SftpModule {

    /** A simple poller that only moves files to a processing directory.

        No WF orders are created and another poller is supposed to monitor the processing path.
    */
    class BBSftpPollerMove inherits SftpPoller {
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
            };
        }

        static hash confEnforced() {
            return {
                "sleep": \UserApi::sleep(),
            };
        }

        static list confRequired() {
            return (
                "processing_path",
            );
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


        constructor(SFTPClient sftp, hash conf, bool run=False): SftpPoller(
            sftp,
            BBSftpPollerMove::confDefault() + conf + BBSftpPollerMove::confEnforced()
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

        #! Process a file -> create a workflow order unless the file has already been processed.
        singleFileEvent(hash fh) {
            logInfo("moving remote file '%s' to processing", fh.name);
            string new_name = join_paths(self.conf.processing_path, fh.name) + "." + UUID::get();
            self.sftp.rename(fh.name, new_name);
            logInfo("'%s' moved to '%s'", fh.name, new_name);
        }

        #! There is nothing to do after a file is processed
        postSingleFileEvent(hash fh) {
        }
    }
}
