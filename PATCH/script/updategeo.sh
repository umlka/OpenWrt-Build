#!/bin/sh

V2DATDIR="/usr/share/v2ray"
GEOIP_URL="https://ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat"
GEOSITE_URL="https://ghproxy.com/https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat"

trap 'rm -rf "${TMPDIR}"' EXIT
TMPDIR=$(mktemp -d) || exit 1
[ ! -d "${V2DATDIR}" ] && mkdir -p "${V2DATDIR}"

echo -e "\e[34mGeoIP List\e[0m 下载中 \e[92m${GEOIP_URL}\e[0m"
if curl --connect-timeout 60 -m 900 -kfSLo "${TMPDIR}/geoip.dat" "${GEOIP_URL}"; then
	mv -f "${TMPDIR}/geoip.dat" "${V2DATDIR}"
	echo -e "\e[34mGeoIP List\e[0m \e[92m下载成功\e[0m"
else
	echo -e "\e[34mGeoIP List\e[0m \e[31m下载失败\e[0m"
fi

echo -e "\e[34mGeosite List\e[0m 下载中 \e[92m${GEOSITE_URL}\e[0m"
if curl --connect-timeout 60 -m 900 -kfSLo "${TMPDIR}/geosite.dat" "${GEOSITE_URL}"; then
	mv -f "${TMPDIR}/geosite.dat" "${V2DATDIR}"
	echo -e "\e[34mGeosite List\e[0m \e[92m下载成功\e[0m"
else
	echo -e "\e[34mGeosite List\e[0m \e[31m下载失败\e[0m"
fi

rm -rf "${TMPDIR}"

exit 0
