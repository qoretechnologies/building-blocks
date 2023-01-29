/** Qorus MQTT Paho client building block
 *
 */

import qore.OMQ.UserApi.UserApi;

import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.MqttClientPersistence;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;

import java.util.Properties;
import java.util.UUID;

import org.qore.jni.Hash;
import org.qore.jni.QoreException;

import qore.OMQ.Observable;

class BBM_MqttPahoClient extends MqttClient {
    protected MqttConnectOptions connOpts;

    protected static Hash connection_options;

    /** Creates the object from configuration in config items
     */
    public BBM_MqttPahoClient() throws Throwable {
        super(getConnectionUri(), getConnectionClientId(), getPersistence());
        connOpts = getConnectionOptions();
    }

    public MqttConnectOptions getConnectionOptionsObject() {
        return connOpts;
    }

    public Hash getConnectionOptionsHash() {
        return connection_options;
    }

    /** Connects to the server
     */
    public void connect() throws MqttException {
        try {
            UserApi.logInfo("Connecting to MQTT server...");
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
        super.connect(connOpts);
        try {
            UserApi.logInfo("Connected to server: %y", getCurrentServerURI());
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
    }

    /** Disconnects from the server
     */
    public void disconnect() throws MqttException {
        try {
            UserApi.logInfo("Disconnecting from server: %y", getCurrentServerURI());
        } catch (Throwable t) {
            throw new RuntimeException(t);
        }
        super.disconnect();
    }

    public static String getConnectionUri() throws Throwable {
        // we get an option with a "getOptions" method that has to be invoked to get the connection hash
        Object co = UserApi.getUserConnection(
            (String)UserApi.getConfigItemValue("mqtt-paho-connection-name")
        );
        connection_options = (Hash)co.getClass().getMethod("getOptions").invoke(co);
        UserApi.logInfo("connection_options: %y", connection_options);
        String uri = (String)connection_options.get("mqtt_uri");
        UserApi.logInfo("using URI: %y", uri);
        return uri;
    }

    /** Returns the URI for the connection
     */
    public static String getConnectionClientId() throws Throwable {
        String client_id = (String)connection_options.get("client-id");
        if (client_id == null) {
            // generate a client ID automatically
            Hash info = (Hash)UserApi.getUserContextInfo();
            client_id = String.format("%s %s v%s (%d) %s",
                (String)info.get("type"),
                (String)info.get("name"),
                (String)info.get("version"),
                (Long)info.get("id"),
                UUID.randomUUID().toString()
            );
        }
        UserApi.logInfo("using client_id: %y", client_id);
        return client_id;
    }

    /** Returns a persistence object for the connection
     */
    public static MqttClientPersistence getPersistence() {
        return new MemoryPersistence();
    }

    /** Returns an MqttConnectOptions object based on configuration
     */
    public static MqttConnectOptions getConnectionOptions() throws Throwable {
        MqttConnectOptions connOpts = new MqttConnectOptions();

        boolean auto_reconnect = (boolean)connection_options.get("auto-reconnect");
        connOpts.setAutomaticReconnect(auto_reconnect);

        boolean clean_session = (boolean)connection_options.get("clean-session");
        connOpts.setCleanSession(clean_session);

        int connection_timeout = (int)(long)(Long)connection_options.get("connection-timeout-secs");
        connOpts.setConnectionTimeout(connection_timeout);

        int keep_alive_interval = (int)(long)(Long)connection_options.get("keep-alive-interval-secs");
        connOpts.setKeepAliveInterval(keep_alive_interval);

        int max_in_flight = (int)(long)(Long)connection_options.get("max-in-flight");
        connOpts.setMaxInflight(max_in_flight);

        String mqtt_version = (String)connection_options.get("mqtt-version");
        if (mqtt_version.equals("MQTT_VERSION_3_1_1")) {
            connOpts.setMqttVersion(MqttConnectOptions.MQTT_VERSION_3_1_1);
        } else if (mqtt_version.equals("MQTT_VERSION_3_1")) {
            connOpts.setMqttVersion(MqttConnectOptions.MQTT_VERSION_3_1);
        }

        String username = (String)connection_options.get("username");
        if (username != null) {
            connOpts.setUserName(username);
        }

        String password = (String)connection_options.get("password");
        if (password != null) {
            connOpts.setPassword(password.toCharArray());
        }

        // SSL properties
        Hash ssl_props = (Hash)connection_options.get("ssl-properties");
        if (ssl_props != null) {
            Properties props = new Properties();
            for (var entry : ssl_props.entrySet()) {
                String key = getString(entry.getKey(), "SSL property key");
                String value = getString(entry.getValue(), "SSL property value");
                props.setProperty(key, value);
            }
            connOpts.setSSLProperties(props);
        }

        String[] server_uris = (String[])connection_options.get("server-uris");
        String[] new_server_uris;
        String mqtt_uri = (String)connection_options.get("mqtt-uri");
        if (server_uris != null && server_uris.length > 0) {
            new_server_uris = new String[server_uris.length + 1];
            new_server_uris[0] = mqtt_uri;
            System.arraycopy(server_uris, 0, new_server_uris, 1, server_uris.length);
            connOpts.setServerURIs(new_server_uris);
        } else {
            new_server_uris = null;
        }

        UserApi.logInfo("MqttClient connection options: servers: %y username: %y password: %s auto_reconnect: %y " +
            "clean_session: %y connection_timeout: %ds keep_alive_interval: %ds max_in_flight: %d mqtt_version: %y " +
            "ssl_props: %y", new_server_uris == null ? mqtt_uri : new_server_uris, username,
            password == null ? "null" : "<masked>", auto_reconnect, clean_session, connection_timeout,
            keep_alive_interval, max_in_flight, mqtt_version, ssl_props);

        return connOpts;
    }

    protected static String getString(Object v, String what) throws Throwable {
        if (v == null) {
            throw new QoreException("INVALID-PROPERTY-TYPE", String.format("got null in %s", what));
        }
        if (!(v instanceof String)) {
            throw new QoreException("INVALID-PROPERTY-TYPE", String.format("got type %s in %s; expected String",
                v.getClass().getName(), what));
        }
        return (String)v;
    }
}
