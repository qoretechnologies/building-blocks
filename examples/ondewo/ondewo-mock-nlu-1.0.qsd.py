from svc import QorusService

from ondewo_bpi.example.login_mock import MockUserLoginServer

class OndewoMockNlu(QorusService):
    def init(self):
        port = UserApi.getConfigItemValue("ondewo-mock-nlu-port")
        self.mock_login_server = MockUserLoginServer()
        # start mock-login server
        self.mock_login_server.serve(port)
