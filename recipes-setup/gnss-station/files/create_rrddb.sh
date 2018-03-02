#!/bin/sh

CFG="/etc/default/rrd_rtkrcv"

[ -f "${CFG}" ] || exit 1
source "${CFG}"

DBDIR="/var/lib/rrdcached/db"
DATATEMPLATE='DS:${COLUMN}:${TYPE}:2:U:U'
RRD_CREATE='${DATASET} RRA:${AGGR}:0.5:1:1800 RRA:${AGGR}:0.5:60:1440 RRA:${AGGR}:0.5:1800:672 RRA:${AGGR}:0.5:7200:672'

for ENTRY in ${DBs} ; do
  DB="`echo ${ENTRY} | cut -d ':' -f 1`"
  DBl="`echo ${DB} | tr '[:upper:]' '[:lower:]'`"

  COLUMNS="`echo ${ENTRY} | cut -d ':' -f 2`"

  TEMP="`echo ${ENTRY} | cut -d ':' -f 3`"
  case TEMP in
    A) TYPE="ABSOLUTE" ;;
    C) TYPE="COUNTER" ;;
    D) TYPE="DERIVE" ;;
    G) TYPE="GAUGE" ;;
    *) TYPE="GAUGE" ;;
  esac

  TEMP="`echo ${ENTRY} | cut -d ':' -f 4`"
  case TEMP in
    A) AGGR="AVERAGE" ;;
    L) AGGR="LAST" ;;
    N) AGGR="MIN" ;;
    X) AGGR="MAX" ;;
    *) AGGR="AVERAGE" ;;
  esac

  DATASET=""
  for COLUMN in `echo ${COLUMNS} | tr ',' ' '` ; do
    export DBDIR DB DBl COLUMN TYPE AGGR DATASET
    DATASET="${DATASET} `echo ${DATATEMPLATE} | envsubst`"
    done

  export DBDIR DB DBl COLUMN TYPE AGGR DATASET
  THISCMD="`echo ${RRD_CREATE} | envsubst`"
  echo "create ${THISCMD}"
  rrdtool create --daemon unix:/var/run/rrdcached.sock ${DBDIR}/rtkrcv_${DBl}.rrd -s 1 ${THISCMD}
  done

