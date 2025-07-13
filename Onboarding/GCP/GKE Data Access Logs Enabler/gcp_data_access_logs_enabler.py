"""
Enables data access logs for gke clusters
"""
import time
import logging
import json
import pathlib
import locale
import codecs

class GkeDataAccessLogsEnabler():
    """
    Enables data access logs for gke clusters
    """
    logger = ""

    def __init__(self):
        self.logger = logging.getLogger()

    def __check_log_type_in_audit_log_configs(self, audit_log_configs, log_type):
        for audit_log_config in audit_log_configs:
            if audit_log_config["logType"] == log_type:
                return True
        return False

    def __add_log_type_to_audit_log_configs_if_needed(self, audit_log_configs, log_type):
        if self.__check_log_type_in_audit_log_configs(audit_log_configs, log_type) == False:
            self.logger.debug("Log type was not found: %s, adding it", log_type)
            audit_log_configs.append(
            {
                "logType": log_type
            })
            self.logger.debug("Log type: %s was added", log_type)
        else:
            self.logger.debug("Log type was found: %s", log_type)

    def __update_iam_policy(self, current_policy):
        auditLogConfigs = ""
        required_log_types = ("ADMIN_READ", "DATA_WRITE", "DATA_READ")

        k8sApiFound = False
        auditConfigsKey = "auditConfigs"
        if (auditConfigsKey in current_policy):
            for auditConfigItem in current_policy[auditConfigsKey]:
                if auditConfigItem["service"] == "container.googleapis.com":
                    k8sApiFound = True
                    self.logger.debug("existing container.googleapis.com audit config was found")
                    auditLogConfigs = auditConfigItem["auditLogConfigs"]
                    for log_type in required_log_types:
                        self.__add_log_type_to_audit_log_configs_if_needed(auditLogConfigs, log_type)
        else:
            current_policy[auditConfigsKey] = []

        if k8sApiFound == False:
            self.logger.debug("No container.googleapis.com audit config was found, adding a new one")
            current_policy[auditConfigsKey].append({
                "service": "container.googleapis.com",
                "auditLogConfigs": list(map(lambda item: {"logType": item}, required_log_types))
            })
    
    def Run(self):
        """
        Enables data access logs for gke clusters
        """
        self.logger.debug("Running")
        fileDirectory = str(pathlib.Path(__file__).parent.resolve())
        filePath = fileDirectory + "/currentPolicy.json"
        self.logger.debug(filePath)
        encodings = [locale.getpreferredencoding(), 'utf-16']
        for enc in encodings:
            try:
                with codecs.open(filePath, 'r+', encoding=enc) as file:
                    currentPolicy = json.load(file)
                    self.logger.debug("Finished reading the iam policy, now changing it")
                    self.__update_iam_policy(currentPolicy)
                    self.logger.debug("Writing the iam policy to the file")
                    file.seek(0)
                    json.dump(currentPolicy, file)
                    file.truncate()
                    return
            except json.JSONDecodeError:
                self.logger.debug("missed %s" % enc)
            except UnicodeDecodeError:
                self.logger.debug("missed %s" % enc)
            

if __name__ == '__main__':
    try:
        print("Starting...")
        gkeDataAccessLogsEnabler = GkeDataAccessLogsEnabler()
        gkeDataAccessLogsEnabler.Run()
        print("Done!")
    except Exception as ex:
        template = "An exception of type {0} occurred. Arguments:\n{1!r}"
        message = template.format(type(ex).__name__, ex.args)
        print(message)
        print("Error encountered: {}".format(ex))
