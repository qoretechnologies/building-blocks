from svc import QorusService

class OndewoBpiTest(QorusService):
    def __init__(self):
        ####### GENERATED SECTION! DON'T EDIT! ########
        self.class_connections = ClassConnections_OndewoBpiTest()
        ############ GENERATED SECTION END ############

    ####### GENERATED SECTION! DON'T EDIT! ########
    def start(self):
        self.class_connections.start()

    def stop(self):
        self.class_connections.stop()
    ############ GENERATED SECTION END ############

####### GENERATED SECTION! DON'T EDIT! ########
class ClassConnections_OndewoBpiTest:
    def __init__(self):
        # map of prefixed class names to class instances
        self.class_map = {
            'BBM_OndewoBpiServer': BBM_OndewoBpiServer(),
        }

    def callClassWithPrefixMethod(self, prefixed_class, method, *argv):
        UserApi.logDebug("ClassConnections_OndewoBpiTest: callClassWithPrefixMethod: method: %s class: %y", method, prefixed_class)
        return getattr(self.class_map[prefixed_class], method)(*argv)

    def start(self, *params):
        UserApi.logDebug("start called with data: %y", params)
        # convert varargs to a single argument if possible
        if (type(params) is list or type(params) is tuple) and (len(params) == 1):
            params = params[0]
        UserApi.logDebug("calling start: %y", params)
        params = self.callClassWithPrefixMethod("BBM_OndewoBpiServer", "start", params)
        UserApi.logDebug("output from start: %y", params)
        return params

    def stop(self, *params):
        UserApi.logDebug("stop called with data: %y", params)
        # convert varargs to a single argument if possible
        if (type(params) is list or type(params) is tuple) and (len(params) == 1):
            params = params[0]
        UserApi.logDebug("calling stop: %y", params)
        params = self.callClassWithPrefixMethod("BBM_OndewoBpiServer", "stop", params)
        UserApi.logDebug("output from stop: %y", params)
        return params
############ GENERATED SECTION END ############
