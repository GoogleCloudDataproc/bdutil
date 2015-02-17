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

# Environment to configure and install MapR Hadoop distribution with bdutil

################################ CONFIGURATION ################################

################################
# These properties are required
CONFIGBUCKET=""
PROJECT=""
################################

# For other values,
# https://cloud.google.com/sdk/gcloud/reference/compute/instances/create
GCE_IMAGE='ubuntu-12-04'
GCE_MACHINE_TYPE='n1-standard-1'
GCE_ZONE='us-central1-f'
# GCE_NETWORK='default'

# Persistent disk storage configuration
USE_ATTACHED_PDS=true

WORKER_ATTACHED_PDS_SIZE_GB=1500
WORKER_ATTACHED_PDS_TYPE='pd-standard'

MASTER_ATTACHED_PD_SIZE_GB=1500
MASTER_ATTACHED_PD_TYPE='pd-standard'

####################### MapR Specific Properties ##############################

MAPR_CLUSTER_NAME="MapRCluster"

# e.g. 3.0.3, 3.1.0, 4.0.1
MAPR_VERSION="4.0.2" 

# OPTIONAL (paste the license in this file)
MAPR_LICENSE="mapr_license.txt"

MAPR_CLUSTER_CONFIGURATION_FILE="node.lst"
# NOTE: 
# (1) Nodes names MUST have this PREFIX in configuration file (node.lst)
# (2) Node names MUST have suffixes: -m, -w-0, -w-1, ...
#     For example, if the PREFIX is 'mapr', 
#     node names MUST be 'mapr-m', 'mapr-w-0', 'mapr-w-1', ... 
PREFIX="mapr"
# NOTE:  This number MUST equal the number of nodes in the configuration file - 1 
#        (i.e. do not count master)
NUM_WORKERS=3

# User details
MAPR_HOME="/opt/mapr"
MAPR_UID="2000"
MAPR_USER="mapr"
MAPR_GROUP="mapr"
MAPR_PASSWD="MapR"

###############################################################################

MAPR_IMAGER_SCRIPT="prepare_mapr_image.sh"
UPLOAD_FILES+=("platforms/mapr/${MAPR_CLUSTER_CONFIGURATION_FILE}")
UPLOAD_FILES+=("platforms/mapr/${MAPR_IMAGER_SCRIPT}")
UPLOAD_FILES+=("platforms/mapr/${MAPR_LICENSE}")

# Adapted from bdutil_env.sh
function evaluate_late_variable_bindings() {
  normalize_boolean 'STRIP_EXTERNAL_MIRRORS'
  normalize_boolean 'ENABLE_HDFS'
  normalize_boolean 'INSTALL_GCS_CONNECTOR'
  normalize_boolean 'INSTALL_BIGQUERY_CONNECTOR'
  normalize_boolean 'INSTALL_DATASTORE_CONNECTOR'
  normalize_boolean 'USE_ATTACHED_PDS'
  normalize_boolean 'CREATE_ATTACHED_PDS_ON_DEPLOY'
  normalize_boolean 'DELETE_ATTACHED_PDS_ON_DELETE'
  normalize_boolean 'VERBOSE_MODE'
  normalize_boolean 'DEBUG_MODE'
  normalize_boolean 'ENABLE_NFS_GCS_FILE_CACHE'
  normalize_boolean 'INSTALL_JDK_DEVEL'

  # Generate WORKERS array based on PREFIX and NUM_WORKERS.
  local worker_suffix='w'
  local master_suffix='m'
  for ((i = 0; i < NUM_WORKERS; i++)); do
    WORKERS[${i}]="${PREFIX}-${worker_suffix}-${i}"
  done

  # The instance name of the VM which serves as both the namenode and
  # jobtracker.
  MASTER_HOSTNAME="${PREFIX}-${master_suffix}"

  # Generate worker PD names based on the worker instance names.
  for ((i = 0; i < NUM_WORKERS; i++)); do
    WORKER_ATTACHED_PDS[${i}]="${WORKERS[${i}]}-pd"
  done

  # List of expanded master-node PD name. Only applicable if USE_ATTACHED_PDS
  # is true.
  MASTER_ATTACHED_PD="${MASTER_HOSTNAME}-pd"

  # GCS directory for deployment-related temporary files.
  local staging_dir_base="gs://${CONFIGBUCKET}/bdutil-staging"
  BDUTIL_GCS_STAGING_DIR="${staging_dir_base}/${MASTER_HOSTNAME}"

  MAPR_PROJECT=${PROJECT}
  MAPR_IMAGE=${GCE_IMAGE}
  MAPR_MACHINE_TYPE=${GCE_MACHINE_TYPE}
  MAPR_ZONE=${GCE_ZONE}
  NODE_NAME_ROOT=${PREFIX}
}

COMMAND_GROUPS+=(
  "deploy-mapr:
    platforms/mapr/configure_mapr_instance.sh"
)

COMMAND_STEPS=(
  'deploy-mapr,deploy-mapr'
)
