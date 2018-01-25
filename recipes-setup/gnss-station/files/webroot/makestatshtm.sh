#!/bin/sh

TABLES="System;cpu:CPU,mem:RAMfree Location;lat:Latitude,lon:Longitude ;hght:Height,stat:Status Satellites;rsat:LocalSATS,bsat:RemoteSATS Resolution;vsat:MatchingSATS,arr:ARratio Distance;bline:StationDistance,dage:DiffdataAge"
PERIODS="30m:30minutes 1d:1day 2w:2weeks 2y:2years"


for PERIOD in ${PERIODS} ; do
  DBterm="`echo ${PERIOD} | cut -d ':' -f 1`"
  TITLE="`echo ${PERIOD} | cut -d ':' -f 2`"

  STATFILE="bstats_${DBterm}.htm"

  cat stats_header.htm >"${STATFILE}"
  echo "    <h2>${TITLE}</h2>" >>"${STATFILE}"
    
  for TABLE in ${TABLES}; do
    SECTION="`echo ${TABLE} | cut -d ';' -f 1`"
    FIELDS="`echo ${TABLE} | cut -d ';' -f 2 | tr ',' ' '`"

    echo "    <h3>${SECTION}</h3>" >>"${STATFILE}"
    echo '    <table border="1" cellpadding="2" cellspacing="2">' >>"${STATFILE}"
    echo '      <tbody>' >>"${STATFILE}"

    TABLE_HEAD="        <tr>\n"
    TABLE_BODY="        <tr>\n"

    for FIELD in ${FIELDS} ; do
      DB="`echo ${FIELD} | cut -d ':' -f 1`"
      HEADER="`echo ${FIELD} | cut -d ':' -f 2`"
      TABLE_HEAD="${TABLE_HEAD}          <th align='center'>${HEADER}</th>\n"
      TABLE_BODY="${TABLE_BODY}          <td align='center'><img alt='${HEADER} graph' src='volatile/rtkrcv_${DB}_${DBterm}.png'></td>\n"
      done

    TABLE_HEAD="${TABLE_HEAD}        </tr>"
    TABLE_BODY="${TABLE_BODY}        </tr>"
    echo "${TABLE_HEAD}" >>"${STATFILE}"
    echo "${TABLE_BODY}" >>"${STATFILE}"
    echo '    </table>' >>"${STATFILE}"
    done

  cat stats_footer.htm >>"${STATFILE}"

  done

