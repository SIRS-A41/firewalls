#!/bin/sh

iptables -F
iptables -t nat -F

iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --src 192.168.0.254 --dst 192.168.1.2 --dport 8444 -j ACCEPT
iptables -A INPUT -j DROP

iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
iptables -A OUTPUT -p tcp --src 192.168.3.1 --dst 192.168.3.2 --dport 27017 -j ACCEPT
iptables -A OUTPUT -p tcp --src 192.168.3.1 --dst 192.168.3.2 --dport 22 -j ACCEPT
iptables -A OUTPUT -j DROP

iptables -A FORWARD -j DROP