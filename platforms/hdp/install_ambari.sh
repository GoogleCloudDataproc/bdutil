#######################################################################

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
#######################################################################

## Name:    install_ambari.sh
## Purpose:
##   - Handle prerequisites for installation of Apache Ambari
##   - Install ambari-agent and ambari-server
##   - Configure ambari-server
# Usage:   Called from 'bdutil'. Do not run directly
#######################################################################

## disable selinux
setenforce 0
sed -i 's/\(^[^#]*\)SELINUX=enforcing/\1SELINUX=disabled/' /etc/selinux/config
sed -i 's/\(^[^#]*\)SELINUX=permissive/\1SELINUX=disabled/' /etc/selinux/config

## workaround as some components of Ambari & the HDP stack are hard
##   coded to /var/lib/hdfs
if [ ! -d /hadoop/hdfs ]; then mkdir /hadoop/hdfs; fi
ln -sf /hadoop/hdfs /var/lib/

## sudo should not require a tty. This is fixed in rhel/centos 7+
echo 'Defaults !requiretty' > /etc/sudoers.d/888-dont-requiretty

## disable transparent_hugepages
cp -a ./thp-disable.sh /usr/local/sbin/
sh /usr/local/sbin/thp-disable.sh || /bin/true
echo -e '\nsh /usr/local/sbin/thp-disable.sh || /bin/true' >> /etc/rc.local

## disable iptables
chkconfig iptables off
service iptables stop

## swappiness to 0
sysctl -w vm.swappiness=0
cat > /etc/sysctl.d/50-swappiness.conf <<-'EOF'
## no more swapping
vm.swappiness=0
EOF

## install & start ntpd
yum install ntp -y
service ntpd start

# install Apache Ambari YUM repository
curl -Ls -o /etc/yum.repos.d/ambari.repo ${AMBARI_REPO}

# install Apache Ambari-agent
yum install ambari-agent -y
sed -i.orig "s/^.*hostname=localhost/hostname=${MASTER_HOSTNAME}/" \
    /etc/ambari-agent/conf/ambari-agent.ini

# script which detects the public IP of nodes in the cluster
#   disabled by default. To enable: set 'AMBARI_PUBLIC' to true in ambari_config.sh
cp -a ./public-hostname-gcloud.sh /etc/ambari-agent/conf/
if [ "${AMBARI_PUBLIC}" -eq 1 ]; then
    sed -i "/\[agent\]/ a public_hostname_script=\/etc\/ambari-agent\/conf\/public-hostname-gcloud.sh" /etc/ambari-agent/conf/ambari-agent.ini
else
    sed -i "/\[agent\]/ a #public_hostname_script=\/etc\/ambari-agent\/conf\/public-hostname-gcloud.sh" /etc/ambari-agent/conf/ambari-agent.ini
fi

# start Apache ambari-agent
service ambari-agent restart
chkconfig ambari-agent on

# install, configure and start Apache ambari-server on the master node
if [ "$(hostname)" = "${MASTER_HOSTNAME}" ]; then
  yum install -y ambari-server
  service ambari-server stop
  ambari-server setup -j ${JAVA_HOME} -s
  if ! nohup bash -c "service ambari-server start 2>&1 > /dev/null"; then
    echo 'Ambari Server failed to start' >&2
    exit 1
  fi
  chkconfig ambari-server on
fi

# Workaround for issue between 2.2.0.0 and 2.2.4.2-X where hdp-select finds
# 2.2.4.2-X but params.hdp_stack_version is 2.2.0.0, causing setup to silently
# fail to copy all the component tarballs like mapreduce.tar.gz and pig.tar.gz
# into hdfs:///hdp/apps/...
AMBARI_FUNCTIONS_DIR='lib/resource_management/libraries/functions'
SCRIPT_BAD_CONDITION=' or not out.startswith(params.hdp_stack_version)'
AMBARI_LIB_BASE='/usr/lib/ambari-server'
AMBARI_COPY_TARBALLS_SCRIPT="${AMBARI_LIB_BASE}/${AMBARI_FUNCTIONS_DIR}/dynamic_variable_interpretation.py"
if [[ -e ${AMBARI_COPY_TARBALLS_SCRIPT} ]]; then
  sed -i "s/${SCRIPT_BAD_CONDITION}//" ${AMBARI_COPY_TARBALLS_SCRIPT}
fi
AMBARI_LIB_BASE='/usr/lib/ambari-agent'
AMBARI_COPY_TARBALLS_SCRIPT="${AMBARI_LIB_BASE}/${AMBARI_FUNCTIONS_DIR}/dynamic_variable_interpretation.py"
if [[ -e ${AMBARI_COPY_TARBALLS_SCRIPT} ]]; then
  sed -i "s/${SCRIPT_BAD_CONDITION}//" ${AMBARI_COPY_TARBALLS_SCRIPT}
fi
