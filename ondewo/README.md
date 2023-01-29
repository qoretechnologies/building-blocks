# ONDEWO Building Blocks

## Overview

This includes building blocks for:
- ONDEWO BPI processing
- ONDEWO NLU client

## Installation

The `install-ondewo-deps.sh` file installs ONDEWO dependencies; it currently supports Ubuntu, Fedora, Alpine Linux, and MacPorts on macOS.

Once the ONDEWO Go/Google RPC dependencies have been installed, then the Qorus ONDEWO configuration can be installed with `make load-ondewo` in the root directory of the `building-blocks` responsitory.

**NOTE** If you are using Docker images, just use the `qorus-ondewo:5.1` docker image instead; all prereqs are already installed.
