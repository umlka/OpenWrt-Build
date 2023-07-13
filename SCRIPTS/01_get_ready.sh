#!/bin/bash

# Clone source code
latest_release="$(curl -s https://github.com/openwrt/openwrt/tags | grep -Eo "v[0-9\.]+\-*r*c*[0-9]*\.tar\.gz" | sed -n '/[2-9][3-9]/p' | sed -n 1p | sed 's/\.tar\.gz//g')"
git clone --single-branch -b "${latest_release}" https://github.com/openwrt/openwrt openwrt
git clone --single-branch -b openwrt-23.05 https://github.com/openwrt/openwrt openwrt_snap
find openwrt/package/* -maxdepth 0 ! -name 'firmware' ! -name 'kernel' ! -name 'base-files' ! -name 'Makefile' -exec rm -rf {} +
rm -rf ./openwrt_snap/package/firmware ./openwrt_snap/package/kernel ./openwrt_snap/package/base-files ./openwrt_snap/package/Makefile
cp -rf ./openwrt_snap/package/* ./openwrt/package/
cp -rf ./openwrt_snap/feeds.conf.default ./openwrt/feeds.conf.default

# Clone packages
git clone -b master --depth 1 https://github.com/openwrt/packages.git openwrt_pkg_ma
git clone -b master --depth 1 https://github.com/immortalwrt/immortalwrt.git immortalwrt
git clone -b openwrt-23.05 --depth 1 https://github.com/immortalwrt/immortalwrt.git immortalwrt_23
git clone -b master --depth 1 https://github.com/immortalwrt/packages.git immortalwrt_pkg
git clone -b master --depth 1 https://github.com/immortalwrt/luci.git immortalwrt_luci
git clone -b openwrt-23.05 --depth 1 https://github.com/immortalwrt/luci.git immortalwrt_luci_23
git clone -b master --depth 1 https://github.com/coolsnowwolf/lede.git lede
git clone -b main --depth 1 https://github.com/umlka/openwrt-packages.git openwrt-packages

exit 0
