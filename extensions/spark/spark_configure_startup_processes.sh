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

# Populates /etc/init.d scripts to keep processes up on startup

set -e

 # Determine Spark master using appropriate mode
if [[ ${SPARK_MODE} == 'standalone' ]]; then
  SPARK_MASTER="spark://${MASTER_HOSTNAME}:7077"
elif [[ ${SPARK_MODE} =~ ^(default)$ ]]; then
  SPARK_MASTER="${SPARK_MODE}"
fi
if [[ ${SPARK_MODE} =~ ^(default|standalone)$ ]]; then
  # Associative array for looking about Hadoop 2 daemon scripts
  declare -r -A SPARK_DAEMON_FULL_NAMES=(
      [master]="org.apache.spark.deploy.master.Master"
      [worker]="org.apache.spark.deploy.worker.Worker"
  )

  SPARK_DAEMONS=()

  if [[ "$(hostname -s)" == "${MASTER_HOSTNAME}" ]]; then
    SPARK_DAEMONS+=('master')
  else
    SPARK_DAEMONS+=('worker')
  fi

  for DAEMON in "${SPARK_DAEMONS[@]}"; do
    if [[ "${DAEMON}" == "master" ]]; then
      START_SCRIPT="${SPARK_INSTALL_DIR}/sbin/start-master.sh"
    else
      DAEMON_SCRIPT="${SPARK_INSTALL_DIR}/sbin/start-slave.sh"
      START_SCRIPT="${DAEMON_SCRIPT} 0 ${SPARK_MASTER}"
    fi
    INIT_SCRIPT=/etc/init.d/spark-${DAEMON}
    cat << EOF > ${INIT_SCRIPT}
#!/usr/bin/env bash
# Boot script for Spark ${DAEMON}
### BEGIN INIT INFO
# Provides:          spark-${DAEMON}
# Required-Start:    \$all \$network
# Required-Stop:     \$all \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Spark-${DAEMON}
# Description:       Spark-${DAEMON} (http://hadoop.apache.org/)
### END INIT INFO

function print_usage() {
  echo "Usage: \$0 start|stop|restart" >&2
}

# Check for root
if (( \${EUID} != 0 )); then
  echo "This must be run as root." >& 2
  exit 1
fi

if (( \$# != 1 )); then
  print_usage
  exit 1
fi

case "\$1" in
  start|stop)
    ${START_SCRIPT}
    RETVAL=\$?
    ;;
  restart)
    \$0 stop
    \$0 start
    RETVAL=\$?
    ;;
  *)
    print_usage
    exit 1
    ;;
esac

exit \${RETVAL}
EOF
    chmod 755 ${INIT_SCRIPT}
    if which insserv; then
      insserv ${INIT_SCRIPT}
    elif which chkconfig; then
      chkconfig --add spark-${DAEMON}
    elif [[ -x /usr/lib/insserv/insserv ]]; then
      ln -s /usr/lib/insserv/insserv /sbin/insserv
      insserv ${INIT_SCRIPT}
    else
      echo "No boot process configuration tool found." >&2
      exit 1
    fi
  done
fi
