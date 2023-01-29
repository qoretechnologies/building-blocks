from ondewo.nlu.client import Client
from ondewo.nlu.client_config import ClientConfig
from ondewo_bpi.config import PORT, CentralClientProvider
import ondewo_bpi.config

class BBM_OndewoNluClient(Client):
    def __init__(self) -> None:
        # Returns a QorusClientConfig object that inherits ondewo.nlu.client_config.ClientConfig and also contains an
        # "is_secure()"" method, however the class is from another interpreter and therefore cannot be used uses as a
        # ClientConfig object
        tmp_config = UserApi.getUserConnection(UserApi.getConfigItemValue("ondewo-nlu-connection"))
        config_dict = tmp_config.get_config_dict()
        UserApi.logDebug("using config: %y", config_dict)
        self.secure = config_dict['secure']
        if config_dict['secure']:
            self.client_config = ClientConfig(
                host=config_dict['host'],
                port=config_dict['port'],
                http_token=config_dict['http-token'],
                user_name=config_dict['username'],
                password=config_dict['password'],
                grpc_cert=config_dict['cert']
            )
        else:
            self.client_config = ClientConfig(
                host=config_dict['host'],
                port=config_dict['port'],
                http_token=config_dict['http-token'],
                user_name=config_dict['username'],
                password=config_dict['password'],
            )

        super().__init__(self.client_config, config_dict['secure'])

    def get_config(self) -> ClientConfig:
        return self.client_config

    def is_secure(self) -> bool:
        return self.secure
