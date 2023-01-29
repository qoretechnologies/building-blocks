from job import QorusJob

class BBM_OndewoVtsiClientTest(QorusJob):
    def __init__(self):
        ####### GENERATED SECTION! DON'T EDIT! ########
        self.class_connections = ClassConnections_BBM_OndewoVtsiClientTest()
        ############ GENERATED SECTION END ############

    ####### GENERATED SECTION! DON'T EDIT! ########
    def run(self):
        self.class_connections.run()
    ############ GENERATED SECTION END ############

####### GENERATED SECTION! DON'T EDIT! ########
class ClassConnections_BBM_OndewoVtsiClientTest:
    def __init__(self):
        # map of prefixed class names to class instances
        self.class_map = {
            'BBM_OndewoVtsiClient': BBM_OndewoVtsiClient(),
        }

    def callClassWithPrefixMethod(self, prefixed_class, method, *argv):
        UserApi.logDebug("ClassConnections_BBM_OndewoVtsiClientTest: callClassWithPrefixMethod: method: %s class: %y", method, prefixed_class)
        return getattr(self.class_map[prefixed_class], method)(*argv)

    def run(self, *params):
        UserApi.logDebug("run called with data: %y", params)
        # convert varargs to a single argument if possible
        if (type(params) is list or type(params) is tuple) and (len(params) == 1):
            params = params[0]
        UserApi.logDebug("calling startCaller: %y", params)
        params = self.callClassWithPrefixMethod("BBM_OndewoVtsiClient", "startCaller", params)
        UserApi.logDebug("output from startCaller: %y", params)
        return params
############ GENERATED SECTION END ############
