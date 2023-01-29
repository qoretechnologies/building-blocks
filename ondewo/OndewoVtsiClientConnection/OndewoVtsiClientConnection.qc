# -*- mode: qore; indent-tabs-mode: nil -*-
# Qore OndewoVtsiClientConnection class definition

/*  OndewoVtsiClientConnection.qc Copyright 2021 Qore Technologies, s.r.o.

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the "Software"),
    to deal in the Software without restriction, including without limitation
    the rights to use, copy, modify, merge, publish, distribute, sublicense,
    and/or sell copies of the Software, and to permit persons to whom the
    Software is furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in
    all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
    FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
    DEALINGS IN THE SOFTWARE.
*/

%module-cmd(python) add-module-path $OMQ_DIR/user/python/lib/python3.8/site-packages

#! Main namespsace for the OndewoVtsiClientConnection module
public namespace OndewoVtsiClientConnection {
#! this is the public function that returns a ConnectionScheme object to Qorus for the connection
public AbstractIterator sub get_schemes() {
    softlist<ConnectionScheme> l = (
        new ConnectionScheme("ondewovtsi", "OndewoVtsiClientConnection"),
    );

    return l.iterator();
}

#! Connection class for 'ondewo.vtsi.client.Client' connection objects
/** Can only be used in remote processes; the grpc module required by the ondewo client module can only be
    initialized in a single Python interpreter
*/
public class OndewoVtsiClientConnection inherits AbstractConnectionWithInfo {
    public {
        #! Default ONDEWO NLU port
        const DefaultOndewoNluPort = 50055;

        #! Default ONDEWO VTSI port
        const DefaultOndewoVtsiPort = 443;

        #! Default ONDEWO GPRC certification location
        const DefaultOndewoCertLocation = "file://$OMQ_DIR/user/ondewo/config/server.pem";

        #! Connection entry info
        const ConnectionScheme = <ConnectionSchemeInfo>{
            "cls": Class::forName("OndewoVtsiClientConnection::OndewoVtsiClientConnection"),
            "options": {
                "bpi-service-name": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO BPI service name; this connection is made with a local BPI server service "
                        "and not directly to the ONDEWO NLU / Conversational AI server",
                },
                "bpi-external-host": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO BPI hostname to be used by the ONDEWO NLU to make the connection to the BPI "
                        "service, must be externally accessible over the internet; if this option is not set, then "
                        "the hostname of the BPI service given by `bpi-service-name` will be used instead.",
                },
                "bpi-external-port": <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "ONDEWO BPI port to be used by the ONDEWO NLU to make the connection to the BPI "
                        "service, must be externally accessible over the internet; if this option is not set, then "
                        "the port of the BPI service given by `bpi-service-name` will be used instead.",
                },
                "nlu-connection-name": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO NLU connection name; the GPRC certification location is taken from this "
                        "connection",
                    "default_value": "ondewo-nlu",
                },

                # Speech-to-Text Options
                "s2t-host":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO Speech-to-Text hostname",
                    "default_value": "grpc-s2t.ondewo.com",
                },
                "s2t-port":  <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "ONDEWO Speech-to-Text port number",
                    "default_value": 443,
                },

                # Text-to-Speech Options
                "t2s-host":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO Text-to-Speech hostname",
                    "default_value": "grpc-t2s.ondewo.com",
                },
                "t2s-port":  <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "ONDEWO Text-to-Speech port number",
                    "default_value": 443,
                },

                # Minio Options
                "minio-host":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO Minio hostname",
                    "default_value": "192.168.1.161",
                },
                "minio-port":  <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "ONDEWO Minio port",
                    "default_value": 9001,
                },
                "minio-access-key":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO Minio access key",
                },
                "minio-secret-key":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO Minio secret key",
                    "sensitive": True,
                },

                # Minio Options
                "rabbitmq-host":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO RabbitMQ hostname",
                    "default_value": "192.168.1.161",
                },
                "rabbitmq-port":  <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "ONDEWO RabbitMQ port",
                    "default_value": 5673,
                },
                "rabbitmq-port2":  <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "ONDEWO RabbitMQ port 2",
                    "default_value": 15673,
                },
                "rabbitmq-user":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO RabbitMQ user",
                },
                "rabbitmq-password":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO RabbitMQ password",
                    "sensitive": True,
                },

                # Asterisk Options
                "asterisk-host":  <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO Asterisk hostname",
                    "default_value": "192.168.1.161",
                },
                "asterisk-port":  <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "ONDEWO Asterisk port",
                    "default_value": 5060,
                },

                # ping timeout
                "connect_timeout": <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "Connect timeout in milliseconds for pings",
                    "default_value": 10000,
                },
                "secure-ping": <ConnectionOptionInfo>{
                    "type": "bool",
                    "desc": "ONDEWO VTSI secure ping flag (i.e. establish an SSL/TLS "
                        "connection after making the socket connection)",
                    "default_value": False,
                },
            },
            "required_options": "bpi-service-name,nlu-connection-name,s2t-host,s2t-port,"
                "t2s-host,t2s-port,minio-access-key,minio-secret-key,"
                "rabbitmq-user,rabbitmq-password,asterisk-host,asterisk-port,secure-ping",
        };

        #! OndewoVtsiClientConnection object connection options
        const Options = map {$1: True}, keys ConnectionScheme.options;

        #! OndewoVtsiClientConnection default options
        const DefaultOptions = map {$1.key: $1.value.default_value}, ConnectionScheme.options.pairIterator(),
            exists $1.value.default_value;

        #! Default I/O timeout for HTTP-based pings
        const DefaultHttpPingTimeout = 45s.durationMilliseconds();
    }

    #! creates the OndewoVtsiClientConnection object
    /** @param name the name of the connection
        @param desc connection description
        @param url connection URL (potentially with password info)
        @param attributes various attributes. See below
        @param options connection options

        See @ref AbstractConnection::constructor() for \c attributes and \c options reference.

        @throw CONNECTION-OPTION-ERROR missing or invalid connection option
    */
    constructor(string name, string desc, string url, hash<auto> attributes = {}, hash<auto> options = {})
        : AbstractConnectionWithInfo(name, desc, url, attributes, options) {
    }

    #! returns \c "ondewovtsi"
    string getType() {
        return "ondewovtsi";
    }

    #! Returns the connection scheme information
    hash<ConnectionSchemeInfo> getConnectionSchemeInfoImpl() {
        return ConnectionScheme;
    }

    #! returns a Python 'QorusClientConfig' object (child of 'ondewo.vtsi.client_config.ClientConfig')
    /** @param connect this argument is ignored; only a client config object is returned
        @param rtopts this connection type does not accept any runtime option, so this parameter is ignored
    */
    private object getImpl(bool connect = True, *hash<auto> rtopts) {
        return OndewoVtsiClientConnectionPriv::getConfig(opts, urlh);
    }

    #! performs the ping
    /** pings are performed by just checking the BPI port for a listener; returns a @ref PingInfo hash
    */
    private hash<PingInfo> pingIntern(hash<PingInfo> rv) {
        date start = now_us();

        # use a HTTP connection check to "ping" the server
        string url = sprintf("http%s://%s:%d", opts."secure-ping" ? "s" : "", urlh.host, urlh.port);
        HTTPClient hc({
            "url": url,
            "connect_timeout": DefaultHttpPingTimeout,
            "timeout": DefaultHttpPingTimeout,
        });
        hc.connect();

        return rv += {
            "ok": True,
            "time": now_us() - start,
            "info": "OK",
        };
    }
}
}

# private namespace, not exported
namespace Priv {
class OndewoVtsiClientConnectionPriv {
    private {
        #! Options copied directly from the connection to the internal config dict
        const DirectOptions = map keys OndewoVtsiClientConnection::ConnectionScheme.options, $1 !~ /^(bpi-|nlu-|connect)/;

        # this has no ondewo code, as we can't have any GRPC dependencies here; they can only be loaded once per
        # process
        const PythonCode = "class QorusVtsiConfigManager:
    def __init__(self, config: dict) -> None:
        self._config = config

    def is_secure(self) -> bool:
        return self._config['vtsi-secure']

    def get_config_dict(self) -> dict:
        return self._config

def get_manager(config: dict) -> QorusVtsiConfigManager:
    return QorusVtsiConfigManager(config)\n";

        #! Program object
        static PythonProgram client_pgm;

        #! client mutex
        static Mutex client_lock();

        #! client loaded
        static bool client_loaded = False;
    }

    #! Initializes the module and the PythonProgram helper object
    static init() {
        # initialize the Qorus client
        QorusClient::initFast();
        # first setup Python code
        client_pgm = new PythonProgram(PythonCode, "ondewo VTSI connection");
        # register this scheme
        ConnectionSchemeCache::registerScheme("ondewovtsi", OndewoVtsiClientConnection::ConnectionScheme);
    }

    #! Returns a QorusVtsiConfigManager object for the connection configuration
    static object getConfig(hash<auto> opts, hash<auto> urlh) {
        *hash<auto> info = UserApi::callRestApi("GET", "services/" + opts.'bpi-service-name');
        string host = opts."bpi-external-host" ?? info.processes[0].host ?? urlh.host;
        int port = opts."bpi-external-port" ?? info.config."ondewo-bpi-server-port".value ?? urlh.port
            ?? OndewoVtsiClientConnection::DefaultOndewoNluPort;

        object nlu_client_config = get_user_connection(opts."nlu-connection-name");
        hash<auto> nlu_config = nlu_client_config.get_config_dict();
        #printf("%y\n", nlu_config);

        hash<auto> config_dict = {
            "vtsi-host": urlh.host,
            "vtsi-port": urlh.port ?? OndewoVtsiClientConnection::DefaultOndewoVtsiPort,
            "vtsi-secure": nlu_config.secure,

            "cai-host": host,
            "cai-port": port,
        } + opts{DirectOptions};
        if (nlu_config.secure) {
            config_dict."vtsi-cert" = nlu_config."cert-path";
        }
        return client_pgm.callFunction("get_manager", config_dict);
    }
}
}
