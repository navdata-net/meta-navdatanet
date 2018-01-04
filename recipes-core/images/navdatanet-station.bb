DESCRIPTION = "navdata.net GNSS Basestation image"
LICENSE = "MIT"

include recipes-core/images/rpi-hwup-image.bb

IMAGE_FEATURES += " debug-tweaks ssh-server-openssh package-management"

PACKAGE_FEED_URIS = "http://ipk.navdata.net/rocko"
PACKAGE_FEED_BASE_PATHS = "dev"
PACKAGE_FEED_ARCHS = "aarch64 all raspberrypi3_64"

IMAGE_INSTALL_append = " rpi-config packagegroup-station"

IMAGE_ROOTFS_EXTRA_SPACE_append += "+ 100000"

