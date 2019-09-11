// name: SalesforceLongPollingTransport
// version: 1.0
// desc: Java test step class
// author: Qore Technologies, s.r.o.
// lang: java
// TAG: classpath: $OMQ_DIR/user/building-blocks/service/salesforce/jar/emp-connector-0.0.1-SNAPSHOT-phat.jar:$OMQ_DIR/user/building-blocks/service/salesforce/jar/jetty-client-7.4.4.v20110707.jar

import java.util.Map;

import org.cometd.client.transport.LongPollingTransport;
import org.eclipse.jetty.client.api.Request;

public class SalesforceLongPollingTransport extends LongPollingTransport {
   private String sessionId;

    public SalesforceLongPollingTransport(Map<String,Object> options, org.eclipse.jetty.client.HttpClient httpClient, String sid) {
        super(options, httpClient);
        sessionId = sid;
    }

    protected void customize(Request request) {
        super.customize(request);
        request.header("Authorization", "OAuth " + sessionId);
    }
}
// END
