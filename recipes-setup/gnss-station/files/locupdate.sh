#!/bin/sh

CFG="/etc/default/rrd_rtkrcv"
XYZ="/tmp/xyz"
export LOCATION="/tmp/location"

export MIN="0.000000000"

MINSOL="`expr 30 \* 60`"
BARRD="`expr 2 \* 24 \* 60 \* 60`"
BARRW="`expr 16 \* 24 \* 60 \* 60`"

export DBDIR="/var/lib/rrdcached/db"
export RRD="unix:/var/run/rrdcached.sock"

[ -f "${CFG}" ] || exit 1

source "${CFG}"

NOW="`date +%s`"

for QLTY in sol sgl ; do
  export QLTY
  DTIM="`rrdtool first --daemon ${RRD} ${DBDIR}/rtkrcv_${QLTY}llh.rrd`"
  DAGE="`expr ${NOW} - ${DTIM}`"
  echo "Age of >${QLTY}<: `expr ${DAGE} / 60`m"
  [ "${DAGE}" -gt "${MINSOL}" ] && break
  done

WINDOW="30m"
[ "${DAGE}" -gt "${BARRD}" ] && WINDOW="1d"
[ "${DAGE}" -gt "${BARRW}" ] && WINDOW="2w"

echo "Choosing >${QLTY}< for window >${WINDOW}<."

TEMP="`rrdtool graph /tmp/test.png --daemon ${RRD} --start -${WINDOW} DEF:lat=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Lat:AVERAGE DEF:lon=${DBDIR}/rtkrcv_sglllh.rrd:Lon:AVERAGE DEF:hght=${DBDIR}/rtkrcv_sglllh.rrd:Hght:AVERAGE PRINT:lat:AVERAGE:%.8lf PRINT:lon:AVERAGE:%.8lf PRINT:hght:AVERAGE:%.8lf | awk 'NR>1'`"

export NLAT="`echo ${TEMP} | cut -d ' ' -f 1`"
export NLON="`echo ${TEMP} | cut -d ' ' -f 2`"
export NHGHT="`echo ${TEMP} | cut -d ' ' -f 3`"

killProcesses() {
  PROCNAME="${1:-/usr/bin/transceiver}"
  PROCESSES="`grep -H "^${PROCNAME}" /proc/*/cmdline | cut -d '/' -f 3`"
  PROCESSES="`echo ${PROCESSES}`"
  for PROCESS in ${PROCESSES} ; do
    echo "Killing >${PROCNAME}< process #${PROCESS}"
    kill ${PROCESS}
    done
  }

killAll() {
  killProcesses '/usr/bin/transceiver'
  killProcesses '/usr/bin/str2str'
  exit
  }

stopTransmission() {
  echo "Deleting ${LOCATION}"
  [ -f ${LOCATION}  ] && rm -f ${LOCATION}
  killAll
  }

[ "${NLAT}" = "nan" ] && stopTransmission
[ "${NLON}" = "nan" ] && stopTransmission
[ "${NHGHT}" = "nan" ] && stopTransmission

[ "${NLAT}" = "" ] && stopTransmission
[ "${NLON}" = "" ] && stopTransmission
[ "${NHGHT}" = "" ] && stopTransmission

expr ${NLAT} \< ${MIN} >/dev/null && stopTransmission
expr ${NLON} \< ${MIN} >/dev/null && stopTransmission
expr ${NHGHT} \< ${MIN} >/dev/null && stopTransmission

[ -f ${LOCATION} ] && . ${LOCATION}

echo "Writing new ${LOCATION}"
echo -e LAT=\"${NLAT}\"\\nLON=\"${NLON}\"\\nHGHT=\"${NHGHT}\"\\n > ${LOCATION}

[ "${NLAT}" != "${LAT}" ] && killAll
[ "${NLON}" != "${LON}" ] && killAll
[ "${NHGHT}" != "${HGHT}" ] && killAll

