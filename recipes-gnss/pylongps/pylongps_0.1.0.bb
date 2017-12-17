SUMMARY = "A GPS Server application and library which allows easy sharing of RTCM Differential GPS updates "
DESCRIPTION = "Pylon GPS makes it easy to share GPS updates from your basestation and allows mobile units to get updates from any nearby basestations."
HOMEPAGE = "http://www.pylongps.com"
LICENSE = "LGPL3"
#LIC_FILES_CHKSUM = "file://readme.txt;beginline=104;endline=141;md5=9adf78faf728f2be96f266651c3e1d05"

SRC_URI = " \
    git://github.com/charlesrwest/pylonGPS.git \
"

S = "${WORKDIR}/git"

APPS = "caster transceiver"

inherit pkgconfig cmake
inherit useradd

USERADD_PACKAGES= "${PN}"
USERADD_PARAM_${PN} = “-d /home/pylon -r -s /bin/bash pylon"

do_install() {
    install -d ${D}${bindir}
    for APP in ${APPS}; do
        install -m 0755 ${B}/${APP} ${D}${bindir}
    done

    # deploy configuration files to /etc/pylon
    install -d ${D}${sysconfdir}/pylon
    install -m 0644 ${WORKDIR}/caster.pylonCasterConfiguration ${D}${sysconfdir}/pylon

    # deploy systemd service definition
    install -d ${D}${sysconfdir}/systemd/system
    install -m 0644 ${WORKDIR}/caster.service /etc/systemd/system
}

#CONFFILES_${PN} += "${sysconfdir}/default/rtkrcv.conf"
