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
# 1. Properly locate toolchain (Line# 44)
# 2. Set 'KERNEL_VARIANT' (Line# 40).
# 3. To build all the supported variants, set 'KERNEL_VARIANT' to "all"
# 4. Open Terminal, ‘cd’ to the Kernel ‘root’ folder and run ‘. build_boeffla.sh’
# 5. The output (anykernel zip) file will be generated in the ‘release_boeffla’ folder
# 6. Enjoy your new Kernel
#
# ***** ***** *Variables to be configured manually* ***** ***** #
# 

KERNEL_NAME="Boeffla-Kernel"

KERNEL_VARIANT="kltekor" # options: klte, kltekor, klteduos & all (build all the variants)

KERNEL_VERSION="beta-v8"

TOOLCHAIN="/home/sunil/UBERTC-arm-eabi-8.0/bin/arm-linux-androideabi-"

ARCHITECTURE="arm"

NUM_CPUS=""   # number of cpu cores used for build (leave empty for auto detection)

KERNEL_DEFCONFIG="Boeffla_@$KERNEL_VARIANT@_defconfig"

COMPILE_DTB="y"

PREPARE_MODULES=""

PREPARE_RELEASE=""

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

if [ "all" == "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME $KERNEL_VERSION for all the supported variants...\n"$COLOR_NEUTRAL
	# kltekor
	if [ -e output_kltekor/ ]; then
		if [ -e output_kltekor/.config ]; then
			rm -f output_kltekor/.config
			if [ -e output_kltekor/arch/arm/boot/zImage ]; then
				rm -f output_kltekor/arch/arm/boot/zImage
			fi
		fi
	else
		mkdir output_kltekor
	fi
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME $KERNEL_VERSION for kltekor\n"$COLOR_NEUTRAL
	make -C $(pwd) O=output_kltekor CFLAGS_KERNEL="$COMPILER_FLAGS_KERNEL" CFLAGS_MODULE="$COMPILER_FLAGS_MODULE" Boeffla_@kltekor@_defconfig 
	# updating kernel version
	sed -i "s;lineageos;$KERNEL_VERSION;" output_kltekor/.config;
	make -j$NUM_CPUS -C $(pwd) O=output_kltekor
	if [ -e output_kltekor/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_kltekor/arch/arm/boot/zImage anykernel_boeffla/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb) for kltekor\n"$COLOR_NEUTRAL
			if [ -f output_kltekor/arch/arm/boot/dt.img ]; then
				rm -f output_kltekor/arch/arm/boot/dt.img
			fi
			chmod 777 tools_boeffla/dtbToolCM
			tools_boeffla/dtbToolCM -2 -o output_kltekor/arch/arm/boot/dt.img -s 2048 -p output_kltekor/scripts/dtc/ output_kltekor/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel_boeffla/dtb ]; then
				rm -f anykernel_boeffla/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_kltekor/arch/arm/boot/dt.img ]; then
				mv -f output_kltekor/arch/arm/boot/dt.img anykernel_boeffla/dtb
			fi
		fi
		# prepare modules if required
		if [ "y" == "$PREPARE_MODULES" ]; then
			# check and create 'modules' folder.
			if [ ! -d "anykernel_boeffla/modules/" ]; then
				mkdir anykernel_boeffla/modules/
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/" ]; then
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/modules/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			fi
			if [ -z "$(ls -A anykernel_boeffla/modules/system/vendor/lib/modules/)" ]; then
				echo -e $COLOR_GREEN"\n “Preparing "modules" folder...\n"$COLOR_NEUTRAL
			else
				rm -r anykernel_boeffla/modules/system/vendor/lib/modules/*
			fi
			echo -e $COLOR_GREEN"\n copying generated 'modules'\n"$COLOR_NEUTRAL
			find output_$KERNEL_VARIANT -name '*.ko' -exec cp -av {} anykernel_boeffla/modules/system/vendor/lib/modules \;
			# set module permissions
			chmod 644 anykernel_boeffla/modules/system/vendor/lib/modules/*
			# strip 'modules'
			${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/system/vendor/lib/modules/*
		fi
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-kltekor-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-kltekor-$KERNEL_VERSION-$KERNEL_DATE.zip
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		cd .. 
		# check and create release folder
		if [ ! -d "release_boeffla/" ]; then
			mkdir release_boeffla/
		fi
		rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
		echo -e $COLOR_GREEN"\n Preparing for kernel release\n"$COLOR_NEUTRAL
		cp release_boeffla/$KERNEL_NAME-kltekor-$KERNEL_VERSION-$KERNEL_DATE.zip kernel-release/$KERNEL_NAME-kltekor.zip
	else
		echo -e $COLOR_RED"\n Building for kltekor is failed. Please fix the issues and try again...\n"$COLOR_NEUTRAL
	fi
	# klte
	if [ -e output_klte/ ]; then
		if [ -e output_klte/.config ]; then
			rm -f output_klte/.config
			if [ -e output_klte/arch/arm/boot/zImage ]; then
				rm -f output_klte/arch/arm/boot/zImage
			fi
		fi
	else
		mkdir output_klte
	fi
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME $KERNEL_VERSION for klte\n"$COLOR_NEUTRAL
	make -C $(pwd) O=output_klte CFLAGS_KERNEL="$COMPILER_FLAGS_KERNEL" CFLAGS_MODULE="$COMPILER_FLAGS_MODULE" Boeffla_@klte@_defconfig 
	# updating kernel version
	sed -i "s;lineageos;$KERNEL_VERSION;" output_klte/.config;
	make -j$NUM_CPUS -C $(pwd) O=output_klte
	if [ -e output_klte/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_klte/arch/arm/boot/zImage anykernel_boeffla/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb) for klte\n"$COLOR_NEUTRAL
			if [ -f output_klte/arch/arm/boot/dt.img ]; then
				rm -f output_klte/arch/arm/boot/dt.img
			fi
			chmod 777 tools_boeffla/dtbToolCM
			tools_boeffla/dtbToolCM -2 -o output_klte/arch/arm/boot/dt.img -s 2048 -p output_klte/scripts/dtc/ output_klte/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel_boeffla/dtb ]; then
				rm -f anykernel_boeffla/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_klte/arch/arm/boot/dt.img ]; then
				mv -f output_klte/arch/arm/boot/dt.img anykernel_boeffla/dtb
			fi
		fi
		# prepare modules if required
		if [ "y" == "$PREPARE_MODULES" ]; then
			# check and create 'modules' folder.
			if [ ! -d "anykernel_boeffla/modules/" ]; then
				mkdir anykernel_boeffla/modules/
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/" ]; then
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/modules/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			fi
			if [ -z "$(ls -A anykernel_boeffla/modules/system/vendor/lib/modules/)" ]; then
				echo -e $COLOR_GREEN"\n “Preparing "modules" folder...\n"$COLOR_NEUTRAL
			else
				rm -r anykernel_boeffla/modules/system/vendor/lib/modules/*
			fi
			echo -e $COLOR_GREEN"\n copying generated 'modules'\n"$COLOR_NEUTRAL
			find output_$KERNEL_VARIANT -name '*.ko' -exec cp -av {} anykernel_boeffla/modules/system/vendor/lib/modules \;
			# set module permissions
			chmod 644 anykernel_boeffla/modules/system/vendor/lib/modules/*
			# strip 'modules'
			${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/system/vendor/lib/modules/*
		fi
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-klte-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-klte-$KERNEL_VERSION-$KERNEL_DATE.zip
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		cd .. 
		# check and create release folder
		if [ ! -d "release_boeffla/" ]; then
			mkdir release_boeffla/
		fi
		rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
		echo -e $COLOR_GREEN"\n Preparing for kernel release\n"$COLOR_NEUTRAL
		cp release_boeffla/$KERNEL_NAME-klte-$KERNEL_VERSION-$KERNEL_DATE.zip kernel-release/$KERNEL_NAME-klte.zip
	else
		echo -e $COLOR_RED"\n Building for klte is failed. Please fix the issues and try again...\n"$COLOR_NEUTRAL
	fi
	# klteduos
	if [ -e output_klteduos/ ]; then
		if [ -e output_klteduos/.config ]; then
			rm -f output_klteduos/.config
			if [ -e output_klteduos/arch/arm/boot/zImage ]; then
				rm -f output_klteduos/arch/arm/boot/zImage
			fi
		fi
	else
		mkdir output_klteduos
	fi
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME $KERNEL_VERSION for klteduos\n"$COLOR_NEUTRAL
	make -C $(pwd) O=output_klteduos CFLAGS_KERNEL="$COMPILER_FLAGS_KERNEL" CFLAGS_MODULE="$COMPILER_FLAGS_MODULE" Boeffla_@klteduos@_defconfig 
	# updating kernel version
	sed -i "s;lineageos;$KERNEL_VERSION;" output_klteduos/.config;
	make -j$NUM_CPUS -C $(pwd) O=output_klteduos
	if [ -e output_klteduos/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_klteduos/arch/arm/boot/zImage anykernel_boeffla/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb) for klteduos\n"$COLOR_NEUTRAL
			if [ -f output_klteduos/arch/arm/boot/dt.img ]; then
				rm -f output_klteduos/arch/arm/boot/dt.img
			fi
			chmod 777 tools_boeffla/dtbToolCM
			tools_boeffla/dtbToolCM -2 -o output_klteduos/arch/arm/boot/dt.img -s 2048 -p output_klteduos/scripts/dtc/ output_klteduos/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel_boeffla/dtb ]; then
				rm -f anykernel_boeffla/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_klteduos/arch/arm/boot/dt.img ]; then
				mv -f output_klteduos/arch/arm/boot/dt.img anykernel_boeffla/dtb
			fi
		fi
		# prepare modules if required
		if [ "y" == "$PREPARE_MODULES" ]; then
			# check and create 'modules' folder.
			if [ ! -d "anykernel_boeffla/modules/" ]; then
				mkdir anykernel_boeffla/modules/
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/" ]; then
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/modules/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			fi
			if [ -z "$(ls -A anykernel_boeffla/modules/system/vendor/lib/modules/)" ]; then
				echo -e $COLOR_GREEN"\n “Preparing "modules" folder...\n"$COLOR_NEUTRAL
			else
				rm -r anykernel_boeffla/modules/system/vendor/lib/modules/*
			fi
			echo -e $COLOR_GREEN"\n copying generated 'modules'\n"$COLOR_NEUTRAL
			find output_$KERNEL_VARIANT -name '*.ko' -exec cp -av {} anykernel_boeffla/modules/system/vendor/lib/modules \;
			# set module permissions
			chmod 644 anykernel_boeffla/modules/system/vendor/lib/modules/*
			# strip 'modules'
			${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/system/vendor/lib/modules/*
		fi
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-klteduos-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-klteduos-$KERNEL_VERSION-$KERNEL_DATE.zip
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		cd .. 
		# check and create release folder
		if [ ! -d "release_boeffla/" ]; then
			mkdir release_boeffla/
		fi
		rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
		echo -e $COLOR_GREEN"\n Preparing for kernel release\n"$COLOR_NEUTRAL
		cp release_boeffla/$KERNEL_NAME-klteduos-$KERNEL_VERSION-$KERNEL_DATE.zip kernel-release/$KERNEL_NAME-klteduos.zip
		echo -e $COLOR_GREEN"\n everything done... please visit 'release_boeffla'...\n"$COLOR_NEUTRAL
	else
		echo -e $COLOR_RED"\n Building for klteduos is failed. Please fix the issues and try again...\n"$COLOR_NEUTRAL
	fi
elif [ -z "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n Please select the variant to build... KERNEL_VARIANT should not be empty...\n"$COLOR_NEUTRAL
elif [ -e arch/arm/configs/$KERNEL_DEFCONFIG ]; then
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
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME $KERNEL_VERSION for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
	make -C $(pwd) O=output_$KERNEL_VARIANT CFLAGS_KERNEL="$COMPILER_FLAGS_KERNEL" CFLAGS_MODULE="$COMPILER_FLAGS_MODULE" $KERNEL_DEFCONFIG 
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
		# prepare modules if required
		if [ "y" == "$PREPARE_MODULES" ]; then
			# check and create 'modules' folder.
			if [ ! -d "anykernel_boeffla/modules/" ]; then
				mkdir anykernel_boeffla/modules/
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/" ]; then
				mkdir anykernel_boeffla/modules/system/
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			elif [ ! -d "anykernel_boeffla/modules/system/vendor/lib/modules/" ]; then
				mkdir anykernel_boeffla/modules/system/vendor/lib/modules/
			fi
			if [ -z "$(ls -A anykernel_boeffla/modules/system/vendor/lib/modules/)" ]; then
				echo -e $COLOR_GREEN"\n “Preparing "modules" folder...\n"$COLOR_NEUTRAL
			else
				rm -r anykernel_boeffla/modules/system/vendor/lib/modules/*
			fi
			echo -e $COLOR_GREEN"\n copying generated 'modules'\n"$COLOR_NEUTRAL
			find output_$KERNEL_VARIANT -name '*.ko' -exec cp -av {} anykernel_boeffla/modules/system/vendor/lib/modules \;
			# set module permissions
			chmod 644 anykernel_boeffla/modules/system/vendor/lib/modules/*
			# strip 'modules'
			${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/system/vendor/lib/modules/*
		fi
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		cd .. 
		# check and create release folder
		if [ ! -d "release_boeffla/" ]; then
			mkdir release_boeffla/
		fi
		rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
		if [ "y" == "$PREPARE_RELEASE" ]; then
			echo -e $COLOR_GREEN"\n Preparing for kernel release\n"$COLOR_NEUTRAL
			cp release_boeffla/$KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip kernel-release/$KERNEL_NAME-$KERNEL_VARIANT.zip
		fi
		echo -e $COLOR_GREEN"\n Building for $KERNEL_VARIANT finished... please visit 'release_boeffla'...\n"$COLOR_NEUTRAL
	else
		echo -e $COLOR_GREEN"\n Building for $KERNEL_VARIANT is failed. Please fix the issues and try again...\n"$COLOR_NEUTRAL
	fi
else
	echo -e $COLOR_GREEN"\n '$KERNEL_VARIANT' is not a supported variant... please check...\n"$COLOR_NEUTRAL
fi
