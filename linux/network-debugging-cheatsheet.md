# Linux Network Debugging Cheat Sheet

Essential tools and commands for troubleshooting network issues on Linux.

---

## Basic Connectivity Testing

### `ping` - Test Network Reachability
Test if a host is reachable via ICMP.
```bash
ping google.com                           # Basic ping
ping -c 4 google.com                      # Send 4 packets and stop
ping -i 0.5 google.com                    # Ping every 0.5 seconds
ping -s 1000 google.com                   # Send 1000 byte packets
ping -W 2 google.com                      # Wait 2 seconds for response
ping -4 google.com                        # Force IPv4
ping -6 google.com                        # Force IPv6
ping -I eth0 google.com                   # Use specific interface
ping -q -c 10 google.com                  # Quiet output (summary only)

# Check local network
ping 192.168.1.1                          # Ping gateway
ping 127.0.0.1                            # Test loopback interface
```

### `ping6` - IPv6 Ping
Test IPv6 connectivity.
```bash
ping6 google.com                          # IPv6 ping
ping6 -c 4 2001:4860:4860::8888          # Ping Google DNS IPv6
ping6 ff02::1%eth0                        # Ping all nodes on link
```

### `traceroute` - Trace Network Path
Show the route packets take to a destination.
```bash
traceroute google.com                     # Trace route to host
traceroute -n google.com                  # Don't resolve hostnames (faster)
traceroute -m 15 google.com               # Max 15 hops
traceroute -q 1 google.com                # 1 query per hop (faster)
traceroute -I google.com                  # Use ICMP instead of UDP
traceroute -T -p 80 google.com            # Use TCP on port 80
traceroute -w 2 google.com                # Wait 2 seconds per hop
```

### `tracepath` - Trace Network Path (simpler)
Similar to traceroute, no root required.
```bash
tracepath google.com                      # Trace path
tracepath -n google.com                   # No DNS resolution
tracepath -l 1400 google.com              # Set initial packet length
```

### `mtr` - Network Diagnostic Tool
Combines ping and traceroute (continuous).
```bash
mtr google.com                            # Interactive mode
mtr -n google.com                         # No DNS resolution
mtr -c 100 google.com                     # Send 100 packets
mtr -r -c 100 google.com                  # Report mode
mtr --tcp -P 443 google.com               # TCP on port 443
mtr --udp -P 53 google.com                # UDP on port 53
mtr -4 google.com                         # IPv4 only
mtr -6 google.com                         # IPv6 only
```

---

## DNS Troubleshooting

### `nslookup` - Query DNS Servers
Look up DNS information.
```bash
nslookup google.com                       # Basic lookup
nslookup google.com 8.8.8.8               # Query specific DNS server
nslookup -type=A google.com               # Query A records
nslookup -type=MX google.com              # Query MX records
nslookup -type=NS google.com              # Query NS records
nslookup -type=TXT google.com             # Query TXT records
nslookup -type=SOA google.com             # Query SOA records
nslookup -type=AAAA google.com            # Query IPv6 addresses

# Reverse lookup
nslookup 8.8.8.8                          # Reverse DNS lookup
```

### `dig` - DNS Lookup Tool (detailed)
Powerful DNS query tool.
```bash
dig google.com                            # Basic query
dig google.com +short                     # Short answer only
dig google.com @8.8.8.8                   # Query specific DNS server
dig google.com A                          # Query A records
dig google.com MX                         # Query MX records
dig google.com NS                         # Query nameservers
dig google.com TXT                        # Query TXT records
dig google.com SOA                        # Query SOA record
dig google.com AAAA                       # Query IPv6 addresses
dig google.com ANY                        # Query all records

# Advanced queries
dig -x 8.8.8.8                            # Reverse lookup
dig +trace google.com                     # Trace DNS resolution path
dig +noall +answer google.com             # Only show answer section
dig +tcp google.com                       # Use TCP instead of UDP
dig -p 5353 google.com                    # Use custom port

# Batch queries
dig google.com facebook.com twitter.com   # Multiple domains
```

### `host` - Simple DNS Lookup
Simplified DNS lookup utility.
```bash
host google.com                           # Basic lookup
host -t MX google.com                     # Query MX records
host -t NS google.com                     # Query nameservers
host -t TXT google.com                    # Query TXT records
host -a google.com                        # Query all records
host 8.8.8.8                              # Reverse lookup
host -v google.com                        # Verbose output
```

### `resolvectl` / `systemd-resolve` - Resolve Domain Names
SystemD DNS resolver utility.
```bash
resolvectl query google.com               # Resolve domain
resolvectl status                         # Show DNS configuration
resolvectl dns                            # Show DNS servers
resolvectl flush-caches                   # Flush DNS cache
resolvectl statistics                     # Show cache statistics

# Older systems
systemd-resolve google.com                # Resolve domain
systemd-resolve --status                  # Show status
```

---

## Port and Connection Testing

### `telnet` - Test Port Connectivity
Test if a port is open and accepting connections.
```bash
telnet google.com 80                      # Test HTTP port
telnet smtp.gmail.com 25                  # Test SMTP port
telnet localhost 3306                     # Test MySQL port

# Exit: Ctrl + ] then type 'quit'
```

### `nc` (netcat) - Network Swiss Army Knife
Versatile networking tool for port testing and more.
```bash
# Port scanning
nc -zv google.com 80                      # Test single port
nc -zv google.com 80-443                  # Scan port range
nc -zvu google.com 53                     # Test UDP port

# Port listening
nc -l 8080                                # Listen on port 8080
nc -l -p 9999                             # Listen on port 9999

# Transfer data
nc -l 8080 > received_file                # Receive file
nc target_host 8080 < file_to_send        # Send file

# Banner grabbing
echo "" | nc google.com 80                # Get HTTP banner
nc -v google.com 22                       # Get SSH banner

# Chat between two machines
nc -l 12345                               # On machine 1 (listen)
nc machine1_ip 12345                      # On machine 2 (connect)
```

### `nmap` - Network Mapper
Powerful network scanning tool.
```bash
# Host discovery
nmap 192.168.1.0/24                       # Scan network
nmap -sn 192.168.1.0/24                   # Ping scan (no port scan)
nmap -Pn google.com                       # Skip ping (assume host is up)

# Port scanning
nmap google.com                           # Scan common ports
nmap -p 80,443 google.com                 # Scan specific ports
nmap -p 1-1000 google.com                 # Scan port range
nmap -p- google.com                       # Scan all 65535 ports
nmap -F google.com                        # Fast scan (100 common ports)

# Service detection
nmap -sV google.com                       # Detect service versions
nmap -O google.com                        # Detect OS
nmap -A google.com                        # Aggressive scan (OS, version, scripts)

# Scan types
nmap -sT google.com                       # TCP connect scan
nmap -sS google.com                       # SYN scan (stealth)
nmap -sU -p 53,161 google.com             # UDP scan
nmap -sA google.com                       # ACK scan (firewall detection)

# Output
nmap -oN output.txt google.com            # Normal output
nmap -oX output.xml google.com            # XML output
nmap -oG output.txt google.com            # Greppable output

# Speed
nmap -T4 google.com                       # Faster scan (T0-T5)
nmap --max-retries 2 google.com           # Limit retries
```

---

## Network Interface Information

### `ifconfig` - Network Interface Configuration (legacy)
Display and configure network interfaces.
```bash
ifconfig                                  # Show all interfaces
ifconfig eth0                             # Show specific interface
ifconfig -a                               # Show all (including down)

# Configure interface (requires root)
sudo ifconfig eth0 192.168.1.100         # Set IP address
sudo ifconfig eth0 netmask 255.255.255.0 # Set netmask
sudo ifconfig eth0 up                     # Bring interface up
sudo ifconfig eth0 down                   # Bring interface down
```

### `ip` - Network Configuration (modern)
Modern replacement for ifconfig.
```bash
# Show interfaces
ip addr show                              # Show all addresses
ip addr show eth0                         # Show specific interface
ip -4 addr                                # IPv4 only
ip -6 addr                                # IPv6 only
ip -br addr                               # Brief format
ip -c addr                                # Colored output

# Show links
ip link show                              # Show all links
ip link show eth0                         # Show specific link
ip -s link                                # Show statistics

# Routing
ip route show                             # Show routing table
ip route get 8.8.8.8                      # Show route to destination
ip -6 route show                          # IPv6 routes

# Neighbors (ARP table)
ip neigh show                             # Show ARP table
ip neigh show dev eth0                    # ARP for specific interface

# Add/Delete addresses (requires root)
sudo ip addr add 192.168.1.100/24 dev eth0    # Add IP
sudo ip addr del 192.168.1.100/24 dev eth0    # Delete IP
sudo ip link set eth0 up                      # Bring up interface
sudo ip link set eth0 down                    # Bring down interface
```

### `ethtool` - Query Network Driver and Hardware
Display and change ethernet device settings.
```bash
ethtool eth0                              # Show interface settings
ethtool -i eth0                           # Show driver information
ethtool -S eth0                           # Show statistics
ethtool -k eth0                           # Show offload settings
ethtool -g eth0                           # Show ring buffer settings

# Link test
ethtool eth0 | grep "Link detected"       # Check if cable connected
```

### `iwconfig` - Wireless Configuration
Configure wireless network interfaces.
```bash
iwconfig                                  # Show wireless interfaces
iwconfig wlan0                            # Show specific interface
iwconfig wlan0 essid "NetworkName"        # Set SSID
iwconfig wlan0 mode Managed               # Set managed mode
```

### `iw` - Wireless Configuration (modern)
Modern wireless configuration tool.
```bash
iw dev                                    # Show wireless devices
iw dev wlan0 info                         # Show device info
iw dev wlan0 link                         # Show connection info
iw dev wlan0 scan                         # Scan for networks
iw dev wlan0 station dump                 # Show connected stations
```

---

## Active Connections and Ports

### `netstat` - Network Statistics (legacy)
Display network connections and statistics.
```bash
# Active connections
netstat -a                                # All connections
netstat -at                               # TCP connections
netstat -au                               # UDP connections
netstat -l                                # Listening ports
netstat -lt                               # Listening TCP ports
netstat -lu                               # Listening UDP ports

# With process information
netstat -tulpn                            # TCP/UDP, listening, numeric, programs
netstat -anp                              # All, numeric, programs

# Routing table
netstat -r                                # Show routing table
netstat -rn                               # Numeric (no DNS lookup)

# Interface statistics
netstat -i                                # Show interface statistics
netstat -ie                               # Detailed interface stats

# Additional info
netstat -s                                # Protocol statistics
netstat -c                                # Continuous mode
netstat -g                                # Multicast group membership
```

### `ss` - Socket Statistics (modern)
Modern replacement for netstat.
```bash
# Basic usage
ss                                        # Show all connections
ss -a                                     # All sockets
ss -l                                     # Listening sockets
ss -t                                     # TCP sockets
ss -u                                     # UDP sockets
ss -x                                     # Unix sockets

# Common combinations
ss -tulpn                                 # TCP/UDP, listening, numeric, processes
ss -tan                                   # TCP, all, numeric
ss -uan                                   # UDP, all, numeric

# State filters
ss -t state established                   # Established TCP connections
ss -t state listening                     # Listening TCP sockets
ss -t state time-wait                     # TIME_WAIT connections

# Address/port filters
ss dst 192.168.1.100                      # Connections to IP
ss sport = :80                            # Connections from port 80
ss dport = :443                           # Connections to port 443
ss src 192.168.1.0/24                     # From network

# Process information
ss -p                                     # Show process info
ss -tp                                    # TCP with processes

# Statistics
ss -s                                     # Summary statistics
ss -i                                     # Internal TCP info
ss -e                                     # Extended info
ss -m                                     # Memory info
```

### `lsof` - List Open Files
Show open files and network connections.
```bash
# Network connections
lsof -i                                   # All internet connections
lsof -i tcp                               # TCP connections
lsof -i udp                               # UDP connections
lsof -i :80                               # Connections on port 80
lsof -i :80-443                           # Port range

# Protocol specific
lsof -i 4                                 # IPv4 only
lsof -i 6                                 # IPv6 only

# By process
lsof -p 1234                              # By process ID
lsof -c nginx                             # By process name
lsof -u username                          # By user

# Network files
lsof -i @192.168.1.100                    # Connections to IP
lsof -i @192.168.1.100:80                 # Connections to IP:port

# Combination
lsof -i tcp -s tcp:ESTABLISHED            # Established TCP connections
lsof -i -P                                # Don't convert port numbers
lsof -i -n                                # Don't resolve hostnames
```

---

## Packet Capture and Analysis

### `tcpdump` - Packet Capture
Capture and analyze network traffic.
```bash
# Basic capture
tcpdump                                   # Capture on default interface
tcpdump -i eth0                           # Capture on specific interface
tcpdump -i any                            # Capture on all interfaces
tcpdump -c 100                            # Capture 100 packets
tcpdump -w capture.pcap                   # Write to file
tcpdump -r capture.pcap                   # Read from file

# Display options
tcpdump -v                                # Verbose
tcpdump -vv                               # More verbose
tcpdump -vvv                              # Even more verbose
tcpdump -n                                # Don't resolve hostnames
tcpdump -nn                               # Don't resolve hosts or ports
tcpdump -X                                # Show hex and ASCII
tcpdump -A                                # Show ASCII only
tcpdump -s 0                              # Capture full packet (default 262144)

# Filters by host
tcpdump host 192.168.1.100                # Traffic to/from host
tcpdump src 192.168.1.100                 # From host
tcpdump dst 192.168.1.100                 # To host

# Filters by network
tcpdump net 192.168.1.0/24                # Network traffic

# Filters by port
tcpdump port 80                           # Port 80 traffic
tcpdump src port 80                       # From port 80
tcpdump dst port 443                      # To port 443
tcpdump portrange 80-443                  # Port range

# Filters by protocol
tcpdump tcp                               # TCP only
tcpdump udp                               # UDP only
tcpdump icmp                              # ICMP only
tcpdump ip6                               # IPv6 only

# Complex filters
tcpdump 'tcp[tcpflags] & tcp-syn != 0'    # SYN packets
tcpdump 'tcp port 80 and (host 192.168.1.100)' # Combined filter
tcpdump 'tcp and not port 22'             # TCP except SSH
tcpdump 'greater 1000'                    # Packets larger than 1000 bytes
tcpdump 'less 100'                        # Packets smaller than 100 bytes

# Common use cases
tcpdump -i eth0 -nn port 80 -w http.pcap  # Capture HTTP traffic
tcpdump -i eth0 -nn icmp                  # Capture ping traffic
tcpdump -i eth0 -nn 'tcp[tcpflags] == tcp-syn' # Capture SYN packets
```

### `tshark` - Terminal Wireshark
Command-line version of Wireshark.
```bash
# Basic capture
tshark -i eth0                            # Capture on interface
tshark -c 100                             # Capture 100 packets
tshark -w capture.pcap                    # Write to file
tshark -r capture.pcap                    # Read from file

# Display filters
tshark -i eth0 -f "port 80"               # Capture filter
tshark -r capture.pcap -Y "http"          # Display filter
tshark -r capture.pcap -Y "ip.addr == 192.168.1.100"

# Output options
tshark -V                                 # Verbose packet details
tshark -x                                 # Show hex dump
tshark -T fields -e ip.src -e ip.dst      # Specific fields

# Statistics
tshark -q -z io,phs                       # Protocol hierarchy
tshark -q -z conv,tcp                     # TCP conversations
tshark -q -z endpoints,ip                 # IP endpoints
```

### `wireshark` - GUI Packet Analyzer
Graphical packet analysis tool.
```bash
wireshark                                 # Launch GUI
wireshark -i eth0                         # Start capture on interface
wireshark -r capture.pcap                 # Open capture file
wireshark -k -i eth0                      # Start capture immediately
```

---

## Bandwidth and Traffic Monitoring

### `iftop` - Interface Top
Display bandwidth usage per connection.
```bash
iftop                                     # Monitor default interface
iftop -i eth0                             # Monitor specific interface
iftop -n                                  # Don't resolve hostnames
iftop -N                                  # Don't resolve ports
iftop -P                                  # Show ports
iftop -B                                  # Show bytes instead of bits
iftop -f "port 80"                        # Filter by port

# Interactive keys:
# h - help
# n - toggle DNS resolution
# s - toggle source
# d - toggle destination
# p - toggle port display
# q - quit
```

### `nethogs` - Network Hogs
Show bandwidth usage per process.
```bash
nethogs                                   # Monitor all interfaces
nethogs eth0                              # Monitor specific interface
nethogs eth0 wlan0                        # Monitor multiple interfaces
nethogs -d 5                              # Update every 5 seconds
sudo nethogs -v 3                         # More detailed view
```

### `iptraf-ng` - IP Traffic Monitor
Interactive colorful IP LAN monitor.
```bash
iptraf-ng                                 # Interactive menu
iptraf-ng -i eth0                         # Monitor interface
iptraf-ng -d eth0                         # Detailed interface stats
iptraf-ng -s eth0                         # TCP/UDP service statistics
```

### `vnstat` - Network Traffic Monitor
Network statistics logger.
```bash
vnstat                                    # Show statistics
vnstat -h                                 # Hourly stats
vnstat -d                                 # Daily stats
vnstat -m                                 # Monthly stats
vnstat -w                                 # Weekly stats
vnstat -i eth0                            # Specific interface
vnstat -l                                 # Live traffic
vnstat --json                             # JSON output

# Database management
vnstat --add -i eth0                      # Add interface to monitor
vnstat --remove -i eth0                   # Remove interface
```

### `bmon` - Bandwidth Monitor
Real-time bandwidth monitoring.
```bash
bmon                                      # Monitor all interfaces
bmon -p eth0                              # Monitor specific interface
bmon -b                                   # Bits per second
bmon -r 2                                 # Update every 2 seconds
```

### `nload` - Network Load Visualizer
Display network usage with graphs.
```bash
nload                                     # Monitor default interface
nload eth0                                # Monitor specific interface
nload eth0 wlan0                          # Monitor multiple interfaces
nload -m                                  # Display multiple interfaces
nload -u M                                # Show in Mbps
nload -t 5000                             # Refresh every 5 seconds
```

---

## ARP and MAC Address Tools

### `arp` - ARP Table (legacy)
Display and modify ARP table.
```bash
arp                                       # Show ARP table
arp -a                                    # Show all entries
arp -n                                    # Numeric output
arp 192.168.1.1                           # Show specific entry

# Modify ARP table
sudo arp -s 192.168.1.100 00:11:22:33:44:55  # Add static entry
sudo arp -d 192.168.1.100                    # Delete entry
```

### `ip neigh` - Neighbor Table (modern)
Modern ARP table management.
```bash
ip neigh show                             # Show ARP table
ip neigh show dev eth0                    # Show for interface
ip -s neigh show                          # Show with statistics

# Modify entries
sudo ip neigh add 192.168.1.100 lladdr 00:11:22:33:44:55 dev eth0  # Add
sudo ip neigh del 192.168.1.100 dev eth0  # Delete
sudo ip neigh flush dev eth0              # Flush entries
```

### `arping` - Send ARP Requests
Send ARP requests to a neighbor.
```bash
arping 192.168.1.1                        # ARP ping
arping -I eth0 192.168.1.1                # Use specific interface
arping -c 4 192.168.1.1                   # Send 4 requests
arping -d 192.168.1.1                     # Duplicate address detection
arping -D 192.168.1.100                   # Check if IP is in use
```

---

## Firewall and NAT

### `iptables` - Firewall Administration (legacy)
Configure IPv4 firewall rules.
```bash
# List rules
sudo iptables -L                          # List all rules
sudo iptables -L -n                       # Numeric output
sudo iptables -L -v                       # Verbose
sudo iptables -L INPUT                    # List INPUT chain
sudo iptables -L -t nat                   # List NAT table
sudo iptables -S                          # List rules as commands

# Common checks
sudo iptables -L -n -v --line-numbers     # Show with line numbers
sudo iptables -t nat -L -n -v             # NAT rules

# Save/Restore
sudo iptables-save > rules.txt            # Save rules
sudo iptables-restore < rules.txt         # Restore rules
```

### `nft` - nftables (modern)
Modern firewall configuration.
```bash
sudo nft list ruleset                     # List all rules
sudo nft list tables                      # List tables
sudo nft list table inet filter           # List specific table
sudo nft flush ruleset                    # Flush all rules
```

### `ufw` - Uncomplicated Firewall
Simple firewall management.
```bash
sudo ufw status                           # Show firewall status
sudo ufw status verbose                   # Detailed status
sudo ufw status numbered                  # Show rule numbers

# Common operations
sudo ufw enable                           # Enable firewall
sudo ufw disable                          # Disable firewall
sudo ufw allow 80                         # Allow port
sudo ufw deny 80                          # Deny port
sudo ufw delete allow 80                  # Delete rule
```

---

## HTTP/HTTPS Testing

### `curl` - Transfer Data from URLs
Test HTTP/HTTPS endpoints.
```bash
# Basic requests
curl https://example.com                  # GET request
curl -I https://example.com               # Headers only
curl -i https://example.com               # Include headers in output
curl -v https://example.com               # Verbose (shows request/response)
curl -s https://example.com               # Silent mode
curl -o output.html https://example.com   # Save to file

# HTTP methods
curl -X POST https://api.example.com      # POST request
curl -X PUT https://api.example.com       # PUT request
curl -X DELETE https://api.example.com    # DELETE request

# Headers and data
curl -H "Content-Type: application/json" https://api.example.com
curl -d "param=value" https://api.example.com  # POST data
curl -d @data.json https://api.example.com     # POST from file

# Authentication
curl -u user:pass https://example.com     # Basic auth
curl -H "Authorization: Bearer TOKEN" https://api.example.com

# Follow redirects
curl -L https://example.com               # Follow redirects
curl -L -o file.html https://example.com  # Follow and save

# Timing
curl -w "@curl-format.txt" https://example.com  # Custom timing output
curl -w "Time: %{time_total}s\n" -o /dev/null -s https://example.com

# SSL/TLS
curl -k https://example.com               # Ignore SSL errors
curl --cacert ca.crt https://example.com  # Use custom CA cert
curl --cert client.crt --key client.key https://example.com  # Client cert

# Testing
curl --connect-timeout 5 https://example.com   # Connection timeout
curl --max-time 10 https://example.com         # Max time for operation
curl --retry 3 https://example.com             # Retry on failure
```

### `wget` - Network Downloader
Download files and test connectivity.
```bash
wget https://example.com/file.zip         # Download file
wget -O output.html https://example.com   # Save with different name
wget -c https://example.com/file.zip      # Continue interrupted download
wget -b https://example.com/file.zip      # Background download
wget --spider https://example.com         # Check if URL exists
wget -S https://example.com               # Show server response
wget --timeout=10 https://example.com     # Set timeout
wget --tries=3 https://example.com        # Number of retries
```

### `ab` - Apache Bench
HTTP server benchmarking.
```bash
ab -n 100 -c 10 http://example.com/       # 100 requests, 10 concurrent
ab -n 1000 -c 100 http://example.com/     # Load test
ab -t 60 -c 10 http://example.com/        # Run for 60 seconds
ab -k -n 1000 http://example.com/         # Use keep-alive
ab -p post.txt -T application/json http://example.com/  # POST request
```

---

## Advanced Diagnostics

### `strace` - Trace System Calls
Debug network-related system calls.
```bash
strace -e trace=network curl google.com   # Network-related calls
strace -e trace=socket,connect ping google.com
strace -p 1234                            # Attach to running process
strace -f -e trace=network nginx          # Follow forks
```

### `iperf` / `iperf3` - Network Performance Testing
Test network bandwidth.
```bash
# Server side
iperf3 -s                                 # Start server
iperf3 -s -p 5201                         # Custom port

# Client side
iperf3 -c server_ip                       # Test to server
iperf3 -c server_ip -t 60                 # Test for 60 seconds
iperf3 -c server_ip -P 4                  # 4 parallel streams
iperf3 -c server_ip -R                    # Reverse (download test)
iperf3 -c server_ip -u                    # UDP test
iperf3 -c server_ip -b 100M               # Target bandwidth
```

### `socat` - Multipurpose Relay
Advanced networking tool.
```bash
# Port forwarding
socat TCP-LISTEN:8080,fork TCP:target:80  # Forward port 8080 to target:80

# Test connectivity
socat - TCP:google.com:80                 # Connect to port

# SSL/TLS
socat OPENSSL-LISTEN:443,cert=server.pem,fork TCP:localhost:80
```

---

## Quick Diagnostic Scripts

### Check if port is open
```bash
timeout 1 bash -c "</dev/tcp/google.com/80" && echo "Open" || echo "Closed"
```

### Test DNS resolution
```bash
getent hosts google.com                   # Test DNS via system resolver
```

### Find process using a port
```bash
sudo lsof -i :80                          # What's using port 80
sudo ss -lptn 'sport = :80'               # Alternative method
```

### Show active connections count
```bash
netstat -an | grep ESTABLISHED | wc -l    # Count established connections
ss -s                                     # Socket statistics summary
```

### Network speed test
```bash
curl -s https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py | python3 -
```

### Check internet connectivity
```bash
ping -c 1 8.8.8.8 > /dev/null 2>&1 && echo "Connected" || echo "No connection"
```

### Show default gateway
```bash
ip route | grep default                   # Default gateway
route -n | grep '^0.0.0.0'               # Alternative
```

### Test MTU size
```bash
ping -M do -s 1472 google.com             # Test MTU (1472 + 28 = 1500)
```

---

## Common Troubleshooting Workflows

### Can't reach a website
```bash
# 1. Check if you can resolve DNS
nslookup example.com
dig example.com

# 2. Test connectivity
ping example.com

# 3. Check routing
traceroute example.com

# 4. Test specific port
nc -zv example.com 80
curl -I https://example.com
```

### Network is slow
```bash
# 1. Check bandwidth usage
iftop
nethogs

# 2. Test path
mtr google.com

# 3. Check for packet loss
ping -c 100 google.com | grep loss

# 4. Test bandwidth
iperf3 -c speedtest.server.com
```

### Port not accessible
```bash
# 1. Check if service is listening
ss -tulpn | grep :80
lsof -i :80

# 2. Check firewall
sudo iptables -L -n
sudo ufw status

# 3. Test locally
telnet localhost 80
nc -zv localhost 80

# 4. Test remotely
telnet remote_ip 80
nmap -p 80 remote_ip
```

### DNS not resolving
```bash
# 1. Check DNS configuration
cat /etc/resolv.conf
resolvectl status

# 2. Test different DNS servers
dig @8.8.8.8 google.com
dig @1.1.1.1 google.com

# 3. Flush DNS cache
sudo systemd-resolve --flush-caches
sudo resolvectl flush-caches

# 4. Check /etc/hosts
cat /etc/hosts
```
