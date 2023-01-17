#!/bin/sh

redis-cli --cluster create %{ for host in master_hosts ~} ${host} %{ endfor ~} --cluster-yes --cluster-replicas 0
