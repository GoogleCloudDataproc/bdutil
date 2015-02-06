#!/usr/bin/env bash
# disable transparent huge pages: for Hadoop
thp_disable=true
if [ "${thp_disable}" = true ]; then
    for path in redhat_transparent_hugepage transparent_hugepage; do
        if test -f /sys/kernel/mm/${path}/enabled; then
            echo never > /sys/kernel/mm/${path}/enabled
        fi
        if test -f /sys/kernel/mm/${path}/defrag; then
            echo never > /sys/kernel/mm/${path}/defrag
        fi
    done
fi
exit 0
