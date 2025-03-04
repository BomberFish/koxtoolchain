#!/bin/bash -e
#
# adapted from NiLuJe's build script:
# http://www.mobileread.com/forums/showthread.php?t=88004
# (live copy: http://trac.ak-team.com/trac/browser/niluje/Configs/trunk/Kindle/Misc/x-compile.sh)
#
# =================== original header ====================
#
# Kindle cross toolchain & lib/bin/util build script
#
# $Id$
#
# kate: syntax bash;
#

## Using CrossTool-NG (http://crosstool-ng.org/)

CUR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_ROOT="${CUR_DIR}/build"
DEFAULT_GIT_REPO="https://github.com/crosstool-ng/crosstool-ng.git"

Build_CT-NG() {
	echo "[*] Building CrossTool-NG . . ."
	ct_ng_git_repo="$1"
	shift
	ct_ng_commit="$1"
	shift
	tc_target="$1"
	PARALLEL_JOBS=$(($(getconf _NPROCESSORS_ONLN 2> /dev/null || sysctl -n hw.ncpu 2> /dev/null || echo 0) + 1))
	echo "[-] ct-ng git repo: ${ct_ng_git_repo}"
	echo "[-] ct-ng commit hash: ${ct_ng_commit}"
	echo "[-] compiling with ${PARALLEL_JOBS} parallel jobs"
	echo "[-] toolchain target: ${tc_target}"

	[ ! -d "${BUILD_ROOT}" ] && mkdir -p "${BUILD_ROOT}"
	pushd "${BUILD_ROOT}"
		if [ ! -d CT-NG ]; then
			git clone "${ct_ng_git_repo}" CT-NG
		fi
		pushd CT-NG
			git remote rm origin
			git remote add origin "${ct_ng_git_repo}"
			git fetch origin
			git checkout "${ct_ng_commit}"
			git clean -fxdq
			./bootstrap
			[ ! -d "${BUILD_ROOT}/CT_NG_BUILD" ] && mkdir -p "${BUILD_ROOT}/CT_NG_BUILD"
			./configure --prefix="${BUILD_ROOT}/CT_NG_BUILD"
			make -j${PARALLEL_JOBS}
			make install
			export PATH="${BUILD_ROOT}/CT_NG_BUILD/bin:${PATH}"
		popd
		# extract platform name from target tuple
		tmp_str="${tc_target#*-}"
		TC_BUILD_DIR="${tmp_str%%-*}"
		[ ! -d "${TC_BUILD_DIR}" ] && mkdir -p "${TC_BUILD_DIR}"
		pushd "${TC_BUILD_DIR}"
			ct-ng distclean

			unset CFLAGS CXXFLAGS LDFLAGS
			ct-ng "${tc_target}"
			ct-ng oldconfig
			# That requires the 1.24 branch, so, don't do it on 1.23
			[ ! -f "${BUILD_ROOT}/CT-NG/steps.mk" ] && ct-ng upgradeconfig
			ct-ng updatetools
			nice ct-ng build
			echo ""
			echo "[INFO ]  ================================================================="
			echo "[INFO ]  Build done. Please add $HOME/x-tools/${tc_target}/bin to your PATH."
			echo "[INFO ]  ================================================================="
		popd
	popd

	echo "[INFO ]  ================================================================="
	echo "[INFO ]  The x-compile.sh script can do that (and more) for you:"
	echo "[INFO ]  * If you need a persistent custom sysroot (e.g., if you intend to build a full dependency chain)"
	echo "[INFO ]    > source ${PWD}/refs/x-compile.sh ${TC_BUILD_DIR} env"
	echo "[INFO ]  * If you just need a compiler:"
	echo "[INFO ]    > source ${PWD}/refs/x-compile.sh ${TC_BUILD_DIR} env bare"
}

HELP_MSG="
usage: $0 PLATFORM

Supported platforms:

	kindle
	kindle5
	kindlepw2
	kobo
	nickel
	remarkable
	cervantes
	pocketbook
	bookeen
"

if [ $# -lt 1 ]; then
	echo "Missing argument"
	echo "${HELP_MSG}"
	exit 1
fi

case $1 in
	-h)
		echo "${HELP_MSG}"
		exit 0
		;;
	kobo)
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabihf"
		;;
	nickel)
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabihf"
		;;
	kindlepw2)
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabi"
		;;
	kindle5)
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabi"
		;;
	kindle)
		# NOTE: Don't swap away from the 1.23-kindle branch,
		#       this TC currently fails to build on 1.24-kindle...
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabi"
		;;
	remarkable)
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabihf"
		;;
	cervantes)
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabi"
		;;
	pocketbook)
		# NOTE: Don't swap away from the 1.23-kindle branch,
		#       this TC currently fails to build on 1.24-kindle...
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			9954e26ad2a0781a12f0066411bc5ee5cd8b2829 \
			"arm-${1}-linux-gnueabi"
		# Then, pull InkView from the (old) official SDK...
		# NOTE: See also https://github.com/pocketbook/SDK_6.3.0/tree/5.19/SDK-iMX6/usr/arm-obreey-linux-gnueabi/sysroot/usr/local for newer FWs...
		chmod a+w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/lib/libinkview.481.5.17.so \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libinkview.so"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libinkview.so"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/lib/libhwconfig.so \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libhwconfig.so"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libhwconfig.so"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/FRSCSDK/arm-none-linux-gnueabi/sysroot/usr/lib/libbookstate.so \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libbookstate.so"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib/libbookstate.so"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/lib"
		chmod a+w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inkview.h \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		# Don't pull 3rd-party includes...
		sed -e '/^#include <zlib.h>/i \/*' -i "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		sed -e '/^#include FT_OUTLINE_H/a *\/' -i "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		# NOTE: This also comments <pthread.h>, which the header itself doesn't need anyway...
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkview.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inkplatform.h \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkplatform.h"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkplatform.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inklog.h \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inklog.h"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inklog.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/inkinternal.h \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkinternal.h"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/inkinternal.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/SDK_481/arm-obreey-linux-gnueabi/sysroot/usr/local/include/hwconfig.h \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/hwconfig.h"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/hwconfig.h"
		wget https://github.com/blchinezu/pocketbook-sdk/raw/5.17/FRSCSDK/arm-none-linux-gnueabi/sysroot/usr/include/bookstate.h \
			-O "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/bookstate.h"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include/bookstate.h"
		chmod a-w "${PWD}/x-tools/arm-${1}-linux-gnueabi/arm-${1}-linux-gnueabi/sysroot/usr/include"
		;;
	bookeen)
		Build_CT-NG \
			https://github.com/BomberFish/crosstool-ng.git \
			a5d02a410558cde6ad3a5bdc1aac02b948fc40cf \
			"arm-${1}-linux-gnueabi"
		;;
	*)
		echo "[!] $1 not supported!"
		echo "${HELP_MSG}"
		exit 1
		;;
esac
