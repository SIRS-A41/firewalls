![[Pasted image 20220118082453.png]]

#### Bob

192.168.254.1

```sh
sudo ip addr add 192.168.254.1/24 broadcast + dev enp0s8
```

### A: reverse proxy/firewall (outside <-> DMZ)

From outside: 192.168.254.254
To DMZ: 192.168.0.254

```sh
sudo ip addr add 192.168.254.254/24 broadcast + dev enp0s8
sudo ip addr add 192.168.0.254/24 broadcast + dev enp0s9
sudo sysctl net.ipv4.ip_forward=1   # enable ip forwarding
```

```sh
# accept only https
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT

# redirect to auth and resources apis
sudo iptables -A OUTPUT -p tcp -d 192.168.0.1 --dport 443 -j ACCEPT
sudo iptables -A OUTPUT -p tcp -d 192.168.0.2 --dport 443 -j ACCEPT

# response packets should have routers ip addr
sudo iptables -t nat -A POSTROUTING -p tcp -s 192.168.0.1/24 --sport 443 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -p tcp -s 192.168.0.2/24 --sport 443 -j MASQUERADE

# i think theres sth missing

sudo iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```

#### Auth API

192.168.0.1

```sh
sudo systemctl restart sshd

sudo ip addr add 192.168.0.1/24 broadcast + dev enp0s8

# router B as gateway to private network
sudo ip route add 192.168.1.0/24 via 192.168.0.100

# router A as default gateway
sudo ip route add default via 192.168.0.254
```

```sh
# accept new connections from router A
sudo iptables -A INPUT -p tcp -s 192.168.0.254 --dport 443 -j ACCEPT

# accept new connections from resource api
sudo iptables -A INPUT -p tcp -s 192.168.0.2 --dport 443 -j ACCEPT

# accept new connections to auth server
sudo iptables -A OUTPUT -p tcp -d 192.168.1.1 --dport 22 -j ACCEPT

sudo iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```

#### Resources API

192.168.0.2

```sh
sudo ip addr add 192.168.0.2/24 broadcast + dev enp0s8

# router B as gateway to private network
sudo ip route add 192.168.1.0/24 via 192.168.0.100

# router A as default gateway
sudo ip route add default via 192.168.0.254
```

```sh
# accept new connections from router A
sudo iptables -A INPUT -p tcp -s 192.168.0.254 --dport 443 -j ACCEPT

# accept new connections to auth api
sudo iptables -A OUTPUT -p tcp -d 192.168.0.1 --dport 443 -j ACCEPT

# accept new ssh connections to resources server
sudo iptables -A OUTPUT -p tcp -d 192.168.1.2 --dport 22 -j ACCEPT

sudo iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```

### B: router (DMZ <-> private)

from DMZ: 192.168.0.100
to private: 192.168.1.100

```sh
sudo ip addr add 192.168.0.100/24 broadcast + dev enp0s8
sudo ip addr add 192.168.1.100/24 broadcast + dev enp0s9
sudo sysctl net.ipv4.ip_forward=1   # enable ip forwarding
```

```sh
# forward connections from auth api to auth server
sudo iptables -A FORWARD -p tcp -s 192.168.0.1 -d 192.168.1.1 --dport 22 -j ACCEPT

# forward connections from resources api to resources server
sudo iptables -A FORWARD -p tcp -s 192.168.0.2 -d 192.168.1.2 --dport 22 -j ACCEPT

sudo iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```


#### Auth server

192.168.1.1

```sh
sudo ip addr add 192.168.1.1/24 broadcast + dev enp0s8

# router B as gateway to dmz
sudo ip route add 192.168.0.0/24 via 192.168.1.100
```

```sh
# accept new connections from auth api
sudo iptables -A INPUT -p tcp -s 192.168.0.1 --dport 22 -j ACCEPT

# ...?

sudo iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```

#### Resources server

192.168.1.2

```sh
sudo systemctl restart sshd
```

```sh
sudo ifconfig enp0s8 192.168.1.2/24 up

# -------------------------

# manjaro
sudo ip addr add 192.168.1.2/24 broadcast + dev enp0s8

# router B as gateway to dmz
sudo ip route add 192.168.0.0/24 via 192.168.1.100
```

```sh
# accept new connections from resources api
sudo iptables -A INPUT -p tcp -s 192.168.0.2 --dport 22 -j ACCEPT

# accept new connections from router C (backups)
sudo iptables -A INPUT -p tcp -s 192.168.1.200 --dport 22 -j ACCEPT

sudo iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```

### C: router (private <-> super private)

from private: 192.168.1.200
to super private: 192.168.3.200

```sh
sudo ifconfig enp0s8 192.168.1.200/24 up
sudo ifconfig enp0s9 192.168.3.200/24 up

# -------------------------

# manjaro
sudo ip addr add 192.168.1.200/24 broadcast + dev enp0s8
sudo ip addr add 192.168.3.200/24 broadcast + dev enp0s9
sudo sysctl net.ipv4.ip_forward=1   # enable ip forwarding
```

```sh
# allow new connections from backup server to auth server
sudo iptables -A FORWARD -p tcp -s 192.168.3.1 -d 192.168.1.1 --dport 22 -j ACCEPT

# allow new connections from backup server to resources server
sudo iptables -A FORWARD -p tcp -s 192.168.3.1 -d 192.168.1.2 --dport 22 -j ACCEPT

# nat packets from backup server
sudo iptables -t nat -A POSTROUTING -p tcp -s 192.168.3.1/24 -j MASQUERADE

sudo iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```

#### Backup server

192.168.3.1

```sh
sudo ifconfig enp0s8 192.168.3.1/24 up

# -------------------------

# manjaro
sudo ip addr add 192.168.3.1/24 broadcast + dev enp0s8

# router C as gateway to private network
# need to nat packets on router
sudo ip route add 192.168.1.0/24 via 192.168.3.200
```

```sh
# allow new scp connections to auth server
sudo iptables -A OUTPUT -p tcp -d 192.168.1.1 --dport 22 -j ACCEPT

# allow new scp connections to resources server
sudo iptables -A OUTPUT -p tcp -d 192.168.1.2 --dport 22 -j ACCEPT

sudo iptables -A INPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A OUTPUT -m state --state ESTABLISHED -j ACCEPT
sudo iptables -A INPUT -j DROP
sudo iptables -A OUTPUT -j DROP
sudo iptables -A FORWARD -j DROP
```
