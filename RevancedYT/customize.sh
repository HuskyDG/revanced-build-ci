if ! $BOOTMODE; then
    abort "! Do not support installing from Recovery"
fi

MAGISKTMP="$(magisk --path)"
test -z "$MAGISKTMP" && MAGISKTMP=/sbin
YOUTUBE="system/priv-app/youtube"


stock_path=$( pm path com.google.android.youtube | grep base | sed 's/package://g' )

ABI=$(getprop ro.product.cpu.abi)
  if [ "$ABI" = "x86" ]; then
    ARCH=x86
    ABI32=x86
    IS64BIT=false
  elif [ "$ABI" = "arm64-v8a" ]; then
    ARCH=arm64
    ABI32=armeabi-v7a
    IS64BIT=true
  elif [ "$ABI" = "x86_64" ]; then
    ARCH=x64
    ABI32=x86
    IS64BIT=true
  else
    ABI=armeabi-v7a
    ARCH=arm
    ABI32=armeabi-v7a
    IS64BIT=false
  fi

if [ "$ABI" == "arm64-v8a" ]; then
    short_ABI=arm64
    ABI_APK=arm64_v8a
elif [ "$ABI" == "armeabi-v7a" ]; then
    short_ABI=arm
    ABI_APK=armeabi_v7a
else
    short_ABI="$ABI"
    ABI_APK="$ABI"
fi

ui_print "- System architecture: $ABI"


USERAPP="/data/app/"

VENDOR_PREFIX="/vendor/"
PRODUCT_PREFIX="/product"
SYSTEM_EXT_PREFIX="/system_ext"

# Remove Vanced Script
rm -rf /data/adb/vanced
rm -rf /data/adb/service.d/vanced.sh
rm -rf /data/adb/post-fs-data.d/vanced.sh

REPLACE="
/$YOUTUBE
"

stock_path=$( pm path com.google.android.youtube | grep base | sed 's/package://g' )

if [ "${stock_path: 0: ${#VENDOR_PREFIX}}" == "$VENDOR_PREFIX" ] || [ "${stock_path: 0: ${#PRODUCT_PREFIX}}" == "$PRODUCT_PREFIX" ] || [ "${stock_path: 0: ${#SYSTEM_EXT_PREFIX}}" == "$SYSTEM_EXT_PREFIX" ]; then
    stock_path="/system${stock_path}"
fi

if [ "${stock_path: 0: ${#USERAPP}}" != "$USERAPP" ] && [ "${stock_path%/*}" != "/system/app" ]; then
    REPLACE="$REPLACE
${stock_path%/*}
"
else
    abort "! Please uninstall updates for YouTube app and try again"
fi

cd "$MAGISKTMP/.magisk/modules/$MODID" && for replace in `find system -name ".replace"`; do
    REPLACE="$REPLACE
/${replace%/*}
"
done

mkdir -p "$MODPATH/$YOUTUBE/lib/$short_ABI"

ui_print "- Install necessary files"

unzip -oj "$MODPATH/$YOUTUBE/base.apk" lib/${ABI}/* -d "$MODPATH/$YOUTUBE/lib/$short_ABI" &>/dev/null

chmod -R 755 "$MODPATH/$YOUTUBE/lib/$short_ABI"

ln -sfT "./sqlite3_${ABI}" "$MODPATH/bin/sqlite3"

ui_print "- Welcome to Magisk Delta ~~"
