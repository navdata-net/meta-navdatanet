#!/bin/sh

LOCFILE="/tmp/location"

[ -f "${LOCFILE}" ] || {
    sleep 10
    exit
    }

source "${LOCFILE}"

#/usr/bin/str2str -in tcpcli://localhost:3131#ubx -out tcpsvr://:8989#rtcm3 -msg "1002(1),1005(10),1006(10),1008(10),1012(1),1013(1),1019(1),1019(1)" -p "${LAT} ${LON} ${HGHT}" -t 1
/usr/bin/str2str -in tcpcli://localhost:3131#ubx -out tcpsvr://:8989#rtcm3 -msg "1002(1),1005(10),1006(10),1008(10),1013(1),1019(1),1020(1)" -p ${LAT} ${LON} ${HGHT} -t 1

