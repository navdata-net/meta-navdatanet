#!/bin/sh

BACKUPDIR="${1:-/tmp}"

DBs="lat lon hght"

for DB in ${DBS} ; do
  rrdtool dump --daemon unix:/var/run/rrdcached.sock /var/lib/rrdcached/db/rtkrcv_${DB}.rrd | gzip > "${BACKUPDIR}/rtkrcv_${DB}.rrd.xml.gz"
  done

