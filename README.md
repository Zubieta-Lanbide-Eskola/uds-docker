# uds-docker

Docker build for UDS environment

This docker compose file runs all the needed components to setup openUDS. Source code can be found in <https://github.com/dkmstr/openuds>

All software development is done in the repo above. This repo defines all the needed setup to run openUDS in a docker compose environment.

`building` directory contains the required files to build some of the used
images. You won't need them unless you plan to build the images by yourself instead of pulling them.

`dockercompose` directory contains the files you should download to deploy
*OpenUDS*. This docker compose environment needs some setup steps, so please
read the [README](./dockercompose/README.md) file on dockercompose folder.
