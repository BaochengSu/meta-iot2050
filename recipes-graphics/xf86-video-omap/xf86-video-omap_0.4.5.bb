#
# Copyright (c) Siemens AG, 2020
#
# Authors:
#  Su Baocheng <baocheng.su@siemens.com>
#
# This file is subject to the terms and conditions of the MIT License.  See
# COPYING.MIT file in the top-level directory.
#

inherit dpkg

SRC_URI += "apt://${PN}"

CHANGELOG_V="<orig-version>+iot2050"

DEBIAN_BUILD_DEPENDS += "libdrm-omap1"

do_prepare_build() {
	deb_add_changelog
	
	# patch control, so that the libdrm-omap1 can be packaged on arm64
    sed -i 's/armel armhf/armel armhf arm64/' ${S}/debian/control
	sed -i 's/libudev-dev,/libudev-dev, libdrm-omap1,/' ${S}/debian/control
}

#dpkg_runbuild_prepend() {
#	export DEB_BUILD_OPTIONS="nocheck"
#}

