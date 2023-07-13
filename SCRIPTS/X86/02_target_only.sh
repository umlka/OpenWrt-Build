#!/bin/bash

### GCC CFlags ###
sed -i 's/Os/O2 -march=x86-64-v2/g' ./include/target.mk

### LTO/GC ###
# Grub 2
sed -i 's/no-lto/no-lto no-gc-sections/g' ./package/boot/grub2/Makefile
# openssl
sed -i 's/no-mips16 gc-sections/no-mips16 gc-sections no-lto/g' ./package/libs/openssl/Makefile
# nginx
sed -i 's/gc-sections/gc-sections no-lto/g' ./feeds/packages/net/nginx/Makefile

### 内核版本修改 ###
sed -i 's/^\(KERNEL_PATCHVER:=\)[0-9]\+\.[0-9]\+$/\15.15/' ./target/linux/x86/Makefile

### 翻译功能优化 ###
cp -rf ../PATCH/duplicate/addition-trans-zh-x86 ./package/new/addition-trans-zh

### 型号显示修复 ###
sed -i '/^exit 0/i\[ $? -eq 0 ] && echo "Compatible PC" > \/tmp\/sysinfo\/model' ./package/base-files/files/etc/rc.local

### 启用 Backlog Threaded ###
sed -i '/^exit 0/i\echo "1" > \/proc\/sys\/net\/core\/backlog_threaded' ./package/base-files/files/etc/rc.local

### 平台补丁 ###
# cloudflare
cp -f ../PATCH/cloudflare/996-audit-check-syscall-bitmap-on-entry-to-avoid-extra-w.patch ./target/linux/x86/patches-5.15/996-audit-check-syscall-bitmap-on-entry-to-avoid-extra-w.patch
cp -f ../PATCH/cloudflare/997-add-a-sysctl-to-enable-disable-tcp_collapse-logic.patch ./target/linux/x86/patches-5.15/997-add-a-sysctl-to-enable-disable-tcp_collapse-logic.patch
cp -f ../PATCH/cloudflare/998-Add-a-sysctl-to-allow-TCP-window-shrinking-in-order-.patch ./target/linux/x86/patches-5.15/998-Add-a-sysctl-to-allow-TCP-window-shrinking-in-order-.patch
cp -f ../PATCH/cloudflare/999-Add-xtsproxy-Crypto-API-module.patch ./target/linux/x86/patches-5.15/999-Add-xtsproxy-Crypto-API-module.patch
sed -i '/CONFIG_CRYPTO_XTS_AES_SYNC/d' ./target/linux/x86/64/config-5.15
echo "CONFIG_CRYPTO_XTS_AES_SYNC=y" >> ./target/linux/x86/64/config-5.15

### Disable mitigations ###
sed -i 's/noinitrd/noinitrd mitigations=off/g' ./target/linux/x86/image/grub-efi.cfg
sed -i 's/noinitrd/noinitrd mitigations=off/g' ./target/linux/x86/image/grub-iso.cfg
sed -i 's/noinitrd/noinitrd mitigations=off/g' ./target/linux/x86/image/grub-pc.cfg

### Match Vermagic ###
latest_release="$(git describe --abbrev=0 --tags | sed 's/^v\(.*\)/\1/')"
kenrel_vermagic="$(curl -s https://downloads.openwrt.org/releases/${latest_release}/targets/x86/64/packages/Packages | awk -F '[- =)]+' '/^Depends: kernel/{for(i=3;i<=NF;i++){if(length($i)==32){print $i;exit}}}')"
echo "${kenrel_vermagic}" > .vermagic
sed -ie 's/^\(.\).*vermagic$/\1cp $(TOPDIR)\/.vermagic $(LINUX_DIR)\/.vermagic/' ./include/kernel-defaults.mk

### 额外的应用 ###
# dae
if [ "${1}" = "1" ]; then
	# pkg
	rm -rf ./feeds/packages/net/dae
	cp -rf ../openwrt-packages/dae ./package/new/dae
	wget -qO - https://github.com/openwrt/openwrt/commit/06e64f9.patch | patch -p1
	#geodata
	rm -rf ./feeds/packages/net/v2ray-geodata
	cp -rf ../openwrt-packages/v2ray-geodata ./package/new/v2ray-geodata
	cp -f ../PATCH/script/updategeo.sh ./package/base-files/files/bin/updategeo
	# update
	if [ ! -z "${2}" ] && [ ! "${2}" = "0" ] && [ ! -z "${3}" ] && [ ! "${3}" = "0" ]; then
		sed -i "s/^\(PKG_VERSION:=\).*/\1${2}/" ./package/new/dae/Makefile
		sed -i "s/^\(PKG_SOURCE_VERSION:=\).*/\1${3}/" ./package/new/dae/Makefile
	else
		latest_commit="$(git ls-remote https://github.com/daeuniverse/dae HEAD | cut -f 1)"
		sed -i "s/^\(PKG_VERSION:=\).*/\1$(curl -s https://api.github.com/repos/daeuniverse/dae/tags | grep -m 1 '"name"' | cut -d '"' -f 4 | sed 's/^v\(.*\)/\1/')-${latest_commit:0:7}/" ./package/new/dae/Makefile
		sed -i "s/^\(PKG_SOURCE_VERSION:=\).*/\1${latest_commit}/" ./package/new/dae/Makefile
	fi
	# config
	cat >> ../SEED/X86/config.seed <<-EOF

	### DAE ###
	CONFIG_DEVEL=y
	CONFIG_KERNEL_DEBUG_INFO=y
	CONFIG_KERNEL_DEBUG_INFO_BTF=y
	# CONFIG_KERNEL_DEBUG_INFO_REDUCED is not set
	CONFIG_KERNEL_BPF_EVENTS=y
	CONFIG_KERNEL_CGROUPS=y
	CONFIG_KERNEL_CGROUP_BPF=y
	CONFIG_KERNEL_XDP_SOCKETS=y
	CONFIG_BPF_TOOLCHAIN_HOST=y
	CONFIG_PACKAGE_dae=y
	CONFIG_PACKAGE_dae-geoip=y
	CONFIG_PACKAGE_dae-geosite=y
	EOF
	cat >> ./target/linux/x86/64/config-5.15 <<-EOF

	### DAE ###
	CONFIG_BPF_STREAM_PARSER=y
	CONFIG_IPV6_SEG6_BPF=y
	EOF
fi

### files 大法 ###
[ -d ../PATCH/dl ] && cp -rf ../PATCH/dl ./dl
[ -d ../PATCH/files ] && cp -rf ../PATCH/files ./files

### Final Cleanup ###
chmod -R 755 .
find . -type f -name '*.rej' -o -name '*.orig' -exec rm -f {} +

exit 0
