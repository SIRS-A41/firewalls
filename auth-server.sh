#!/bin/sh

iptables -F
iptables -t nat -F

iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --src 192.168.2.1 --dst 192.168.2.2 --dport 6379 -j ACCEPT
iptables -A INPUT -j DROP

iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -j DROP

iptables -A FORWARD -j DROP