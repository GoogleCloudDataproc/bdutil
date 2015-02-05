#!/usr/bin/env bash
# Copyright 2014 Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#TODO(pclay) support other Linux distributions.
download_bd_resource \
    http://archive.cloudera.com/cdh${CDH_VERSION}/debian/wheezy/amd64/cdh/cloudera.list \
    /etc/apt/sources.list.d/cloudera.list
# TODO(pclay): fix insecure download of apt-key.
download_bd_resource \
    http://archive.cloudera.com/cdh${CDH_VERSION}/debian/wheezy/amd64/cdh/archive.key \
    /tmp/cloudera.key
apt-key add /tmp/cloudera.key

apt-get update

if [[ $(hostname -s) == ${MASTER_HOSTNAME} ]]; then
  COMPONENTS="${MASTER_COMPONENTS}"
else
  COMPONENTS="${DATANODE_COMPONENTS}"
fi

for COMPONENT in ${COMPONENTS}; do
  if ! install_application ${COMPONENT}; then
    # Check that it was actually installed as Services often fail to start.
    dpkg -s ${COMPONENT}
  fi
  # Stop installed services:
  if [[ -x "/etc/init.d/${COMPONENT}" ]]; then
    service ${COMPONENT} stop
  fi
done
