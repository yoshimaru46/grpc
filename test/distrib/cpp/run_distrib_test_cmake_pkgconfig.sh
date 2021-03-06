#!/bin/bash
# Copyright 2017 gRPC authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -ex

cd "$(dirname "$0")/../../.."

echo "deb http://archive.debian.org/debian jessie-backports main" | tee /etc/apt/sources.list.d/jessie-backports.list
echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf
sed -i '/deb http:\/\/deb.debian.org\/debian jessie-updates main/d' /etc/apt/sources.list
apt-get update
apt-get install -t jessie-backports -y libssl-dev pkg-config

# Install c-ares
cd third_party/cares/cares
git fetch origin
git checkout cares-1_15_0
mkdir -p cmake/build
cd cmake/build
cmake -DCMAKE_BUILD_TYPE=Release ../..
make -j4 install
cd ../../../../..
rm -rf third_party/cares/cares  # wipe out to prevent influencing the grpc build

# Install zlib
cd third_party/zlib
mkdir -p cmake/build
cd cmake/build
cmake -DCMAKE_BUILD_TYPE=Release ../..
make -j4 install
cd ../../../..
rm -rf third_party/zlib  # wipe out to prevent influencing the grpc build

# Install protobuf
cd third_party/protobuf
mkdir -p cmake/build
cd cmake/build
cmake -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_BUILD_TYPE=Release ..
make -j4 install
cd ../../../..
rm -rf third_party/protobuf  # wipe out to prevent influencing the grpc build

# Just before installing gRPC, wipe out contents of all the submodules to simulate
# a standalone build from an archive
# shellcheck disable=SC2016
git submodule foreach 'cd $toplevel; rm -rf $name'

# Install gRPC
mkdir -p cmake/build
cd cmake/build
cmake -DgRPC_INSTALL=ON -DgRPC_BUILD_TESTS=OFF -DgRPC_PROTOBUF_PROVIDER=package -DgRPC_ZLIB_PROVIDER=package -DgRPC_CARES_PROVIDER=package -DgRPC_SSL_PROVIDER=package -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local/grpc ../..
make -j4 install
cd ../..

# Build helloworld example using Makefiles and pkg-config
cd examples/cpp/helloworld
export PKG_CONFIG_PATH=/usr/local/grpc/lib/pkgconfig
export PATH=$PATH:/usr/local/grpc/bin
make
