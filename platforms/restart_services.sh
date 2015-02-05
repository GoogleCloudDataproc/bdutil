#!/usr/bin/env bash
# Copyright 2014 Google Inc. All Rights Reserved.D
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

# Restarts services corresponding to installed packages.
# Performs last minute initialization as needed.

set -e

source hadoop_helpers.sh

if [[ $(hostname -s) == ${MASTER_HOSTNAME} ]]; then
  COMPONENTS=${MASTER_COMPONENTS}
else
  COMPONENTS=${DATANODE_COMPONENTS}
fi

# Component ordering is sensitive. hive-metastore must come before hive-server2
# and hdfs must be up before oozie.
for COMPONENT in ${COMPONENTS}; do
  if [[ -x /etc/init.d/${COMPONENT} ]]; then
    # Initialize HDFS
    if [[ ${COMPONENT} == 'hadoop-hdfs-namenode' ]]; then
      service hadoop-hdfs-namenode stop
      # Do not refomat if already formatted.
      yes n | service hadoop-hdfs-namenode init
      service hadoop-hdfs-namenode start

      # Setup /tmp and /user directories.
      if [[ "${DEFAULT_FS}" == 'hdfs' ]]; then
        initialize_hdfs_dirs
      fi
    # Initialize Oozie. Requires Namenode to be up.
    elif [[ ${COMPONENT} == 'oozie' ]]; then
      # Requires HDFS to be up and running.
      # Might be CDH specific.
      oozie-setup sharelib create -fs ${NAMENODE_URI} \
          -locallib /usr/lib/oozie/oozie-sharelib-yarn.tar.gz
      service oozie restart
    else
      service ${COMPONENT} restart
    fi
  fi
done
