import java.util.Properties;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;

import org.qore.jni.Hash;

import com.qoretechnologies.qorus.UserApi;

class BBM_JavaConfig {
    /** the required config type
     */
    enum ConfType {
        SHORT,
        INT,
        FLOAT,
    }

    /** @param prop_pfx the prefix to use to match config item names for the configuration hash

        @return the properties set from config items according to the prefix
     */
    public static Hash get(String prop_pfx) throws Throwable {
        return get(prop_pfx, null);
    }

    /** @param prop_pfx the prefix to use to match config item names for the configuration hash
        @param prop_types the types of the actual configuration names after the prefix has been stripped

        @return the properties set from config items d
     */
    public static Hash get(String prop_pfx, Map<String, ConfType> prop_types) throws Throwable {
        Hash props = new Hash();
        // the config item hash is actually returned as a Hash
        Hash config = (Hash)UserApi.getConfigItemHash();

        for (Entry<String, Object> entry : config.entrySet()) {
            Object val = entry.getValue();
            if (val == null) {
                continue;
            }
            String key = entry.getKey();
            if (key.startsWith(prop_pfx)) {
                String prop_key = key.replaceFirst(prop_pfx, "");
                // convert value if necessary
                if (prop_types != null && prop_types.containsKey(prop_key)) {
                    val = convertValue(config, key, prop_types.get(prop_key));
                }
                props.put(prop_key, val);
                UserApi.logInfo("setting %s = %y", prop_key, val);
            }
        }

        return props;
    }

    /** converts values to the required type
     */
    private static Object convertValue(Hash config, String key, ConfType type) {
        switch (type) {
            case SHORT:
                return config.getAsShort(key);

            case INT:
                return config.getAsInt(key);

            case FLOAT:
                return config.getAsFloat(key);
            }

        return null;
    }
}
