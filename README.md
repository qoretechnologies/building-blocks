# Qorus Integration Engine® Building Blocks

This repository contains building blocks or components for Qorus Integration Engine®

building blocks in any supported language can be used by code in other languages, so just because you are working with a code in Python, you don't have to restrict yourself to Python-based building blocks, Java, Python, and Qore-based building blocks can be mixed in any solution.

Building blocks are meant to provide reusable elements to solve technical challenges in a generic way to reduce development effort - ideally to eliminate development and transform the delivery of complex functionality to simply configuration.

**NOTE: Building blocks here require Qorus 5.1.25+ for full functionality**

**NOTE: The building blocks here are made available under the Apache license 2.0:**
>
> Copyright 2021 Qore Technologies, s.r.o.
>
> Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.  You may obtain a copy of the License at
>
>     http://www.apache.org/licenses/LICENSE-2.0
>
> Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the License for the specific language governing permissions and limitations under the License.

Contact Qore Technologies (info@qoretechnologies.com) if you need support for these building blocks.

## Installation

Qorus must be installed, and the command-line environment must be set up for Qorus as well; also GNU make should be available in the `PATH`.

After cloning the repository, type `make load-bb`

## Building Blocks Index

**NOTE: Some building blocks have dependencies in other building blocks, modules, and/or data types; when deploying
single building blocks, ensure that all dependencies are deployed at the same time.  Keep in mind that modules often
require system option changes in `$OMQ_DIR/etc/options` (ex: `qorus.dataprovider-modules`) which require a Qorus
restart to take effect.**

**NOTE: Qorus must be restarted after installing the full building block release or any release with module dependencies
where the `qorus.dataprovider-module` option was updated for the first time in order for system option changes to take
effect.**

**NOTE: Qorus types must be deployed first in Qorus before they can be used in the IDE in mappers or workflow static
data types, etc.**

**NOTE: If step building blocks are subclassed, make sure and either remove the `primary()` or `validation()` method
or override it and make an explicit call to the parent class method in the child class

**NOTE: Qorus implements a significant quantity of powerful generic functionality in data provider factories; the
`qorus-api` factory implements Qorus-specific functionality
(see https://qoretechnologies.com/manual/qorus/current/qorus/finite_state_machines.html#fsm_qorus_api_calls), and Qore
and modules implement other generic functionality as well.  These APIs can be browsed and used in Qorus flows (Finite
State Machines) in API call states where documentation for each API call (request - response data provider) is also
displayed.

The following building blocks are available:

### AI / NLU / ONDEWO Building Blocks

|Building Block|Description|
|---|---|
|[BBM_OndewoBpiServer](#bbm_ondewobpiserver-building-block)|ONDEWO Business Process Integration server building block with event-based connectors for intent handling
|[BBM_OndewoIntentHandler](#bbm_ondewointenthandler-building-block)|ONDEWO intent handler helper class
|[BBM_OndewoNluClient](#bbm_ondewonluclient-building-block)|ONDEWO Natural Language Understanding client class
|[BBM_OndewoVtsiClient](#bbm_ondewovtsiclient-building-block)|ONDEWO VTSI client class

### Data Provider / Mapper Building Blocks

|Building Block|Description|
|---|---|
|[BBM_AutoMapper](#bbm_automapper-building-block)|base building block for running a mapper in autonomous mode; includes an input/output connector
|[BBM_AutoMapperRecord](#bbm_automapperrecord-building-block)|base building block for running a mapper in autonomous mode with request/record-based recovery logic
|[BBM_AutoMapperRecordStep](#bbm_automapperrecordstep-building-block)|step building block to map record-based data from an output provider to an input provider with config-based error recovery support; runs a mapper in autonomous mode
|[BBM_AutoMapperRequest](#bbm_automapperrequest-building-block)|base building block for running a mapper in autonomous mode with request/response-based recovery logic
|[BBM_CsvReadDataProvider](#bbm_csvreaddataprovider-building-block)|base building block for processing CSV data as input; implements an output connector
|[BBM_DataProviderRecordCreateProcessor](#bbm_dataproviderrecordcreateprocessor-building-block)|building block for a data provider output pipeline processor
|[BBM_DataProviderSearchRecordIterator](#bbm_dataprovidersearchrecorditerator-building-block)|building block class with a connector returning a record iterator that can be used to populate a pipeline
|[BBM_ExcelReadDataProvider](#bbm_excelreaddataprovider-building-block)|base building block for processing Excel spreadsheet data as input; implements an output connector
|[BBM_GenericMapper](#bbm_genericmapper-building-block)|building block for generic data transformation support based on a mapper; includes an input/output connector; use this building block to use a mapper that will **not** run in autonomous mode (for example where input data can be used directly)

### Data Provider / Pipeline Blocks

|Building Block|Description|
|---|---|
|[BBM_GetPipelineData](#bbm_getpipelinedata-building-block)|building block for providing a data pipeline with initial processing data from configuration
|[BBM_SimpleFilterPipelineData](#bbm_simplefilterpipelinedata-building-block)|building block for filtering records in a data pipeline

### Filesystem Event Building Blocks

|Building Block|Description|
|---|---|
|[BBM_FsEventBase](#bbm_fseventbase-building-block)|generic class for services for event-driven file actions on the local filesystem

### FTP Building Blocks

|Building Block|Description|
|---|---|
|[BBM_FtpPollerBase](#bbm_ftppollerbase-building-block)|generic base class for polling for files from an FTP server with a polling connector
|[BBM_FtpPollerCreateOrder](#bbm_ftppollercreateorder-building-block)|class for polling for files from an FTP server and creating a workflow order from them
|[BBM_FtpPollerCreateOrderJob](#bbm_ftppollercreateorderjob-building-block)|base class for FTP polling jobs that create workflow orders for files received

### Generic / Utility Building Blocks

|Building Block|Description|
|---|---|
|[BBM_DataSerialization](#bbm_dataserialization-building-block)|transforms input data into a serialized string, includes an input/output connector
|[BBM_GetArray](#bbm_getarray-building-block)|returns a list of data based on configuration, meant to be used to provide array input for an array step, provides an input/output connector
|[BBM_InternalIterator](#bbm_internaliterator-building-block)|allows for iteration of internal data; converts a hash with an internal list into a list of hashes having common top-level data with the interior element repeated
|[BBM_JavaConfig](#bbm_javaconfig-building-block)|sets Java configuration based on configuration items
|[BBM_ListCache](#bbm_listcache-building-block)|a simple cache class holding a list of data items with connectors to control the cache
|[BBM_PauseDataPassthru](#bbm_pausedatapassthru-building-block)|executes a configurable and optionally skippable pause or delay, includes an input/output connector
|[BBM_RegularExpressions](#bbm_regularexpressions-building-block)|helper building block used by other building blocks for for regular expression configuration item handling

### HTTP Server Building Blocks

|Building Block|Description|
|---|---|
|[BBM_AwsSnsServiceBase](#bbm_awssnsservicebase-building-block)|Base AWS Simple Notification Service abstract class building block
|[BBM_AwsSnsServiceEventSource](#bbm_awssnsserviceeventsource-building-block)|AWS Simple Notification Service class building block with an event-based connection
|[BBM_CorsBase](#bbm_corsbase-building-block)|base class for CORS functionality used by other building blocks
|[BBM_HttpAuthenticatorBase](#bbm_httpauthenticatorbase-building-block)|base class for HTTP authentication used by other building blocks
|[BBM_HttpFileHandler](#bbm_httpfilehandler-building-block)|generic building block for serving files from the filesystem via HTTP/S
|[BBM_HttpServiceGenericBase](#bbm_httpservicegenericbase-building-block)|base class for HTTP handler services; meant as a base class for higher-level HTTP-based server building blocks
|[BBM_HttpReverseProxyService](#bbm_httpreverseproxyservice-building-block)|a reverse proxy building block supporting 1:1 forwarding of chunked transfer encoding and protocol handlers such as WebSockets
|[BBM_HttpServiceBase](#bbm_httpservicebase-building-block)|base class for HTTP handler services; can be used directly
|[BBM_QorusUiExtension](#bbm_qorusuiextension-building-block)|building block for Qorus UI extension server services

### Kafka Building Blocks

|Building Block|Description|
|---|---|
|[BBM_KafkaConsumer](#bbm_kafkaconsumer-building-block)|**[Kafka](https://kafka.apache.org/)** message consumer building block, includes input/output connectors
|[BBM_KafkaProducer](#bbm_kafkaproducer-building-block)|**[Kafka](https://kafka.apache.org/)** message producer building block, includes input/output connectors

### MQTT Building Blocks

|Building Block|Description|
|---|---|
|[BBM_MqttPahoClient](#bbm_mqttpahoclient-building-block)|**[MQTT Paho](https://www.eclipse.org/paho/)** client base building block
|[BBM_MqttPahoPublisher](#bbm_mqttpahopublisher-building-block)|**[MQTT Paho](https://www.eclipse.org/paho/)** client publisher building block with connectors for publishing MQTT messages
|[BBM_MqttPahoSubscriber](#bbm_mqttpahosubscriber-building-block)|**[MQTT Paho](https://www.eclipse.org/paho/)** client subscriber building block with an event-based connector for listening to MQTT messages / topics

### REST Building Blocks

|Building Block|Description|
|---|---|
|[BBM_RestAction](#bbm_restaction-building-block)|generic class for making a REST request, includes input/output connectors
|[BBM_RestActionStep](#bbm_restactionstep-building-block)|generic step class for making a REST request, includes input/output connectors
|[BBM_RestActionWithRecovery](#bbm_restactionwithrecovery-building-block)|generic class for making a REST request, includes recovery logic and config as well as input/output connectors
|[BBM_RestServiceBase](#bbm_restservicebase-building-block)|base class for REST handler services

### Salesforce Building Blocks

|Building Block|Description|
|---|---|
|[BBM_SalesforceStreamBase](#bbm_salesforcestreambase-building-block)|base class for **Salesforce** streaming API support, provides an event source connector
|[BBM_SalesforceStreamCreateOrder](#bbm_salesforcestreamcreateorder-building-block)|base class for creating workflow orders based on **Salesforce** events

### SFTP Building Blocks

|Building Block|Description|
|---|---|
|[BBM_SftpPollerBase](#bbm_sftppollerbase-building-block)|generic base class for polling for files from an SFTP server with a polling connector
|[BBM_SftpPollerCreateOrder](#bbm_sftppollercreateorder-building-block)|class for polling for files from an SFTP server and creating a workflow order from them
|[BBM_SftpPollerCreateOrderJob](#bbm_sftppollercreateorderjob-building-block)|base class for SFTP polling jobs that create workflow orders for files received

### SNMP Building Blocks

|Building Block|Description|
|---|---|
|[BBM_SnmpServiceTrapEventSource](#bbm_snmpservicetrapeventsource-building-block)|SNMP trap event source with an event connector

### WebSocket Server Building Blocks

|Building Block|Description|
|---|---|
|[BBM_WebSocketServiceBase](#bbm_websocketservicebase-building-block)|base class for WebSocket handler services
|[BBM_WebSocketServiceEventSource](#bbm_websocketserviceeventsource-building-block)|base class for WebSocket handler services with an event connector
|[BBM_WebSocketServiceDataEventSource](#bbm_websocketservicedataeventsource-building-block)|base class for WebSocket handler services with an event connector based on serialized event data (JSON or YAML)

### WSGi Server Building Blocks

|Building Block|Description|
|---|---|
|[BBM_WsgiHandlerBase](#bbm_wsgihandlerbase-building-block)|WSGi HTTP server handler base building block; serves any Python-based WSGi server service from a Qorus service, also providing the Qorus API to the WSGi server as well as dynamic Java imports
|[BBM_WsgiServer](#bbm_wsgiserver-building-block)|WSGi HTTP server building block; serves any Python-based WSGi server service from a Qorus service, also providing the Qorus API to the WSGi server as well as dynamic Java imports
|[BBM_WsgiUiExtension](#bbm_wsgiuiextension-building-block)|Allows for serving a WSGi server as a Qorus UI extension based on configuration

### Building Blocks Replaced By Server functionality

These building blocks are deprecated as their functionality has been replaced with functionality implemented directly
in the Qorus server using the `qorus-api` data provider factory.

|Building Block|Description|
|---|---|
|[BBM_BindSubworkflow](#bbm_bindsubworkflow-building-block)|binds a subworkflow in a subworkflow step; the subworkflow data is provided as input data, includes input/output connectors; use the `util/workflow/bind-subworkflow` API data provider in the `qorus-api` factory instead
|[BBM_BindSubworkflowStatic](#bbm_bindsubworkflowstatic-building-block)|binds a subworkflow in a workflow step based on configuration in the building block, includes input/output connectors; use the `util/workflow/bind-subworkflow` API data provider in the `qorus-api` factory instead
|[BBM_Break](#bbm_break-building-block)|building block that throws an `FSM-BREAK` exception for flow control in FSMs; includes an input connector; use the `util/break` API data provider in the `qorus-api` factory instead
|[BBM_Continue](#bbm_continue-building-block)|building block that throws an `FSM-CONTINUE` exception for flow control in FSMs; includes an input connector; use the `util/continue` API data provider in the `qorus-api` factory instead
|[BBM_CreateOrder](#bbm_createorder-building-block)|creates a new workflow order; the workflow order data is provided as input data, includes input/output connectors; use the `workflows/create-order` API data provider in the `qorus-api` factory instead
|[BBM_CreateOrderStatic](#bbm_createorderstatic-building-block)|creates a new workflow order based on configuration in the building block, includes input/output connectors; use the `workflows/create-order` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRecordCreate](#bbm_dataproviderrecordcreate-building-block)|building block for record-based data providers for creating records, includes an input/output connector; use the `data-provider/create` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRecordCreateBase](#bbm_dataproviderrecordcreatebase-building-block)|base building block for record-based data providers for record creation; use the `data-provider/create` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRecordUpdate](#bbm_dataproviderrecordupdate-building-block)|building block for record-based data providers for updating records, includes an input/output connector; use the `data-provider/update` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRecordUpdateBase](#bbm_dataproviderrecordupdatebase-building-block)|base base class for record-based data providers for creating records; use the `data-provider/update` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRequest](#bbm_dataproviderrequest-building-block)|building block for request-based data providers; the request message body is created from config, includes an input/output connector; use the `data-provider/do-request` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRequestBase](#bbm_dataproviderrequestbase-building-block)|base class for using the data-provider request API to make requests; use the `data-provider/do-request` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRequestWithRecovery](#bbm_dataproviderrequestwithrecovery-building-block)|building block for request-based data providers with recovery logic; supports recovery with a single value, includes connectors for using in workflow steps for fault-tolerant operation; use the `data-provider/do-request` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderRequestWithRecoveryStep](#bbm_dataproviderrequestwithrecoverystep-building-block)|step building block for request-reply data providers with config-based error recovery support; use the `data-provider/do-request` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderSearch](#bbm_dataprovidersearch-building-block)|performs a search in a record-based data provider and returns the result, includes input/output connectors; use the `data-provider/search` API data provider in the `qorus-api` factory instead
|[BBM_DataProviderSearchBase](#bbm_dataprovidersearchbase-building-block)|base class for using the data provider search API; use the `data-provider/search` API data provider in the `qorus-api` factory instead
|[BBM_DeleteFilePath](#bbm_deletefilepath-building-block)|deletes a file based on configuration, includes an input/output connector; includes an input connector; use the `delete` API data provider in the `file` factory instead
|[BBM_ExecSyncWorkflow](#bbm_execsyncworkflow-building-block)|executes a workflow synchronously; the workflow order data is provided as input data, includes input/output connectors; use the `workflows/exec-sync` API data provider in the `qorus-api` factory instead
|[BBM_ExecSyncWorkflowStatic](#bbm_execsyncworkflowstatic-building-block)|executes a workflow synchronously based on configuration in the building block, includes input/output connectors; use the `workflows/exec-sync` API data provider in the `qorus-api` factory instead
|[BBM_GetData](#bbm_getdata-building-block)|returns arbitrary data based on configuration, provides an input/output connector; includes an input connector; use the `util/get-data` API data provider in the `qorus-api` factory instead
|[BBM_LogMessage](#bbm_logmessage-building-block)|logs a message based on configuration; use the `util/log-message` API data provider in the `qorus-api` factory instead
|[BBM_OutputData](#bbm_outputdata-building-block)|writes data to output location according to configuration giving the data to write and the output locations, includes an input/output connector; use the `util/write-output` API data provider in the `qorus-api` factory instead
|[BBM_QorusServiceMethodCaller](#bbm_qorusservicemethodcaller-building-block)|calls a Qorus service method and returns the result, includes an input/output connector; use the `services/call-method` API data provider in the `qorus-api` factory instead
|[BBM_SmtpEmailSender](#bbm_smtpemailsender-building-block)|building block class with a connector for sending emails; use the `send-email` API data provider in the `smtpclient` factory instead
|[BBM_ThrowException](#bbm_throwexception-building-block)|building block that throws an exception according to configuration; includes an input connector; use the `util/throw-exception` API data provider in the `qorus-api` factory instead
|[BBM_UpdateOrderDynamicData](#bbm_updateorderdynamicdata-building-block)|building block that can be used to write data to a workflow order's dynamic data hash, includes an input/output connector; use the `util/write-output` API data provider in the `qorus-api` factory instead


## **AbstractSalesforceEventStreamer Building Block**

Event streaming support for Salesforce.com using the streaming API
___

## **BBM_AutoMapper Building Block**

## Summary

Base class for running a mapper in autonomous mode, meaning that the input and output data are provided by data providers configured in the mapper.

This building block is not suitable for mapping input data and returning output data, for that use `BBM_GenericMapper` or a mapper in an FSM, a data pipeline, or in a class connection in an interface.

Use this object's configuration to provide input or search filtering as well as to tune the output data handling.

## Connectors

### Input/Output Connector `runMapper`

This connector runs the mapper in autonomous mode.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).

## References

See `BBM_GenericMapper`
___

## **BBM_AutoMapperRecord Building Block**

## Summary

Base class for running a mapper with a record-based output data provider in autonomous mode, meaning that the input and output data are provided by data providers configured in the mapper.  This building block also supports recovery logic and a validation connector.

This building block is not suitable for mapping input data and returning output data, for that use `BBM_GenericMapper` or a mapper in an FSM, a data pipeline, or in a class connection in an interface.

Use this object's configuration to provide input or search filtering as well as to tune the output data handling.

## Connectors

### Input/Output Connector `runMapper`

This connector runs the mapper in autonomous mode.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).

### Input/Output Connector `validate`

This connector is suitable for step validation logic; it returns a string providing the validation status, either `COMPLETE` or `RETRY`, depending if output data was found in the output data provider or not.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).

## References

See `BBM_GenericMapper`

___

## **BBM_AutoMapperRecordStep Building Block**

## Summary

Step base class for running a mapper with a record-based output data provider in autonomous mode, meaning that the input and output data are provided by data providers configured in the mapper.

Use this object's configuration to provide input or search filtering as well as to tune the output data handling.

## Connectors

There are no connectors in this building block, as it is already a step class with the `primary()` and `validation()` methods implemented to execute the auto mapper configuration.
___

## **BBM_AutoMapperRequest Building Block**

## Summary

Base class for running a mapper with a request/response-based output data provider in autonomous mode, meaning that the input and output data are provided by data providers configured in the mapper.  This building block also supports recovery logic and a validation connector.

This building block is not suitable for mapping input data and returning output data, for that use `BBM_GenericMapper` or a mapper in an FSM, a data pipeline, or in a class connection in an interface.

Use this object's configuration to provide input or search filtering as well as to tune the output data handling.

## Connectors

### Input/Output Connector `runMapper`

This connector runs the mapper in autonomous mode.

Local data for the call to `UserApi::expandTemplatedValue()` is the input argument data for the connector available as `$local:input`.

### Input/Output Connector `validate`

This connector is suitable for step validation logic; it returns a string providing the validation status, either `COMPLETE` or `RETRY`, depending if output data was found in the output data provider or not.

Local data for the call to `UserApi::expandTemplatedValue()` is the input argument data for the connector available as `$local:input`.

## References

See `BBM_GenericMapper`
___

## **BBM_AwsSnsServiceBase Building Block**

## Summary

Base AWS [Simple Notification Service][Simple Notification Service] handler service abstract base class.

This class is not meant to be used directly.

## References

See `BBM_AwsSnsServiceEventSource`


___

## **BBM_AwsSnsServiceEventSource Building Block**

## Summary

Base AWS [Simple Notification Service][Simple Notification Service] handler service event source class.

## Connectors

### Input/Output Connector `snsEvent`

Provides SNS event information when it's received by this class.

## References

See `BBM_AwsSnsServiceBase`

___

## **BBM_BindSubworkflow Building Block**

## Summary

Binds a subworkflow in a subworkflow step.

This building block uses the input data for binding; for a building block that binds based on configuration, see `BBM_BindSubworkflowStatic`

This building block is useful only in limited use cases; `BBM_BindSubworkflowStatic` can do everything this building block can do and more; it's recommended to use `BBM_BindSubworkflowStatic` instead.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/workflow/bind-subworkflow` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `bindSubworkflow`

Binds the subworkflow based on the input data; configuration is only used to identify the workflow and to specify output data handling.
___

## **BBM_BindSubworkflowStatic Building Block**

## Summary

Binds a subworkflow in a subworkflow step based on configuration.

This building block uses configuration for all binding data; for a building block that binds purely based on input data, see `BBM_BindSubworkflow`

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/workflow/bind-subworkflow` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `bindSubworkflow`

Binds the subworkflow based on configuration.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).
___

## **BBM_Break Building Block**

## Summary

Building block that throws an `FSM-BREAK` exception to provide a `break` action when executing an FSM.

There is no configuration

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/break` API data provider in the `qorus-api` factory instead

## Connectors

### Input Connector doBreak

Throws an `FSM-BREAK` exception to provide a `break` action when executing an FSM.

Input data is ignored

___

## **BBM_Continue Building Block**

## Summary

Building block that throws an `FSM-CONTINUE` exception to provide a `continue` action when executing an FSM.

There is no configuration

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/continue` API data provider in the `qorus-api` factory instead

## Connectors

### Input Connector doContinue

Throws an `FSM-CONTINUE` exception to provide a `continue` action when executing an FSM.

Input data is ignored

___

## **BBM_CorsBase Building Block**

## Summary 

Base class for HTTP CORS handlers; there is no configuration and no connectors; this class is a helper class meant to be used by classes providing HTTP handling functionality.
___

## **BBM_CreateOrder Building Block**

## Summary

Building block for creating a workflow order from input data.

This building block uses the input data for creating the new workflow order; for a building block that binds based on configuration, see `BBM_CreateOrderStatic`

This building block is useful only in limited use cases; `BBM_CreateOrderStatic` can do everything this building block can do and more; it's recommended to use `BBM_CreateOrderStatic` instead.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `workflows/create-order` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `createOrder`

Creates a new workflow order based on the input data; configuration is only used to identify the workflow and to specify output data handling.
___

## **BBM_CreateOrderStatic Building Block**

## Summary

Building block for creating a workflow order from configuration.

This building block uses configuration to create the new workflow order; for a building block that binds purely based on input data, see `BBM_CreateOrder`

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `workflows/create-order` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `createOrderStatic`

Create the workflow order based on configuration.
The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).
___

## **BBM_CsvReadDataProvider Building Block**

## Summary

Provides a config-based data provider object for data from CSV input data

## Connectors

 ### Input/Output Connector `searchRecordsConnector`

Creates a CSV read data provider object and returns the records parsed.

Local data for the call to `UserApi::expandTemplatedValue()` for all config items is the input  argument data for the connector available as `$local:input`.
___

## **BBM_DataProviderRecordCreate Building Block**

## Summary

Building block for creating records in record-based data providers.

The record to be created is determined by the value of the config item `dataprovider-create-input`; ex:

```
name: $static:name
description: $static:description
```

For a data provider supporting the `returning` create option (like `DbTableDataProvider`, for example), the output data can return values created implicitly in the record creation action such as column values populated by sequences from a trigger using the `dataprovider-create-options` config item - ex: `returning: customer_id`

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/create` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `DataProvider Record Create`

Inserts data from the input argument, or, if there is none, from config item `dataprovider-create-input`

### Input/Output Connector  `DataProvider Record Create From Config`

Inserts data solely from config item `dataprovider-create-input`.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).

### Input/Output Connector `DataProvider Record Validate`

This connector is suitable for step validation logic; it returns a string providing the validation status, either `COMPLETE` or `RETRY`, depending if output data was found in the output data provider or not.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).
___

## **BBM_DataProviderRecordCreateBase Building Block**

## Summary

Base class for building block classes for creating records in record-based data providers.

This base class has no configuration; see `BBM_DataProviderRecordCreate` for a usable building block with connectors and configuration.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/create` API data provider in the `qorus-api` factory instead

## References

See `BBM_DataProviderRecordCreate`
___

## **BBM_DataProviderRecordCreateProcessor Building Block**

## Summary

Provides a data provider record creation processor, suitable for use as an output element in a data pipeline.

## Processor

Accepts input data and writes the output to the configured data provider.

Supports bulk processing; all input records are passed 1:1 as output after processing.

Provides transaction safety; all output in the pipeline will be performed in a single tractionaction, if the data provider supports transaction management.

___

## **BBM_DataProviderRecordUpdate Building Block**

## Summary

Building block to make an update in record-based data providers.

## Connectors

### Input/Output Connector `updateDataProviderRecord`

Used to make an update in a record-based data provider based on input data providing the update hash; if no input data is provided, then the update hash is taken from config item `dataprovider-update-set `.

The output data is a hash with the single key `count` giving the number of records updated.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/update` API data provider in the `qorus-api` factory instead

### Input/Output Connector `updateDataProviderRecordFromConfig`

Used to make an update in a record-based data provider based on config item `dataprovider-update-set ` providing the update hash.

Input data is available as `$local:input` when resolving config items with this connector.

The output data is a hash with the single key `count` giving the number of records updated.

___

## **BBM_DataProviderRecordUpdateBase Building Block**

building block for record-based data providers

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/update` API data provider in the `qorus-api` factory instead
___

## **BBM_DataProviderRequest Building Block**

## Summary

Building block base class for request-reply-based data providers.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/do-request` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `makeDataProviderRequestConnector`

This connector makes a request using the input data for the request body.

### Input/Output Connector `makeDataProviderRequestFromConfigConnector`

This connector makes a request using configuration to provide the request body.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).

## References

See `BBM_DataProviderRequestWithRecovery`
___

## **BBM_DataProviderRequestBase Building Block**

## Summary

Base class for using the data-provider request API to make requests; no configuration

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/do-request` API data provider in the `qorus-api` factory instead

## References

See `BBM_DataProviderRequest` and `BBM_DataProviderRequestWithRecovery` forbuilding blocks with configuration and connectors based on this base class.
___

## **BBM_DataProviderRequestWithRecovery Building Block**

## Summary

Building block for request-based data providers with recovery logic; supports recovery with a single request

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/do-request` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `makeDataProviderRequestConnector`

This connector makes a request using the input data for the request body.

### Input/Output Connector `makeDataProviderRequestFromConfigConnector`

This connector makes a request using configuration to provide the request body.

Local data for the call to `UserApi::expandTemplatedValue()` is the input argument data for the connector available as `$local:input`.

### Input/Output Connector `DataProvider Request Validation`

This connector is suitable for step validation logic; it returns a string providing the validation status, either `COMPLETE` or `RETRY`, depending if output data was found in the output data provider or not.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).

___

## **BBM_DataProviderRequestWithRecoveryStep Building Block**

## Summary

Building block for request-based data providers with recovery logic; supports recovery with a single request

This class has no connectors as it is meant to be directly usable as a normal step class; the `primary()` and `validation()` logic is implemented already in this class.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/do-request` API data provider in the `qorus-api` factory instead
___

## **BBM_DataProviderSearch Building Block**

## Summary

Performs a search in a record-based data provider and returns the result

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/search` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `DataProvider Single Record Search`

This connector executes the search using the input data for the search parameters; the search must return a single record (or no result).

With this connector, the local data (i.e. `$local:*`) for the `dataprovider-search-output-data` config item is the record returned if any data is returned; if no data is returned from the search, no output data can be stored; the internal call to `UserApi::updateOutputData()` is not executed in this case.

### Input/Output Connector `DataProvider Single Record Search From Config`

This connector executes the search using configuration for search parameters; the search must return a single record (or no result).

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`) except `dataprovider-search-output-data`.

With this connector, the local data (i.e. `$local:*`) for the `dataprovider-search-output-data` config item is the record returned if any data is returned; if no data is returned from the search, no output data can be stored; the internal call to `UserApi::updateOutputData()` is not executed in this case.

### Input/Output Connector `DataProvider Multiple Record Search`

This connector executes the search using the input data for the search parameters; the search can return multiple records; output data is the list of hashes representing the records retrieved, or no data, in case no records were matched.

With this connector, the local data for the `dataprovider-search-output-data` config item is the records returned in `$local:records`).

### Input/Output Connector `DataProvider Multiple Record Search From Config`

This connector executes the search using configuration for search parameters; the search can return multiple records; output data is the list of hashes representing the records retrieved, or no data, in case no records were matched.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`) except `dataprovider-search-output-data`.

With this connector, the local data for the `dataprovider-search-output-data` config item is the records returned in `$local:records`).

## References

See `BBM_DataProviderSearchBase`

___

## **BBM_DataProviderSearchBase Building Block**

## Summary

Base class for using the data provider search API; no configuration or connectors

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `data-provider/search` API data provider in the `qorus-api` factory instead

## References

See `BBM_DataProviderSearch`

___

## **BBM_DataProviderSearchRecordIterator Building Block**

## Summary

Provides a building block that outputs a record iterator suitable for use as an input element in a data pipeline.

## Connectors

### Input/Output Connector getIterator()

Performs the search and returns a bulk record iterator for use as input to a data pipeline, for example.

Input data is available as `$local:input` when resolving config items with this connector.

___

## **BBM_DataSerialization Building Block**

## Summary

Serializes data to a specific format according to the `data-serialization-format` configuration item:
- **JSON**: serialize to a JSON string
- **XML**: serialize to an XML string
- **XML-RPC**: serialize to an XML string in [XML-RPC](https://en.wikipedia.org/wiki/XML-RPC) format
- **YAML**: serialize to a YAML string

Use the `data-serialization-verbose-output` config item to use multi-line serialization for more human-readable results for complex data structures if necessary.

## Connectors

### Input/Output Connector `serialize`

Input data is available as local context data during the resolution of all config item as `$local:input`.  

The output data includes the serialized data in the `output` key of the hash returned.

___

## **BBM_DeleteFilePath Building Block**

## Summary

Deletes a file from the filesystem

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `delete` API data provider in the `file` factory instead

## Connectors

### Input/Output Connector `deleteFilePath`

Deletes the file identified by the `delete-file-path` config item.

Local data used when resolving config items for this connector is the input argument data for the connector available as `$local:input`.
___

## **BBM_ExcelReadDataProvider Building Block**

## Summary

Provides a config-based data provider object for data from a **[Microsoft Excel](https://www.microsoft.com/en-us/microsoft-365/excel)** spreadsheet.

## Connectors

### Input/Output Connector `searchRecordsConnector`

Creates an Excel read data provider object and returns the records parsed.

Local data for the call to `UserApi::expandTemplatedValue()` for all config items is the input  argument data for the connector available as `$local:input`.
___

## **BBM_ExecSyncWorkflow Building Block**

## Summary

Executes a synchronous workflow order and returns the results.

This building block is useful only in limited use cases;`BBM_ExecSyncWorkflowStatic` can do everything this building block can do and more; it's recommended to use `BBM_ExecSyncWorkflowStatic` instead.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `workflows/exec-sync` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `execSyncWorkflow`

Creates a new workflow order based on the input data; configuration is only used to identify the workflow and to specify output data handling.
___

## **BBM_ExecSyncWorkflowStatic Building Block**

## Summary

Class for executing a synchronous workflow order from configuration.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `workflows/exec-sync` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `execSyncWorkflowStatic`

Creates and executes a workflow order synchronously from the configuration data.

The input data is available as `$local:input` for all config items resolved  with this connector (in internal calls to `UserApi::expandTemplatedValue()).

___

## **BBM_FsEventBase Building Block**

generic class for event-driven file actions on the local filesystem
___

## **BBM_FtpPollerBase Building Block**

## Summary

Generic building block class for polling for files from an FTP server.

This class is meant to be used as a base class for interfaces (normally a job or a service) that provide FTP polling as an event connector.

If config item `ftp-polling-file-connection` is set, then files are streamed efficiently to the given local file system location and not stored in memory.  If this config item is not set, then all files are transferred and stored in main memory, which can cause problems with very large files.

If uploads to the FTP server are not atomic, the `ftp-polling-minage` config item can be used to ensure that files are only polled after they have been present on the FTP server for a defined period of time, which should be greater than the maximum time required to transfer the largest files.

Note that this class can be used in either a job or a service to provide regular polling for files from an FTP server.  Use in a job is encouraged, as the job schedule is easily controlled by operational users and is the pollijng schedule, additionally the results of each polling operation are exposed in the UI and in the API as job results, making it easier to monitor the FTP polling status.

## Connectors

### Input/Output Connector `pollForFiles`

Used to poll for files once and return file data as output for all files polled; this connector is useful in a job to poll for files regularly according to the job's schedule.  Input data is ignored.

### Input/Output Connector `start`

This connector can be used in a service to poll in a service's `start()` method in a background thread.  In order to use this class's `ftpFileEvent` connector, this connector must be used as the service's `start()` method.  

Input data is ignored and passed through to the output data.

### Input/Output Connector `stop`

This connector can be used in a service to stop polling in a service's `stop()` method.   In order to use this class's `ftpFileEvent` connector, this connector must be used as the service's `stop()` method.  

Input data is ignored and passed through to the output data.

### Event Connector `ftpFileEvent`

This event connector can be used in a service to process file events once they have been polled and fully transferred to the server.  In order to use this connector, the `start` and `stop` connectors must be used in a service's `start()` and `stop()` methods to start and stop the polling thread, respectively.

## References

See:
- class building block: `BBM_FtpPollerCreateOrder`
- job base class: `BBM_FtpPollerCreateOrderJob`


___

## **BBM_FtpPollerCreateOrder Building Block**

## Summary 

Building block class for polling for files from an FTP server and creating a workflow order from files polled.

The local context data for the internal workflow order creation call is the file event data as described by data type `qoretechnologies/building-blocks/ftp/event`; therefore this information can be used when creating the order; for example `create-workflow-staticdata` = `$local:*` would set the initial static order data to the file event hash.

Duplicates can be detected from order keys, i.e. if one of the following config items is used: 
- `create-workflow-specific-unique-key`
- `create-workflow-unique-key`
- `create-workflow-global-unique-key`

In this case this object also contains configuration that allows for an alternative "duplicate-file-handling" workflow order to be created.  See config items in the **FTP Polling Workflow Creation Duplicate File Handling** group for more information.

## References

See `BBM_FtpPollerCreateOrderJob` for a class designed to be used as the base class for a job
___

## **BBM_FtpPollerCreateOrderJob Building Block**

## Summary 

Building block job base class for polling for files from an FTP server and creating a workflow order from files polled.

The local context data for the internal workflow order creation call is the file event data as described by data type `qoretechnologies/building-blocks/ftp/event`; therefore this information can be used when creating the order; for example `create-workflow-staticdata` = `$local:*` would set the initial static order data to the file event hash.

Duplicates can be detected from order keys, i.e. if one of the following config items is used: 
- `create-workflow-specific-unique-key`
- `create-workflow-unique-key`
- `create-workflow-global-unique-key`

In this case this object also contains configuration that allows for an alternative "duplicate-file-handling" workflow order to be created.  See config items in the **FTP Polling Workflow Creation Duplicate File Handling** group for more information.

**Note** The `ftp-polling-interval-secs` config item is always ignored in this class; this class must be used as the base class for a job, and the job's schedule determines the polling interval.
___

## **BBM_GenericMapper Building Block**

## Summary

This is a generic mapper class building block that can be used to make generic data transformations.

## Connectors

### Input/Output Connector `map`

This connector uses the configured mapper to transform the input data; the output data is the result of the map operation.

Input data is available as `$local:input` when resolving config items with this connector.

Note that input data used for the mapper is always the connector input data if present.

### Input/Output Connector `mapFromConfig`

This connector uses the configured mapper to transform the input data; the output data is the result of the map operation.

Note that input data used for the mapper is always taken from the `automapper-input` config item; input data is only used as context data (i.e. as `$local:input`) when resolving config item template values.

___

## **BBM_GetArray Building Block**

## Summary

Returns an array from the configuration data

## Connectors

### Input/Output Connector `getArray`

This connector returns a list defined by the value of the `get-array-output` config item; if this config item returns a non-list value, then it is converted to a list before returning.

The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).
___

## **BBM_GetData Building Block**

## Summary

Returns data from configuration data

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/get-data` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `getData`

Returns the value of the `get-data` config item.

Input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).

### Input/Output Connector `getDataAsList`

Returns the value of the `get-data` config item, converted to a single-element list if necessary.

Input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).
___

## **BBM_GetPipelineData Building Block**

## Summary

Provides input data to a data pipeline; note that this class ignores input data passed to it but rather only provides data to the next element based on its configuration.

This class is suitable for using as the first step in a pipeline to pass existing data into a pipeline for processing.

## Processor Description

Uses input data only for resolving the output data from config item `get-pipeline-data`; the input data is not passed through to the next element in the pipeline unless it's referenced in the `get-pipeline-data` config item.

Local data (in this case, the processor's input data) for the call to `UserApi::expandTemplatedValue()` is the input argument data for the connector available as `$local:input.
___

## **BBM_HttpAuthenticatorBase Building Block**

## Summary

Base building block class for providing authenticators.

This class has no connectors or configuration but is rather used by other service building block classes providing HTTP and related network services that can optionally require authentication (REST, WebSocket, etc).
___

## **BBM_HttpFileHandler Building Block**

## Summary

A generic building block for HTTP file handling for use in Qorus services.

This class can be used to expose files from the filesystem to HTTP clients iin a Qorus service.

It contains no connectors; it is driven entirely by configuration.  

Initialization is performed automatically when the class is instantiated.
___

## **BBM_HttpReverseProxyService Building Block**

## Summary

Reverse HTTP proxy building block for use in a Qorus service.

Provides HTTP and also WebSocket proxying functionality; also chunked transfers are forwarded directly as well.

There are no connectors; this building block class is driven entirely by configuration.
___

## **BBM_HttpServiceBase Building Block**

## Summary

Abstract base class for HTTP handler services.

As an abstract class, it cannot support connectors; it is entirely driven by configuration.
___

## **BBM_HttpServiceGenericBase Building Block**

## Summary

Abstract base class for HTTP handler services.

As an abstract class, it cannot support connectors; it is entirely driven by configuration.
___

## **BBM_InternalIterator Building Block**

## Summary

Building block that allows for iteration of internal data; converts a hash with an internal list into a list of hashes having common top-level data with the interior element repeated 

## Connectors

### Input/Output Connector `internalIterator`

Accepts the input data and returns a list of records according to the `internal-iterator-key-path` config item, designating the position in the input data to iterate.

Input data is furthermore available as `$local:input` when resolving config items with this connector.

___

## **BBM_JavaConfig Building Block**

## Summary

Helper class that sets Java configuration based on configuration items

It does not provide any connectors; it is entirely driven by configuration.
___

## **BBM_KafkaConsumer Building Block**

## Summary

**[Kafka](https://kafka.apache.org/)** message consumer building block; provides a Kafka message event source to Qorus.

This building block class is designed to be used in a Qorus service.

## Connectors

### Event Connector `event`

Provides Kafka messages as events.

Event connectors can only be used in Qorus services.

### Input/Output Connector `start`

Starts listening to Kafka messages; meant to be assocated with a service's `start()` method.

Input data is ignored; returns `true` if the Kafka listening thread was started, `false` immediately if already running.  This connector returns `true` at the end of listening; the `start()` method runs for the lifetime of the object until stopped.

### Input/Output Connector `stop`

Stops listening to Kafka messages; means to be associated with a service's `stop()` method.

Input data is ignored; returns `null` (`NOTHING` if called from Qore, `None` if called from Python).
___

## **BBM_KafkaProducer Building Block**

## Summary

**[Kafka](https://kafka.apache.org/)** message producer building block for sending Kafka messages from Qorus.

## Connectors

## Input/Output Connector `sendMessage`

Sends a message synchronously; the input data is used to send the message and must correspond to the given input type.

Output data provides information about the message sent.

## Input/Output Connector `sendMessageAsync`

Sends a message asynchronously; the input data is used to send the message and must correspond to the given input type.

Output data is a `Future` object regarding the asynchronous message sent.
___

## **BBM_ListCache Building Block**

## Summary

A building block class that implements a simple cache of a list of data items of any type

## Connectors

### Input/Output Connector `cacheData`

This connector adds data to the cache by resolving the `list-cache-data` config item.

The input data is available as `$local:input` for all config items resolved with this connector (in the call to `UserApi::expandTemplatedValue()`).

The input data is returned as output data as well.

### Input/Output Connector `getData`

Returns the data cached; input data is ignored as no configuration is used in this connector.

### Input/Output Connector `clear`

The cache is emptied; input data is ignored; the cache contents are returned as output data.
___

## **BBM_LogMessage Building Block**

## Summary

Output a message to the current log file.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/log-message` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `logMessage`

Logs a message to the log file according to the values of the configuration; input data to the connector is available as `$local:input`.

Ouput data is the messages logged in a hash in the `msg` key.
___

## **BBM_MqttPahoClient Building Block**

## Summary

[MQTT Paho](https://www.eclipse.org/paho/) client for publishing and listening to MQTT messages.

This class is the base class for the publishing and listening classes.  There are no connectors; it is driven entierly by configuration.
___

## **BBM_MqttPahoPublisher Building Block**

## Summary

[MQTT Paho](https://www.eclipse.org/paho/) client for publishing messages to an MQTT topic

## Connectors

### Input/Output Connector `publishFromConfig`

Used to publish a message from config item `mqtt-paho-message-body`.

The input data is available as `$local:input` for all config items resolved with this connector (in the call to `UserApi::expandTemplatedValue()`).

Message data is converted to a binary for publishing, if necessary by first converting to a string.

The output data is the `org.eclipse.paho.client.mqttv3.MqttMessage` object published.

### Input/Output Connector `publish`

Used to publish a message from data passed as input; if no value is passed, then the message data is taken from config item `mqtt-paho-message-body`.

The input data is converted to a binary if necessary, if necessary by first converting to a string.

The output data is the `org.eclipse.paho.client.mqttv3.MqttMessage` object published.

Is is recommended to use the `publishFromConfig` connector instead.

___

## **BBM_MqttPahoSubscriber Building Block**

## Summary

[MQTT Paho](https://www.eclipse.org/paho/) client for receiving messages from an MQTT server

## Connectors

### Event Connector `connectionLost`

Raised when the connection is lost; event hash keys:
- **`class_name`**: (`string`) the full exception class name
- **`message`**: (`string`) the exception message
- **`cause`**: (`java.lang.Throwable`) the exception object itself

### Event Connector `deliveryComplete`

Raised when a message has been successfully delivered; event hash keys:
- **`topics`** (`list<string>`) the topic or topics for the message
- **`id`**: (`string`) the message ID delivered
- **`payload`**: the message payload, decoded according to config item `mqtt-paho-message-format`
- **`qos`**: (`int`) the QoS code for the message
- **`duplicate`**: (`bool`) if the message is a duplicate
- **`retained`**: (`bool`) if the message was retained
- **`message`**: (`org.eclipse.paho.client.mqttv3.MqttMessage`)
 the message object itself

### Event Connector `messageArrived`

Raised when a message arrives from a topic matching config item `mqtt-paho-message-topics`; event hash keys:
- **`topic`** (`string`) the topic for the message
- **`id`**: (`string`) the message ID delivered
- **`payload`**: the message payload, decoded according to config item `mqtt-paho-message-format`
- **`qos`**: (`int`) the QoS code for the message
- **`duplicate`**: (`bool`) if the message is a duplicate
- **`retained`**: (`bool`) if the message was retained
- **`message`**: (`org.eclipse.paho.client.mqttv3.MqttMessage`)
 the message object itself

### Input / Output Connector `start`

Passes through any input given.  Can be used as the start method of a service. Only returns when `stop()` is called.
### Input / Output Connector `stop`

Passes through any input given.  Stops listening and disconnects the connection.
___

## **BBM_OndewoBpiServer Building Block**

Building block for an ONDEWO Business Process Integration server service in Qorus
___

## **BBM_OndewoIntentHandler Building Block**

ONDEWO intent handler
___

## **BBM_OndewoNluClient Building Block**

Building block that returns an ONDEWO NLU / Conversational AI client from an `ondewonlu://` Qorus connection
___

## **BBM_OndewoVtsiClient Building Block**

 Building block that returns an ONDEWO VTSI client from an `ondewovtsi://` Qorus connection
___

## **BBM_OutputData Building Block**

## Summary

Writes output data to locations provided by config item `output-data-hash`, which should be assigned a hash in the following format:
- **key**: *data to store* -> **value**: *location to store it in*

The keys in the hash are expanded with calls to `UserApi::expandTemplatedValue()`

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/write-output` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `writeOutput`

This connector executes the output write data operation.

Input data is available as `$local:input` when resolving config items with this connector.

It is recommended to use this connector instead of the similar `writeOutputData` connector, as this connector support standard handling of the local input data, and the `writeOutputData` connector does not.

### Input/Output Connector `writeOutputData`

This connector executes the output write data operation.

Local data for the call to `UserApi::expandTemplatedValue()` is the input argument data for the connector; if the input data is a hash, then it is used directly as the local context data for the `$local:` template.  If the input data is not a hash, then it is stored in the `input` key of the local data hash.

This connector differs from `writeOutput` only in the non-standard handling of the local input data.

It is recommended to use the `writeOutput` connector instead, as it uses standard input data handling.

## `output-data-hash` Config Item Examples

- `$local:input: $dynamic:data` -> store the input data in the `data` key of dynamic data
- `'$info:started': '$pstate:started'` -> store the `started` key from the `$info:` template into the `started` key of the persistent state hash for the current interface
- `'$local:*': '$jinfo:result'` -> store the entire local context data hash in the `result` key of the `$jinfo:` (job info) hash
___

## **BBM_PauseDataPassthru Building Block**

## Summary

A building block that executes a configurable pause or delay.

The `pause` connector passes through any data as-is when used in a connection.

Note that if the interface shuts down while the pause is in action, a `RETRY-ERROR` will be thrown to ensure a retry when used in a workflow context.

## Connectors

### Input/Output Connector `pause`

Performs a configurable pause based on the config item values resolved.

Input data is available as `$local:input` when resolving config items with this connector.
___

## **BBM_QorusServiceMethodCaller Building Block**

This building block allows for Qorus service methods to be called based on configuration

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `services/call-method` API data provider in the `qorus-api` factory instead
___

## **BBM_QorusUiExtension Building Block**

## Summary

Qorus web UI extension handlindler service building block.   Allows a Qorus service to provide a UI extension with configuration.

The UI resources files should be provided as service resources; the default resource will be served according to config item `ui-extension-default-resource`.

## Connectors

### Input/Output Connector `init`

Initializes the service according to configurqation; input data is returned as-is but is otherwise ignored.
___

## **BBM_RegularExpressions Building Block**

## Summary

Generic object defining constants for regular expression configuration item handling.

This building block class has no configuration or connectors; it is designed to be used by other building blocks providing regular expression support.
___

## **BBM_RestAction Building Block**

## Summary

Building block class for making a REST request.

Use the `rest-output-data` config item to write the results of the REST call to an output location; ex: `body: $dynamic:rest_results` would write the response body to the `rest_results` key of the dynamic data hash in a workflow order.

Note that there is inline retry configuration for I/O errors; by default this object will make 3 retries spaced 5 seconds apart if configured socket errors are encountered; see config items for more information.

## Connectors

Output data for all connectors is a hash with the following keys:
- `body`: the response message body, if any
- `request-uri`: the request URI string sent (ex: `GET /services/async/38.0/job HTTP/1.1`)
- `request-headers`: hash of outgoing HTTP request headers
- `request-serialization`: message serialization used in the request body
- `response-code`: the HTTP response code
- `response-uri`: the HTTP response URI
- `response-headers`:  a hash of processed incoming HTTP headers in the response with keys converted to lower case and with additional information added
- `response-serialization`: message serialization used in the response body
- `response-chunked`: `true` if the response body was sent chunked

### Input/Output Connector `restAction`

This connector uses the input data as a hash to provide the following values for the REST call:
- `body`: the request message body (note that requests with `GET` and `HEAD` methods should not contain a message body)
- `uri_path` the request URI path
- `hdr`: any headers to include in the request

### Input/Output Connector `restActionFromConfig`

This connector takes all configuration for the REST call from config items.
The input data is available as `$local:input` for all config items resolved with this connector (in internal calls to `UserApi::expandTemplatedValue()`).
___

## **BBM_RestActionStep Building Block**

generic step for making a transaction-safe REST request
___

## **BBM_RestActionWithRecovery Building Block**

Class for making a transaction-safe REST request
___

## **BBM_RestServiceBase Building Block**

## Summary

Base class for REST handler services

There are no connectors; this class is driven entirely by configuration.
___

## **BBM_SalesforceStreamBase Building Block**

## Summary

Base class for **Salesforce** streaming API support; reports events; can only be used in services

## Connectors

### Event Connector `event`

Provides information about events in a Salesforce instance in Qorus services.
___

## **BBM_SalesforceStreamCreateOrder Building Block**

## Summary

Service building block class for Salesforce.com streaming API support; creates a workflow order for each event received according to the configuration.

There are no connectors; it is entirely driven by configuration.
___

## **BBM_SftpPollerBase Building Block**

## Summary

Generic building block class for polling for files from an SFTP server.

This class is meant to be used as a base class for interfaces (normally a job or a service) that provide SFTP polling as an event connector.

If config item `sftp-polling-file-connection` is set, then files are streamed efficiently to the given local file system location and not stored in memory.  If this config item is not set, then all files are transferred and stored in main memory, which can cause problems with very large files.

If uploads to the SFTP server are not atomic, the `sftp-polling-minage` config item can be used to ensure that files are only polled after they have been present on the FTP server for a defined period of time, which should be greater than the maximum time required to transfer the largest files.

Note that this class can be used in either a job or a service to provide regular polling for files from an SFTP server.  Use in a job is encouraged, as the job schedule is easily controlled by operational users and is the pollijng schedule, additionally the results of each polling operation are exposed in the UI and in the API as job results, making it easier to monitor the SFTP polling status.

## Connectors

### Input/Output Connector `pollForFiles`

Used to poll for files once and return file data as output for all files polled.  Input data is ignored.

### Input/Output Connector `start`

This connector can be used in a service to poll in a service's `start()` method in a background thread.  In order to use this class's `sftpFileEvent` connector, this connector must be used as the service's `start()` method.

Input data is ignored and passed through to the output data.

### Input/Output Connector `stop`

This connector can be used in a service to stop polling in a service's `stop()` method.   In order to use this class's `sftpFileEvent` connector, this connector must be used as the service's `stop()` method.

Input data is ignored and passed through to the output data.

### Event Connector `sftpFileEvent`

This event connector can be used in a service to process file events once they have been polled and fully transferred to the server.  In order to use this connector, the `start` and `stop` connectors must be used in a service's `start()` and `stop()` methods to start and stop the polling thread, respectively.

## References

See:
- class building block: `BBM_SftpPollerCreateOrder`
- job base class: `BBM_SftpPollerCreateOrderJob`


___

## **BBM_SftpPollerCreateOrder Building Block**

## Summary

Building block class for polling for files from an SFTP server and creating a workflow order from files polled.

The local context data for the internal workflow order creation call is the file event data as described by data type `qoretechnologies/building-blocks/sftp/event`; therefore this information can be used when creating the order; for example `create-workflow-staticdata` = `$local:*` would set the initial static order data to the file event hash.

Duplicates can be detected from order keys, i.e. if one of the following config items is used:
- `create-workflow-specific-unique-key`
- `create-workflow-unique-key`
- `create-workflow-global-unique-key`

In this case this object also contains configuration that allows for an alternative "duplicate-file-handling" workflow order to be created.  See config items in the **SFTP Polling Workflow Creation Duplicate File Handling** group for more information.

## References

See `BBM_SftpPollerCreateOrderJob` for a class designed to be used as the base class for a job
___

## **BBM_SftpPollerCreateOrderJob Building Block**

## Summary 

Building block job base class for polling for files from an SFTP server and creating a workflow order from files polled.

The local context data for the internal workflow order creation call is the file event data as described by data type `qoretechnologies/building-blocks/sftp/event`; therefore this information can be used when creating the order; for example `create-workflow-staticdata` = `$local:*` would set the initial static order data to the file event hash.

Duplicates can be detected from order keys, i.e. if one of the following config items is used: 
- `create-workflow-specific-unique-key`
- `create-workflow-unique-key`
- `create-workflow-global-unique-key`

In this case this object also contains configuration that allows for an alternative "duplicate-file-handling" workflow order to be created.  See config items in the **SFTP Polling Workflow Creation Duplicate File Handling** group for more information.

**Note** The `sftp-polling-interval-secs` config item is always ignored in this class; this class must be used as the base class for a job, and the job's schedule determines the polling interval.

## Connectors

### Input/Output Connector `runJob`

Runs the poll action once.
___

## **BBM_SimpleFilterPipelineData Building Block**

## Summary

This building block provides a pipeline processor element that does simple record filtering.  It supports bulk processing.

## Pipeline Processor

This building block's pipeline processor uses each data record as local context and then evaluates `simple-filter-criteria` on each record.  If the result of the evaluation is boolean `true`, then the record is accepted and passed on for further processing.  If not, the record is ignored.

Ex: If the input record is `{key1: value, type: 2}`, `simple-filter-criteria` = `$qore-expr:{$local:type == 1}`, then the filter criteria config item will result in `False` which will result in the record being rejected.  The example filter criteria only accepts records where `type == 1` (if you want to also reject records without a type, then you could use `$qore-expr:{$local:type??{0} == 1}`).

Bulk processing is supported in the same manner, and the "hash of lists" is rebuilt without references to the discarded records.

**Boolean Evaluation Table**

|**Data**|**Example Values**|**Description**|
|:---|:---|:---
|`True` or `False`|True|direct interpretation
|empty string, hash, list, or binary value|`""`, `{}`, `[]`|`False`
|int, float, number, or string 0|`0`, `0.0`, `"0"`|`False`
|non-empty string and not `"0"`|`"string"`|`True`
|non-empty hash, list, or binary value|`{key: value}`|`True`

___

## **BBM_SmtpEmailSender Building Block**

## Summary

A building class to send one or more emails through an SMTP server.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `send-email` API data provider in the `smtpclient` factory instead

## Connectors

### Input/Output Connector sendEmail

Sends an email to the recipient based on configuration.

Input data is available as `$local:input` when resolving config items with this connector.

___

## **BBM_SnmpCommonBase Building Block**

Building block providing a base class for working with SNMP traps
___

## **BBM_SnmpServiceTrapEventSource Building Block**

Building block providing an event source for SNMP traps
___

## **BBM_TextAnalysis Building Block**

## Summary

A Python-based text analysis building block class using tensorflow, keras, and numpy to apply a pre-trained model on text input to classify the user's intent.

## Connectors

### Input/Output Connector `processInput`

Processes the input directly; input must be a string.

The output is any action string associated wiht the input.

### Input/Output Connector `processInputHash`

Process input data identified as by the `text-analysis-hash-event-key` config item which designates a key in the input hash holding the input data.

Output data is a hash with a `result` key giving the action associated with the input.

### Input/Output Connector `processInputFromConfig`

Process input data identified by the `text-analysis-input` config item, where the input data to this connector is available as `$local:input`/

Output data is a hash with a `result` key giving the action associated with the input.

___

## **BBM_ThrowException Building Block**

## Summary

Throws an exception

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/throw-exception` API data provider in the `qorus-api` factory instead

## Connectors

### Input Connector throwException

This connector throws an exception according to the configuration.

Input data is available as `$local:input` when resolving config items with this connector.
___

## **BBM_UpdateOrderDynamicData Building Block**

## Summary

Updates the dynamic data of a workflow order based on configuration.

**NOTE**:  This building block's functionality has been superceded by an API (request - response) data provider; it's recommended to use the `util/write-output` API data provider in the `qorus-api` factory instead

## Connectors

### Input/Output Connector `update`

Performs the update of dynamic data according to configuration.

Input data is available as `$local:input` when resolving config items with this connector.

Provides the hash data updated in the given order as output data.

**NOTE**: the update performed uses `UserApi::updateDynamicOrderData()` and therefore is atomic
___

## **BBM_WebSocketServiceBase Building Block**

## Summary

A base class for WebSocket handler services in Qorus services

There are no connectors; it is entirely driven by configuration, and WebSocket server services are initialized when the object is created.
___

## **BBM_WebSocketServiceDataEventSource Building Block**

## Summary

A data event source for WebSocket events in Qorus services, supporting serialized data for events.

The class's constructor initializes the object, so if it's used as an event source (or generally in any connection) or as the primary service class, there is no need to use the `init` connector.

## Data Serialization

The default data serialization is `json`, as this is the most common serialization used; `yaml` is also supported.

## Connectors

### Event Connector `webSocketReceiveEvent`

Provides a hash event when a WebSocket message is received from a client.

### Input/Output Connector `init`

Must be used to initialize the object in a service if this class is not used as an event source (or generally in any connection) or as the primary service class.

### Input/Output Connector `webSocketSendEvent`

Sends a message or a response to a client; the client is identified by the `cid` key in the input hash.

No ouput data is provided.

### Input/Output Connector `webSocketBroadcastEvent`

Broadcasts a message to all clients; the message is provided as the `msg` key in the input data.

No ouput data is provided.
___

## **BBM_WebSocketServiceEventSource Building Block**

## Summary

An event source for WebSocket events in Qorus services

This class is designed to be used as an event source for services.

The class's constructor initializes the object, so if it's used as an event source (or generally in any connection) or as the primary service class, there is no need to use the `init` connector.

## Connectors

### Event Connector `webSocketReceiveEvent`

Provides a hash event when a WebSocket message is received from a client.

### Input/Output Connector `init`

Must be used to initialize the object in a service if this class is not used as an event source (or generally in any connection) or as the primary service class.

### Input/Output Connector `webSocketSendEvent`

Sends a message or a response to a client; the client is identified by the `cid` key in the input hash.

No ouput data is provided.

### Input/Output Connector `webSocketBroadcastEvent`

Broadcasts a message to all clients; the message is provided as the `msg` key in the input data.

No ouput data is provided.
___

## **BBM_WsgiHandlerBase Building Block**

WSGi HTTP Server Handler Base Building Block for Qorus

This class is written in Qore instead of Python to be thread-safe and scalable.

The `WsgiAppHelper` class is used to initialize the WSGi app with the same syntax as [Gunicorn](https://gunicorn.org/)
___

## **BBM_WsgiServer Building Block**

WSGi Server Building Block for Qorus

This class is written in Qore instead of Python to be thread-safe and scalable.

The `WsgiAppHelper` class is used to initialize the WSGi app with the same syntax as [Gunicorn](https://gunicorn.org/)
___

## **BBM_WsgiUiExtension Building Block**

WSGi Qorus UI Extension Building Block for Qorus

This class is written in Qore instead of Python to be thread-safe and scalable.

The `WsgiAppHelper` class is used to initialize the WSGi app with the same syntax as [Gunicorn](https://gunicorn.org/)
___

## **SalesforceLoginParameters Building Block**

Helper class for salesforce event sources in Qorus
___

## **SalesforceLongPollingTransport Building Block**

Helper class for salesforce event sources in Qorus
___

## **WsgiAppHelper Building Block**

Used to create the WSGi application object for a WSGi server
___
