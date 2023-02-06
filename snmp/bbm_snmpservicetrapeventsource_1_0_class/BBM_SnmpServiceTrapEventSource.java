import org.snmp4j.*;
import org.snmp4j.smi.*;
import org.snmp4j.mp.SnmpConstants;
import org.snmp4j.transport.*;
import org.snmp4j.security.*;
import org.snmp4j.mp.*;

import org.qore.jni.Hash;

import qore.OMQ.UserApi.UserApi;
import qore.OMQ.Observable;

public class BBM_SnmpServiceTrapEventSource extends Observable {
    private BBM_SnmpCommonBase snmp;

    public BBM_SnmpServiceTrapEventSource() throws Throwable {
        String bind_address = (String)UserApi.getConfigItemValue("snmp-event-source-listen-address");

        UdpAddress listen_address = new UdpAddress(bind_address);
        TransportMapping<? extends Address> transport = new DefaultUdpTransportMapping(listen_address);
        snmp = new BBM_SnmpCommonBase(transport);

        CommandResponder trapPrinter = new CommandResponder() {
            public synchronized void processPdu(CommandResponderEvent e) {
                PDU command = e.getPDU();
                if (command != null) {
                    try {
                        UserApi.logDebug("BBM_SnmpServiceTrapEventSource: received trap: " + command.toString());
                        //System.out.println(command.toString());

                        java.util.List<VariableBinding> vars = command.getAll();
                        Hash event = new Hash();
                        Hash event_vars = new Hash();
                        for (VariableBinding varb : vars) {
                            Variable var = varb.getVariable();
                            event_vars.put(var.getSyntaxString(), true);
                        }
                        event.put("vars", event_vars);
                        notifyObservers("BBM_SnmpServiceTrapEventSource::snmpTrap", event);
                    } catch (Throwable t) {
                        throw new RuntimeException(t);
                    }
                }
            }
        };
        snmp.snmp.addCommandResponder(trapPrinter);

        transport.listen();
    }
}
