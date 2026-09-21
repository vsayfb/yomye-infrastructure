#!/bin/bash
set -euxo pipefail

echo "Installing iptables..."
dnf install -y iptables-services

echo "Enabling IPv4 forwarding..."
cat >/etc/sysctl.d/99-nat.conf <<EOF
net.ipv4.ip_forward = 1
EOF

sysctl --system

IFACE=$(ip -o -4 route show to default | awk '{print $5}')

echo "Default interface: $IFACE"

echo "Configuring NAT..."

iptables -t nat -C POSTROUTING -o "$IFACE" -j MASQUERADE 2>/dev/null || \
iptables -t nat -A POSTROUTING -o "$IFACE" -j MASQUERADE

iptables -C FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -C FORWARD -j ACCEPT 2>/dev/null || \
iptables -A FORWARD -j ACCEPT

echo "Saving firewall rules..."
iptables-save > /etc/sysconfig/iptables

systemctl enable --now iptables

echo "Interface: $IFACE"
echo
echo "IP forwarding:"
sysctl net.ipv4.ip_forward
echo
echo "NAT table:"
iptables -t nat -L -n -v
echo
echo "FORWARD chain:"
iptables -L FORWARD -n -v
echo "Done."