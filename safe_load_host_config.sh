#!/bin/bash

# 檢查是否以 root 權限執行
if [ "$EUID" -ne 0 ]; then 
  echo "請以 root 權限執行此腳本"
  exit 1
fi

# 定義網路介面
IFACE1="enp22s0f0np0"
IFACE2="enp22s0f1np1"

# 檢查網路介面是否存在
for IFACE in $IFACE1 $IFACE2; do
  if ! ip link show "$IFACE" >/dev/null 2>&1; then
    echo "錯誤: 網路介面 $IFACE 不存在"
    exit 1
  fi
done

echo "開始設定網路轉發規則..."

# 啟用 IP 轉發功能
echo "1. 啟用 IP 轉發..."
sysctl -w net.ipv4.ip_forward=1

# 設定 NAT 規則
echo "2. 設定 NAT 規則..."
iptables -t nat -A POSTROUTING -o $IFACE1 -j MASQUERADE
iptables -t nat -A POSTROUTING -o $IFACE2 -j MASQUERADE

# UFW 設置
echo "3. 設定 UFW 規則..."
ufw allow in on $IFACE1
ufw allow out on $IFACE1
ufw allow in on $IFACE2
ufw allow out on $IFACE2

# 設定 FORWARD 規則
echo "4. 設定 FORWARD 規則..."
iptables -I FORWARD 1 -i $IFACE1 -o $IFACE2 -j ACCEPT
iptables -I FORWARD 1 -i $IFACE2 -o $IFACE1 -j ACCEPT

# 設定預設 FORWARD 規則為 DROP
echo "5. 設定預設 FORWARD 規則為 DROP..."
iptables -P FORWARD DROP

echo "設定完成！"
echo "請確認以下設定："
echo "- IP 轉發狀態："
sysctl net.ipv4.ip_forward
echo "- iptables NAT 規則："
iptables -t nat -L POSTROUTING
echo "- iptables FORWARD 規則："
iptables -L FORWARD