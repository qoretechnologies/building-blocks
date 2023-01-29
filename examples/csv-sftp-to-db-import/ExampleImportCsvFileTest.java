
import qoremod.QorusInterfaceTest.*;
import qoremod.QorusClientBase.*;
import qoremod.QorusClientBase.OMQ.$Constants;
import qoremod.QorusClientBase.OMQ.Client.QorusSystemRestHelper;
import qoremod.QorusClientBase.OMQ.QorusClientAPI;
import qoremod.QorusClientBase.OMQ.UserApi.UserApi;
import qoremod.ssh2.SSH2.SFTPClient;

import qoremod.SqlUtil.AbstractTable;

import org.qore.jni.QoreClosureMarkerImpl;
import org.qore.jni.Hash;

import java.util.UUID;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import java.util.concurrent.ThreadLocalRandom;
import java.time.Instant;

public class ExampleImportCsvFileTest extends QorusJobTest {
    // Qorus REST API interface object
    public static QorusSystemRestHelper qrest;

    // CSV header line
    public static String CsvHeader = "StoreCode,ProductCode,ProductDescription,Available,Ordered,InTransit,"
        + "ReportDate\n";

    // SFTP client object for pushing test files to the SFTP server
    public static SFTPClient sftp;

    // Test store values
    public static String[] Stores = {
        "Václavské náměstí",
        "Náměstí Míru",
        "Malostranské náměstí",
        "Komenského náměstí",
    };

    // Test product info
    public static Hash[] Products = {
        new Hash() {
            {
                put("code", "SV300S37A/120G");
                put("desc", "Kingston SSDNow V300 120GB 7mm");
            }
        },
        new Hash() {
            {
                put("code", "SSDSC2BW120A401");
                put("desc", "Intel 530 120GB SSD bulk");
            }
        },
        new Hash() {
            {
                put("code", "MZ-7PD256BW");
                put("desc", "Samsung SSD840 256GB 7mm, Pro");
            }
        },
    };

    // static initialization
    static {
        try {
            qrest = new QorusSystemRestHelper();
        } catch (Throwable e) {
            throw new RuntimeException(e);
        }
    }

    // main program
    public static void main(String[] args) throws Throwable {
        new ExampleImportCsvFileTest(args);
    }

    // Test class constructor
    public ExampleImportCsvFileTest(String[] args) throws Throwable {
        // run the superclass constructor first
        super("example-import-csv-file");

        // add test cases
        addTestCase("job test", new QoreClosureMarkerImpl() {
            public Object call(Object... args) throws Throwable { testJob(); return null; }
        });

        // run all test cases and report the results
        main();
    }

    // primary test case
    private void testJob() throws Throwable {
        // set job to run only on demand during the test
        qrest.put("jobs/example-import-csv-file/setActive", new Hash() {
            {
                put("active", false);
            }
        });

        try {
            // get the current number of records in the table
            AbstractTable inventory_example = UserApi.getSqlTable("omquser", "inventory_example");
            long num_recs = inventory_example.rowCount();

            // create a test file with 5 records and put it on the server
            String csv = ExampleImportCsvFileTest.getFileData(5);

            String filename = String.format("StockReport-%s.csv", UUID.randomUUID().toString());
            putFileOnSftpServer(filename, csv);

            // create a "RunJobResult" action and test for a COMPLETE status
            RunJobResult action = new RunJobResult($Constants.StatComplete);
            exec(action);
            Hash result = action.getJobResult();

            // check job results that one workflow order was created
            Hash[] jinfo = (Hash[])getJobResultHash(result.getLong("job_instanceid")).get("info");
            assertEq(1, jinfo.length, "check wf orders created");

            // wait for order status
            waitForStatus(jinfo[0].getLong("workflow_instanceid"));

            // get workflow order info
            long wfiid = jinfo[0].getLong("workflow_instanceid");
            Hash winfo = (Hash)qrest.get("orders/" + String.valueOf(wfiid));
            // assert that it's COMPLETE
            assertEq($Constants.StatComplete, winfo.getString("workflowstatus"), "check order status");

            // check that 5 additional rows have been added to the table
            assertEq(num_recs + 5, inventory_example.rowCount(), "check data imported in DB");

            // now let's submit the same file again and ensure it gets saved to the duplicate directory
            putFileOnSftpServer(filename, csv);

            // create a "RunJobResult" action and test for a COMPLETE status
            action = new RunJobResult($Constants.StatComplete);
            // run the job and check the result
            exec(action);
            result = action.getJobResult();

            // check job results that no new workflow order was created
            Hash[] jinfo2 = (Hash[])getJobResultHash(result.getLong("job_instanceid")).get("info");
            assertEq(1, jinfo2.length, "check duplicate job result info length");
            assertEq(wfiid, jinfo2[0].getLong("workflow_instanceid"),
                "check duplicate wf order ID");
            assertTrue(jinfo2[0].getBool("duplicate"), "verify duplicate flag");
        } finally {
            // set job to run only on demand during the test
            qrest.put("jobs/example-import-csv-file/setActive", new Hash() {
                {
                    put("active", true);
                }
            });
        }
    }

    // wait for the workflow order with the given ID to get a COMPLETE status
    void waitForStatus(long wfiid) throws Throwable {
        waitForStatus(wfiid, $Constants.StatComplete);
    }

    // wait for the workflow order with the given ID to get the given status
    void waitForStatus(long wfiid, String status) throws Throwable {
        String stat;
        // poll the status ~4 times a second
        while (true) {
            Hash h = (Hash)qrest.get("orders/" + String.valueOf(wfiid));
            stat = h.getString("workflowstatus");
            if (stat.equals(status) || stat.equals($Constants.StatError)) {
                break;
            }

            // wait for status to change
            Thread.sleep(250);
        }

        // output the status
        System.out.println(String.format("workflow order ID %d has status %s", wfiid, stat));

        // assert that the status is the desired status
        assertEq(stat, status, "wfiid " + String.valueOf(wfiid) + " has status " + status);
    }

    // Returns a string of CSV data that can be parsed by our interface
    static String getFileData(int num_records) throws Throwable {
        return CsvHeader
            + Stream.generate(() -> getRecordString()).limit(num_records).collect(Collectors.joining());
    }

    // Get a single string for our CSV file with random data
    static String getRecordString() {
        Hash prod = Products[ThreadLocalRandom.current().nextInt(0, Products.length)];
        return String.format("%s,%s,\"%s\",%d,%d,%d,%s\n",
            Stores[ThreadLocalRandom.current().nextInt(0, Stores.length)],
            prod.getString("code"),
            prod.getString("desc"),
            ThreadLocalRandom.current().nextInt(0, 10),
            ThreadLocalRandom.current().nextInt(0, 10),
            ThreadLocalRandom.current().nextInt(0, 10),
            Instant.now().toString());
    }

    // Sends a test file to the server with an atomic mechanism using a temporary *.part filename extension
    static void putFileOnSftpServer(String filename, String csv) throws Throwable {
        getClient();
        String tempname = filename + ".part";
        long bytes = sftp.putFile(csv, tempname);
        // rename file to target name
        sftp.rename(tempname, filename);
        System.out.println(String.format("wrote %d bytes of %s to sftp://%s:%d", bytes, filename, sftp.getHost(),
            sftp.getPort()));
    }

    // Sets up the SFTP client object for our interface
    static void getClient() throws Throwable {
        if (sftp != null) {
            return;
        }
        // get connection name
        String conn = (String)qrest.get("jobs/example-import-csv-file/config/sftp-polling-connection-name/value");
        sftp = (SFTPClient)UserApi.getUserConnection(conn);
    }
}
