# TODO add licence


# This file contains environment-variable overrides to be used in conjunction
# with bdutil_env.sh in order to deploy a Hadoop + Flink cluster.
# Usage: ./bdutil deploy -e extensions/flink/flink_env.sh

# In standalone mode, Flink runs the job manager and the task managers (workers)
# on the cluster without using YARN containers. Flink also supports YARN
# deployment which will be implemented in future version of the Flink bdutil plugin.
FLINK_MODE="standalone"

# URIs of tarballs for installation.
FLINK_HADOOP1_TARBALL_URI='gs://flink-dist/flink-0.8.0-bin-hadoop1.tgz'
FLINK_HADOOP2_TARBALL_URI='gs://flink-dist/flink-0.8.0-bin-hadoop2.tgz'
FLINK_HADOOP2_YARN_TARBALL_URI='gs://flink-dist/flink-0.8.0-bin-hadoop2-yarn.tgz'

# Directory on each VM in which to install each package.
FLINK_INSTALL_DIR='/home/hadoop/flink-install'

# Optional JVM arguments to pass
# Flink config entry: env.java.opts:
FLINK_JAVA_OPTS="-DsomeOption=value"

# Heap memory used by the job manager (master) determined by the physical (free) memory of the server
# Flink config entry: jobmanager.heap.mb: {{jobmanager_heap}}
FLINK_JOBMANAGER_MEMORY_FRACTION='0.8'

# Heap memory used by the task managers (slaves) determined by the physical (free) memory of the servers
# Flink config entry: taskmanager.heap.mb: {{taskmanager_heap}}
FLINK_TASKMANAGER_MEMORY_FRACTION='0.8'

# Number of task slots per task manager (worker)
# ideally set to the number of physical cpus
# if set to 'auto', the number of slots will be determined automatically
# Flink config entry: taskmanager.numberOfTaskSlots: {{num_task_slots}}
FLINK_TASKMANAGER_SLOTS='auto'

# Default parallelization degree (number of concurrent actions per task)
# If set to 'auto', this will be determined automatically
# Flink config entry: parallelization.degree.default: {{parallelization}}
FLINK_PARALLELIZATION_DEGREE='auto'

# The number of buffers for the network stack.
# Flink config entry: taskmanager.network.numberOfBuffers: {{taskmanager_num_buffers}}
FLINK_NETWORK_NUM_BUFFERS=2048


COMMAND_GROUPS+=(
  "install_flink:
     extensions/flink/install_flink.sh
  "
  "start_flink:
     extensions/flink/start_flink.sh
  "
)

# Installation of flink on master and workers; then start_flink only on master.
COMMAND_STEPS+=(
  'install_flink,install_flink'
  'start_flink,*'
)
