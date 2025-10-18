# firewall-iptables
# Three .sh scripts allow the setup of an iptables network firewall with 3 networks: WAN, LAN and DMZ.

# Script sh permettent la mise en place un firewall réseau (iptables) avec trois réseaux dont un de DMZ.
# Les scripts s'installent sur des serveurs (passerelles) Debian ou autres distribution de Linux

Prerequis:
==========

Configuration 3 interfaces réseaux (WAN, LAN, DMZ)
-------------------------------------------------
Exemple: 
WAN = eth0 192.168.1.100
LAN = eth1 172.16.16.100
DMZ = eth2 172.17.17.100

Adapter les interfaces dans les variables des scripts de configuration de firewall
----------------------------------------------------------------------------------
fw.sh
flush.sh

Créer un dossier "fw" pour ces deux scripts dans /etc
-----------------------------------------------------
mkdir /etc/fw


Copier les deux scripts et ainsi que le 3ieme script de demarrage "/init.d/fw":
----------------------------------------------------------------------
cp fw.sh flush.sh /etc/fw/
cp fw /etc/init.d/fw

Donniers les droits d'exécution 774 pour ces 3 scripts:
-------------------------------------------------------
chmod 774 /etc/fw/fw.sh
chmod 774 /etc/fw/flush.sh
chmod 774 /etc/init.d/fw

Mettre a jour la RC avec le script de demarrage "fw":
-----------------------------------------------------
update-rc.d -f fw defaults 90

Commandes:
----------
Pour activer manuellement le pare-feu :
 sh -x /etc/fw/flush.sh

Pour reactiver manuellement le firewall:
sh -x /etc/fw/fw.sh

Pour verificer l'etat de firewall:
iptables -L
iptables -L -t nat

Configuration de routage:
------------------------
vim /etc/sysctl.conf
net.ipv4.ip_forward = 1
root@server:/# sysctl -p



