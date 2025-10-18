#!/bin/sh
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++++++++++ /etc/fw/flush.sh - V. 2 - L-M 8/11/2020 -    ++++++++++++++++++++++
# +++++++++++ Usage: Script pour vider les regles iptables ++++++++++++++++++++++
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# +++ Emplacments de script : /etc/fw/flush.sh /etc/fw/fw.sh /etc/init.d/fw  ++++

#
# Variable:
#
INT_EXT=eth0
INT_VPN=tun0
P_VPN=6000
#
# On remet la police par defaut a ACCEPT
#
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
#
# On remet les polices par defaut pour la table NAT
#
iptables -t nat -P PREROUTING ACCEPT
iptables -t nat -P POSTROUTING ACCEPT
iptables -t nat -P OUTPUT ACCEPT
#
# On vide (flush) toutes les regles existantes
#
iptables -F
iptables -t nat -F
#
# Et enfin, on efface toutes les chaaines qui n'existent
# pas par defaut dans les tables filter et nat
#
iptables -X
iptables -t nat -X

# Autoriser le VPN meme si le firewall est desactive:
iptables -A FORWARD -i ${INT_VPN} -j ACCEPT
iptables -A FORWARD -o ${INT_VPN} -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport ${P_VPN} -j ACCEPT
iptables -t filter -A INPUT -p udp --dport ${P_VPN} -j ACCEPT

# Autoriser le NAT pour n importe quel reseau et pour le vpn, meme si le firewall est desactive:
iptables -t nat -A POSTROUTING -o ${INT_EXT} -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${INT_EXT} -j MASQUERADE
exit 0
