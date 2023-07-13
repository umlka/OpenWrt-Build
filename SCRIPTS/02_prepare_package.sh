#!/bin/bash

### 基础部分 ###
# 移除 SNAPSHOT 标签
sed -i 's/-SNAPSHOT//g' ./include/version.mk
sed -i 's/-SNAPSHOT//g' ./package/base-files/image-config.in
# 维多利亚的秘密
echo "net.netfilter.nf_conntrack_helper=1" >> ./package/kernel/linux/files/sysctl-nf-conntrack.conf

### 必备补丁 ###
# TCP performance optimizations backport from linux/net-next
cp -f ../PATCH/backport/TCP/* ./target/linux/generic/backport-5.15/
# x86_csum
cp -f ../PATCH/backport/x86_csum/* ./target/linux/generic/backport-5.15/
# fstools
wget -qO - https://github.com/immortalwrt/immortalwrt/commit/19f355e.patch | patch -p1

### Fullcone ###
# Patch Kernel 以解决 FullCone 冲突
cp -f ../lede/target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch ./target/linux/generic/hack-5.15/952-add-net-conntrack-events-support-multiple-registrant.patch
# Patch FireWall 以增添 FullCone 功能
# FW4
rm -rf ./package/network/config/firewall4
cp -rf ../immortalwrt/package/network/config/firewall4 ./package/network/config/firewall4
cp -f ../PATCH/firewall/990-unconditionally-allow-ct-status-dnat.patch ./package/network/config/firewall4/patches/990-unconditionally-allow-ct-status-dnat.patch
rm -rf ./package/libs/libnftnl
cp -rf ../immortalwrt/package/libs/libnftnl ./package/libs/libnftnl
rm -rf ./package/network/utils/nftables
cp -rf ../immortalwrt/package/network/utils/nftables ./package/network/utils/nftables
# network
wget -qO - https://github.com/openwrt/openwrt/commit/bbf39d07.patch | patch -p1
# Patch LuCI 以增添 FullCone 开关
patch -p1 < ../PATCH/firewall/luci-app-firewall_add_fullcone.patch
# FullCone PKG
git clone -b master --depth 1 https://github.com/fullcone-nat-nftables/nft-fullcone.git ./package/new/nft-fullcone

### 基础软件包 ###
# Golang
rm -rf ./feeds/packages/lang/golang
cp -rf ../openwrt_pkg_ma/lang/golang ./feeds/packages/lang/golang
# NIC drivers
git clone -b master --depth 1 https://github.com/sbwml/package_kernel_r8101.git ./package/new/r8101
git clone -b master --depth 1 https://github.com/sbwml/package_kernel_r8125.git ./package/new/r8125
git clone -b master --depth 1 https://github.com/sbwml/package_kernel_r8152.git ./package/new/r8152
git clone -b master --depth 1 https://github.com/sbwml/package_kernel_r8168.git ./package/new/r8168
cp -f ../lede/target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch ./target/linux/x86/patches-5.15/996-intel-igc-i225-i226-disable-eee.patch

### 额外的应用 ###
# autocore
cp -rf ../immortalwrt_23/package/emortal/autocore ./package/new/autocore
rm -rf ./feeds/luci/modules/luci-base
cp -rf ../immortalwrt_luci_23/modules/luci-base ./feeds/luci/modules/luci-base
#sed -i "s/(br-lan)//g" ./feeds/luci/modules/luci-base/root/usr/share/rpcd/ucode/luci
rm -rf ./feeds/luci/modules/luci-mod-status
cp -rf ../immortalwrt_luci_23/modules/luci-mod-status ./feeds/luci/modules/luci-mod-status
# autoreboot
rm -rf ./feeds/luci/applications/luci-app-autoreboot
cp -rf ../immortalwrt_luci/applications/luci-app-autoreboot ./feeds/luci/applications/luci-app-autoreboot
ln -sf ../../../feeds/luci/applications/luci-app-autoreboot ./package/feeds/luci/luci-app-autoreboot
# ddns
sed -i '/boot()/,+2d' ./feeds/packages/net/ddns-scripts/files/etc/init.d/ddns
svn export https://github.com/sbwml/openwrt_pkgs/trunk/ddns-scripts-aliyun ./package/new/ddns-scripts-aliyun
# homeproxy
rm -rf ./feeds/packages/net/sing-box
cp -rf ../immortalwrt_pkg/net/sing-box ./feeds/packages/net/sing-box
ln -sf ../../../feeds/packages/net/sing-box ./package/feeds/packages/sing-box
rm -rf ./feeds/packages/net/chinadns-ng
cp -rf ../immortalwrt_pkg/net/chinadns-ng ./feeds/packages/net/chinadns-ng
ln -sf ../../../feeds/packages/net/chinadns-ng ./package/feeds/packages/chinadns-ng
rm -rf ./feeds/luci/applications/luci-app-homeproxy
git clone -b dev --depth 1 https://github.com/immortalwrt/homeproxy.git ./package/new/homeproxy
sed -i 's/ImmortalWrt/OpenWrt/g' ./package/new/homeproxy/po/zh_Hans/homeproxy.po
sed -i 's/ImmortalWrt proxy/OpenWrt proxy/g' ./package/new/homeproxy/htdocs/luci-static/resources/view/homeproxy/{client.js,server.js}
# upnp
rm -rf ./feeds/packages/net/miniupnpd
cp -rf ../openwrt_pkg_ma/net/miniupnpd ./feeds/packages/net/miniupnpd
sed -i 's/services/network/g' ./feeds/luci/applications/luci-app-upnp/root/usr/share/luci/menu.d/luci-app-upnp.json
# ramfree
rm -rf ./feeds/luci/applications/luci-app-ramfree
cp -rf ../immortalwrt_luci/applications/luci-app-ramfree ./feeds/luci/applications/luci-app-ramfree
ln -sf ../../../feeds/luci/applications/luci-app-ramfree ./package/feeds/luci/luci-app-ramfree
# vlmcsd
rm -rf ./feeds/packages/net/vlmcsd
cp -rf ../immortalwrt_pkg/net/vlmcsd ./feeds/packages/net/vlmcsd
ln -sf ../../../feeds/packages/net/vlmcsd ./package/feeds/packages/vlmcsd
rm -rf ./feeds/luci/applications/luci-app-vlmcsd
cp -rf ../immortalwrt_luci/applications/luci-app-vlmcsd ./feeds/luci/applications/luci-app-vlmcsd
ln -sf ../../../feeds/luci/applications/luci-app-vlmcsd ./package/feeds/luci/luci-app-vlmcsd

### 修改默认配置 ###
rm -f .config
sed -i 's/CONFIG_WERROR=y/# CONFIG_WERROR is not set/g' ./target/linux/generic/config-5.15

