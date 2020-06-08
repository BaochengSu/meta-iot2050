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

PROVIDES += "libdrm-omap1"

# these patches are from TI's arago project
SRC_URI += " \
    apt://libdrm \
    file://musl-ioctl.patch;apply=no \
    file://0001-Add-option-to-run-a-test-indefinitely.patch;apply=no \
    file://0001-omap-fix-omap_bo_size-for-tiled-buffers.patch;apply=no \
    file://0002-omap-add-OMAP_BO-flags-to-affect-buffer-allocation.patch;apply=no \
    file://0001-libsync-add-support-for-pre-v4.7-kernels.patch;apply=no \
    file://0002-Add-sync_fence_info-and-sync_pt_info.patch;apply=no \
"

CHANGELOG_V="<orig-version>+iot2050"

do_prepare_build() {
	deb_add_changelog

	# apply patch
	cd ${S}
	quilt import ${WORKDIR}/*.patch
	quilt push -a

	# patch rules, so that the libdrm-omap1 can be compiled on arm64
	sed -i -e '/Domap/d' ${S}/debian/rules
	sed -i -e '/omap1/d' ${S}/debian/rules
	sed -i -e "/Dtegra=true/ a confflags += -Domap=true" ${S}/debian/rules
	sed -i -e "/Dtegra=false/ a confflags += -Domap=false" ${S}/debian/rules
	sed -i -e '/Domap/s/.*/\t&/' ${S}/debian/rules
	sed -i -e "/tegra0/ a dh_makeshlibs -plibdrm-omap1 -V'libdrm-omap1 (>= 2.4.38)' -- -c4" ${S}/debian/rules
	sed -i -e '/omap1/s/.*/\t&/' ${S}/debian/rules

    # patch control, so that the libdrm-omap1 can be packaged on arm64
    sed -i '32s/any-arm/any-arm arm64/' ${S}/debian/control
    sed -i '132s/any-arm/any-arm arm64/' ${S}/debian/control
}

dpkg_runbuild_prepend() {
	export DEB_BUILD_OPTIONS="nocheck"
}
