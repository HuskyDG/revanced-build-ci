#!/usr/bin/env bash

CURDIR=$PWD
WGET_HEADER="User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:102.0) Gecko/20100101 Firefox/102.0"
MODULEPATH=$CURDIR/RevancedYT
YTVER=17.29.34
VERSIONCODE=180000005
SEND=$CURDIR/send.py

rm -rf $CURDIR/$YTVER.zip
rm -rf $CURDIR/RevancedYT_$YTVER.zip
rm -rf $MODULEPATH/youtube && mkdir -p $MODULEPATH/youtube
rm -rf $MODULEPATH/revanced.apk


clone() {
echo "Cleaning and Cloning $1"
rm -rf $3
URL=https://github.com/revanced
git clone --depth=1 $URL/$1 -b $2 $CURDIR/$3
}

req() {
    wget -q -O "$2" --header="$WGET_HEADER" "$1"
}

dl_yt() {
    echo "Downloading YouTube"
    url="https://www.apkmirror.com/apk/google-inc/youtube/youtube-${1//./-}-release/"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's/href="/@/g; s;.*APK</span>[^@]*@\([^#]*\).*;\1;p')"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    url="https://www.apkmirror.com$(req "$url" - | tr '\n' ' ' | sed -n 's;.*href="\(.*key=[^"]*\)">.*;\1;p')"
    req "$url" "$2"
}

dl_yt $YTVER $CURDIR/$YTVER.zip
#unzip -j -q $CURDIR/$YTVER.zip *.apk -d $MODULEPATH/youtube

clone revanced-patcher main revanced-patcher
clone revanced-patches main revanced-patches
clone revanced-cli main revanced-cli
clone revanced-integrations main revanced-integrations

cd $CURDIR/revanced-patcher && sh gradlew build
cd $CURDIR/revanced-patches && sh gradlew build
cd $CURDIR/revanced-cli && sh gradlew build
cd $CURDIR/revanced-integrations && sh gradlew build
PATCHER=`ls $CURDIR/revanced-patcher/build/libs/revanced-patcher-[0-9].[0-9]*.[0-9].jar`
PATCHES=`ls $CURDIR/revanced-patches/build/libs/revanced-patches-[0-9].[0-9]*.[0-9].jar`
CLI=`ls $CURDIR/revanced-cli/build/libs/revanced-cli-[0-9].[0-9]*.[0-9]-all.jar`
INTEG=`ls $CURDIR/revanced-integrations/app/build/outputs/apk/release/app-release-unsigned.apk`

SKIPPATCHES=$(cat $CURDIR/skippedpatches)
for SKIPPATCH in ${SKIPPATCHES[@]}; do
SKIP+=' -e '$SKIPPATCH
done

#java -jar $CLI -a $MODULEPATH/youtube/base.apk -o $MODULEPATH/revanced.apk -b $PATCHES -l
java -jar $CLI -a $MODULEPATH/youtube/base.apk -o $MODULEPATH/revanced.apk --keystore=$CURDIR/revanced.keystore -b $PATCHES -m $INTEG --experimental $SKIP || exit 1
#    -e  microg-support -e hide-infocard-suggestions -e hide-autoplay-button -e disable-create-button -e disable-fullscreen-panels \
#    -e hide-shorts-button -e hide-cast-button -e hide-cast-button -e custom-branding -e hide-watermark -e premium-heading

cd $CURDIR || exit 1

for file in $MODULEPATH/module.prop out/*; do
    sed -i "s/\${VERSION}/$YTVER/g" "$file"
    sed -i "s/\${VERSIONCODE}/$VERSIONCODE/g" "$file"
done

cd $MODULEPATH || exit 1
mkdir -p system/priv-app
mv -f youtube system/priv-app

# output
mkdir $CURDIR/out

zip -rv9 $CURDIR/out/revanced-magisk.zip *
