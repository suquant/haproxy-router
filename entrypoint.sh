#!/bin/sh
#
# This script is designed to be run inside the container
#

# fail hard and fast even on pipelines
set -eo pipefail

# set debug based on envvar
[[ $DEBUG ]] && set -x

ETCD_NODE=${ETCD_NODE:-127.0.0.1:2379}
CONFD_LOGLEVEL=${CONFD_LOGLEVEL:-info}
CONFD_INTERVAL=${CONFD_INTERVAL:-2}
DPORTS=${DPORTS:-80,443}
IPTABLES_SLEEPTIME=${IPTABLES_SLEEPTIME:-0.5}
RELOAD_SLEEPTIME=${IPTABLES_SLEEPTIME:-0.5}
CONFIG_FILE=/etc/haproxy/haproxy.cfg

reload() {
    /sbin/iptables -I INPUT -p tcp -m multiport --dports ${DPORTS} --syn -j DROP
    /bin/sleep ${IPTABLES_SLEEPTIME}
    /usr/sbin/haproxy -f ${CONFIG_FILE} -db -sf $(pgrep haproxy) &
    /bin/sleep ${RELOAD_SLEEPTIME}
    /sbin/iptables -D INPUT -p tcp -m multiport --dports ${DPORTS} --syn -j DROP
    wait
}
trap reload SIGHUP

chown -R haproxy /var/lib/haproxy

/usr/bin/confd -node=${ETCD_NODE} -log-level=${CONFD_LOGLEVEL} -interval=${CONFD_INTERVAL} &

sleep 2

/usr/sbin/haproxy -f ${CONFIG_FILE} -db &
wait