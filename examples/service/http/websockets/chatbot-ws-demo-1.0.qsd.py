from svc import QorusService
from qore.__root__ import BBM_QorusUiExtension
from qore.__root__ import BBM_WebSocketServiceEventSource
from qore.__root__.OMQ import Observer

class ChatbotWsDemo(QorusService):
    def __init__(self):
        ####### GENERATED SECTION! DON'T EDIT! ########
        self.class_connections = ClassConnections_ChatbotWsDemo()
        ############ GENERATED SECTION END ############

    ####### GENERATED SECTION! DON'T EDIT! ########
    def init(self):
        self.class_connections.UI_Extension()
    ############ GENERATED SECTION END ############

####### GENERATED SECTION! DON'T EDIT! ########
class ClassConnections_ChatbotWsDemo(Observer):
    # must inherit Observer, because there is an event-based connector
    def __init__(self):
        super(ClassConnections_ChatbotWsDemo, self).__init__()
        UserApi.startCapturingObjectsFromPython()
        # map of prefixed class names to class instances
        self.class_map = {
            'BBM_QorusUiExtension': BBM_QorusUiExtension(),
            'BBM_WebSocketServiceEventSource': BBM_WebSocketServiceEventSource(),
            'BBM_TextAnalysis': BBM_TextAnalysis(),
        }
        UserApi.stopCapturingObjectsFromPython()

        # register observers
        self.callClassWithPrefixMethod("BBM_WebSocketServiceEventSource", "registerObserver", self)

    def callClassWithPrefixMethod(self, prefixed_class, method, *argv):
        UserApi.logDebug("ClassConnections_ChatbotWsDemo: callClassWithPrefixMethod: method: %s class: %y", method, prefixed_class)
        return getattr(self.class_map[prefixed_class], method)(*argv)

    # override Observer's update()
    def update(self, id, *params):
        if (id == "BBM_WebSocketServiceEventSource::event (ignored)"):
            self.WebSockets(*params)

    def UI_Extension(self, *params):
        UserApi.logDebug("UI_Extension called with data: %y", params)
        # convert varargs to a single argument if possible
        if (type(params) is list or type(params) is tuple) and (len(params) == 1):
            params = params[0]
        UserApi.logDebug("calling init: %y", params)
        params = self.callClassWithPrefixMethod("BBM_QorusUiExtension", "init", params)
        UserApi.logDebug("output from init: %y", params)
        return params

    def WebSockets(self, *params):
        UserApi.logDebug("WebSockets called with data: %y", params)
        # convert varargs to a single argument if possible
        if (type(params) is list or type(params) is tuple) and (len(params) == 1):
            params = params[0]
        mapper = UserApi.getMapper("chatbot-ws-input")
        params = mapper.mapAuto(params)

        UserApi.logDebug("calling processInputHash: %y", params)
        params = self.callClassWithPrefixMethod("BBM_TextAnalysis", "processInputHash", params)
        UserApi.logDebug("output from processInputHash: %y", params)
        mapper = UserApi.getMapper("chatbot-ws-output")
        params = mapper.mapAuto(params)

        UserApi.logDebug("calling webSocketSendEvent: %y", params)
        params = self.callClassWithPrefixMethod("BBM_WebSocketServiceEventSource", "sendMessage", params)
        UserApi.logDebug("output from webSocketSendEvent: %y", params)
        return params
############ GENERATED SECTION END ############
