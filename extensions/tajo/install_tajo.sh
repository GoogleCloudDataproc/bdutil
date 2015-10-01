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

set -o nounset
set -o errexit

# Get the filename out of the full URI.
TAJO_TARBALL=${TAJO_TARBALL_URI##*/}

# Get the tarball, untar it.
gsutil cp ${TAJO_TARBALL_URI} /home/hadoop/${TAJO_TARBALL}
tar -C /home/hadoop -xzvf /home/hadoop/${TAJO_TARBALL}
mv /home/hadoop/tajo*/ ${TAJO_INSTALL_DIR}

# Add the TAJO 'bin' path to the .bashrc so that it's easy to call 'TAJO'
# during interactive ssh session.
add_to_path_at_login "${TAJO_INSTALL_DIR}/bin"

if [ ! -d /hadoop_gcs_connector_metadata_cache ]
then
  mkdir /hadoop_gcs_connector_metadata_cache
  chown hadoop.hadoop /hadoop_gcs_connector_metadata_cache/
fi

sudo chown -R hadoop.hadoop ${TAJO_INSTALL_DIR}
