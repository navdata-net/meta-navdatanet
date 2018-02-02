SUMMARY = "A library for geographic projections."
HOMEPAGE = "https://geographiclib.sourceforge.io/html/python/index.html"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=b59808f7152cf0cd345c992f4957ea37"

SRC_URI[md5sum] = "eec8f975cd72af4f8ddebade1f613184"
SRC_URI[sha256sum] = "635da648fce80a57b81b28875d103dacf7deb12a3f5f7387ba7d39c51e096533"

PYPI_PACKAGE = "geographiclib"

inherit pypi setuptools

RDEPENDS_${PN} += "${PYTHON_PN}-math"

#FILES_${PN}-doc = "${datadir}/nvector_docs"

