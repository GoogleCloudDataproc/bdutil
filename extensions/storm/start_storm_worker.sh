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

# Define Supervisor Configurations for Storm
cat > /etc/supervisor/conf.d/storm.conf <<EOF
[program:storm-supervisor]
command=${STORM_INSTALL_DIR}/bin/storm supervisor
numprocs=1
autostart=true
autorestart=true
user=root
redirect_stderr=true
stdout_logfile=${STORM_VAR}/supervisor.log

[program:storm-logviewer]
command=${STORM_INSTALL_DIR}/bin/storm logviewer
numprocs=1
autostart=true
autorestart=true
user=hadoop
redirect_stderr=true
stdout_logfile=${STORM_VAR}/logviewer.log
EOF

# Reload supervisor
supervisorctl reload
