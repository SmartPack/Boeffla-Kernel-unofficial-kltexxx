#!/bin/bash

COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[1;32m"
COLOR_NEUTRAL="\033[0m"

# Boeffla-Kernel (unofficial) Build Script
#
# (c) sunilpaulmathew@xda-developers.com

KERNEL_NAME="Boeffla-Kernel"

KERNEL_VARIANT="kltekor"

KERNEL_VERSION="unofficial"

KERNEL_DATE="$(date +"%Y%m%d")"

COMPILE_DTB="y"

TOOLCHAIN="/home/sunil/android-ndk-r15c/toolchains/arm-linux-androideabi-4.9/prebuilt/linux-x86_64/bin/arm-linux-androideabi-"
ARCHITECTURE="arm"

COMPILER_FLAGS_KERNEL="-Wno-maybe-uninitialized -Wno-array-bounds"
COMPILER_FLAGS_MODULE="-Wno-maybe-uninitialized -Wno-array-bounds"

NUM_CPUS=""   # number of cpu cores used for build (leave empty for auto detection)

export ARCH=$ARCHITECTURE
export CROSS_COMPILE="${CCACHE} $TOOLCHAIN"

if [ -z "$NUM_CPUS" ]; then
	NUM_CPUS=`grep -c ^processor /proc/cpuinfo`
fi

if [ -z "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n Please select the variant to build... KERNEL_VARIANT should not be empty...\n"$COLOR_NEUTRAL
fi

if [ "kltekor" == "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
	if [ -e output_kor/.config ]; then
		rm -f output_kor/.config
		if [ -e output_kor/arch/arm/boot/zImage ]; then
			rm -f output_kor/arch/arm/boot/zImage
		fi
	else
	mkdir output_kor
	fi
	make -C $(pwd) O=output_kor arch=arm boeffla_kltekor_defconfig && make -j$NUM_CPUS -C $(pwd) O=output_kor
	if [ -e output_kor/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_kor/arch/arm/boot/zImage anykernel_boeffla/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb) for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
			if [ -f output_kor/arch/arm/boot/dt.img ]; then
				rm -f output_kor/arch/arm/boot/dt.img
			fi
			chmod 777 tools_boeffla/dtbToolCM
			tools_boeffla/dtbToolCM -2 -o output_kor/arch/arm/boot/dt.img -s 2048 -p output_kor/scripts/dtc/ output_kor/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel_boeffla/dtb ]; then
				rm -f anykernel_boeffla/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_kor/arch/arm/boot/dt.img ]; then
				mv -f output_kor/arch/arm/boot/dt.img anykernel_boeffla/dtb
			fi
		fi
		echo -e $COLOR_GREEN"\n copying generated modules\n"$COLOR_NEUTRAL
		rm -r anykernel_boeffla/modules/
		mkdir anykernel_boeffla/modules/
		find output_kor -name '*.ko' -exec cp -av {} anykernel_boeffla/modules \;
		# set module permissions
		chmod 644 anykernel_boeffla/modules/*
		# strip modules
		${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/*
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		cd .. && rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && rm -r anykernel_boeffla/modules/ && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
		echo -e $COLOR_GREEN"\n building $KERNEL_NAME for $KERNEL_VARIANT finished... please visit 'release_boeffla'...\n"$COLOR_NEUTRAL
	else
		echo -e $COLOR_GREEN"\n Building error... zImage not found...\n"$COLOR_NEUTRAL
	fi
fi

if [ "klte" == "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
	if [ -e output_eur/.config ]; then
		rm -f output_eur/.config
		if [ -e output_eur/arch/arm/boot/zImage ]; then
			rm -f output_eur/arch/arm/boot/zImage
		fi
	else
	mkdir output_eur
	fi
	make -C $(pwd) O=output_eur arch=arm boeffla_klte_defconfig && make -j$NUM_CPUS -C $(pwd) O=output_eur
	if [ -e output_eur/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_eur/arch/arm/boot/zImage anykernel_boeffla/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb) for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
			if [ -f output_eur/arch/arm/boot/dt.img ]; then
				rm -f output_eur/arch/arm/boot/dt.img
			fi
			chmod 777 tools_boeffla/dtbToolCM
			tools_boeffla/dtbToolCM -2 -o output_eur/arch/arm/boot/dt.img -s 2048 -p output_eur/scripts/dtc/ output_eur/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel_boeffla/dtb ]; then
				rm -f anykernel_boeffla/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_eur/arch/arm/boot/dt.img ]; then
				mv -f output_eur/arch/arm/boot/dt.img anykernel_boeffla/dtb
			fi
		fi
		echo -e $COLOR_GREEN"\n copying generated modules\n"$COLOR_NEUTRAL
		rm -r anykernel_boeffla/modules/
		mkdir anykernel_boeffla/modules/
		find output_eur -name '*.ko' -exec cp -av {} anykernel_boeffla/modules \;
		# set module permissions
		chmod 644 anykernel_boeffla/modules/*
		# strip modules
		${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/*
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		cd .. && rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && rm -r anykernel_boeffla/modules/ && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
		echo -e $COLOR_GREEN"\n building $KERNEL_NAME for $KERNEL_VARIANT finished... please visit 'release_boeffla'...\n"$COLOR_NEUTRAL
	else
		echo -e $COLOR_GREEN"\n Building error... zImage not found...\n"$COLOR_NEUTRAL
	fi
fi

if [ "kltekdi" == "$KERNEL_VARIANT" ]; then
	echo -e $COLOR_GREEN"\n building $KERNEL_NAME for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
	if [ -e output_kdi/.config ]; then
		rm -f output_kdi/.config
		if [ -e output_kdi/arch/arm/boot/zImage ]; then
			rm -f output_kdi/arch/arm/boot/zImage
		fi
	else
	mkdir output_kdi
	fi
	make -C $(pwd) O=output_kdi arch=arm boeffla_kltekdi_defconfig && make -j$NUM_CPUS -C $(pwd) O=output_kdi
	if [ -e output_kdi/arch/arm/boot/zImage ]; then
		echo -e $COLOR_GREEN"\n copying zImage to anykernel directory\n"$COLOR_NEUTRAL
		cp output_kdi/arch/arm/boot/zImage anykernel_boeffla/
		# compile dtb if required
		if [ "y" == "$COMPILE_DTB" ]; then
			echo -e $COLOR_GREEN"\n compiling device tree blob (dtb) for $KERNEL_VARIANT\n"$COLOR_NEUTRAL
			if [ -f output_kdi/arch/arm/boot/dt.img ]; then
				rm -f output_kdi/arch/arm/boot/dt.img
			fi
			chmod 777 tools_boeffla/dtbToolCM
			tools_boeffla/dtbToolCM -2 -o output_kdi/arch/arm/boot/dt.img -s 2048 -p output_kdi/scripts/dtc/ output_kdi/arch/arm/boot/
			# removing old dtb (if any)
			if [ -f anykernel_boeffla/dtb ]; then
				rm -f anykernel_boeffla/dtb
			fi
			# copying generated dtb to anykernel directory
			if [ -e output_kdi/arch/arm/boot/dt.img ]; then
				mv -f output_kdi/arch/arm/boot/dt.img anykernel_boeffla/dtb
			fi
		fi
		echo -e $COLOR_GREEN"\n copying generated modules\n"$COLOR_NEUTRAL
		rm -r anykernel_boeffla/modules/
		mkdir anykernel_boeffla/modules/
		find output_kdi -name '*.ko' -exec cp -av {} anykernel_boeffla/modules \;
		# set module permissions
		chmod 644 anykernel_boeffla/modules/*
		# strip modules
		${TOOLCHAIN}strip --strip-unneeded anykernel_boeffla/modules/*
		echo -e $COLOR_GREEN"\n generating recovery flashable zip file\n"$COLOR_NEUTRAL
		cd anykernel_boeffla/ && zip -r9 $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip * -x README.md $KERNEL_NAME-$KERNEL_VARIANT-$KERNEL_VERSION-$KERNEL_DATE.zip
		echo -e $COLOR_GREEN"\n cleaning...\n"$COLOR_NEUTRAL
		cd .. && rm anykernel_boeffla/zImage && rm anykernel_boeffla/dtb && rm -r anykernel_boeffla/modules/ && mv anykernel_boeffla/$KERNEL_NAME-* release_boeffla/
		echo -e $COLOR_GREEN"\n building $KERNEL_NAME for $KERNEL_VARIANT finished... please visit 'release_boeffla'...\n"$COLOR_NEUTRAL
	else
		echo -e $COLOR_GREEN"\n Building error... zImage not found...\n"$COLOR_NEUTRAL
	fi
fi
