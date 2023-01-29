import qore.OMQ.*;
import qore.OMQ.UserApi.*;
import qore.OMQ.UserApi.Service.*;
import org.qore.jni.QoreJavaApi;
import org.qore.jni.QoreObject;
import java.util.Map;
import org.qore.jni.Hash;
import java.lang.reflect.Method;
import java.lang.reflect.InvocationTargetException;
import qoremod.Mapper.Mapper;
import qore.BBM_QorusUiExtension;
import qore.BBM_WebSocketServiceEventSource;
import qore.BBM_TextAnalysis;

class ChatbotWsDemo extends QorusService {
    // ==== GENERATED SECTION! DON'T EDIT! ==== //
    ClassConnections_ChatbotWsDemo classConnections;
    // ======== GENERATED SECTION END ========= //

    public ChatbotWsDemo() throws Throwable {
        super();
        // ==== GENERATED SECTION! DON'T EDIT! ==== //
        classConnections = new ClassConnections_ChatbotWsDemo();
        // ======== GENERATED SECTION END ========= //
    }

    // ==== GENERATED SECTION! DON'T EDIT! ==== //
    public void init() throws Throwable {
        classConnections.UI_Extension(null);
    }
    // ======== GENERATED SECTION END ========= //
}

// ==== GENERATED SECTION! DON'T EDIT! ==== //
class ClassConnections_ChatbotWsDemo extends Observer {
    // must inherit Observer, because there is an event-based connector
    // map of prefixed class names to class instances
    private final Hash classMap;

    ClassConnections_ChatbotWsDemo() throws Throwable {
        classMap = new Hash();
        UserApi.startCapturingObjectsFromJava();
        try {
            classMap.put("BBM_QorusUiExtension", QoreJavaApi.newObjectSave("BBM_QorusUiExtension"));
            classMap.put("BBM_WebSocketServiceEventSource", QoreJavaApi.newObjectSave("BBM_WebSocketServiceEventSource"));
            classMap.put("BBM_TextAnalysis", QoreJavaApi.newObjectSave("BBM_TextAnalysis"));
        } finally {
            UserApi.stopCapturingObjectsFromJava();
        }

        // register observers
        callClassWithPrefixMethod("BBM_WebSocketServiceEventSource", "registerObserver", this);
    }

    Object callClassWithPrefixMethod(final String prefixedClass, final String methodName,
                                     Object params) throws Throwable {
        UserApi.logDebug("ClassConnections_ChatbotWsDemo: callClassWithPrefixMethod: method: %s class: %y", methodName, prefixedClass);
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
        if (id.equals("BBM_WebSocketServiceEventSource::event (ignored)")) {
            WebSockets(params);
        }
    }

    public Object UI_Extension(Object params) throws Throwable {
        // convert varargs to a single argument if possible
        if (params != null && params.getClass().isArray() && ((Object[])params).length == 1) {
            params = ((Object[])params)[0];
        }
        UserApi.logDebug("UI_Extension called with data: %y", params);

        UserApi.logDebug("calling init: %y", params);
        return callClassWithPrefixMethod("BBM_QorusUiExtension", "init", params);
    }

    public Object WebSockets(Object params) throws Throwable {
        // convert varargs to a single argument if possible
        if (params != null && params.getClass().isArray() && ((Object[])params).length == 1) {
            params = ((Object[])params)[0];
        }
        Mapper mapper;
        UserApi.logDebug("WebSockets called with data: %y", params);

        mapper = UserApi.getMapper("chatbot-ws-input");
        params = mapper.mapAuto(params);

        UserApi.logDebug("calling processInputHash: %y", params);
        params = callClassWithPrefixMethod("BBM_TextAnalysis", "processInputHash", params);

        mapper = UserApi.getMapper("chatbot-ws-output");
        params = mapper.mapAuto(params);

        UserApi.logDebug("calling webSocketSendEvent: %y", params);
        return callClassWithPrefixMethod("BBM_WebSocketServiceEventSource", "sendMessage", params);
    }
}
// ======== GENERATED SECTION END ========= //
