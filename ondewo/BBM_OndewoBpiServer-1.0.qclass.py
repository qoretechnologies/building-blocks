import os
import time

os.chdir(os.environ['OMQ_DIR'] + '/user/ondewo')

from typing import Optional, Tuple
import logging

from ondewo.nlu import session_pb2, user_pb2
import grpc

#from ondewo.nlu import session_pb2, intent_pb2, user_pb2, context_pb2

from ondewo_bpi.bpi_server import BpiServer
from ondewo_bpi.example.login_mock import MockUserLoginServer, PortChecker
from ondewo_bpi.message_handler import MessageHandler

from ondewo.nlu.client import Client
from ondewo.nlu.client_config import ClientConfig
from ondewo_bpi.config import PORT, CentralClientProvider
import ondewo_bpi.config

from qore.__root__.Qore.Thread import Mutex, Condition
from qore.__root__.OMQ import Observable

class QorusCentralClientProvider(CentralClientProvider):
    def __init__(self) -> None:
        self._built = False
        self.client = BBM_OndewoNluClient()
        self.config = self.client.get_config()

        # align global vars in client module with configuration used
        ondewo_bpi.config.PORT = str(UserApi.getConfigItemValue("ondewo-bpi-server-port"))
        ondewo_bpi.config.CAI_HOST = self.config.host
        ondewo_bpi.config.CAI_PORT = self.config.port
        ondewo_bpi.config.CAI_TOKEN = self.config.http_token
        ondewo_bpi.config.HTTP_AUTH_TOKEN = self.config.http_token
        ondewo_bpi.config.USER_NAME = self.config.user_name
        ondewo_bpi.config.USER_PASS = self.config.password
        ondewo_bpi.config.SECURE = self.client.is_secure()
        UserApi.logInfo("using username: %y", ondewo_bpi.config.USER_NAME)

    def _instantiate_client(self, cai_port: str = "") -> Tuple[ClientConfig, Client]:
        return self.client, self.config

class QorusBpiServer(BpiServer):
    """
    Qorus ONDEWO BPI Server Building Block
    """

    def __init__(self, observer: Observable) -> None:
        # update module name for logger
        os.environ["MODULE_NAME"] = "qorus_bpi_server"
        self.stop_flag = False
        self.mutex = Mutex()
        self.cond = Condition()
        self.observer = observer
        # BpiServer.__init__() triggers Client-init and Login() grpc call
        super().__init__(QorusCentralClientProvider())
        self.register_handlers()

    def register_handlers(self) -> None:
        self.register_intent_handler(
            intent_pattern=r"Default \.*", handlers=[self.handle_default_intents],
        )
        self.register_intent_handler(
            intent_pattern=r"i.*\.*", handlers=[self.handle_custom_intents],
        )

    def handle_default_intents(self, response: session_pb2.DetectIntentResponse) -> session_pb2.DetectIntentResponse:
        UserApi.logWarn("Default intent handler was triggered!")
        self.observer.intentEvent(response)
        return response

    def handle_custom_intents(self, response: session_pb2.DetectIntentResponse) -> session_pb2.DetectIntentResponse:
        UserApi.logWarn("Custom intent handler was triggered!")
        self.observer.intentEvent(response)
        return response

    def Login(self, request: user_pb2.LoginRequest, context: grpc.ServicerContext) -> user_pb2.LoginResponse:
        request.user_email = ondewo_bpi.config.USER_NAME
        request.password = ondewo_bpi.config.USER_PASS
        return super().Login(request, context)

    def serve(self) -> None:
        UserApi.logInfo(f"attempting to start server on port {PORT}")
        self._setup_server()
        UserApi.logWarn("%y", {"message": f"Server started on port {PORT}", "content": PORT})
        UserApi.logWarn("%y",
            {
                "message": f"using intent handlers list {self.intent_handlers}",
                "content": self.intent_handlers,
            }
        )
        # wait until stop issued
        self.mutex.lock()
        while (not self.stop_flag):
            self.cond.wait(self.mutex)
        self.mutex.unlock()
        UserApi.logInfo("%y", {"message": "server shut down", "tags": ["timing"]})

    def stop(self) -> None:
        self.mutex.lock()
        self.stop_flag = True
        self.cond.signal()
        self.mutex.unlock()

class QorusPythonLoggingHandler(logging.Handler):
    def __init__(self):
        super().__init__(logging.DEBUG)

    def emit(self, record):
        msg = 'BPI: ' + self.format(record)
        if record.levelno >= logging.CRITICAL:
            UserApi.logFatal("%s", msg)
        elif record.levelno >= logging.ERROR:
            UserApi.logError("%s", msg)
        elif record.levelno >= logging.WARNING:
            UserApi.logWarn("%s", msg)
        elif record.levelno >= logging.INFO:
            UserApi.logInfo("%s", msg)
        elif record.levelno >= logging.DEBUG:
            UserApi.logDebug("%s", msg)
        else:
            UserApi.logTrace("%s", msg)

class BBM_OndewoBpiServer(Observable):
    def __init__(self) -> None:
        super().__init__()
        BBM_OndewoBpiServer.singleton = self

    def start(self, params) -> None:
        logging.basicConfig(force=True, handlers=(QorusPythonLoggingHandler(),), level=logging.DEBUG)
        self.server = QorusBpiServer(self)
        self.server.serve()

    def stop(self, params) -> None:
        self.server.stop()

    # notify observers of intent event
    @staticmethod
    def intentEvent(intentResponse: session_pb2.DetectIntentResponse) -> None:
        UserApi.logInfo("intentEvent(), before self.notifyObservers: %y", intentResponse)
        intent: str = str(intentResponse.query_result.intent.display_name)
        # convert context parameters to a 2 layer dict: context name -> parameter name -> value
        context_params = {}
        for output_context in intentResponse.query_result.output_contexts:
            for key in output_context.parameters:
                #UserApi.logInfo("context %y param key %y = %y (%y)", output_context.name, key,
                #    output_context.parameters[key].value, context_params)
                if not output_context.name in context_params:
                    context_params[output_context.name] = {}
                context_params[output_context.name][key] = output_context.parameters[key].value
        UserApi.logInfo("intent: %y context_params: %y", intent, context_params)
        BBM_OndewoBpiServer.singleton.notifyObservers(
            "BBM_OndewoBpiServer::intentEvent", {
                'intent': intent,
                'context_params': context_params,
                'event': intentResponse
            })
        UserApi.logInfo("intentEvent(), after self.notifyObservers: %y", intentResponse)
