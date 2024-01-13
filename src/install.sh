#!/bin/bash

set -xe

./build.sh clean
./build.sh
sudo cp ./ccts /usr/local/bin/
