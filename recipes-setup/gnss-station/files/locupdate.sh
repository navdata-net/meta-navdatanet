#!/bin/sh

CFG="/etc/default/rrd_rtkrcv"
XYZ="/tmp/xyz"
export LOCATION="/tmp/location"
export PYLON="/tmp/pylon"

export MIN="0.000000000"

declare -A MARGIN=( ["30m"]="10s" ["1d"]="1min" ["2w"]="1h" )
declare -A MINDATA=( ["1d"]="1080" ["2w"]="96" )

export DBDIR="/var/lib/rrdcached/db"
export RRD="unix:/var/run/rrdcached.sock"

echo -e "\033\0143" >/dev/tty4
date

[ -f "${CFG}" ] || {
  echo "${CFG} missing."
  exit 1
  }

source "${CFG}"

NOW="`date +%s`"

WINDOW="1d"
QLTY="sgl"


for QLTY in sol sgl ; do
  for WINDOW in 2w 1d ; do
    SOLVALS="`rrdtool fetch ${DBDIR}/rtkrcv_${QLTY}llh.rrd --daemon ${RRD} -a --start +${MARGIN[${WINDOW}]}-${WINDOW} AVERAGE | tail -n +3 | grep -v nan | wc -l`"
    echo "${SOLVALS} entries in ${WINDOW} of ${QLTY} > ${MINDATA[${WINDOW}]} ?"
    [ "${SOLVALS}" -gt "${MINDATA[${WINDOW}]}" ] && break
    done
  [ "${SOLVALS}" -gt "${MINDATA[${WINDOW}]}" ] && break
  done

[ "${QLTY}" = "sgl" -a "${WINDOW}" = "1d" -a "${SOLVALS}" -lt "30" ] && WINDOW="30m"

export WINDOW
export QLTY

echo "Using >${QLTY}< for window >${WINDOW}<."

TEMP="`rrdtool graph /tmp/test.png --daemon ${RRD} --start +${MARGIN[${WINDOW}]}-${WINDOW} DEF:lat=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Lat:AVERAGE DEF:lon=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Lon:AVERAGE DEF:hght=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Hght:AVERAGE PRINT:lat:AVERAGE:%.8lf PRINT:lon:AVERAGE:%.8lf PRINT:hght:AVERAGE:%.8lf | awk 'NR>1'`"

export NLAT="`echo ${TEMP} | cut -d ' ' -f 1`"
export NLON="`echo ${TEMP} | cut -d ' ' -f 2`"
export NHGHT="`echo ${TEMP} | cut -d ' ' -f 3`"

export PLAT="`printf '%.4f' ${NLAT}`"
export PLON="`printf '%.4f' ${NLON}`"



killProcesses() {
  PROCNAME="${1:-/usr/bin/transceiver}"

  pushd /proc >/dev/null
  for PROCESS in `ls -d -1 [0-9]*`; do
    [ -d "/proc/${PROCESS}" ] && cat "/proc/${PROCESS}/cmdline" | tr -s '\0' ' ' | grep "^${PROCNAME}" 2>/dev/null && {
      echo "Killing >${PROCNAME}< process #${PROCESS}"
      kill ${PROCESS}
      }
    done
  popd >/dev/null
  }

killLocation() {
  echo "Killing location process."
  killProcesses '/usr/bin/str2str -in tcpcli://127.0.0.1:3132#rtcm3 -out tcpcli://127.0.0.1:3123#rtcm3 -msg 1006(10) -p'
  }

killPylon() {
  echo "Killing pylon transceiver processes."
  killProcesses '/usr/bin/transceiver'
  }

killAll() {
  killPylon
  killLocation
  exit
  }

deleteLocation() {
  echo "Deleting ${LOCATION}"
  [ -f "${LOCATION}" ] && rm -f "${LOCATION}"
  killLocation
  exit
  }

stopAll() {
  echo "Deleting ${LOCATION}"
  [ -f "${LOCATION}" ] && rm -f "${LOCATION}"
  echo "Deleting ${PYLON}"
  [ -f "${PYLON}" ] && rm -f "${PYLON}"
  killAll
  }

zeroOut() {
  echo "Zero coordinate received."
  stopAll
  }



[ "${NLAT}" = "nan" -o "${NLON}" = "nan" -o "${NHGHT}" = "nan" ] && {
  echo "nan location data received."
  stopAll
  }

[ "${NLAT}" = "" -o "${NLON}" = "" -o "${NHGHT}" = "" ] && {
  echo "Empty location data received."
  stopAll
  }


expr ${NLAT} \< ${MIN} >/dev/null && zeroOut
expr ${NLON} \< ${MIN} >/dev/null && zeroOut
expr ${NHGHT} \< ${MIN} >/dev/null && zeroOut


[ -f "${PYLON}" ] && source "${PYLON}"

[ "${PLAT}" != "${LAT}" -o "${PLON}" != "${LON}" ] && {
  echo "Writing new ${PYLON}"
  echo -e LAT=\"${PLAT}\"\\nLON=\"${PLON}\"\\n > "${PYLON}"
  cat "${PYLON}"
  killPylon
  }

[ "${WINDOW}" = "30m" ]  && {
  echo "Not enough confidence in location."
  deleteLocation
  }

[ "${QLTY}" = "sgl" -a "${SOLVALS}" -lt "${MINDATA[1d]}" ]  && {
  echo "Not enough data collected in location."
  deleteLocation
  }


HMAX="`rrdtool graph /tmp/test.png --daemon ${RRD} --start +${MARGIN[${WINDOW}]}-${WINDOW} DEF:hght=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Hght:AVERAGE PRINT:hght:MAX:%.8lf | awk 'NR>1'`"
HMIN="`rrdtool graph /tmp/test.png --daemon ${RRD} --start +${MARGIN[${WINDOW}]}-${WINDOW} DEF:hght=${DBDIR}/rtkrcv_${QLTY}llh.rrd:Hght:AVERAGE PRINT:hght:MIN:%.8lf | awk 'NR>1'`"
HVAR="`echo $HMAX $HMIN | awk '{print int($1-$2)}'`"

[ "${HVAR}" -gt "29" ] && {
  echo "Height variation too large: ${HVAR}m"
  deleteLocation
  }


[ -f "${LOCATION}" ] && source "${LOCATION}"

[ "${NLAT}" != "${LAT}" -o "${NLON}" != "${LON}" -o "${NHGHT}" != "${HGHT}" ] && {
  echo "Writing new ${LOCATION}"
  echo -e LAT=\"${NLAT}\"\\nLON=\"${NLON}\"\\nHGHT=\"${NHGHT}\"\\n > "${LOCATION}"
  cat "${LOCATION}"
  killLocation
  }

