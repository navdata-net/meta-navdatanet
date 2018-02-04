#!/bin/sh

DSTSERVER="${1:-pylon.navdata.net}"

MYLOCATION="/tmp/location"

[ -f "${MYLOCATION}" ] || {
  echo "No location file. Waiting..."
  sleep 60
  exit 1
  }

[ -f /etc/default/transceiver_raw ] || {
  echo "/etc/default/transceiver_raw missing"
  sleep 60
  exit 1
  }

source /etc/default/transceiver_raw
source "${MYLOCATION}"

echo "Got location Lat: ${LAT} - Lon: ${LON} - Hght: ${HGHT}"

HGHT="`printf '%08.3f' ${HGHT}`"

/usr/bin/transceiver -read_tcp 127.0.0.1 3131 -output_caster "${DSTSERVER}" 10001 10002 10003 10004 10005 10006 -output_basestation ${LAT} ${LON} RAW ${Status}_UB_${HGHT}_${Name} 1

