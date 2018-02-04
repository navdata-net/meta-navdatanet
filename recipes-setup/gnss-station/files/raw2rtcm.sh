#!/bin/sh

CFGFILE="/etc/default/raw2rtcm"

[ -f "${CFGFILE}" ] || {
    echo "Configuration file >${CFGFILE}< missing."
    sleep 30
    exit 1
    }

echo "Reading configuration."
source "${CFGFILE}"
echo "Source data format: >${RAWFORMAT}<"
echo "RTCM messages: >${MSGS}<"

/usr/bin/str2str -in tcpsvr://localhost:3121#${RAWFORMAT} -out tcpsvr://:3131 -out tcpsvr://:3132#rtcm3 -msg "${MSGS}" -t 1

