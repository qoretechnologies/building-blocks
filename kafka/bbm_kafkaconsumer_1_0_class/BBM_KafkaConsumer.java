import org.apache.kafka.clients.consumer.KafkaConsumer;
import org.apache.kafka.common.errors.WakeupException;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.common.record.TimestampType;
import org.apache.kafka.common.header.Headers;
import org.apache.kafka.common.header.Header;

import org.qore.jni.Hash;

import qore.OMQ.UserApi.UserApi;
import qore.OMQ.Observable;

import java.util.Map;
import java.util.HashMap;
import java.util.Collections;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.Arrays;
import java.util.concurrent.locks.ReentrantLock;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.Iterator;
import java.util.Optional;
import java.util.TimeZone;
import java.time.ZonedDateTime;
import java.time.Instant;
import java.time.Duration;

/** Creates a KafkaConsumer object based on configuration
 */
class BBM_KafkaConsumer extends Observable {
    /** The consumer
     */
    protected KafkaConsumer<Object, Object> cons;

    /** quit flag
     */
    private final AtomicBoolean quit = new AtomicBoolean(false);

    /** done lock
    */
    private final Lock lock = new ReentrantLock();
    /** done condition
    */
    private Condition done_cond = lock.newCondition();
    /** running flag
    */
    private boolean running = false;

    // describe the actual types, as kafka will convert from strings to anything, but insists on the correct base type
    /** keys are the actual configuration names, not the config item names
     */
    public static final Map<String, BBM_JavaConfig.ConfType> PropTypeMap =
        Collections.unmodifiableMap(new HashMap<String, BBM_JavaConfig.ConfType>() {
        {
            put("fetch.min.bytes", BBM_JavaConfig.ConfType.INT);
            put("heartbeat.interval.ms", BBM_JavaConfig.ConfType.INT);
            put("max.partition.fetch.bytes", BBM_JavaConfig.ConfType.INT);
            put("session.timeout.ms", BBM_JavaConfig.ConfType.INT);
            put("default.api.timeout.ms", BBM_JavaConfig.ConfType.INT);
            put("fetch.max.bytes", BBM_JavaConfig.ConfType.INT);
            put("max.poll.interval.ms", BBM_JavaConfig.ConfType.INT);
            put("max.poll.records", BBM_JavaConfig.ConfType.INT);
            put("receive.buffer.bytes", BBM_JavaConfig.ConfType.INT);
            put("request.timeout.ms", BBM_JavaConfig.ConfType.INT);
            put("send.buffer.bytes", BBM_JavaConfig.ConfType.INT);
            put("auto.commit.interval.ms", BBM_JavaConfig.ConfType.INT);
            put("fetch.max.wait.ms", BBM_JavaConfig.ConfType.INT);
            put("metrics.num.samples", BBM_JavaConfig.ConfType.INT);
            put("sasl.login.refresh.buffer.seconds", BBM_JavaConfig.ConfType.SHORT);
            put("sasl.login.refresh.min.period.seconds", BBM_JavaConfig.ConfType.SHORT);
        }
    });

    /** Creates the object from configuration in config items
     */
    public BBM_KafkaConsumer() throws Throwable {
        cons = createConsumer();
    }

    /** Stops polling and closes the object
     */
    public Object stop(Object ignored) {
        quit.set(true);
        cons.wakeup();

        lock.lock();
        try {
            while (running) {
                done_cond.awaitUninterruptibly();
            }
        } finally {
            lock.unlock();
        }
        cons.close();
        return null;
    }

    /** Close this consumer
     */
    public void close() {
        if (cons != null) {
            cons.close();
        }
    }

    /** Returns the consumer object
     */
    public KafkaConsumer<Object, Object> getConsumer() {
        return cons;
    }

    /** Returns a KafkaConsumer object based on configuration
    */
    public static KafkaConsumer<Object, Object> createConsumer() throws Throwable {
        Hash config = BBM_JavaConfig.get("kafka-conf-", PropTypeMap);
        UserApi.logInfo("using KafkaConsumer config: %y", config);
        return new KafkaConsumer<Object, Object>(config);
    }

    /** Starts receiving messages
     */
    public Boolean start(Object ignored) throws Throwable {
        // make sure this only runs once
        {
            lock.lock();
            try {
                if (running) {
                    return false;
                }
                running = true;
            } finally {
                lock.unlock();
            }
        }

        eventLoop();
        return true;
    }

    /** the actual event loop
     */
    private void eventLoop() throws Throwable {
        try {
            String topic_array[] = (String[])UserApi.getConfigItemValue("kafka-topics");
            UserApi.logInfo("subscribing to: %y", (Object)topic_array);
            cons.subscribe(Arrays.asList(topic_array));
            while (!quit.get()) {
                try {
                    // we use an interruptible poll, so we can use a very log poll interval
                    ConsumerRecords<Object, Object> recs = cons.poll(Duration.ofMillis(Long.MAX_VALUE));
                    Iterator<ConsumerRecord<Object, Object>> i = recs.iterator();
                    while (i.hasNext()) {
                        ConsumerRecord<Object, Object> rec = i.next();
                        Hash event = new Hash();
                        event.put("key", rec.key());
                        event.put("value", rec.value());
                        event.put("headers", headerToHash(rec.headers()));
                        Optional<Integer> leader_epoch = rec.leaderEpoch();
                        if (leader_epoch.isPresent()) {
                            event.put("leader_epoch", leader_epoch.get());
                        }
                        event.put("offset", rec.offset());
                        event.put("partition", rec.partition());
                        event.put("serialized_key_size", rec.serializedKeySize());
                        event.put("serialized_value_size", rec.serializedValueSize());
                        event.put("timestamp", rec.timestamp());
                        {
                            TimestampType tt = rec.timestampType();
                            switch (tt) {
                                case CREATE_TIME: event.put("timestamp_type", "CreateTime"); break;
                                case LOG_APPEND_TIME: event.put("timestamp_type", "LogAppendTime"); break;
                                case NO_TIMESTAMP_TYPE: event.put("timestamp_type", "NotAvailable"); break;
                                default: event.put("timestamp_type", "unknown"); break;
                            }
                        }
                        ZonedDateTime ts_date = ZonedDateTime.ofInstant(Instant.ofEpochMilli(rec.timestamp()),
                            TimeZone.getDefault().toZoneId());
                        event.put("timestamp_date", ts_date);
                        UserApi.logInfo("rec: %y", rec);
                        event.put("topic", rec.topic());
                        notifyObservers("BBM_KafkaConsumer::eventLoop", event);
                    }
                } catch (WakeupException e) {
                    if (!quit.get()) {
                        throw e;
                    }
                    UserApi.logInfo("exiting KafkaConsumer event loop");
                    break;
                }
            }
        } finally {
            lock.lock();
            try {
                running = false;
                done_cond.signalAll();
            } finally {
                lock.unlock();
            }
        }
    }

    /** Returns a hash of Headers
     */
    private Hash headerToHash(Headers hdrs) {
        Hash rv = new Hash();
        Iterator<Header> i = hdrs.iterator();
        while (i.hasNext()) {
            Header hdr = i.next();
            rv.put(hdr.key(), hdr.value());
        }
        return rv;
    }
}
