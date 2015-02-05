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

# This file contains environment-variable overrides to be used in conjunction
# with bdutil_env.sh in order to deploy a Hadoop + Storm cluster.
# Usage: ./bdutil deploy -e extensions/storm/storm_env.sh

# Install direcotries
STORM_INSTALL_DIR='/home/hadoop/storm-install'
ZOOKEEPER_INSTALL_DIR='/home/hadoop/zookeeper-install'

# local info directories
STORM_VAR='/var/storm'
ZOOKEEPER_VAR='/var/zookeeper'

# URIs of tarballs
STORM_TARBALL_URI='gs://storm-dist/apache-storm-0.9.2-incubating.tar.gz'
ZOOKEEPER_TARBALL_URI='gs://zookeeper-dist/zookeeper-3.4.6.tar.gz'

# Storm UI is on port 8080.
MASTER_UI_PORTS=('8080' ${MASTER_UI_PORTS[@]})

COMMAND_GROUPS+=(
  "install_storm:
    extensions/storm/install_supervisor.sh
    extensions/storm/install_zookeeper.sh
    extensions/storm/install_storm.sh
  "
  "start_storm_worker:
    extensions/storm/start_storm_worker.sh
  "
  "start_storm_master:
    extensions/storm/start_storm_master.sh
  "
)


COMMAND_STEPS+=(
  'install_storm,install_storm'
  'start_storm_master,start_storm_worker'
)
