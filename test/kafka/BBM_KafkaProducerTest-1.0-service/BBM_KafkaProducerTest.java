import qore.OMQ.*;
import qore.OMQ.UserApi.*;
import qore.OMQ.UserApi.Service.*;

import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import org.qore.jni.Hash;

class BBM_KafkaProducerTest extends QorusService {
    private BBM_KafkaProducer prod;

    public BBM_KafkaProducerTest() throws Throwable {
        super();
    }

    public void init() throws Throwable {
        prod = new BBM_KafkaProducer();
    }

    public void stop() {
        prod.close();
    }

    public Hash sendMessage(String topic, Object value) throws Throwable {
        Hash msg = new Hash() {
            {
                put("topic", topic);
                put("value", value);
            }
        };
        return prod.sendMessage(msg);
    }

    public Hash sendMessage(String topic, Object key, Object value) throws Throwable {
        Hash msg = new Hash() {
            {
                put("topic", topic);
                put("key", key);
                put("value", value);
            }
        };
        return prod.sendMessage(msg);
    }

    public Hash sendMessage(String topic, Integer partition, Object key, Object value) throws Throwable {
        Hash msg = new Hash() {
            {
                put("topic", topic);
                put("partition", partition);
                put("key", key);
                put("value", value);
            }
        };
        return prod.sendMessage(msg);
    }

    public Hash sendMessage(Hash msg) throws Throwable {
        return prod.sendMessage(msg);
    }
}
