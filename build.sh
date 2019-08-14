#!/bin/bash

#set -e

DATE_POSTFIX=$(date +"%d%m%y%H%M")

## Copy this script inside the kernel directory
KERNEL_DIR=$PWD
KERNEL_TOOLCHAIN=$PWD/../aarch64-linux-android-4.9/bin
CLANG_TOOLCHAIN=$PWD/../android-9.0.6-clang/bin
KERNEL_DEFCONFIG=titan-stock_defconfig
ZIP_DIR=$PWD/../AnyKernel3/
SYSTEM_MOD=$PWD/../AnyKernel3/modules/system/lib/modules/
VENDOR_MOD=$PWD/../AnyKernel3/modules/vendor/lib/modules/qca_cld3
FINAL_KERNEL_ZIP=Titan_$DATE_POSTFIX.zip
FINAL_DIR=$PWD/../Kernel

BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
#red
R='\033[05;31m'
purple='\e[0;35m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

echo -e "$blue***********************************************"
echo -e "$R              BUILDING TITAN KERNEL            "
echo -e "$blue***********************************************"

echo -e "$yellow // Build Started!!!  //"

echo -e  "$cyan // Cleaning up //"
make clean && make mrproper && rm -rf out/
cd $ZIP_DIR && rm -rf Image.gz-dtb
cd modules/system/lib/modules/ && find . ! -name 'placeholder' -type f -exec rm -f {} + && rm -rf ../../../vendor/lib/modules/qca_cld3/qca_cld3_wlan.ko
cd $KERNEL_DIR

echo -e "$cyan // defconfig is set to $KERNEL_DEFCONFIG //$nocol"

make O=out ARCH=arm64 $KERNEL_DEFCONFIG

echo -e "$cyan // Compile Image //$nocol"

PATH="$CLANG_TOOLCHAIN:$KERNEL_TOOLCHAIN:${PATH}" make -j$(nproc --all) O=out ARCH=arm64 CC=clang CLANG_TRIPLE=aarch64-linux-gnu- CROSS_COMPILE=aarch64-linux-android-

echo -e "$cyan // Verify Compiling Output //$nocol"
ls -lia $KERNEL_DIR/out/arch/arm64/boot/

echo -e "$purple**** Copying Image.gz-dtb ****"
cp $KERNEL_DIR/out/arch/arm64/boot/Image.gz-dtb $ZIP_DIR

echo -e "$purple**** Copying Modules ****"
[ -e "$KERNEL_DIR/out/block/test-iosched.ko" ] && cp $KERNEL_DIR/out/block/test-iosched.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/char/rdbg.ko" ] && cp $KERNEL_DIR/out/drivers/char/rdbg.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/media/platform/msm/dvb/adapter/mpq-adapter.ko" ] && cp $KERNEL_DIR/out/drivers/media/platform/msm/dvb/adapter/mpq-adapter.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/media/platform/msm/dvb/demux/mpq-dmx-hw-plugin.ko" ] && cp $KERNEL_DIR/out/drivers/media/platform/msm/dvb/demux/mpq-dmx-hw-plugin.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/media/usb/gspca/gspca_main.ko" ] && cp $KERNEL_DIR/out/drivers/media/usb/gspca/gspca_main.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/net/wireless/ath/wil6210/wil6210.ko" ] && cp $KERNEL_DIR/out/drivers/net/wireless/ath/wil6210/wil6210.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/platform/msm/msm_11ad/msm_11ad_proxy.ko" ] && cp $KERNEL_DIR/out/drivers/platform/msm/msm_11ad/msm_11ad_proxy.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/scsi/ufs/ufs_test.ko" ] && cp $KERNEL_DIR/out/drivers/scsi/ufs/ufs_test.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/net/bridge/br_netfilter.ko" ] && cp $KERNEL_DIR/out/net/bridge/br_netfilter.ko $SYSTEM_MOD || echo "module not found"
[ -e "$KERNEL_DIR/out/drivers/staging/qcacld-3.0/wlan.ko" ] && cp $KERNEL_DIR/out/drivers/staging/qcacld-3.0/wlan.ko $VENDOR_MOD/qca_cld3_wlan.ko || echo "module not found"

echo -e "$cyan // Verifying zip Directory //$nocol"
ls -lia $ZIP_DIR
ls -lia $SYSTEM_MOD
ls -lia $VENDOR_MOD

echo -e "$purple**** Time to zip up! ****$nocol"
cd $ZIP_DIR
zip -r9 $FINAL_KERNEL_ZIP * -x .git README.md *placeholder anykernel.sh.bk
mv $FINAL_KERNEL_ZIP $FINAL_DIR

echo -e "$cyan // Show Kernel Zip //$nocol"
ls -lia $FINAL_DIR

echo -e "$yellow // Build Successfull!!!  //"
cd $KERNEL_DIR
rm -rf $KERNEL_DIR/out/

BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
echo -e "$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
