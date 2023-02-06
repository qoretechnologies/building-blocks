#!/usr/bin/env python3

# import Python's sys module
import sys
# import Python's random.randint()
from random import randint
# import Python's time.time()
from time import time, sleep
# import Python's datetime.datetime
from datetime import datetime
# import Python's uuid
import uuid

# the "qoreloader" module is provided by Qorus and provides the bridge between Python <-> Qore and, with Qore's "jni"
# module, between Python <-> Java
# reference: https://qoretechnologies.com/manual/qorus/gitlab-docs/develop/python/python/html/index.html#python_qoreloader_module
import qoreloader

# the "qoreloader" module provides the magic package "qore" which allows us to import Qore APIs and use them as if
# they were Python APIs
# reference: https://qoretechnologies.com/manual/qorus/gitlab-docs/develop/python/python/html/index.html#python_qoreloader_import_qore
from qore.QorusInterfaceTest import QorusJobTest, RunJobResult, Action

# import Qore's "OMQ" namespace, which is available in the Qore program as provided by importing the
# "QorusInterfaceTest" module above
from qore.__root__ import OMQ

# import Qorus's "UserApi" class
from qore.__root__.OMQ.UserApi import UserApi

# import Qorus's "QorusSystemRestHelper" class
from qore.__root__.OMQ.Client import QorusSystemRestHelper

# import Qore's SFTPClient class from the ssh2 module
from qore.ssh2 import SFTPClient

# import Qore's AbstractTable class
from qore.SqlUtil import AbstractTable, Table

# we inherit the QorusJobTest class
# reference: https://qoretechnologies.com/manual/qorus/gitlab-docs/develop/qorus/classQorusInterfaceTest_1_1QorusJobTest.html
class MyTest(QorusJobTest):
    # static class variables
    stores: tuple = (
        'Václavské náměstí',
        'Náměstí Míru',
        'Malostranské náměstí',
        'Komenského náměstí',
    )
    qrest: QorusSystemRestHelper = QorusSystemRestHelper()

    # create client object
    omqclient: OMQ.QorusClientAPI = OMQ.QorusClientAPI()

    sftp: SFTPClient = None

    # initialize the new object
    def __init__(self):
        # call the parent class's constructor
        super(QorusJobTest, self).__init__("example-import-csv-file", sys.argv[1:])
        # add test cases
        self.addTestCase("job test", self.test)
        # execute the tests
        self.main()

    def test(self):
        # set job to run only on demand during the test
        MyTest.qrest.put("jobs/example-import-csv-file/setActive", {"active": False})

        try:
            # get the current number of records in the table
            inventory_example: AbstractTable = UserApi.getSqlTable("omquser", "inventory_example")
            num_recs: int = inventory_example.rowCount()

            # create a test file with 5 records and put it on the server
            csv: str = MyTest.getFileData(5)
            filename: str = 'StockReport-{}.csv'.format(uuid.uuid4())
            self.putFileOnSftpServer(filename, csv)

            # create a "RunJobResult" action and test for a COMPLETE status
            action: Action = RunJobResult(OMQ.StatComplete)
            # run the job and check the result
            result: dict = self.exec(action).getJobResult()

            # check job results that one workflow order was created
            jinfo: tuple = self.getJobResultHash(result['job_instanceid'])['info']
            self.assertEq(1, len(jinfo), 'check wf orders created')

            # wait for order status
            self.waitForStatus(jinfo[0]['workflow_instanceid'])

            # get workflow order info
            winfo: dict = self.qrest.get("orders/" + str(jinfo[0]['workflow_instanceid']))
            # assert that it's COMPLETE
            self.assertEq(OMQ.StatComplete, winfo['workflowstatus'], 'check order status')

            # check that 5 additional rows have been added to the table
            self.assertEq(num_recs + 5, inventory_example.rowCount(), 'check data imported in DB')

            # now let's submit the same file again and ensure it gets saved to the duplicate directory
            self.putFileOnSftpServer(filename, csv)

            # create a "RunJobResult" action and test for a COMPLETE status
            action: Action = RunJobResult(OMQ.StatComplete)
            # run the job and check the result
            result: dict = self.exec(action).getJobResult()

            # check job results that no new workflow order was created
            jinfo2: tuple = self.getJobResultHash(result['job_instanceid'])['info']
            self.assertEq(1, len(jinfo2), 'check duplicate job result info length')
            self.assertEq(jinfo[0]['workflow_instanceid'], jinfo2[0]['workflow_instanceid'],
                'check duplicate wf order ID')
            self.assertTrue(jinfo2[0]['duplicate'], 'verify duplicate flag')
        except:
            raise
        finally:
            # reset job to run normally after the test completes
            MyTest.qrest.put("jobs/example-import-csv-file/setActive", {"active": True})

    def putFileOnSftpServer(self, filename: str, csv: str):
        self.getClient()
        tempname: str = '{}.part'.format(filename)
        bytes: int = MyTest.sftp.putFile(csv, tempname)
        # rename file to target name
        MyTest.sftp.rename(tempname, filename)
        if self.m_options.get('verbose', 0) > 2:
            print('wrote {} bytes of {} to sftp://{}:{}'.format(bytes, filename, MyTest.sftp.getHost(),
                MyTest.sftp.getPort()))

    def getClient(self):
        if not MyTest.sftp:
            # get connection name
            conn: str = MyTest.qrest.get('jobs/example-import-csv-file/config/sftp-polling-connection-name/value')
            MyTest.sftp = UserApi.getUserConnection(conn)

    @staticmethod
    def getFileData(num_records: int) -> str:
        csv: str = "StoreCode,ProductCode,ProductDescription,Available,Ordered,InTransit,ReportDate\n"
        for x in range(num_records):
            prod: dict = MyTest.getProductInfo()
            csv += '{},{},\"{}\",{},{},{},{}\n'.format(
                MyTest.stores[randint(0, 3)],
                prod['code'], prod['desc'],
                randint(0, 9), randint(0, 9), randint(0, 9), datetime.fromtimestamp(time())
            )
        return csv

    @staticmethod
    def getProductInfo() -> dict:
        x: int = randint(0, 2)
        if x == 0:
            return {
                "code": "SV300S37A/120G",
                "desc": "Kingston SSDNow V300 120GB 7mm",
            }
        elif x == 1:
            return {
                "code": "SSDSC2BW120A401",
                "desc": "Intel 530 120GB SSD bulk",
            }

        return {
            "code": "MZ-7PD256BW",
            "desc": "Samsung SSD840 256GB 7mm, Pro",
        }

    # wait for the workflow order to have the given status
    def waitForStatus(self, wfiid: int, status: str = OMQ.StatComplete):
        h: dict = None
        while True:
            h = self.qrest.get("orders/" + str(wfiid))
            if h['workflowstatus'] == status or h['workflowstatus'] == OMQ.StatError:
                break

            # wait for status to change
            sleep(0.250)

        if self.m_options.get('verbose', 0) > 2:
            print("workflow order ID {} has status {}".format(wfiid, h['workflowstatus']))

        self.assertEq(h['workflowstatus'], status, "wfiid " + str(wfiid) + " has status " + status)

MyTest()