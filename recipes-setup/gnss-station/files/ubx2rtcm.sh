#!/bin/sh

LOCFILE="/tmp/location"

[ -f "${LOCFILE}" ] || {
    sleep 10
    exit
    }

source "${LOCFILE}"

/usr/bin/str2str -in tcpcli://localhost:3131#ubx -out tcpsvr://:8989#rtcm3 -msg "1002(1),1005(20),1006(20),1008(20),1010(1),1019(1),1020(1),1045(1)" -p ${LAT} ${LON} ${HGHT} -t 1

