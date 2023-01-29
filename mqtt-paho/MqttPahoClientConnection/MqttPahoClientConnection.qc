# -*- mode: qore; indent-tabs-mode: nil -*-
# Qore MqttPahoClientConnection class definition

/*  MqttPahoClientConnection.qc Copyright 2021 Qore Technologies, s.r.o.

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

%module-cmd(jni) add-classpath $OMQ_DIR/user/building-blocks/mqtt-paho/jar/org.eclipse.paho.client.mqttv3-1.2.5.jar

%module-cmd(jni) import org.eclipse.paho.client.mqttv3.MqttClient
%module-cmd(jni) import org.eclipse.paho.client.mqttv3.MqttConnectOptions
%module-cmd(jni) import org.eclipse.paho.client.mqttv3.MqttException
%module-cmd(jni) import org.eclipse.paho.client.mqttv3.MqttMessage
%module-cmd(jni) import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence
%module-cmd(jni) import org.eclipse.paho.client.mqttv3.MqttCallback
%module-cmd(jni) import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken

%requires uuid

#! Main namespsace for the MqttPahoClientConnection module
public namespace MqttPahoClientConnection {
#! this is the public function that returns a ConnectionScheme object to Qorus for the connection
public AbstractIterator sub get_schemes() {
    softlist<ConnectionScheme> l = (
        new ConnectionScheme("mqttpaho", "MqttPahoClientConnection"),
    );
    return l.iterator();
}

#! Connection class for org.eclipse.paho.client.mqttv3.MqttClient connection objects
/**
*/
public class MqttPahoClientConnection inherits AbstractConnectionWithInfo {
    public {
        #! The main MQTT URI
        string mqtt_uri;

        #! Default insecure port
        const DefaultInsecurePort = 1883;

        #! Default secure port
        const DefaultSecurePort = 8883;

        #! Connection entry info
        const ConnectionScheme = <ConnectionSchemeInfo>{
            "cls": Class::forName("MqttPahoClientConnection::MqttPahoClientConnection"),
            "options": {
                "server-uris": <ConnectionOptionInfo>{
                    "type": "list",
                    "desc": "The address of additional MQTT servers in addition to the one in the URL; these URLs "
                        "should have the format: `tcp://host:port` (for an insecure connection) or `ssl://host:port` "
                        "(for a secure connection)",
                },
                "client-id": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "A client identifier that is unique on the server being connected to; if this config "
                        "item is not set, then a unique ID will be generated automatically.\n\n"
                        "**NOTE**: If durable subscriptions or reliable messaging are required, this config item "
                        "must have a persistent and unique value; automatically generated include a UUID which is "
                        "generated each time the client is created.",
                },
                "auto-reconnect": <ConnectionOptionInfo>{
                    "type": "bool",
                    "desc": "Sets whether the client will automatically attempt to reconnect to the server if the "
                        "connection is lost.\n\n"
                        "If set to `false`, the client will not attempt to automatically reconnect to the server in "
                        "the event that the connection is lost.\n\n"
                        "If set to `true`, in the event that the connection is lost, the client will attempt to "
                        "reconnect to the server. It will initially wait 1 second before it attempts to reconnect, "
                        "for every failed reconnect attempt, the delay will double until it is at 2 minutes at which "
                        "point the delay will stay at 2 minutes.",
                    "default_value": False,
                },
                "clean-session": <ConnectionOptionInfo>{
                    "type": "bool",
                    "desc": "Sets whether the client and server should remember state across restarts and "
                        "reconnects.\n\n"
                        "If set to `false`, both the client and server will maintain state across restarts of the "
                        "client, the server and the connection. As state is maintained, message delivery will be "
                        "reliable meeting the specified QOS even if the client, server or connection are restarted. "
                        "The server will treat a subscription as durable.\n\n"
                        "If set to `true` the client and server will not maintain state across restarts of the "
                        "client, the server or the connection. This means Message delivery to the specified QOS "
                        "cannot be maintained if the client, server or connection are restarted. The server will "
                        "treat a subscription as non-durable",
                    "default_value": True,
                },
                "connection-timeout-secs": <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "Sets the connection timeout value. This value, measured in seconds, defines the maximum "
                        "time interval the client will wait for the network connection to the MQTT server to be "
                        "established.\n\n"
                        "A value of `0` disables timeout processing meaning the client will wait until the network "
                        "connection is made successfully or fails.",
                    "default_value": 30,
                },
                "keep-alive-interval-secs": <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "Sets the \"keep alive\" interval. This value, measured in seconds, defines the maximum "
                        "time interval between messages sent or received. It enables the client to detect if the "
                        "server is no longer available, without having to wait for the TCP/IP timeout.\n\n"
                        "The client will ensure that at least one message travels across the network within each "
                        "keep alive period.\n\n"
                        "In the absence of a data-related message during the time period, the client sends a very "
                        "small \"ping\" message, which the server will acknowledge. A value of `0` disables "
                        "keepalive processing in the client.",
                    "default_value": 60,
                },
                "max-in-flight": <ConnectionOptionInfo>{
                    "type": "int",
                    "desc": "Sets the \"max inflight\" value. Please increase this value in a high traffic "
                        "environment.",
                    "default_value": 10,
                },
                "mqtt-version": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "Sets the MQTT protocol version to use for the connection.",
                    "allowed_values": (
                        <AllowedValueInfo>{
                            "value": "MQTT_VERSION_DEFAULT",
                            "desc": "connect with version 3.1.1, and to fall back to 3.1 if that fails.",
                        },
                        <AllowedValueInfo>{
                            "value": "MQTT_VERSION_3_1",
                            "desc": "3.1 only",
                        },
                        <AllowedValueInfo>{
                            "value": "MQTT_VERSION_3_1_1",
                            "desc": "3.1.1 only",
                        },
                    ),
                    "default_value": "MQTT_VERSION_DEFAULT",
                },

                "username": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "MQTT server user name",
                },
                "password": <ConnectionOptionInfo>{
                    "type": "string",
                    "desc": "MQTT server password",
                    "sensitive": True,
                },

                "secure": <ConnectionOptionInfo>{
                    "type": "bool",
                    "desc": "MQTT client secure flag (make a TLS/SSL connection)",
                    "default_value": False,
                },

                "ssl-properties": <ConnectionOptionInfo>{
                    "type": "hash",
                    "desc": "Sets the SSL properties for the connection. Note that these properties are only valid "
                        "if an implementation of the Java Secure Socket Extensions (JSSE) is available.\n\n"
                        "The following properties can be used:\n"
                        "- `com.ibm.ssl.protocol`: One of: `SSL`, `SSLv3`, `TLS`, `TLSv1`, `SSL_TLS`.\n"
                        "- `com.ibm.ssl.contextProvider`: Underlying JSSE provider. For example `IBMJSSE2` or "
                            "`SunJSSE`\n"
                        "- `com.ibm.ssl.keyStore`: The name of the file that contains the KeyStore object that you "
                            "want the KeyManager to use. For example `/mydir/etc/key.p12`\n"
                        "- `com.ibm.ssl.keyStorePassword`: The password for the KeyStore object that you want the "
                            "KeyManager to use.\n"
                        "- `com.ibm.ssl.keyStoreType`: Type of key store, for example `PKCS12`, `JKS`, or `JCEKS`.\n"
                        "- `com.ibm.ssl.keyStoreProvider`: Key store provider, for example `IBMJCE` or `IBMJCEFIPS`.\n"
                        "- `com.ibm.ssl.trustStore`: The name of the file that contains the KeyStore object that you "
                            "want the TrustManager to use.\n"
                        "- `com.ibm.ssl.trustStorePassword`: The password for the TrustStore object that you want "
                            "the TrustManager to use.\n"
                        "- `com.ibm.ssl.trustStoreType`: The type of KeyStore object that you want the default "
                            "TrustManager to use. Same possible values as `keyStoreType`.\n"
                        "- `com.ibm.ssl.trustStoreProvider`: Trust store provider, for example `IBMJCE` or "
                            "`IBMJCEFIPS`.\n"
                        "- `com.ibm.ssl.enabledCipherSuites`: A list of which ciphers are enabled. Values are "
                            "dependent on the provider, for example: "
                            "`SSL_RSA_WITH_AES_128_CBC_SHA;lSSL_RSA_WITH_3DES_EDE_CBC_SHA`.\n"
                        "- `com.ibm.ssl.keyManager`: Sets the algorithm that will be used to instantiate a "
                            "KeyManagerFactory object instead of using the default algorithm available in the "
                            "platform. Example values: `IbmX509` or `IBMJ9X509`.\n"
                        "- `com.ibm.ssl.trustManager`: Sets the algorithm that will be used to instantiate a "
                            "TrustManagerFactory object instead of using the default algorithm available in the "
                            "platform. Example values: `PKIX` or `IBMJ9X509`.",
                },
            },
        };

        #! MqttPahoClientConnection object connection options
        const Options = map {$1: True}, keys ConnectionScheme.options;

        #! MqttPahoClientConnection default options
        const DefaultOptions = map {$1.key: $1.value.default_value}, ConnectionScheme.options.pairIterator(),
            exists $1.value.default_value;
    }

    #! creates the MqttPahoClientConnection object
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
        if (*list<auto> invalid_uris = map $1, opts."server-uris", $1.typeCode() != NT_STRING) {
            throw "CONNECTION-OPTION-ERROR", sprintf("invalid values in 'server-uris': %y; all entries must be "
                "strings");
        }
        mqtt_uri = url;
        if (!urlh.port) {
            mqtt_uri += ":";
            mqtt_uri += opts.secure ? DefaultSecurePort : DefaultInsecurePort;
        }
        if (opts.secure) {
            mqtt_uri =~ s/^mqttpaho:\/\//ssl:\/\//;
        } else {
            mqtt_uri =~ s/^mqttpaho:\/\//tcp:\/\//;
        }
    }

    #! returns \c "mqttpaho"
    string getType() {
        return "mqttpaho";
    }

    #! Returns the connection scheme information
    hash<ConnectionSchemeInfo> getConnectionSchemeInfoImpl() {
        return ConnectionScheme;
    }

    #! returns an object of connection parameters that can be used to create an MqttClient object
    /** @param connect this argument is ignored; only a client config object is returned
        @param rtopts this connection type does not accept any runtime option, so this parameter is ignored
    */
    private ConnectionOptions getImpl(bool connect = True, *hash<auto> rtopts) {
        return new ConnectionOptions(opts + {
            "mqtt_uri": mqtt_uri,
        });
    }

    #! performs the ping
    /** pings are performed by dynamically loading the executing 'ondewo.nlu.client' class and creating a client from
        the config; returns a @ref PingInfo hash
    */
    private hash<PingInfo> pingIntern(hash<PingInfo> rv) {
        MqttConnectOptions connOpts();
        connOpts.setAutomaticReconnect(opts."auto-reconnect");
        connOpts.setCleanSession(opts."clean-session");
        connOpts.setConnectionTimeout(opts."connection-timeout-secs");
        connOpts.setKeepAliveInterval(opts."keep-alive-interval-secs");
        connOpts.setMaxInflight(opts."max-in-flight");
        switch (opts."mqtt-version") {
            case "MQTT_VERSION_3_1_1":
                connOpts.setMqttVersion(MqttConnectOptions::MQTT_VERSION_3_1_1);
                break;
            case "MQTT_VERSION_3_1":
                connOpts.setMqttVersion(MqttConnectOptions::MQTT_VERSION_3_1);
                break;
        }
        if (opts.username.val()) {
            connOpts.setUserName(opts.username);
        }
        if (opts.password.val()) {
            connOpts.setPassword(opts.password);
        }
        if (opts."ssl-properties") {
            Properties props();
            map props.setProperty($1.key, $1.value), opts."ssl-properties".pairIterator();
            connOpts.setSSLProperties(props);
        }        string mqtt_url = url;

        # do not use the client_id when pinging
        string client_id = sprintf("mqtt-paho-qorus-monitor-%s-%s", name, UUID::get());
        date start = now_us();
        MqttClient client(mqtt_uri, client_id);
        client.connect(connOpts);
        on_exit client.disconnect();

        return rv += {
            "ok": True,
            "time": now_us() - start,
            "info": "OK",
        };
    }
}

public class ConnectionOptions {
    public {
        hash<auto> h;
    }

    constructor(hash<auto> h) {
        self.h = h;
    }

    hash<auto> getOptions() {
        return h;
    }
}
}

# private namespace, not exported
namespace Priv {
class MqttPahoClientConnectionPriv {
    public {
    }

    #! Initializes the module and the PythonProgram helper object
    static init() {
        # register this scheme
        ConnectionSchemeCache::registerScheme("mqttpaho", MqttPahoClientConnection::ConnectionScheme);
    }
}
}
