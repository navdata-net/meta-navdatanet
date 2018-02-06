#!/bin/sh

export LOCATION="/tmp/location"

[ -f "${LOCATION}" ] || {
  echo "No location file. Waiting..."
  sleep 60
  exit
  }

source "${LOCATION}"

/usr/bin/str2str -in tcpcli://127.0.0.1:3132#rtcm3 -out tcpcli://127.0.0.1:3123#rtcm3 -msg "1006(10)" -p ${LAT} ${LON} ${HGHT} -s 30000 -t 1

