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
# with bdutil_env.sh in order to deploy a Hadoop cluster with Hama installed
# and configured.
# Usage: ./bdutil deploy extensions/hama/hama_env.sh.

# URIs of tarball to install.
HAMA_TARBALL_URI='gs://hama-dist/hama-dist-0.7.0.tar.gz'

# Default Hama dist tarball requires Hadoop 2.
import_env hadoop2_env.sh

# Directory on each VM in which to install hama.
HAMA_INSTALL_DIR='/home/hadoop/hama-install'

COMMAND_GROUPS+=(
  "install_hama:
     extensions/hama/install_hama.sh
  "
  "start_hama:
     extensions/hama/start_hama.sh
  "
)

# Installation of hama on master and workers; then start_hama only on master.
COMMAND_STEPS+=(
  'install_hama,install_hama'
  'start_hama,*'
)
