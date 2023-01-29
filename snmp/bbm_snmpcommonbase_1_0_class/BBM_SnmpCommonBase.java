import org.snmp4j.*;
import org.snmp4j.smi.*;
import org.snmp4j.mp.SnmpConstants;
import org.snmp4j.transport.*;
import org.snmp4j.security.*;
import org.snmp4j.mp.*;

import com.qoretechnologies.qorus.UserApi;

public class BBM_SnmpCommonBase {
    public Snmp snmp;

    public BBM_SnmpCommonBase(TransportMapping<? extends Address> transport) throws Throwable {
        snmp = new Snmp(transport);

        byte[] localEngineID = ((MPv3)snmp.getMessageProcessingModel(
            MessageProcessingModel.MPv3
        )).createLocalEngineID();

        USM usm = new USM(SecurityProtocols.getInstance(), new OctetString(localEngineID), 0);

        SecurityModels.getInstance().addSecurityModel(usm);

        snmp.setLocalEngine(localEngineID, 0, 0);

        String username = (String)UserApi.getConfigItemValue("snmp-user");
        UsmUser user = new UsmUser(new OctetString(username), null, null, null, null);
        snmp.getUSM().addUser(new OctetString(username), user);
    }
}
