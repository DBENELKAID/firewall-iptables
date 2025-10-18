#!/bin/sh
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ++++++++++++++++ Objet:	PARE-FEU RESEAU IPTABLES avec DMZ		++++++++++++
# ++++++++++++++++ Auteur:	Driss BENELKAID					++++++++++++
# ++++++++++++++++ Usage:	Reseaux d'entreprises ou home			++++++++++++
# ++++++++++++++++ version:	2 - 11-2020					++++++++++++
# ++++++++++++++++ LastModif:	08-11-2020 - 22:20				++++++++++++
# ++++++++ Emplacments de scripts /etc/fw/fw.sh /etc/fw/flush.sh /etc/init.d/fw ++++++++++++
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# ==========
# Variables:
# ==========
INT_EXT=eth0
INT_LOCAL=eth1
INT_DMZ=eth2
INT_VPN=tun0
SRV_SFTP=172.17.17.1
P_SSH=1977
P_VPN=6000
#
# ------------------------------------
# Supprimer les parametrages existants
# ------------------------------------
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
#
# -------------------------------------------------------------------------------
# Fermer les entrees, sorties et transits. A partir de maintenant tout est refuse
# -------------------------------------------------------------------------------
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# =======================================================================================
# =====================  Regles firewall InPut & OutPu du Firewall ======================
# =======================================================================================
#
# --------------------------------------------
# On autorise le PARE-FEU e s'appeler lui-meme
# --------------------------------------------
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# ICMP: Les ping depuis et vers le PARE-FEU
iptables -A OUTPUT -o ${INT_EXT} -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i ${INT_EXT} -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o ${INT_DMZ} -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i ${INT_DMZ} -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o ${INT_LOCAL} -p icmp -j ACCEPT
iptables -A INPUT -i ${INT_LOCAL} -p icmp -j ACCEPT

# ICI je rajoutrai une regle pour le serveur de tempt NTP: 
iptables -A OUTPUT -o ${INT_EXT} -p udp --dport 123 -j ACCEPT
iptables -A INPUT -i ${INT_EXT} -p udp --sport 123 -j ACCEPT

# DNS OUTPUT :
iptables -A OUTPUT -o ${INT_EXT} -p udp --dport domain -j ACCEPT
# HTTP & THHPS:
iptables -o ${INT_EXT} -A OUTPUT -p tcp --dport http -j ACCEPT # pour apt-get update
iptables -o ${INT_EXT} -A OUTPUT -p tcp --dport https -j ACCEPT # pour apt-get update
# webmin: 
iptables -i ${INT_LOCAL} -A INPUT -p tcp --dport 10000 -j ACCEPT # pour apt-get update
# SMTP Google Gmail envoie alertes de passerelle:
iptables -o ${INT_EXT} -A OUTPUT -p tcp --dport 587 -j ACCEPT # SMTP TLS
iptables -o ${INT_EXT} -A OUTPUT -p tcp --dport 465 -j ACCEPT # SMTP SSL
# Ici on pourra rajouter des regles  pour autoriser les ports OUTPUT et INPUT
# ***************************************************************************

# ---------------------------------------------------------------------------------
# Ne pas casser les connexions etablies sur le PARE-FEU sur toutes les interfaces:
# ---------------------------------------------------------------------------------
iptables -A INPUT -i ${INT_EXT} -m state --state ESTABLISHED,RELATED -j ACCEPT # acces ssh en dmz
iptables -A OUTPUT  -o ${INT_EXT} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i ${INT_LOCAL} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o ${INT_LOCAL} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i ${INT_DMZ} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o ${INT_DMZ} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i ${INT_VPN} -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -o ${INT_VPN} -m state --state ESTABLISHED,RELATED -j ACCEPT

# ==================== Fin regles firewall InPut & OutPu du Firewall =====================
# ========================================================================================
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# ========================================================================================
# ==========  Regles firewall reseau, autoriser le flux entre les interface ==============
# ========================================================================================


# On definit des chaines utilisateurs, ce n'est pas indispensable, mais facilitera la lecture
# des autorisations, elles indiquent un chemin : d'ou on vient et ou on va
iptables -N inet-dmz
iptables -N local-dmz
iptables -N dmz-inet
iptables -N dmz-local
iptables -N local-inet
iptables -N inet-local # Uniquement pour certains service specifics
#
# ------------------------------------------------------------------------------------------
# On associe une action (ici le transit d une interface a l'autre) chaque chaine utilisateur
# ------------------------------------------------------------------------------------------
iptables -A FORWARD -i ${INT_EXT} -o ${INT_LOCAL} -j inet-local # Uniquement pour certains services
iptables -A FORWARD -i ${INT_LOCAL} -o ${INT_EXT} -j local-inet
iptables -A FORWARD -i ${INT_EXT} -o ${INT_DMZ} -j inet-dmz
iptables -A FORWARD -i ${INT_DMZ} -o ${INT_EXT} -j dmz-inet
iptables -A FORWARD -i ${INT_LOCAL} -o ${INT_DMZ} -j local-dmz
iptables -A FORWARD -i ${INT_DMZ} -o ${INT_LOCAL} -j dmz-local

# NTP serveur de temps pour local:
iptables -A local-inet -p udp --dport 123 -j ACCEPT
iptables -A inet-local -p udp --sport 123 -j ACCEPT
# 
# ICMP FORWARDING: Les ping entre les 3 interfaces (vers local non autorise):
iptables -A inet-local -p icmp -j ACCEPT # ping sens inet-local non autorise par regle echo-request
iptables -A local-inet -p icmp --icmp-type echo-request -j ACCEPT
iptables -A inet-dmz -p icmp -j ACCEPT
iptables -A dmz-inet -p icmp --icmp-type echo-request -j ACCEPT
iptables -A local-dmz -p icmp --icmp-type echo-request -j ACCEPT
iptables -A dmz-local -p icmp -j ACCEPT # ping sens dmz-local non autorise par regle echo-request
#
# FORWARDING dmz vers Internet #  local vers Internet # PARE-FEU vers Internet

# DNS 
iptables -A local-inet -p udp --dport domain -j ACCEPT # domain = 53
iptables -A inet-local -p udp --sport domain -j ACCEPT
iptables -A dmz-inet -p udp --dport domain -j ACCEPT
iptables -A inet-dmz -p udp --sport domain -j ACCEPT

# HTTP
iptables -A local-inet -p tcp --dport http -j ACCEPT # http = 80
iptables -A inet-local -p tcp --sport http -j ACCEPT
iptables -A dmz-inet -p tcp --dport http -j ACCEPT
iptables -A inet-dmz -p tcp --sport http -j ACCEPT
# HTTPS
iptables -A local-inet -p tcp --dport https -j ACCEPT # https = 443
iptables -A inet-local -p tcp --sport https -j ACCEPT
iptables -A dmz-inet -p tcp --dport https -j ACCEPT
iptables -A inet-dmz -p tcp --sport https -j ACCEPT
#

# Autoriser le reseau local aux serveurs externes FTP
# Attention, il faut configurer le client FTP en parametres de transfer en (actif), utiliser un jeu de caracteres personalises (latin-9) et UTF-8
iptables -A local-inet -p tcp --dport 20 -j ACCEPT
iptables -A inet-local -p tcp --sport 20 -j ACCEPT
iptables -A local-inet -p tcp --dport 21 -j ACCEPT
iptables -A inet-local -p tcp --sport 21 -j ACCEPT
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp
#

# Autoriser le reseau local aux serveurs externes SSH (SFTP SFTPD)
iptables -A local-inet -p tcp --dport 22 -j ACCEPT
iptables -A inet-local -p tcp --sport 22 -j ACCEPT

## Autoriser ce firewall aux serveurs externes SSH (SFTP SFTPD)
#iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
#iptables -A INPUT -p tcp --sport 22 -j ACCEPT

# MAIL : 
# 1 SMTP :
iptables -A local-inet -p tcp --dport 25 -j ACCEPT # SMTP sans chiffrement
iptables -A inet-local -p tcp --sport 25 -j ACCEPT # SMTP sans chiffrement
iptables -A local-inet -p tcp --dport 587 -j ACCEPT # SMTP avec chiffrement
iptables -A inet-local -p tcp --sport 587 -j ACCEPT # SMTP avec chiffrement
iptables -A local-inet -p tcp --dport 465 -j ACCEPT # SMTP SSL
iptables -A inet-local -p tcp --sport 465 -j ACCEPT # SMTP SSL
# 2 POP:
iptables -A local-inet -p tcp --dport 110 -j ACCEPT # POP
iptables -A inet-local -p tcp --sport 110 -j ACCEPT # POP
iptables -A local-inet -p tcp --dport 995 -j ACCEPT # POP3S (POP3 over SSL)
iptables -A inet-local -p tcp --sport 995 -j ACCEPT # POP3S (POP3 over SSL)
# 3 IMAP:
iptables -A local-inet -p tcp --dport 143 -j ACCEPT # IMAP
iptables -A inet-local -p tcp --sport 143 -j ACCEPT # IMAP
iptables -A local-inet -p tcp --dport 993 -j ACCEPT # IMAP SSL
iptables -A inet-local -p tcp --sport 993 -j ACCEPT # IMAP SSL

#
# ============ Fin regles firewall reseau, autoriser le flux en les interface =============
# =========================================================================================
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^



# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# =========================================================================================
# =========================== Cloisonnement trafic SSH en DMZ =============================
# =========================================================================================

# On autorise le flux de SSH vient de inet et local vers DMZ seulement au serveur SFTP:
iptables -A inet-dmz -p tcp -d ${SRV_SFTP} --dport ${P_SSH} -j ACCEPT
iptables -A dmz-inet -p tcp  --sport ${P_SSH} -j ACCEPT
iptables -A local-dmz -p tcp -d ${SRV_SFTP} --dport ${P_SSH} -j ACCEPT
iptables -A dmz-local -p tcp --sport ${P_SSH} -j ACCEPT
#
# On autorise le flux de SSH vers le firewall mais il sera redirege vers le serveur SFTP en DMZ:
iptables -i ${INT_EXT} -A INPUT -p tcp --dport ${P_SSH} -j ACCEPT # sera redirigee vers SRV_SFTP en dmz
iptables -i ${INT_LOCAL} -A INPUT -p tcp --dport ${P_SSH} -j ACCEPT
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# =========================================================================================


# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# =========================================================================================
# ================================ VPN OpenVPN ============================================
# =========================================================================================
iptables -A FORWARD -i ${INT_VPN} -j ACCEPT # pour router les paquets entre les reseaux WAN, LAN, DMZ et VPN
iptables -A FORWARD -o ${INT_VPN} -j ACCEPT # idem
iptables -t filter -A INPUT -p tcp --dport ${P_VPN} -j ACCEPT # indesponsable pour se connecter au serveur VPN en TCP
iptables -t filter -A INPUT -p udp --dport ${P_VPN} -j ACCEPT # idem mais pour UDP

# ICMP dans VPN:
iptables -A OUTPUT -o ${INT_VPN} -p icmp --icmp-type echo-request -j ACCEPT # pour pinguer IP de interface INT_VPN
iptables -A INPUT -i ${INT_VPN} -p icmp --icmp-type echo-request -j ACCEPT # idem
# ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
# ==========================================================================================

# REDIRECTIONS: Tout trafic ssh vient d'Internet doit etre redirige vers le SRV_SFTP en dmz (permet de cloisonier le SSH en DMZ)
iptables -t nat -A PREROUTING -j DNAT -i ${INT_EXT} -p tcp --dport ${P_SSH} --to-destination ${SRV_SFTP}
#iptables -t nat -A PREROUTING -j DNAT -i ${INT_LOCAL} -p tcp --dport ${P_SSH} --to-destination ${SRV_SFTP} # Attention lire la ligne suivante:
# la regle precedente permet d'interdir l'acces SSH a ce firewall depuis local, tout trafic vient du local sera redirige vers le SRV_SFTP en dmz, 
# elle desactivee pour permettre de se connecter au firewall depuis local.
# Toutes les adresses a destination d'Internet doivent etre traduites (NAT/PAT)
iptables -t nat -A POSTROUTING -o ${INT_EXT} -j MASQUERADE
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o ${INT_EXT} -j MASQUERADE


# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ATTENTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Ne pas activer ces lignes de Test, des regles crees pour faire des diagnostiques sur le firewall.
# TCP pour Test:
#iptables -A local-inet -p tcp --dport 1:65535 -j ACCEPT
#iptables -A inet-local -p tcp --sport 1:65535 -j ACCEPT
#iptables -A dmz-inet -p tcp --dport 1:65535 -j ACCEPT
#iptables -A inet-dmz -p tcp --sport 1:65535 -j ACCEPT
# UDP pour Test:
#iptables -A local-inet -p udp --dport 1:65535 -j ACCEPT
#iptables -A inet-local -p udp --sport 1:65535 -j ACCEPT
#iptables -A dmz-inet -p udp --dport 1:65535 -j ACCEPT
#iptables -A inet-dmz -p udp --sport 1:65535 -j ACCEPT
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! ATTENTION !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


