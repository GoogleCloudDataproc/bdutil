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

# Downloads the relevant gcs-connector-<version>.jar, before Hadoop has actually
# been installed; this way, the initial startup of Hadoop daemons can already
# load the gcs-connector as needed so that we don't need to restart.

if (( ${INSTALL_GCS_CONNECTOR} )) ; then
  LIB_JARS_DIR="${HADOOP_INSTALL_DIR}/lib"
  mkdir -p ${LIB_JARS_DIR}

  # Grab the connector jarfile, add it to installation /lib directory.
  JARNAME=$(grep -o '[^/]*\.jar' <<< ${GCS_CONNECTOR_JAR})
  LOCAL_JAR="${LIB_JARS_DIR}/${JARNAME}"

  download_bd_resource "${GCS_CONNECTOR_JAR}" "${LOCAL_JAR}"
fi
