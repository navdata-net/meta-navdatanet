SUMMARY = "RTKLib GPS real-time kinematic open-source software."
DESCRIPTION = "Open-source software to get accurate gps position information."
HOMEPAGE = "http://www.rtklib.com"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://readme.txt;beginline=104;endline=141;md5=9adf78faf728f2be96f266651c3e1d05"

# corresponds to "rtklib 2.4.2 p11"
#SRCREV = "76b9c97257f304aedad38b5a6bbbac444724aab3"
SRC_URI = " \
    git://github.com/rtklibexplorer/RTKLIB.git \
    file://base_m8t.cmd \
"

S = "${WORKDIR}/git"
# CUI apps listed in makeall.sh
APPS = "pos2kml str2str rnx2rtkp convbin rtkrcv"

do_configure[noexec] = "1"

CFLAGS += "-I${S}/src"
do_compile() {
    for APP in ${APPS}; do
        oe_runmake -C ${S}/app/${APP}/gcc/
    done
}

do_install() {
    install -d ${D}${bindir}
    for APP in ${APPS}; do
        install -m 0755 ${B}/app/${APP}/gcc/${APP} ${D}${bindir}
    done

    # install cmd files to /etc/rtklib/cmd/
    install -d ${D}${sysconfdir}/rtklib/cmd
    install -m 0644 ${WORKDIR}/rtkrcv.conf ${D}${sysconfdir}/rtklib/cmd/

    # copy data files to /etc/rtklib/data
    install -d ${D}${sysconfdir}/rtklib/data
    install -m 0644 ${S}/data/* ${D}${sysconfdir}/rtklib/data/
}

#CONFFILES_${PN} += "${sysconfdir}/default/rtkrcv.conf"
