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

# Plugin which allows manually resizing bdutil-deployed clusters. To resize
# upwards, set NEW_NUM_WORKERS to the new, larger value, keeping the old
# NUM_WORKERS (or -n flag) at the existing cluster size. Then:
#
# Deploy only the new workers, e.g. {hadoop-w-2, hadoop-w-3, hadoop-w-4}:
# ./bdutil -e my_base_env.sh -e resize_env.sh deploy
#
# Explicitly start the Hadoop daemons on just the new workers:
# ./bdutil -e my_base_env.sh -e resize_env.sh run_command -t workers -- "service hadoop-hdfs-datanode start && service hadoop-mapreduce-tasktracker start"
#
# If using Spark as well, explicitly start the Spark daemons on the new workers:
# ./bdutil -e my_base_env.sh -e resize_env.sh run_command -t workers -u extensions/spark/start_single_spark_worker.sh -- "./start_single_spark_worker.sh"
#
# Edit your base config to reflect your new cluster size:
# echo NUM_WORKERS=5 >> my_base_env.sh
#
# When resizing down, simply set the base NUM_WORKERS to the desired smaller
# size, and set NEW_NUM_WORKERS equal to the current cluster size; this can
# be thought of as "undo-ing" a "resize upwards" command:
# ./bdutil -e my_base_env.sh -n 2 -e resize_env.sh delete
# echo NUM_WORKERS=2 >> my_base_env.sh
NEW_NUM_WORKERS=5

# During resizes, make sure to avoid touching the master node.
SKIP_MASTER=true

# Save away the base evaluate_late_variable_bindings function so we can
# override it and replace the WORKERS array.
copy_func evaluate_late_variable_bindings old_evaluate_late_variable_bindings

function evaluate_late_variable_bindings() {
  old_evaluate_late_variable_bindings

  WORKERS=()
  WORKER_ATTACHED_PDS=()

  local worker_suffix='w'
  local master_suffix='m'
  if (( ${OLD_HOSTNAME_SUFFIXES} )); then
    echo 'WARNING: Using deprecated -nn and -dn naming convention'
    worker_suffix='dn'
    master_suffix='nn'
  fi
  for ((i = ${NUM_WORKERS}; i < ${NEW_NUM_WORKERS}; i++)); do
    local shift_i=$((${i} - ${NUM_WORKERS}))
    WORKERS[${shift_i}]="${PREFIX}-${worker_suffix}-${i}"
  done
  for ((i = ${NUM_WORKERS}; i < ${NEW_NUM_WORKERS}; i++)); do
    local shift_i=$((${i} - ${NUM_WORKERS}))
    WORKER_ATTACHED_PDS[${shift_i}]="${WORKERS[${shift_i}]}-pd"
  done

  local num_workers_to_add=$((${NEW_NUM_WORKERS} - ${NUM_WORKERS}))
  NUM_WORKERS=${num_workers_to_add}
}
