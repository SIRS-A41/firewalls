#!/bin/sh

iptables -F
iptables -t nat -F

iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -j DROP

iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --src 192.168.4.2 --dst 192.168.4.1 --dport 22 -j ACCEPT
iptables -A OUTPUT -j DROP

iptables -A FORWARD -j DROP