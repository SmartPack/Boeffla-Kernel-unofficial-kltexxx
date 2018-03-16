#!/bin/bash

#
# Boeffla-Kernel (unofficial) Build Script
# 
# Author: sunilpaulmathew <sunil.kde@gmail.com>
#

#
# This script is licensed under the terms of the GNU General Public 
# License version 2, as published by the Free Software Foundation, 
# and may be copied, distributed, and modified under those terms.
#

#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#

#
# ***** ***** ***** ..How to use this script… ***** ***** ***** #
#
# For those who want to build this kernel using this script…
#
# Please note: this script is by-default designed to build only 
# one variants at a time.
#

# 1. Properly locate toolchain (Line# 47)
# 2. Select the 'KERNEL_VARIANT' (Line# 43)
# 3. Open Terminal, ‘cd’ to the Kernel ‘root’ folder and run ‘. build_boeffla.sh’
# 4. The output (anykernel zip) file will be generated in the ‘release_boeffla’ folder
# 5. Enjoy your new Kernel

#
# ***** ***** *Variables to be configured manually* ***** ***** #
# 

KERNEL_NAME="Boeffla-Kernel"

KERNEL_VARIANT="kltekor" # options: klte, kltekor, kltekdi

KERNEL_VERSION="v1"

TOOLCHAIN="/home/sunil/android-ndk-r15c/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-"

ARCHITECTURE="arm"

NUM_CPUS=""   # number of cpu cores used for build (leave empty for auto detection)

KERNEL_DEFCONFIG="Boeffla_@$KERNEL_VARIANT@_defconfig"

COMPILE_DTB="y"

KERNEL_DATE="$(date +"%Y%m%d")"

COMPILER_FLAGS_KERNEL="-Wno-maybe-uninitialized -Wno-array-bounds"
COMPILER_FLAGS_MODULE="-Wno-maybe-uninitialized -Wno-array-bounds"

# ***** ***** ***** ***** ***THE END*** ***** ***** ***** ***** #

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[1;32m"
COLOR_NEUTRAL="\033[0m"

export ARCH=$ARCHITECTURE

export CROSS_COMPILE="${CCACHE} $TOOLCHAIN"

if [ -z "$NUM_CPUS" ]; then
	NUM_CPUS=`grep -c ^processor /proc/cpuinfo`
fi

if [ -z "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n Please select the variant to build... KERNEL_VARIANT should not be empty...\n"$COLOR_NEUTRAL
else
	if [ -e arch/arm/configs/$KERNEL_DEFCONFIG ]; then
		if [ -e output_$KERNEL_VARIANT/ ]; then
			if [ -e output_$KERNEL_VARIANT/.config ]; then
				rm -f output_$KERNEL_VARIANT/.config
				if [ -e output_$KERNEL_VARIANT/arch/arm/boot/zImage ]; then
					rm -f output_$KERNEL_VARIANT/arch/arm/boot/zImage
				fi
			fi
		else
			mkdir output_$KERNEL_VARIANT
		fi
		echo -e $COLOR_GREEN"\n building $KERNEL_NAME for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
		make -C $(pwd) O=output_$KERNEL_VARIANT $KERNEL_DEFCONFIG 
		# updating kernel version
		sed -i "s;lineageos;$KERNEL_VERSION;" output_$KERNEL_VARIANT/.config;
		make -j$NUM_CPUS -C $(pwd) O=output_$KERNEL_VARIANT
		if [ -e output_$KERNEL_VARIANT/arch/arm/boot/zImage ]; then
			echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
			cp output_$KERNEL_VARIANT/arch/arm/boot/zImage anykernel_boeffla/
			# compile dtb if required
			if [ "y" == "$COMPILE_DTB" ]; then
				echo -e $COLOR_GREEN"\n compiling device tree blob (dtb) for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
				if [ -f output_$KERNEL_VARIANT/arch/arm/boot/dt.img ]; then
					rm -f output_$KERNEL_VARIANT/arch/arm/boot/dt.img
				fi
				chmod 777 tools_boeffla/dtbToolCM
				tools_boeffla/dtbToolCM -2 -o output_$KERNEL_VARIANT/arch/arm/boot/dt.img -s 2048 -p output_$KERNEL_VARIANT/scripts/dtc/ output_$KERNEL_VARIANT/arch/arm/boot/
				# removing old dtb (if any)
				if [ -f anykernel_boeffla/dtb ]; then
					rm -f anykernel_boeffla/dtb
				fi
				# copying generated dtb to anykernel directory
				if [ -e output_$KERNEL_VARIANT/arch/arm/boot/dt.img ]; then
					mv -f output_$KERNEL_VARIANT/arch/arm/boot/dt.img anykernel_boeffla/dtb
				fi
			fi
			# check and create 'modules' folder.
			if [ ! -d "anykernel_boeffla/modules/" ]; then
				mkdir anykernel_boeffla/modules/
				if [ ! -d "anykernel_boeffla/modules/system/" ]; then
					mkdir anykernel_boeffla/modules/system/
					if [ ! -d "anykernel_boeffla/modules/system/lib/" ]; then
						mkdir anykernel_boeffla/modules/system/lib/
						if [ ! -d "anykernel_boeffla/modules/system/lib/modules/" ]; then
							mkdir anykernel_boeffla/modules/system/lib/modules/
						fi
					fi
				fi
			fi
			if [ -z "$(ls -A anykernel_boeffla/modules/system/lib/modules/)" ]; then
				echo -e $COLOR_GREEN"\n “Preparing "modules" folder...\n"$COLOR_NEUTRAL
			else
				rm -r anykernel_boeffla/modules/system/lib/modules/*
			fi
			echo -e $COLOR_GREEN"\n copying generated 'modules'\n"$COLOR_NEUTRAL
			find output_$KERNEL_VARIANT -name '*.ko' -exec cp -av {} anykernel_boeffla/modules/system/lib/modules \;
			# set module permissions
			chmod 644 anykernel_boeffla/modules/system/lib/modules/*
			# strip 'modules'
			${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/system/lib/modules/*
			echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
			cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip
			echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
			cd .. && rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
			echo -e $COLOR_GREEN"\n everything done... please visit 'release_boeffla'...\n"$COLOR_NEUTRAL
		else
			echo -e $COLOR_GREEN"\n Building error... zImage not found...\n"$COLOR_NEUTRAL
		fi
	else
		echo -e $COLOR_GREEN"\n '$KERNEL_VARIANT' is not a supported variant... please check...\n"$COLOR_NEUTRAL
	fi
fi
