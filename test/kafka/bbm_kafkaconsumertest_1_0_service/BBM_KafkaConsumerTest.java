import qore.OMQ.*;
import qore.OMQ.UserApi.*;
import qore.OMQ.UserApi.Service.*;
import org.qore.jni.QoreJavaApi;
import org.qore.jni.QoreObject;
import java.util.Map;
import org.qore.jni.Hash;
import java.lang.reflect.Method;
import java.lang.reflect.InvocationTargetException;
import qore.BBM_ListCache;
import qore.BBM_LogMessage;

class BBM_KafkaConsumerTest extends QorusService {
    // ==== GENERATED SECTION! DON'T EDIT! ==== //
    ClassConnections_BBM_KafkaConsumerTest classConnections;
    // ======== GENERATED SECTION END ========= //

    public BBM_KafkaConsumerTest() throws Throwable {
        super();
        // ==== GENERATED SECTION! DON'T EDIT! ==== //
        classConnections = new ClassConnections_BBM_KafkaConsumerTest();
        // ======== GENERATED SECTION END ========= //
    }

    // ==== GENERATED SECTION! DON'T EDIT! ==== //
    public Object getMessages() throws Throwable {
        return classConnections.getMessages(null);
    }

    // ======== GENERATED SECTION END ========= //

    // ==== GENERATED SECTION! DON'T EDIT! ==== //
    public void start() throws Throwable {
        classConnections.start(null);
        classConnections.getMessages(null);
    }

    public void stop() throws Throwable {
        classConnections.stop(null);
    }
    // ======== GENERATED SECTION END ========= //
}

// ==== GENERATED SECTION! DON'T EDIT! ==== //
class ClassConnections_BBM_KafkaConsumerTest extends Observer {
    // must inherit Observer, because there is an event-based connector
    // map of prefixed class names to class instances
    private final Hash classMap;

    ClassConnections_BBM_KafkaConsumerTest() throws Throwable {
        classMap = new Hash();
        UserApi.startCapturingObjectsFromJava();
        try {
        classMap.put("BBM_KafkaConsumer", new BBM_KafkaConsumer());
            classMap.put("BBM_ListCache", QoreJavaApi.newObjectSave("BBM_ListCache"));
            classMap.put("BBM_LogMessage", QoreJavaApi.newObjectSave("BBM_LogMessage"));
        } finally {
            UserApi.stopCapturingObjectsFromJava();
        }

        // register observers
        callClassWithPrefixMethod("BBM_KafkaConsumer", "registerObserver", this);
    }

    Object callClassWithPrefixMethod(final String prefixedClass, final String methodName,
                                     Object params) throws Throwable {
        UserApi.logDebug("ClassConnections_BBM_KafkaConsumerTest: callClassWithPrefixMethod: method: %s class: %y", methodName, prefixedClass);
        final Object object = classMap.get(prefixedClass);

        if (object instanceof QoreObject) {
            QoreObject qoreObject = (QoreObject)object;
            return qoreObject.callMethod(methodName, params);
        } else {
            final Method method = object.getClass().getMethod(methodName, Object.class);
            try {
                return method.invoke(object, params);
            } catch (InvocationTargetException ex) {
                throw ex.getCause();
            }
        }
    }

    // override Observer's update()
    public void update(String id, Hash params) throws Throwable {
        if (id.equals("BBM_KafkaConsumer::eventLoop")) {
            KafkaMessageEvent(params);
        }
    }

    public Object KafkaMessageEvent(Object params) throws Throwable {
        // convert varargs to a single argument if possible
        if (params != null && params.getClass().isArray() && ((Object[])params).length == 1) {
            params = ((Object[])params)[0];
        }
        UserApi.logDebug("KafkaMessageEvent called with data: %y", params);

        UserApi.logDebug("calling cacheData: %y", params);
        params = callClassWithPrefixMethod("BBM_ListCache", "cacheData", params);

        UserApi.logDebug("calling logMessage: %y", params);
        return callClassWithPrefixMethod("BBM_LogMessage", "logMessage", params);
    }

    public Object start(Object params) throws Throwable {
        // convert varargs to a single argument if possible
        if (params != null && params.getClass().isArray() && ((Object[])params).length == 1) {
            params = ((Object[])params)[0];
        }
        UserApi.logDebug("start called with data: %y", params);

        UserApi.logDebug("calling start: %y", params);
        return callClassWithPrefixMethod("BBM_KafkaConsumer", "start", params);
    }

    public Object stop(Object params) throws Throwable {
        // convert varargs to a single argument if possible
        if (params != null && params.getClass().isArray() && ((Object[])params).length == 1) {
            params = ((Object[])params)[0];
        }
        UserApi.logDebug("stop called with data: %y", params);

        UserApi.logDebug("calling stop: %y", params);
        return callClassWithPrefixMethod("BBM_KafkaConsumer", "stop", params);
    }

    public Object getMessages(Object params) throws Throwable {
        // convert varargs to a single argument if possible
        if (params != null && params.getClass().isArray() && ((Object[])params).length == 1) {
            params = ((Object[])params)[0];
        }
        UserApi.logDebug("getMessages called with data: %y", params);

        UserApi.logDebug("calling getData: %y", params);
        return callClassWithPrefixMethod("BBM_ListCache", "getData", params);
    }
}
// ======== GENERATED SECTION END ========= //
