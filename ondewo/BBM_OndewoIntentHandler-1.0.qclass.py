from ondewo.nlu import session_pb2

# ONDEWO intent handling class
class BBM_OndewoIntentHandler:
    # this method also has a connector with the same name
    # the "intent" dict has a single key: "event" which is a session_pb2.DetectIntentResponse object
    def handleIntent(self, intent: dict) -> dict:
        UserApi.logInfo("BBM_OndewoIntentHandler.handleIntent() %y", intent)
        return intent
