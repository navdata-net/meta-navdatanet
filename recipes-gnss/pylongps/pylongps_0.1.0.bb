SUMMARY = "A GPS Server application and library which allows easy sharing of RTCM Differential GPS updates"
DESCRIPTION = "Pylon GPS makes it easy to share GPS updates from your basestation and allows mobile units to get updates from any nearby basestations."
HOMEPAGE = "http://www.pylongps.com"
LICENSE = "LGPLv3"
LIC_FILES_CHKSUM = "file://LICENSE;md5=6df79487081a679ce42441612c160a88"

PR = "rc1"

DEPENDS += "protobuf protobuf-native"
DEPENDS += "zeromq cppzmq"
DEPENDS += "poco"
DEPENDS += "sqlite-native"
DEPENDS += "libsodium-native"

SRCREV = "${AUTOREV}"
SRC_URI = "git://github.com/charlesrwest/pylonGPS.git;protocol=https \
           file://caster.pylonCasterConfiguration \
           file://caster.service \
           file://transceiver.init \
           file://transceiver.default \
           file://fixes.patch \
           file://yocto.patch \
           file://navdatanet.patch \
           "

S = "${WORKDIR}/git"

APPS = "caster transceiver"
LIBS = "libpylongps.so"

FILES_SOLIBSDEV = ""
FILES_${PN} += " ${libdir}/libpylongps.so"

inherit pkgconfig cmake
EXTRA_OECMAKE += " -DCMAKE_SKIP_RPATH=TRUE"

inherit useradd

USERADD_PACKAGES = "${PN}"
USERADD_PARAM_${PN} = "-d /home/pylon -r -m -s /bin/sh pylon"

#inherit update-rc.d
#INITSCRIPT_NAME = "transceiver_raw"
#INITSCRIPT_PARAMS = "start 25 2 3 4 5 . stop 15 0 6 1 ."

#inherit systemd
#SYSTEMD_SERVICE_${PN} = "caster.service"

do_install() {
    install -d ${D}${bindir}
    for APP in ${APPS}; do
        install -m 0755 ${B}/bin/${APP} ${D}${bindir}
        #chrpath -d ${D}${bindir}/${APP}
    done

    install -d ${D}${libdir}
    for LIB in ${LIBS}; do
        install -m 0644 ${B}/lib/${LIB} ${D}${libdir}
        #chrpath -d ${D}${libdir}/${LIB}
    done

    # deploy configuration files to /etc/pylon
    install -d -m 0750 ${D}${sysconfdir}/pylon
    install -m 0640 ${WORKDIR}/caster.pylonCasterConfiguration ${D}${sysconfdir}/pylon
    chgrp -R pylon ${D}${sysconfdir}/pylon

    # deploy systemd service definition
    #install -d ${D}${systemd_unitdir}/system
    #install -m 0644 ${WORKDIR}/caster.service ${D}${systemd_unitdir}/system

    # deploy System V startup file
    install -d ${D}${sysconfdir}/init.d
    install -m 755 ${WORKDIR}/transceiver.init ${D}${sysconfdir}/init.d/transceiver_raw

    #deploy default options
    install -d ${D}${sysconfdir}/default
    install -m 755 ${WORKDIR}/transceiver.default ${D}${sysconfdir}/default/transceiver_raw

}

CONFFILES_${PN} = "${sysconfdir}/default/transceiver_raw"

