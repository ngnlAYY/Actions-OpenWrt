#!/bin/bash
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#
# Copyright (c) 2019-2024 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# 工作流中在运行本脚本前已 cd openwrt，此处直接在当前目录操作
CONFIG_GENERATE="package/base-files/files/bin/config_generate"
[ -f "$CONFIG_GENERATE" ] || CONFIG_GENERATE="feeds/packages/base-files/files/bin/config_generate"
[ -f "$CONFIG_GENERATE" ] || CONFIG_GENERATE="feeds/base-files/files/bin/config_generate"

# 修改默认 LAN IP（与 immortalwrt.lan 等解析的地址一致）
if [ -n "${DEFAULT_IP}" ] && [ -f "$CONFIG_GENERATE" ]; then
  sed -i "s/192\.168\.1\.1/${DEFAULT_IP}/g" "$CONFIG_GENERATE"
  echo "  [diy-part2] 默认 IP 已改为: $DEFAULT_IP"
fi

# 修改默认主机名（ImmortalWrt/OpenWrt）
if [ -n "${DEFAULT_HOSTNAME}" ] && [ -f "$CONFIG_GENERATE" ]; then
  for old in ImmortalWrt OpenWrt; do
    sed -i "s/${old}/${DEFAULT_HOSTNAME}/g" "$CONFIG_GENERATE"
  done
  echo "  [diy-part2] 默认主机名已改为: $DEFAULT_HOSTNAME"
fi

# 修改默认 WiFi 名称（SSID）：仅在含 ssid 的行中替换 OpenWrt/ImmortalWrt
if [ -n "${DEFAULT_WIFI_SSID}" ]; then
  # 对 sed 替换中的 & 和 \ 转义（使用 | 作分隔符，SSID 中可含 /）
  wifi_ssid_escaped="$(echo "$DEFAULT_WIFI_SSID" | sed 's/[&\]/\\&/g')"
  for dir in package/kernel/mac80211 package/network package/base-files target \
             feeds/packages feeds/base feeds/network feeds/kernel; do
    [ -d "$dir" ] || continue
    find "$dir" -maxdepth 8 -type f \( -name "*.sh" -o -name "*.lua" -o -name "*.json" -o -name "*.ucode" -o -name "wireless" -o -name "*.conf" \) 2>/dev/null | while read -r f; do
      [ -f "$f" ] || continue
      if grep -qi "ssid" "$f" && grep -qE "OpenWrt|ImmortalWrt" "$f"; then
        sed -i "/ssid/s|OpenWrt|${wifi_ssid_escaped}|g; /ssid/s|ImmortalWrt|${wifi_ssid_escaped}|g" "$f"
        echo "  [diy-part2] 默认 WiFi SSID 已改: $f"
      fi
    done
  done
  echo "  [diy-part2] 默认 WiFi 名称已改为: $DEFAULT_WIFI_SSID"
fi

# 修改 LAN 域名（hostname.lan -> hostname.$LAN_DOMAIN，如 immortalwrt.lan 中的 .lan）
if [ -n "${LAN_DOMAIN}" ]; then
  for f in \
    package/base-files/files/etc/config/dhcp \
    feeds/packages/base-files/files/etc/config/dhcp \
    package/network/services/dnsmasq/files/dhcp.conf \
    feeds/network/services/dnsmasq/files/dhcp.conf; do
    [ -f "$f" ] || continue
    if grep -q "lan" "$f" 2>/dev/null; then
      sed -i "s/option domain 'lan'/option domain '${LAN_DOMAIN}'/g" "$f"
      sed -i 's|local=/lan/|local=/'"${LAN_DOMAIN}"'/|g' "$f"
      sed -i "s/domain=lan/domain=${LAN_DOMAIN}/g" "$f"
      echo "  [diy-part2] LAN 域名已改为: $LAN_DOMAIN (已修改 $f)"
    fi
  done
  # 部分源码在 uci-defaults 或 board.d 里写死 domain
  for dir in package feeds; do [ -d "$dir" ] || continue; find "$dir" -maxdepth 6 -type f \( -name "*.sh" -o -name "dhcp" -o -name "network" \) 2>/dev/null; done | while read -r f; do
    [ -f "$f" ] || continue
    if grep -qE "['\"]lan['\"]|/lan/|domain=lan" "$f" 2>/dev/null; then
      sed -i "s/option domain 'lan'/option domain '${LAN_DOMAIN}'/g" "$f"
      sed -i "s/option domain \"lan\"/option domain \"${LAN_DOMAIN}\"/g" "$f"
      sed -i 's|local=/lan/|local=/'"${LAN_DOMAIN}"'/|g' "$f"
      sed -i "s/domain=lan/domain=${LAN_DOMAIN}/g" "$f"
    fi
  done
fi

# Modify default theme (example, keep commented)
#sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
