// name: SalesforceLoginParameters
// version: 1.0
// desc: Java test step class
// author: Qore Technologies, s.r.o.
// lang: java
// TAG: classpath: $OMQ_DIR/user/building-blocks/service/salesforce/jar/emp-connector-0.0.1-SNAPSHOT-phat.jar

import java.net.URL;
import java.net.MalformedURLException;

import com.salesforce.emp.connector.BayeuxParameters;

public class SalesforceLoginParameters implements BayeuxParameters {
    private String token;
    private URL url;

    public SalesforceLoginParameters(String token, String url) {
        this.token = token;
        try {
            this.url = new URL(url);
        } catch (MalformedURLException e) {
            throw new IllegalArgumentException(String.format("Unable to create url: %s", url), e);
        }
    }

    public String bearerToken() {
        return token;
    }

    public URL getUrl() {
        return url;
    }

    @Override
    public URL host() {
        return url;
    }
}
// END
