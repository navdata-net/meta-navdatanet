DESCRIPTION = "Package group for navdata.net GNSS basestation."

LICENSE = "MIT"

inherit packagegroup

RDEPENDS_${PN} = "libgcc rpi-gpio parted e2fsprogs curl ntp nginx rrdtool pylongps rtklibexplorer gnss-station"

