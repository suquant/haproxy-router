#!/bin/sh
#
# This script is designed to be run inside the container
#

# fail hard and fast even on pipelines
set -eo pipefail

# set debug based on envvar
[[ $DEBUG ]] && set -x

ETCD_NODE=${ETCD_NODE:-127.0.0.1:2379}
CONFD_LOGLEVEL=${CONFD_LOGLEVEL:-error}
CONFD_INTERVAL=${CONFD_INTERVAL:-2}

chown -R haproxy /var/lib/haproxy

/usr/bin/confd -node=${ETCD_NODE} -log-level=${CONFD_LOGLEVEL} -interval=${CONFD_INTERVAL} &

sleep 2

exec /usr/sbin/haproxy -db -f /etc/haproxy/haproxy.cfg
