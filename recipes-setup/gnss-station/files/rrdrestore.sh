#!/bin/sh

BACKUPDIR="${1:-/tmp}"

DBs="lat lon hght"

for DB in ${DBS} ; do
  zcat "${BACKUPDIR}/rtkrcv_${DB}.rrd.xml.gz" | rrdtool restore --daemon unix:/var/run/rrdcached.sock - /var/lib/rrdcached/db/rtkrcv_${DB}.rrd
  done

