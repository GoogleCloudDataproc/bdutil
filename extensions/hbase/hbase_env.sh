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
# with bdutil_env.sh in order to deploy a Hadoop cluster with HBase installed
# and configured.
# Usage: ./bdutil deploy extensions/hbase/hbase_env.sh.

# URIs of tarball to install.
HBASE_TARBALL_URI='gs://hbase-dist/hbase-0.94.19.tar.gz'

# Directory on each VM in which to install hbase.
HBASE_INSTALL_DIR='/home/hadoop/hbase-install'

COMMAND_GROUPS+=(
  "install_hbase:
     extensions/hbase/install_hbase.sh
  "
  "start_hbase:
     extensions/hbase/start_hbase.sh
  "
)

# Installation of hbase on master and workers; then start_hbase only on master.
COMMAND_STEPS+=(
  'install_hbase,install_hbase'
  'start_hbase,*'
)
