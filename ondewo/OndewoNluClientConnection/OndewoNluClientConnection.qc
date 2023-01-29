# -*- mode: qore; indent-tabs-mode: nil -*-
# Qore OndewoNluClientConnection class definition

/*  OndewoNluClientConnection.qc Copyright 2021 Qore Technologies, s.r.o.

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

#! Main namespsace for the OndewoNluClientConnection module
public namespace OndewoNluClientConnection {
#! this is the public function that returns a ConnectionScheme object to Qorus for the connection
public AbstractIterator sub get_schemes() {
    softlist<ConnectionScheme> l = (
        new ConnectionScheme("ondewonlu", "OndewoNluClientConnection"),
    );

    return l.iterator();
}

#! Connection class for 'ondewo.nlu.client.Client' connection objects
/** Can only be used in remote processes; the grpc module required by the ondewo client module can only be
    initialized in a single Python interpreter
*/
public class OndewoNluClientConnection inherits AbstractConnectionWithInfo {
    public {
        #! Default ONDEWO NLU port
        const DefaultOndewoNluPort = 50055;

        #! Default ONDEWO GPRC certification location
        const DefaultOndewoCertLocation = "file://$OMQ_DIR/user/ondewo/config/server.pem";

        #! Connection entry info
        const ConnectionScheme = <ConnectionSchemeInfo>{
            "cls": Class::forName("OndewoNluClientConnection::OndewoNluClientConnection"),
            "options": {
                "http-token": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO CAI (Conversational AI)/NLU client HTTP authentication token",
                    "sensitive": True,
                },
                "username": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO CAI (Conversational AI)/NLU user name",
                },
                "password": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO CAI (Conversational AI)/NLU password",
                    "sensitive": True,
                },
                "secure": <ConnectionOptionInfo>{
                    "type": "bool",
                    "desc": "ONDEWO CAI (Conversational AI)/NLU secure flag",
                    "default_value": False,
                },
                "secure-ping": <ConnectionOptionInfo>{
                    "type": "bool",
                    "desc": "ONDEWO CAI (Conversational AI)/NLU secure ping flag (i.e. establish an SSL/TLS "
                        "connection after making the socket connection)",
                    "default_value": False,
                },
                "cert-location": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "ONDEWO GRPC Server certificate location.  Provides a "
                        "location to the certificate to be used for GRPC communication to the CAI "
                        "(Conversational AI)/VTSI.  The filename is passed to `UserApi::getTextFileFromLocation()`",
                    "default_value": DefaultOndewoCertLocation,
                },
            },
            "required_options": "http-token,username,password,secure,secure-ping",
        };

        #! OndewoNluClientConnection object connection options
        const Options = map {$1: True}, keys ConnectionScheme.options;

        #! OndewoNluClientConnection default options
        const DefaultOptions = map {$1.key: $1.value.default_value}, ConnectionScheme.options.pairIterator(),
            exists $1.value.default_value;

        #! Default I/O timeout for HTTP-based pings
        const DefaultHttpPingTimeout = 45s.durationMilliseconds();
    }

    #! creates the OndewoNluClientConnection object
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
        opts.secure = parse_boolean(opts.secure);
    }

    #! returns \c "ondewonlu"
    string getType() {
        return "ondewonlu";
    }

    #! Returns the connection scheme information
    hash<ConnectionSchemeInfo> getConnectionSchemeInfoImpl() {
        return ConnectionScheme;
    }

    #! returns a Python 'QorusClientConfig' object (child of 'ondewo.nlu.client_config.ClientConfig')
    /** @param connect this argument is ignored; only a client config object is returned
        @param rtopts this connection type does not accept any runtime option, so this parameter is ignored
    */
    private object getImpl(bool connect = True, *hash<auto> rtopts) {
        return OndewoNluClientConnectionPriv::getConfig(opts, urlh);
    }

    #! performs the ping
    /** pings are performed by dynamically loading the executing 'ondewo.nlu.client' class and creating a client from
        the config; returns a @ref PingInfo hash
    */
    private hash<PingInfo> pingIntern(hash<PingInfo> rv) {
        date start = now_us();
        if (opts.native_ping) {
            object config = get();
            # use a real ONDEWO NLU client to check the connection
            PythonProgram pgm = OndewoNluClientConnectionPriv::setupClientProgram();
            #printf("config: %y\n", config.className());
            object client = pgm.callFunction("get_ondewo_client", config);
            remove client;
        } else {
            # use a HTTP connection check to "ping" the server
            string url = sprintf("http%s://%s:%d", opts."secure-ping" ? "s" : "", urlh.host, urlh.port);
            HTTPClient hc({
                "url": url,
                "connect_timeout": DefaultHttpPingTimeout,
                "timeout": DefaultHttpPingTimeout,
            });
            hc.connect();
        }

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
class OndewoNluClientConnectionPriv {
    private {
        const PythonCode = "
import sys
import os
sys.path.append(os.environ['OMQ_DIR'] + '/user/python/lib/python3.8/site-packages')
from ondewo.nlu.client_config import ClientConfig

class QorusClientConfig(ClientConfig):
    def __init__(self, config: dict) -> None:
        self._config = config
        if config['secure']:
            super().__init__(
                host=config['host'],
                port=config['port'],
                http_token=config['http-token'],
                user_name=config['username'],
                password=config['password'],
                grpc_cert=config['cert'],
            )
        else:
            super().__init__(
                host=config['host'],
                port=config['port'],
                http_token=config['http-token'],
                user_name=config['username'],
                password=config['password'],
            )
        self.secure = config['secure']

    def is_secure(self) -> bool:
        return self.secure

    def get_config_dict(self) -> dict:
        return self._config

def get_config(config: dict) -> QorusClientConfig:
    return QorusClientConfig(config)\n";

        #! Program object
        static PythonProgram client_pgm;

        #! client mutex
        static Mutex client_lock();

        #! client loaded
        static bool client_loaded = False;
    }

    #! Initializes the module and the PythonProgram helper object
    static init() {
        # first setup Python code
        client_pgm = new PythonProgram(PythonCode, "ondewo connection");
        # register this scheme
        ConnectionSchemeCache::registerScheme("ondewonlu", OndewoNluClientConnection::ConnectionScheme);
    }

    #! Returns a QorusClientConfig object for the connection configuration
    static object getConfig(hash<auto> opts, hash<auto> urlh) {
        hash<auto> config_dict = {
            "secure": opts.secure,
            "host": urlh.host,
            "port": urlh.port ?? OndewoNluClientConnection::DefaultOndewoNluPort,
            "http-token": opts."http-token",
            "username": opts.username ?? urlh.username,
            "password": opts.password ?? urlh.password,
        };
        if (opts.secure) {
            string pem_code = UserApi::getTextFileFromLocation(opts."cert-location"
                ?? OndewoNluClientConnection::DefaultOndewoCertLocation);
            config_dict.cert = pem_code;
            # save location path as a config option
            string loc = opts."cert-location";
            loc =~ s/^file:\/\///;
            config_dict."cert-path" = substitute_env_vars(loc);
        }
        return client_pgm.callFunction("get_config", config_dict);
    }

    #! Imports the ondewo.nlu.client.Client class if not already imported
    static PythonProgram setupClientProgram() {
        if (client_loaded) {
            return client_pgm;
        }

        client_lock.lock();
        on_exit client_lock.unlock();

        # check again in the lock
        if (!client_loaded) {
            client_pgm.evalStatementKeep("from ondewo.nlu.client import Client

class QorusOndewoClient(Client):
    def __init__(self, config: QorusClientConfig) -> None:
        super().__init__(config, config.is_secure())
        self._config = config

    def get_config() -> ClientConfig:
        return self._config

    def is_secure() -> bool:
        return self._config.is_secure()

def get_ondewo_client(config: QorusClientConfig) -> QorusOndewoClient:
    return QorusOndewoClient(config)\n", "dynamic client program");
            client_loaded = True;

            #printf("loaded client\n");
        }

        return client_pgm;
    }
}
}
