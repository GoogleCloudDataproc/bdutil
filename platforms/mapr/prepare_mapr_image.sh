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

#
#	leveraged from mapr_imager.sh and prepare-mapr-image.sh (MapR-on-GCE)
#
# Script to be executed on top of a newly created Linux instance 
# to install MapR components for an instance image to be used later.
# The specific packages can be passed in via meta data (see maprpackages
# below)
#
# The resulting image will be used as a basis for configure-mapr-instance.sh
# See that script for the steps that need to be done BEFORE this node
# can successfully run MapR services.
#
# Expectations:
#	- Script run as root user (hence no need for permission checks)
#	- Basic distro differences (APT-GET vs YUM, etc) can be handled
#	    There are so few differences, it seemed better to manage one script.
#
# Tested with MapR 2.x, 3.x and 4.x
#
# JAVA
#	This script default to OpenJDK; the logic to support Oracle JDK 
#   is included for users who which to implicitly accept Oracle's 
#	end-user license agreement.
#

# This instance may have been just started.
# Allow ample time for the network and setup processes to settle.
sleep 10

# Metadata for this installation ... pull out details that we'll need
#
#	Note: The official release of GCE requires extra HTTP headers to
#	satisfy the metadata requests.
#
murl_top=http://metadata/computeMetadata/v1
murl_attr="${murl_top}/instance/attributes"
md_header="Metadata-Flavor: Google"

THIS_HOST=`/bin/hostname`
THIS_IMAGE=${MAPR_IMAGE}
GCE_PROJECT=${MAPR_PROJECT}

MAPR_HOME=${MAPR_HOME:-"/opt/mapr"}
MAPR_UID=${MAPR_UID:-"2000"}
MAPR_USER=${MAPR_USER:-"mapr"}
MAPR_GROUP=${MAPR_GROUP:-"mapr"}
MAPR_PASSWD=${MAPR_PASSWD:-"MapR"}

configFile=${MAPR_CLUSTER_CONFIGURATION_FILE}

###############################################################################

LOG=/tmp/prepare_mapr_image.log
OUT=/tmp/prepare_mapr_image.out

MAPR_PACKAGES=`grep ^$THIS_HOST $configFile | cut -f2 -d:`
echo "MAPR_PACKAGES: " ${MAPR_PACKAGES} >> $LOG
echo "THIS_IMAGE: " ${THIS_IMAGE} >> $LOG
echo "GCE_PROJECT: " ${GCE_PROJECT} >> $LOG
echo "MAPR_VERSION: " ${MAPR_VERSION} >> $LOG

# Extend the PATH.  This shouldn't be needed after Compute leaves beta.
PATH=/sbin:/usr/sbin:$PATH


# Helper utility to log the commands that are being run and
# save any errors to a log file
#	BEWARE : any error forces the script to exit
#		Since there are some some errors that we can live with,
#		this helper script is not used for all operations.
#
#	BE CAREFUL ... this function cannot handle command lines with
#	their own redirection.

c() {
    echo $* >> $LOG
    $* || {
	echo "============== $* failed at "`date` >> $LOG
	exit 1
    }
}


# For CentOS, add the EPEL repo
#   NOTE: this target will change FREQUENTLY !!!
#	For changes, refer to https://github.com/mapr/gce/blob/master/prepare-mapr-image.sh
function add_epel_repo() {
    EPEL_RPM=/tmp/epel.rpm
	if [ `which lsb_release 2> /dev/null` ] ; then
    	CVER=`lsb_release -r | awk '{print $2}'`
	elif [ -f /etc/centos-release ] ; then
		CVER=`grep -o '[0-9]*' /etc/centos-release | head -1`
	fi

    CVER=${CVER:-6}
    if [ ${CVER%.*} -eq 5 ] ; then
        EPEL_LOC="epel/5/x86_64/epel-release-5-4.noarch.rpm"
	elif [ "${CVER%.*}" -eq 7 ] ; then
		EPEL_LOC="epel/7/x86_64/e/epel-release-7-5.noarch.rpm"
    else
        EPEL_LOC="epel/6/x86_64/epel-release-6-8.noarch.rpm"
    fi

	epel_def=/etc/yum.repos.d/epel.repo
	if [ -f $epel_def ] ; then
		grep -q "^enabled=1" $epel_def
		if [ $? -ne 0 ] ; then
			sed -i '0,/^enabled=0/s/enabled=0/enabled=1/' $epel_def
		fi
	else
		curl -L -f -o $EPEL_RPM http://download.fedoraproject.org/pub/$EPEL_LOC
		[ $? -eq 0 ] && rpm --quiet -i $EPEL_RPM
	fi
}


# The "customized" debian distributions often have configuration
# files that should not be overwritten during the upgrade process.
# We need the Dpkg::Options arg so that we don't get an error
# during the upgrad operation that will cause us to bail out
# right away.
function update_os_deb() {
	apt-get update
	# c apt-get upgrade -y -o Dpkg::Options::="--force-confdef,confold"
	c apt-get install -y nfs-common iputils-arping libsysfs2
	c apt-get install -y ntp

	c apt-get install -y syslinux sdparm
	c apt-get install -y sysstat
	apt-get install -y dnsutils less lsof
	apt-get install -y clustershell pdsh realpath

	[ -f /etc/debian_version ] && touch /etc/init.d/.legacy-bootordering
}

# For CentOS and Fedora, the GCE environment does not support 
# plugin modules to be added to the kernel ... so we don't
# need the module-init-tools package.   Moreover, on several
# occasions, updating that module cause strange behavior during
# instance launch.
function update_os_rpm() {
	add_epel_repo

	yum makecache
	# c yum update -y --exclude=module-init-tools
	c yum install -y nfs-utils iputils libsysfs
	c yum install -y ntp ntpdate

	c yum install -y syslinux sdparm
	c yum install -y sysstat
	c yum install -y bind-utils
	yum install -y bind-utils less lsof
	yum install -y clustershell pdsh
}

# Make sure that NTP service is sync'ed and running
# Key Assumption: the /etc/ntp.conf file is reasonable for the 
#	hosting cloud platform.   We could shove our own NTP servers into
#	place, but that seems like a risk.
function update_ntp_config() {
	echo "  updating NTP configuration" >> $LOG

		# Make sure the service is enabled at boot-up
	if [ -x /etc/init.d/ntp ] ; then
		SERVICE_SCRIPT=/etc/init.d/ntp
		update-rc.d ntp enable
	elif [ -x /etc/init.d/ntpd ] ; then
		SERVICE_SCRIPT=/etc/init.d/ntpd
		chkconfig ntpd on
	else
		return 0
	fi

	$SERVICE_SCRIPT stop
	ntpdate pool.ntp.org
	$SERVICE_SCRIPT start

		# TBD: copy in /usr/share/zoneinfo file based on 
		# zone in which the instance is deployed
	zoneInfo=${MAPR_ZONE}
	curZone=`basename "${zoneInfo}"`
	curTZ=`date +"%Z"`
	echo "    Instance zone is $curZone; TZ setting is $curTZ" >> $LOG

		# Update the timezones we're sure of.
	TZ_HOME=/usr/share/zoneinfo/posix
	case $curZone in
		europe-west*)
			newTZ="CET"
			;;
		us-central*)
			newTZ="CST6CDT"
			;;
		us-east*)
			newTZ="EST5EDT"
			;;
		*)
			newTZ=${curTZ}
	esac

	if [ -n "${newTZ}"  -a  -f $TZ_HOME/$newTZ  -a  "${curTZ}" != "${newTZ}" ] 
	then
		echo "    Updating TZ to $newTZ" >> $LOG
		cp -p $TZ_HOME/$newTZ /etc/localtime
	fi
}

function update_ssh_config() {
	echo "  updating SSH configuration" >> $LOG

	SSHD_CONFIG=/etc/ssh/sshd_config

	# allow ssh via keys (some virtual environments disable this)
  sed -i 's/#AuthorizedKeysFile/AuthorizedKeysFile/' $SSHD_CONFIG

	# allow roaming (GCE disabled this in 2014 ... for unknown reasons)
  sed -i 's/^#[ ]*HostbasedAuthentication.*/HostbasedAuthentication yes/g' $SSHD_CONFIG

	# For Dev Clusters ONLY !!!
	#	allow ssh password prompt (only for our dev clusters)
	#	root login via passwordless ssh
  sed -i 's/ChallengeResponseAuthentication .*no$/ChallengeResponseAuthentication yes/' $SSHD_CONFIG
  sed -i 's/PasswordAuthentication .*no$/PasswordAuthentication yes/' $SSHD_CONFIG
  sed -i 's/PermitRootLogin .*no$/PermitRootLogin yes/' $SSHD_CONFIG

	[ -x /etc/init.d/ssh ]   &&  /etc/init.d/ssh  restart
	[ -x /etc/init.d/sshd ]  &&  /etc/init.d/sshd restart
}

function update_os() {
  echo "Installing OS security updates and useful packages" >> $LOG

  if which dpkg &> /dev/null; then
    update_os_deb
  elif which rpm &> /dev/null; then
    update_os_rpm
  fi

	# raise TCP rbuf size
  echo 4096 1048576 4194304 > /proc/sys/net/ipv4/tcp_rmem  
#  sysctl -w vm.overcommit_memory=1  # swap behavior

		# SElinux gets in the way of older MapR installs (1.2)
		# as well as MySQL (if we want a non-standard data directory)
		#	Be sure to disable it IMMEDIATELY for the rest of this 
		#	process; the change to SELINUX_CONFIG will ensure the 
		#	change across reboots.
  SELINUX_CONFIG=/etc/selinux/config
  if [ -f $SELINUX_CONFIG ] ; then
	sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' $SELINUX_CONFIG
	[ -d /selinux ] && echo 0 > /selinux/enforce
  fi

	update_ntp_config
	update_ssh_config
}

# Whatever version of Java we want, we can do here.  The
# OpenJDK is a little easier because the mechanism for accepting
# the Oracle JVM EULA changes frequently.
#
#	Be sure to add the JAVA_HOME to our environment ... we'll use it later

function install_oraclejdk_deb() {
    echo "Installing Oracle JDK (for deb distros)" >> $LOG

	apt-get install -y python-software-properties
	add-apt-repository -y ppa:webupd8team/java
	apt-get update

	echo debconf shared/accepted-oracle-license-v1-1 select true | \
		debconf-set-selections
	echo debconf shared/accepted-oracle-license-v1-1 seen true | \
		debconf-set-selections

	apt-get install -y x11-utils
	apt-get install -y oracle-jdk7-installer
	if [ $? -ne 0 ] ; then
		echo "  Oracle JDK installation failed" >> $LOG
		return 1
	fi

#	update-java-alternatives -s java-7-oracle

	JAVA_HOME=/usr/lib/jvm/java-7-oracle
	export JAVA_HOME
    echo "	JAVA_HOME=$JAVA_HOME"

	return 0
}

function install_openjdk_deb() {
    echo "Installing OpenJDK packages (for deb distros)" >> $LOG

	apt-get install -y x11-utils

		# The GCE Debian 6 image doesn't have a repo enabled for
		# Java 7 ... stick with Java 6 fo that version
	deb_version=`cat /etc/debian_version`
	if [ -n "$deb_version"  -a  "${deb_version%%.*}" = "6" ] ; then
		apt-get install -y openjdk-6-jdk openjdk-6-doc 
		JAVA_HOME=/usr/lib/jvm/java-6-openjdk
	else
		apt-get install -y openjdk-7-jdk openjdk-7-doc 
		JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64
	fi
	export JAVA_HOME
	echo "	JAVA_HOME=$JAVA_HOME" >> $LOG
}

function install_oraclejdk_rpm() {
    echo "Installing Oracle JDK (for rpm distros)" >> $LOG

	JDK_RPM="http://download.oracle.com/otn-pub/java/jdk/7u75-b13/jdk-7u75-linux-x64.rpm"

	$(cd /tmp; curl -f -L -C - -b "oraclelicense=accept-securebackup-cookie" -O $JDK_RPM)

	RPM_FILE=/tmp/`basename $JDK_RPM`
	if [ ! -s $RPM_FILE ] ; then
    	echo "	Downloading Oracle JDK failed" >> $LOG
		return 1
	fi
	
	rpm -ivh $RPM_FILE
	if [ $? -ne 0 ] ; then
    	echo "	Oracle JDK installation failed" >> $LOG
		return 1
	fi

	JAVA_HOME=/usr/java/latest
	export JAVA_HOME
    echo "	JAVA_HOME=$JAVA_HOME" | tee -a $LOG

	return 0
}

function install_openjdk_rpm() {
    echo "Installing OpenJDK packages (for rpm distros)" >> $LOG

	yum install -y java-1.7.0-openjdk java-1.7.0-openjdk-devel 
#	yum install -y java-1.7.0-openjdk-javadoc

	jcmd=`readlink -f /usr/bin/java`
	JAVA_HOME=${jcmd%/bin/java}
	[ -z "${JAVA_HOME}" ] && JAVA_HOME=/usr/lib/jvm/java-1.7.0-openjdk
	export JAVA_HOME
    echo "	JAVA_HOME=$JAVA_HOME" >> $LOG
}

# This has GOT TO SUCCEED ... otherwise the node is useless for MapR
function install_java() {
	echo Installing JAVA >> $LOG

		# If Java is already installed, simply set JAVA_HOME
		# Should check for Java version, but both 1.6 and 1.7 work.
		#
	javacmd=`which java`
	if [ $? -eq 0 ] ;  then
		echo "JRE (and possibly JDK) already installed on this instance" >> $LOG
		java -version 2>&1 | head -1 >> $LOG

			# We could be linked to the JRE or JDK version; we want
			# the REAL jdk, so look for javac in the directory we choose
		jcmd=`python -c "import os; print os.path.realpath('$javacmd')"`
		if [ -x ${jcmd%/jre/bin/java}/bin/javac ] ; then
			JAVA_HOME=${jcmd%/jre/bin/java}
		elif [ -x ${jcmd%/java}/javac ] ; then
			JAVA_HOME=${jcmd%/bin/java}
		else
			JAVA_HOME=""
		fi

		if [ -n "${JAVA_HOME:-}" ] ; then
			echo "	JAVA_HOME=$JAVA_HOME" | tee -a $LOG

			echo updating /etc/profile.d/javahome.sh >> $LOG
			echo "JAVA_HOME=${JAVA_HOME}"   > /etc/profile.d/javahome.sh
			echo "export JAVA_HOME"        >> /etc/profile.d/javahome.sh

			return 0
		fi

		echo "Could not identify JAVA_HOME; will install JDK ourselves" >> $LOG
	fi

	if which dpkg &> /dev/null; then
		install_oraclejdk_deb
		[ $? -ne 0 ] && install_openjdk_deb
	elif which rpm &> /dev/null; then
		install_oraclejdk_rpm
		[ $? -ne 0 ] && install_openjdk_rpm
	fi

	if [ -x $JAVA_HOME/bin/java ] ; then
		echo Java installation complete >> $LOG

			# Strip of jre just in case
		JAVA_HOME="${JAVA_HOME%/jre}"

		echo updating /etc/profile.d/javahome.sh >> $LOG
		echo "JAVA_HOME=${JAVA_HOME}"   > /etc/profile.d/javahome.sh
		echo "export JAVA_HOME"        >> /etc/profile.d/javahome.sh
	else
		echo Java installation failed >> $LOG
	fi
}

function add_mapr_user() {
	echo Adding/configuring mapr user >> $LOG
	id $MAPR_USER &> /dev/null
	if [ $? -eq 0 ] ; then
			# If we passed a UID in as meta-data, 
			# now is the time to make sure it lines up
			# with the pre-existing account.
			#	NOTE: we ONLY do this if a UID was passed in
		target_uid=$(curl -f $murl_attr/mapruid)
		if [ -n "${target_uid}" -a  `id $MAPR_USER` -ne ${target_uid} ] ; then
			echo "updating ${MAPR_USER} account to uid ${MAPR_UID}" >> $LOG
			usermod -u ${target_uid} ${MAPR_USER}
			groupmod -g ${target_uid} ${MAPR_USER}
		fi

		return 0 
	fi

	echo "useradd -u $MAPR_UID -c MapR -m -s /bin/bash" >> $LOG
	useradd -u $MAPR_UID -c "MapR" -m -s /bin/bash $MAPR_USER 2> /dev/null
	if [ $? -ne 0 ] ; then
			# Assume failure was dup uid; try with default uid assignment
		echo "useradd returned $?; trying auto-generated uid" >> $LOG
		useradd -c "MapR" -m -s /bin/bash $MAPR_USER
	fi

	if [ $? -ne 0 ] ; then
		echo "Failed to create new user $MAPR_USER {error code $?}"
		return 1
	else
		passwd $MAPR_USER << passwdEOF > /dev/null
$MAPR_PASSWD
$MAPR_PASSWD
passwdEOF

	fi

		# Create sshkey for $MAPR_USER (must be done AS MAPR_USER)
	su $MAPR_USER -c "mkdir ~${MAPR_USER}/.ssh ; chmod 700 ~${MAPR_USER}/.ssh"
	su $MAPR_USER -c "ssh-keygen -q -t rsa -f ~${MAPR_USER}/.ssh/id_rsa -P '' "
	su $MAPR_USER -c "cp -p ~${MAPR_USER}/.ssh/id_rsa ~${MAPR_USER}/.ssh/id_launch"
	su $MAPR_USER -c "cp -p ~${MAPR_USER}/.ssh/id_rsa.pub ~${MAPR_USER}/.ssh/authorized_keys"
	su $MAPR_USER -c "chmod 600 ~${MAPR_USER}/.ssh/authorized_keys"
		
		# TBD : copy the key-pair used to launch the instance directly
		# into the mapr account to simplify connection from the
		# launch client.
	MAPR_USER_DIR=`eval "echo ~${MAPR_USER}"`
#	LAUNCHER_SSH_KEY_FILE=$MAPR_USER_DIR/.ssh/id_launcher.pub
#	curl ${murl_top}/public-keys/0/openssh-key > $LAUNCHER_SSH_KEY_FILE
#	if [ $? -eq 0 ] ; then
#		cat $LAUNCHER_SSH_KEY_FILE >> $MAPR_USER_DIR/.ssh/authorized_keys
#	fi

		# Enhance the login with rational stuff
    cat >> $MAPR_USER_DIR/.bashrc << EOF_bashrc

CDPATH=.:$HOME
export CDPATH

# PATH updates based on settings in MapR env file
MAPR_HOME=${MAPR_HOME:-/opt/mapr}
MAPR_ENV=\${MAPR_HOME}/conf/env.sh
[ -f \${MAPR_ENV} ] && . \${MAPR_ENV} 
[ -n "\${JAVA_HOME}:-" ] && PATH=\$PATH:\$JAVA_HOME/bin
[ -n "\${MAPR_HOME}:-" ] && PATH=\$PATH:\$MAPR_HOME/bin

set -o vi

EOF_bashrc

		# Add MapR user to sudo group if it exists
	grep -q -e "^sudo:" /etc/group
	[ $? -eq 0 ] && usermod -G sudo $MAPR_USER

	return 0
}

function setup_mapr_repo_deb() {
    MAPR_REPO_FILE=/etc/apt/sources.list.d/mapr.list
    MAPR_PKG="http://package.mapr.com/releases/v${MAPR_VERSION}/ubuntu"
    MAPR_ECO="http://package.mapr.com/releases/ecosystem/ubuntu"

	major_ver=${MAPR_VERSION%%.*}
	if [ ${major_ver:-3} -gt 3 ] ; then
		MAPR_ECO=${MAPR_ECO//ecosystem/ecosystem-${major_ver}.x}
	fi

    echo Setting up repos in $MAPR_REPO_FILE

    if [ ! -f $MAPR_REPO_FILE ] ; then
    	cat > $MAPR_REPO_FILE << EOF_ubuntu
deb $MAPR_PKG mapr optional
deb $MAPR_ECO binary/
EOF_ubuntu
	else
		sed -i "s|/releases/v.*/|/releases/v${MAPR_VERSION}/|" $MAPR_REPO_FILE
	fi
	
    apt-get update
}

function setup_mapr_repo_rpm() {
    MAPR_REPO_FILE=/etc/yum.repos.d/mapr.repo
    MAPR_PKG="http://package.mapr.com/releases/v${MAPR_VERSION}/redhat"
    MAPR_ECO="http://package.mapr.com/releases/ecosystem/redhat"

	major_ver=${MAPR_VERSION%%.*}
	if [ ${major_ver:-3} -gt 3 ] ; then
		MAPR_ECO=${MAPR_ECO//ecosystem/ecosystem-${major_ver}.x}
	fi

    echo Setting up repos in $MAPR_REPO_FILE

	if [ -f $MAPR_REPO_FILE ] ; then
		sed -i "s|/releases/v.*/|/releases/v${MAPR_VERSION}/|" $MAPR_REPO_FILE
		yum makecache
		return
	fi

    cat > $MAPR_REPO_FILE << EOF_redhat
[MapR]
name=MapR Version $MAPR_VERSION media
baseurl=$MAPR_PKG
${MAPR_PKG//package.mapr.com/archive.mapr.com}
enabled=1
gpgcheck=0
protected=1

[MapR_ecosystem]
name=MapR Ecosystem Components
baseurl=$MAPR_ECO
${MAPR_ECO//package.mapr.com/archive.mapr.com}
enabled=1
gpgcheck=0
protected=1
EOF_redhat

    yum makecache
}


function setup_mapr_repo() {
	if which dpkg &> /dev/null; then
		setup_mapr_repo_deb
		MAPRGPG_KEY=/tmp/maprgpg.key
		wget -O $MAPRGPG_KEY http://package.mapr.com/releases/pub/maprgpg.key 
		[ $? -eq 0 ] && apt-key add $MAPRGPG_KEY
	elif which rpm &> /dev/null; then
		setup_mapr_repo_rpm
		rpm --import http://package.mapr.com/releases/pub/maprgpg.key
	fi
}


# Helper utility to update ENV settings in env.sh.
# Function is replicated in the configure-mapr-instance.sh script.
# Function WILL NOT override existing settings ... it looks
# for the default "#export <var>=" syntax and substitutes the new value
#
#	NOTE: this updates ONLY the env variables that are commented out
#	within env.sh.  It WILL NOT overwrite active settings.  This is
#	OK for our current deployment model, but may not be sufficient in
#	all cases.

MAPR_ENV_FILE=$MAPR_HOME/conf/env.sh
update-env-sh()
{
	[ -z "${1:-}" ] && return 1
	[ -z "${2:-}" ] && return 1

	AWK_FILE=/tmp/ues$$.awk
	cat > $AWK_FILE << EOF_ues
/^#export ${1}=/ {
	getline
	print "export ${1}=$2"
}
{ print }
EOF_ues

	cp -p $MAPR_ENV_FILE ${MAPR_ENV_FILE}.imager_save
	awk -f $AWK_FILE ${MAPR_ENV_FILE} > ${MAPR_ENV_FILE}.new
	[ $? -eq 0 ] && mv -f ${MAPR_ENV_FILE}.new ${MAPR_ENV_FILE}
}


install_mapr_packages() {
	mpkgs=""
	for pkg in `echo ${MAPR_PACKAGES//,/ }`
	do
		mpkgs="$mpkgs mapr-$pkg"
	done

	echo Installing MapR base components {$MAPR_PACKAGES} >> $LOG
	if which dpkg &> /dev/null; then
		c apt-get install -y --force-yes $mpkgs
	elif which rpm &> /dev/null; then
		c yum install -y $mpkgs
	fi

	echo Configuring $MAPR_ENV_FILE  >> $LOG
	update-env-sh MAPR_HOME $MAPR_HOME
	update-env-sh JAVA_HOME $JAVA_HOME
}


#
# Disable starting of MAPR, and clean out the ID's that will be intialized
# with the full install. 
#	NOTE: the instantiation process from an image generated via
#	this script MUST recreate the hostid and hostname files
#
function disable_mapr_services() 
{
	echo Temporarily disabling MapR services >> $LOG
	mv -f $MAPR_HOME/hostid    $MAPR_HOME/conf/hostid.image
	mv -f $MAPR_HOME/hostname  $MAPR_HOME/conf/hostname.image

	if which dpkg &> /dev/null; then
		update-rc.d -f mapr-warden disable
		echo $MAPR_PACKAGES | grep -q zookeeper
		if [ $? -eq 0 ] ; then
			update-rc.d -f mapr-zookeeper disable
		fi
	elif which rpm &> /dev/null; then
		chkconfig mapr-warden off
		echo $MAPR_PACKAGES | grep -q zookeeper
		if [ $? -eq 0 ] ; then
			chkconfig mapr-zookeeper off
		fi
	fi
}


# High level wrapper around the above scripts. 
# Ideally, we should handle errors correctly here.
main() {
	echo "Image creation started at "`date` >> $LOG
	
	update_os
	install_java

	add_mapr_user
	setup_mapr_repo
	install_mapr_packages
	disable_mapr_services

	echo "Image creation completed at "`date` >> $LOG
	echo IMAGE READY >> $LOG
	return 0
}

main
exitCode=$?

# Save of the install log to ~${MAPR_USER}; some cloud images
# use AMI's that automatically clear /tmp with every reboot
MAPR_USER_DIR=`eval "echo ~${MAPR_USER}"`
if [ -n "${MAPR_USER_DIR}"  -a  -d ${MAPR_USER_DIR} ] ; then
		cp $LOG $MAPR_USER_DIR
		chmod a-w ${MAPR_USER_DIR}/`basename $LOG`
		chown ${MAPR_USER}:`id -gn ${MAPR_USER}` \
			${MAPR_USER_DIR}/`basename $LOG`
fi

exit $exitCode

