import uuid
from typing import Dict, Optional
from ondewo.nlu import context_pb2
from ondewo.s2t.speech_to_text_pb2 import TranscribeRequestConfig
from ondewo.t2s.text_to_speech_pb2 import RequestConfig
from ondewo.vtsi.client import VtsiClient, VtsiConfiguration
from ondewo.vtsi.client import create_parameter_dict
from ondewo.vtsi.voip_pb2 import StartCallInstanceRequest, StartMultipleCallInstancesRequest, S2TConfig, T2SConfig, \
    BaseServiceConfig, CsiConfig, AudioObjectStorageConfig, MessageBrokerConfig, RabbitMqConfig, MinioConfig, \
    Endpoint, AsteriskConfig, CommonServicesConfigs, NLUConfig, SIPConfig
from ondewo.s2t import speech_to_text_pb2

import os
import sys

#from ondewo.vtsi.client import ConfigManager
#from ondewo.vtsi.dataclasses.server_configurations_dataclasses import AudioConfiguration, \
#    AsteriskConfiguration, CaiConfiguration
#from ondewo.vtsi.voip_pb2 import StartCallInstanceResponse

class BBM_OndewoVtsiClient(VtsiClient):
    def __init__(self) -> None:
        # Returns a QorusVtsiConfigManager object
        self.vtsi_connection = UserApi.getUserConnection(
            UserApi.getConfigItemValue("ondewo-vtsi-connection"))
        self.vtsi_config: dict = self.vtsi_connection.get_config_dict()
        UserApi.logInfo("vtsi conn: %y: %y config: %y", self.vtsi_connection, self.vtsi_config,
            UserApi.getConfigItemHash())

        cert_path = self.vtsi_config.get('vtsi-cert', '')
        if cert_path and os.path.exists(cert_path):
            with open(cert_path, 'r') as f:
                self.cert_data = f.read()

        self.csi_config = CsiConfig(
            audio_object_store_config = AudioObjectStorageConfig(
                minio_config = MinioConfig(
                    endpoint = Endpoint(host = self.vtsi_config['minio-host'], port = str(self.vtsi_config['minio-port'])),
                    access_key = self.vtsi_config['minio-access-key'],
                    secret_key = self.vtsi_config['minio-secret-key'],
                )
            ),
            message_broker_config = MessageBrokerConfig(
                rabbit_mq_config = RabbitMqConfig(
                    host = self.vtsi_config['rabbitmq-host'],
                    port = str(self.vtsi_config['rabbitmq-port']),
                    port_2 = str(self.vtsi_config['rabbitmq-port2']),
                    user = self.vtsi_config['rabbitmq-user'],
                    password = self.vtsi_config['rabbitmq-password'],
                )
            ),
        )

        self.asterisk_config = AsteriskConfig(
            base_config = BaseServiceConfig(
                host = self.vtsi_config['asterisk-host'],
                port = self.vtsi_config['asterisk-port'],
            ),
        )

        voip_config = VtsiConfiguration(
            host = self.vtsi_config['vtsi-host'],
            port = str(self.vtsi_config['vtsi-port']),
            secure = self.vtsi_config['vtsi-secure'],
            cert_path = cert_path,
        )
        super().__init__(config_voip = voip_config)

    def get_service_configs(self, contexts) -> CommonServicesConfigs:
        cai_project_id: str = UserApi.getConfigItemValue("ondewo-project-id")
        cai_language: str = UserApi.getConfigItemValue("ondewo-cai-language")
        initial_intent: str = UserApi.getConfigItemValue("ondewo-project-initial-intent")

        UserApi.logDebug("BBM_OndewoVtsiClient: ondewo-project-initial-intent: %y", initial_intent)

        # do not send grpc_cert, as the SIP must connect to our BPI server with an insecure connection
        cai_config = NLUConfig(
            base_config = BaseServiceConfig(
                host = self.vtsi_config['cai-host'],
                port = self.vtsi_config['cai-port'],
            ),
            project_id = cai_project_id,
            initial_intent = initial_intent,
            contexts = contexts,
            language_code = cai_language,
        )

        s2t_language: str = UserApi.getConfigItemValue("ondewo-project-language-model")
        t2s_language: str = UserApi.getConfigItemValue("ondewo-project-voice")

        tts_config_internal: RequestConfig = RequestConfig(t2s_pipeline_id = t2s_language, length_scale = 0.9)
        tts_config = T2SConfig(
            base_config = BaseServiceConfig(
                host = self.vtsi_config['t2s-host'],
                port = self.vtsi_config['t2s-port'],
                grpc_cert = self.cert_data or '',
            ),
            t2s_config = tts_config_internal,
        )

        stt_config_internal: TranscribeRequestConfig = TranscribeRequestConfig(
            s2t_pipeline_id = s2t_language,
            ctc_decoding = speech_to_text_pb2.CTCDecoding.BEAM_SEARCH_WITH_LM,
            return_options = speech_to_text_pb2.TranscriptionReturnOptions(
                return_audio = True
            ),
        )
        stt_config = S2TConfig(
            base_config = BaseServiceConfig(
                host = self.vtsi_config['s2t-host'],
                port = self.vtsi_config['s2t-port'],
                grpc_cert = self.cert_data or '',
            ),
            s2t_config = stt_config_internal,
        )

        return CommonServicesConfigs(
            asterisk_config = self.asterisk_config,
            cai_config = cai_config,
            tts_config = tts_config,
            stt_config = stt_config,
            csi_config = self.csi_config,
        )

    def get_config_dict(self) -> dict:
        return self.vtsi_connection.get_config_dict()

    def is_secure(self) -> bool:
        return self.vtsi_connection.is_secure()

    def get_project_id(self) -> str:
        return UserApi.getConfigItemValue("ondewo-project-id")

    # Helper function to convert plain dictionary format to ONDEWO Context Parameter dictionary format
    def create_parameter_dict(self, my_dict: Dict) -> Optional[Dict[str, context_pb2.Context.Parameter]]:
        assert isinstance(my_dict, dict) or my_dict is None, "parameter must be a dict or None"
        if my_dict is not None:
            return {
                key: context_pb2.Context.Parameter(
                    display_name = key,
                    value = my_dict[key]
                )
                for key in my_dict
            }
        return None

    # Helper function to append context to the contexts list
    def append_context(self, contexts_to_pass, input_context_parameters: Dict[str, str], name: str):
        context = context_pb2.Context(
            name=name,
            lifespan_count=10000,
            parameters=self.create_parameter_dict(input_context_parameters),
        )
        contexts_to_pass.append(context)

    def createContextParameter(self, contexts_to_pass, project_id: str, call_id: str, call_info_params: Dict[str, str]):
        # Append to input context list (several context can be added)
        self.append_context(
            contexts_to_pass,
            call_info_params,
            name = f"projects/{project_id}/agent/sessions/{call_id}/contexts/input"
        )
        UserApi.logDebug("BBM_OndewoVtsiClient: contexts_to_pass: %y", contexts_to_pass)
        UserApi.logDebug("BBM_OndewoVtsiClient: contexts_to_pass: parameters: %y", contexts_to_pass[0].parameters)

    def startCaller(self, input):
        UserApi.logDebug("BBM_OndewoVtsiClient: startCaller")

        UserApi.logDebug("BBM_OndewoVtsiClient: startCaller: input: %y", input)

        phone_number: str = UserApi.getConfigItemValue("vtsi-client-phone-number")
        call_parameter = UserApi.getConfigItemValue("vtsi-client-call-parameter")
        sip_sim_version: str = UserApi.getConfigItemValue("ondewo-sip-sim-version")
        output_item = UserApi.getConfigItemValue("vtsi-client-output-data", None, False)

        UserApi.logDebug("BBM_OndewoVtsiClient: call_parameter: %y", call_parameter)
        UserApi.logDebug("BBM_OndewoVtsiClient: ondewo-sip-sim-version: %y", sip_sim_version)

        call_id = str(uuid.uuid4())
        UserApi.logDebug("BBM_OndewoVtsiClient: call_id: %y", call_id)

        cai_project_id: str = UserApi.getConfigItemValue("ondewo-project-id")
        UserApi.logDebug("BBM_OndewoVtsiClient: ondewo-project-id: %y", cai_project_id)

        contexts_to_pass = []
        self.createContextParameter(contexts_to_pass, project_id = cai_project_id, call_id = call_id,
            call_info_params = call_parameter)

        # Setup and start call
        UserApi.logDebug("BBM_OndewoVtsiClient: start call with phone number: %y", phone_number)
        UserApi.logDebug("BBM_OndewoVtsiClient: start call with call parameter: %y", call_parameter)

        sip_config = SIPConfig(
            call_id = call_id,
            sip_sim_version = sip_sim_version,
            phone_number = phone_number,
            headers = None,
        )

        service_configs: CommonServicesConfigs = self.get_service_configs(contexts_to_pass)

        start_call_instance_request = StartCallInstanceRequest(
            sip_config = sip_config,
            services_configs = service_configs,
        )
        response: StartCallInstanceResponse = self.start_call_instance_request(start_call_instance_request)

        UserApi.logDebug("BBM_OndewoVtsiClient: response: %y", repr(response))
        UserApi.logDebug("BBM_OndewoVtsiClient: response.request: %y", response.request)
        UserApi.logDebug("BBM_OndewoVtsiClient: response.success: %y", response.success)

        UserApi.logDebug("BBM_OndewoVtsiClient: startCaller: output_item: %y", output_item)
        if output_item:
            UserApi.updateOutputData({'call_id': call_id}, output_item)
        return input

    def startListener(self, input):
        UserApi.logDebug("BBM_OndewoVtsiClient: startListener")
        return input
