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

# finalize the cluster configuration

source hadoop_helpers.sh

# initialize hdfs dirs
loginfo "Set up HDFS /tmp and /user dirs"
initialize_hdfs_dirs admin


AMBARI_CLUSTER=$(get_ambari_cluster_name)

# update hadoop configuration to include the gcs connector
if (( ${INSTALL_GCS_CONNECTOR} )) ; then
  loginfo "Setting up GCS connector cache cleaner and configuration."
  if (( ${ENABLE_NFS_GCS_FILE_CACHE} )); then
    export GCS_METADATA_CACHE_TYPE='FILESYSTEM_BACKED'
    export GCS_FILE_CACHE_DIRECTORY="$(get_nfs_mount_point)"

    setup_cache_cleaner
  else
    export GCS_METADATA_CACHE_TYPE='IN_MEMORY'
    # For IN_MEMORY cache, this directory won't actually be used, but we set
    # it to a sane default for easy manual experimentation of file caching.
    export GCS_FILE_CACHE_DIRECTORY='/tmp/gcs_connector_metadata_cache'
  fi

  # If it wasn't set at cluster creation configure the GCS connector.
  if ! /var/lib/ambari-server/resources/scripts/configs.sh \
      get localhost ${AMBARI_CLUSTER} core-site \
      | grep -q '^"fs.gs'; then
    subsitute_bash_in_json configuration.json
    sed -n < configuration.json \
        's/.*"\(fs\.\S*gs\.\S*\)"\s*:\s*"\([^"]*\)".*/\1 \2/p' \
        | xargs -n 2 /var/lib/ambari-server/resources/scripts/configs.sh \
        set localhost ${AMBARI_CLUSTER} core-site
    # Will reload core-site.xml
    SERVICES_TO_UPDATE+=" HDFS"
  fi

  loginfo "Adding /usr/local/lib/hadoop/lib to " \
      "mapreduce.application.classpath."
  NEW_CLASSPATH=$(/var/lib/ambari-server/resources/scripts/configs.sh \
      get localhost ${AMBARI_CLUSTER} mapred-site \
      | grep -E '^"mapreduce.application.classpath"' \
      | tr -d \" \
      | awk '{print "/usr/local/lib/hadoop/lib/*,"$3}' | sed 's/,$//')
  /var/lib/ambari-server/resources/scripts/configs.sh \
      set localhost ${AMBARI_CLUSTER} \
      mapred-site mapreduce.application.classpath ${NEW_CLASSPATH}
  sleep 10
fi

loginfo "Restarting services, because Ambari usually requires it."
SERVICE='ALL'
ambari_service_stop
ambari_wait_requests_completed
ambari_service_start
ambari_wait_requests_completed

# Check GCS connectivity
check_filesystem_accessibility

# Set up files and pig views, which was added in Ambari 2.1.
#
if version_at_least "${AMBARI_VERSION}" '2.1'; then
  # This should be done automatically but it wasn't as of 2016-03-16.
  for view in FILES PIG; do
    # Both of these views are currently 1.0.0
    VIEW="${AMBARI_API}/views/${view}/versions/1.0.0/instances/AUTO_${view}_INSTANCE"
    if ${AMBARI_CURL} ${VIEW} |& grep -q '404 Not Found'; then
      ${AMBARI_CURL} -X POST ${VIEW} \
        -d "{\"ViewInstanceInfo\": {\"cluster_handle\": \"${AMBARI_CLUSTER}\"}}"
    fi
  done
fi
