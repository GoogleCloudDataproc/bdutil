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

# Installs Supervisor using apt-get.

# Strip the debian mirrors to force only using the GCS mirrors. Not ideal for
# production usage due to stripping security.debian.org, but reduces external
# load for non-critical use cases.

install_application 'supervisor'

# No easy way to install supervisor on CentOS and have it configured
if ! [[ -x $(which apt-get) ]] && [[ -x $(which yum) ]]; then
  # Install supervisor
  yum install -y python-setuptools
  easy_install supervisor
  mkdir -p /etc/supervisor/conf.d/
  mkdir -p /var/log/supervisor

  # Set up the supervisor configuration
  cat > supervisord.conf <<EOF
; supervisor config file

[unix_http_server]
file=/var/run//supervisor.sock   ; (the path to the socket file)
chmod=0766

[supervisord]
logfile=/var/log/supervisor/supervisord.log ; (main log file;default $CWD/supervisord.log)
pidfile=/var/run/supervisord.pid ; (supervisord pidfile;default supervisord.pid)
childlogdir=/var/log/supervisor            ; ('AUTO' child log dir, default $TEMP)

; the below section must remain in the config file for RPC
; (supervisorctl/web interface) to work, additional interfaces may be
; added by defining them in separate rpcinterface: sections
[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run//supervisor.sock ; use a unix:// URL  for a unix socket

; The [include] section can just contain the "files" setting.  This
; setting can list multiple files (separated by whitespace or
; newlines).  It can also contain wildcards.  The filenames are
; interpreted as relative to this file.  Included files *cannot*
; include files themselves.

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

  # Move the configuration file into the right folder
  mv supervisord.conf /etc/

  # Start Supervisor
  supervisord
  supervisorctl start all
fi

perl -pi -e 's|(?<=chmod=).*|0766| ;' \
 /etc/supervisor/supervisord.conf

