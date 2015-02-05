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

# Misc configurations for components not installed elsewhere.
# Not necessarily CDH specific.

# Use FQDNs
grep ${HOSTNAME} -lR ${HADOOP_CONF_DIR} \
  | xargs -r sed -i "s/${HOSTNAME}/$(hostname --fqdn)/g"

# Configure Hive Metastore
if dpkg -s hive-metastore > /dev/null; then
  # Configure Hive metastorea
  bdconfig set_property \
      --configuration_file /etc/hive/conf/hive-site.xml \
      --name 'hive.metastore.uris' \
      --value "thrift://$(hostname --fqdn):9083" \
      --clobber
fi

# Configure Hue
if dpkg -s hue > /dev/null; then
  # Replace localhost with hostname.
  sed -i "s/#*\([^#]*=.*\)localhost/\1$(hostname --fqdn)/" /etc/hue/conf/hue.ini
fi

# Configure Oozie
if dpkg -s oozie > /dev/null; then
  sudo -u oozie /usr/lib/oozie/bin/ooziedb.sh create -run

  # Try to enable gs:// paths
  bdconfig set_property \
      --configuration_file /etc/oozie/conf/oozie-site.xml \
      --name 'oozie.service.HadoopAccessorService.supported.filesystems' \
      --value 'hdfs,gs,webhdfs,hftp' \
      --clobber
fi

# Enable WebHDFS
bdconfig set_property \
    --configuration_file ${HADOOP_CONF_DIR}/hdfs-site.xml \
    --name 'dfs.webhdfs.enabled' \
    --value true \
    --clobber

# Enable Hue / Oozie impersonation
bdconfig merge_configurations \
    --configuration_file ${HADOOP_CONF_DIR}/core-site.xml \
    --source_configuration_file cdh-core-template.xml \
    --resolve_environment_variables \
    --clobber
