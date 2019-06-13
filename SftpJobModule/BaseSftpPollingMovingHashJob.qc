# -*- mode: qore; indent-tabs-mode: nil -*-

%requires qore >= 0.9

%requires Util

%new-style
%require-types
%strict-args
%enable-all-warnings

public namespace SftpModule {

    public class BaseSftpPollingMovingHashJob inherits QorusJob {

        private *hash<string, hash<ConfigItemInfo>> getConfigItemsImpl() {
            return {
                 "sftp_connection_name": <ConfigItemInfo>{
                    "type": "string",
                    "description": "SFTP connection name",
                    "strictly_local": True,
                },
                "processing_path": <ConfigItemInfo>{
                    "type": "string",
                    "default_value": "processing",
                    "description": "Path to a SFTP directory to store processed files (must be on the same filesystem)",
                    "strictly_local": True,
                },
                "wf_name": <ConfigItemInfo>{
                    "type": "string",
                    "description": "Name of the workflow to be created; WF version can be specified after colon, "
                                   "otherwise the last available version of the workflow is used",
                    "strictly_local": True,
                },
                "rejection_wf_name": <ConfigItemInfo>{
                    "type": "string",
                    "description": "Name of the rejection workflow to be created; WF version can be specified after "
                                   "colon, otherwise the last available version of the workflow is used",
                    "strictly_local": True,
                },
                "regex_mask": <ConfigItemInfo>{
                    "type": "string",
                    "default_value": ".*",
                    "description": "File name regular expression mask specifying files that should be polled",
                    "strictly_local": True,
                },
                "static_data": <ConfigItemInfo>{
                    "type": "hash",
                    "default_value": {
                        "file_name": "$filename",
                        "file_path": "$filepath",
                        "parent_jiid": "$jobiid"
                    },
                    "description": "Static data for the workflow order that's created for a polled file",
                    "strictly_local": True,
                },
                "order_keys": <ConfigItemInfo>{
                    "type": "hash",
                    "default_value": {
                        "parent_jiid": "$jobiid",
                        "file_name": "$orig_filename",
                    },
                    "description": "Order keys for the workflow order that's created for a polled file",
                    "strictly_local": True,
                },
                "wf_unique_key": <ConfigItemInfo>{
                    "type": "hash",
                    "description": "Workflow unique key",
                    "strictly_local": True,
                },
                "rejection_wf_unique_key": <ConfigItemInfo>{
                    "type": "hash",
                    "description": "Rejection workflow unique key",
                    "strictly_local": True,
                },
                "ignore_duplicate_error": <ConfigItemInfo>{
                    "type": "bool",
                    "default_value": False,
                    "description":
                        "Flag specifying whether the job should ignore duplicate errors when creating WF orders",
                    "strictly_local": True,
                },
                "age": <ConfigItemInfo>{
                    "type": "int",
                    "default_value": 0,
                    "description": "Minimal age in seconds for the file to be polled",
                    "strictly_local": True,
                },
            };
        }

        run() {
            # get an SFTP client for the connection
            string sftp_conn_name = getConfigItemValue("sftp_connection_name");
            SFTPClient sftp = UserApi::getUserConnection(sftp_conn_name);

            string regex_mask = getConfigItemValue("regex_mask");
            string processing_path = getConfigItemValue("processing_path");

            # run the poller that just moves files to a processing directory
            hash conf_move = {
                "job_info": self.getInfo(),
                "regex_mask": regex_mask,
                "processing_path": processing_path,
                "minage": getConfigItemValue("age"),
                "log_info": \logInfo(),
            };
            BBSftpPollerMove poller_move(sftp, conf_move, False);
            logInfo("Scanning the monitored directory...");
            poller_move.runOnce();

            # update the regex for the renamed file name (in the processing directory)
            string regex_uuid = "\.[a-z0-9-]+";
            if (string_ends_with(regex_mask, "$") && !string_ends_with(regex_mask, "\$")) {
                regex_mask = regex_mask.substr(0, length(regex_mask) - 1) + regex_uuid + "$";
            } else {
                regex_mask = regex_mask + regex_uuid;
            }

            # run the poller that will actually process the file (and create a workflow order for it)
            hash conf_process = {
                "job_info": self.getInfo(),
                "wf_name": getConfigItemValue("wf_name"),
                "rejection_wf_name": getConfigItemValue("rejection_wf_name"),
                "regex_mask": regex_mask,
                "processing_path": processing_path,
                "static_data": getConfigItemValue("static_data"),
                "order_keys": getConfigItemValue("order_keys"),
                "wf_unique_key": getConfigItemValue("wf_unique_key"),
                "rejection_wf_unique_key": getConfigItemValue("rejection_wf_unique_key"),
                "ignore_duplicate_error": getConfigItemValue("ignore_duplicate_error"),
                "log_info": \logInfo(),
            };
            sftp.chdir(processing_path);
            logInfo("Switched to '%s', starting the processing poller...", processing_path);
            BBSftpPollerHash poller_process(sftp, conf_process, False);
            poller_process.runOnce();
        }
    }
}
