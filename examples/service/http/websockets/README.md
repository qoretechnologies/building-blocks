# Chatbot Demo

## Overview

This is a demo of a "no-code" AI-driven chatbot in Qorus Integration Engine(R) built with building blocks.

It requires Qorus 5.1+ to run.

It is based on configuration in Qorus, a simple UI extension that provides an HTML interface and a WebSocket
connection to the Qorus server, a JSON-formatted indent file (`intents.json`) that links user input strings and
an itent label, and a model (in `saved_model`) that is trained from the intent file by the script `train.py`.

**NOTE**: The current service configuration requires a [Qorus instance in Kubernetes](https://git.qoretechnologies.com/qorus/qorus-kubernetes/-/tree/master/kubernetes) to run; to allow it to run
in non-Kubernetes instances, make sure and change the `Stateless` flag in the `chatbot-ws-demo` service to `false`
and then (re-)deploy the service.
## Installation

1. Get Qorus 5.1+ up and running; the quickest way is with Docker: https://git.qoretechnologies.com/qorus/qorus-docker
2. Install tensorflow for Python in your Qorus instance
   - With Docker, execute:
`docker exec qorus pip install --prefix=/opt/qorus/user/python tensorflow`

   - With Kubernetes, execute:
`kubectl exec -it deploy/qorus-core -- pip install --prefix=/opt/qorus/user/python tensorflow`

3. Clone the `building-block` repository with this example
   - `git clone https://git.qoretechnologies.com/qorus/building-blocks.git`
4. Set up the VS Code IDE with the above repository and configure it for your Qorus instance
   - https://marketplace.visualstudio.com/items?itemName=qoretechnologies.qorus-vscode
5. Deploy this service from the IDE to your Qorus instance with all dependencies
   - **NOTE**: if not running under Kubernetes, set the `Stateless` attribute to `false` in the `chatbot-ws-demo` service and then (re-)deploy the service; if not the service cannot be started and the demo will not work
6. Access the UI extension from the Qorus Web UI under `... More -> Extensions -> Chatbot`