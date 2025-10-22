# Linux Commands Cheat Sheet

Essential Linux commands with descriptions and examples.

---

## File System Navigation

### `pwd` - Print Working Directory
Shows your current directory location.
```bash
pwd
# Output: /home/user/documents
```

### `ls` - List Directory Contents
Lists files and directories.
```bash
ls                    # List current directory
ls -l                 # Long format with details
ls -la                # Include hidden files
ls -lh                # Human-readable file sizes
ls -lt                # Sort by modification time
ls -lS                # Sort by file size
ls /path/to/dir       # List specific directory
```

### `cd` - Change Directory
Navigate between directories.
```bash
cd /home/user         # Go to specific path
cd ..                 # Go up one level
cd ~                  # Go to home directory
cd -                  # Go to previous directory
cd                    # Go to home directory
```

### `tree` - Display Directory Tree
Shows directory structure as a tree.
```bash
tree                  # Show tree from current directory
tree -L 2             # Limit depth to 2 levels
tree -a               # Include hidden files
tree -d               # Directories only
```

---

## File Operations

### `touch` - Create Empty File
Creates a new empty file or updates timestamp.
```bash
touch file.txt                    # Create new file
touch file1.txt file2.txt         # Create multiple files
touch /path/to/file.txt           # Create with full path
```

### `cat` - Concatenate and Display Files
Displays file contents.
```bash
cat file.txt                      # Display file
cat file1.txt file2.txt           # Display multiple files
cat > newfile.txt                 # Create file (Ctrl+D to save)
cat file1.txt file2.txt > merged.txt  # Merge files
```

### `less` - View File Page by Page
View large files with navigation.
```bash
less file.txt                     # View file (q to quit)
less +F file.txt                  # Follow file (like tail -f)
# Navigation: Space (next page), b (previous), / (search), q (quit)
```

### `head` - Display Beginning of File
Shows first lines of a file.
```bash
head file.txt                     # First 10 lines
head -n 20 file.txt               # First 20 lines
head -c 100 file.txt              # First 100 bytes
```

### `tail` - Display End of File
Shows last lines of a file.
```bash
tail file.txt                     # Last 10 lines
tail -n 20 file.txt               # Last 20 lines
tail -f /var/log/syslog           # Follow file (real-time)
tail -f file.txt                  # Watch file for changes
```

### `cp` - Copy Files/Directories
Copy files and directories.
```bash
cp file.txt copy.txt              # Copy file
cp file.txt /path/to/dest/        # Copy to directory
cp -r dir1 dir2                   # Copy directory recursively
cp -i file.txt dest.txt           # Interactive (prompt before overwrite)
cp -u source.txt dest.txt         # Copy only if newer
```

### `mv` - Move/Rename Files
Move or rename files and directories.
```bash
mv oldname.txt newname.txt        # Rename file
mv file.txt /path/to/dest/        # Move file
mv -i file.txt dest/              # Interactive mode
mv dir1 dir2                      # Rename/move directory
```

### `rm` - Remove Files/Directories
Delete files and directories.
```bash
rm file.txt                       # Remove file
rm -i file.txt                    # Interactive (confirm)
rm -r directory                   # Remove directory recursively
rm -rf directory                  # Force remove (use carefully!)
rm *.txt                          # Remove all .txt files
```

### `mkdir` - Make Directory
Create directories.
```bash
mkdir newdir                      # Create directory
mkdir -p path/to/nested/dir       # Create nested directories
mkdir dir1 dir2 dir3              # Create multiple directories
mkdir -m 755 newdir               # Create with permissions
```

### `rmdir` - Remove Empty Directory
Delete empty directories.
```bash
rmdir emptydir                    # Remove empty directory
rmdir -p path/to/empty/dir        # Remove nested empty directories
```

---

## File Viewing and Editing

### `nano` - Simple Text Editor
Easy-to-use terminal text editor.
```bash
nano file.txt                     # Edit file
nano +10 file.txt                 # Open at line 10
# Ctrl+O (save), Ctrl+X (exit), Ctrl+W (search)
```

### `vi` / `vim` - Advanced Text Editor
Powerful text editor.
```bash
vi file.txt                       # Edit file
vim file.txt                      # Enhanced vi
# i (insert mode), Esc (normal mode), :w (save), :q (quit), :wq (save & quit)
```

### `echo` - Display Text
Print text or variables.
```bash
echo "Hello World"                # Print text
echo $HOME                        # Print variable
echo "text" > file.txt            # Write to file (overwrite)
echo "text" >> file.txt           # Append to file
```

---

## File Searching

### `find` - Search for Files
Find files and directories.
```bash
find . -name "*.txt"              # Find .txt files in current dir
find /home -name "file.txt"       # Find specific file
find . -type f                    # Find files only
find . -type d                    # Find directories only
find . -size +100M                # Find files larger than 100MB
find . -mtime -7                  # Modified in last 7 days
find . -name "*.log" -delete      # Find and delete
find . -name "*.sh" -exec chmod +x {} \;  # Find and execute command
```

### `locate` - Fast File Search
Quickly find files using database.
```bash
locate file.txt                   # Find file
locate "*.conf"                   # Find config files
sudo updatedb                     # Update locate database
```

### `which` - Locate Command
Find location of executable.
```bash
which python                      # Find python executable
which -a python                   # Show all matches
```

### `whereis` - Locate Binary/Source/Manual
Find binary, source, and manual pages.
```bash
whereis bash                      # Find bash locations
whereis -b python                 # Binary only
```

---

## Text Processing

### `grep` - Search Text
Search for patterns in files.
```bash
grep "pattern" file.txt           # Search in file
grep -r "pattern" directory       # Recursive search
grep -i "pattern" file.txt        # Case-insensitive
grep -n "pattern" file.txt        # Show line numbers
grep -v "pattern" file.txt        # Invert match (exclude)
grep -c "pattern" file.txt        # Count matches
grep -l "pattern" *.txt           # List matching files
grep -E "pat1|pat2" file.txt      # Extended regex (OR)
```

### `sed` - Stream Editor
Edit text streams.
```bash
sed 's/old/new/' file.txt         # Replace first occurrence per line
sed 's/old/new/g' file.txt        # Replace all occurrences
sed -i 's/old/new/g' file.txt     # Edit file in-place
sed '5d' file.txt                 # Delete line 5
sed -n '10,20p' file.txt          # Print lines 10-20
```

### `awk` - Text Processing
Pattern scanning and processing.
```bash
awk '{print $1}' file.txt         # Print first column
awk '{print $1, $3}' file.txt     # Print columns 1 and 3
awk -F: '{print $1}' /etc/passwd  # Use : as delimiter
awk 'NR==5' file.txt              # Print line 5
awk '/pattern/ {print}' file.txt  # Print matching lines
```

### `sort` - Sort Lines
Sort file contents.
```bash
sort file.txt                     # Sort alphabetically
sort -r file.txt                  # Reverse sort
sort -n file.txt                  # Numerical sort
sort -u file.txt                  # Sort and remove duplicates
sort -k 2 file.txt                # Sort by column 2
```

### `uniq` - Remove Duplicates
Remove duplicate adjacent lines.
```bash
uniq file.txt                     # Remove duplicates
uniq -c file.txt                  # Count occurrences
uniq -d file.txt                  # Show only duplicates
sort file.txt | uniq              # Sort then remove duplicates
```

### `wc` - Word Count
Count lines, words, characters.
```bash
wc file.txt                       # Lines, words, bytes
wc -l file.txt                    # Count lines
wc -w file.txt                    # Count words
wc -c file.txt                    # Count bytes
```

### `cut` - Cut Columns
Extract sections from lines.
```bash
cut -d: -f1 /etc/passwd           # First field, : delimiter
cut -c 1-10 file.txt              # Characters 1-10
cut -f1,3 file.txt                # Fields 1 and 3 (tab-delimited)
```

### `tr` - Translate Characters
Replace or delete characters.
```bash
echo "hello" | tr 'a-z' 'A-Z'     # Convert to uppercase
tr -d '0-9' < file.txt            # Delete all digits
tr -s ' ' < file.txt              # Squeeze multiple spaces
```

---

## File Permissions

### `chmod` - Change File Permissions
Modify file permissions.
```bash
chmod 755 file.sh                 # rwxr-xr-x
chmod +x script.sh                # Add execute permission
chmod -w file.txt                 # Remove write permission
chmod u+x file.sh                 # Add execute for user
chmod g-w file.txt                # Remove write for group
chmod o+r file.txt                # Add read for others
chmod -R 755 directory            # Recursive
```

**Permission Numbers:**
- 7 = rwx (read, write, execute)
- 6 = rw- (read, write)
- 5 = r-x (read, execute)
- 4 = r-- (read only)
- 0 = --- (no permissions)

### `chown` - Change Ownership
Change file owner and group.
```bash
chown user file.txt               # Change owner
chown user:group file.txt         # Change owner and group
chown -R user:group directory     # Recursive
chown :group file.txt             # Change group only
```

### `chgrp` - Change Group
Change file group ownership.
```bash
chgrp groupname file.txt          # Change group
chgrp -R groupname directory      # Recursive
```

---

## System Information

### `uname` - System Information
Display system information.
```bash
uname -a                          # All information
uname -s                          # Kernel name
uname -r                          # Kernel release
uname -m                          # Machine hardware
```

### `hostname` - Show/Set Hostname
Display or set system hostname.
```bash
hostname                          # Show hostname
hostname -I                       # Show IP addresses
```

### `uptime` - System Uptime
Show how long system has been running.
```bash
uptime                            # Show uptime and load average
uptime -p                         # Pretty format
```

### `date` - Display Date/Time
Show or set system date and time.
```bash
date                              # Current date and time
date +%Y-%m-%d                    # Format: 2024-01-15
date +%H:%M:%S                    # Time only
date +%s                          # Unix timestamp
```

### `cal` - Calendar
Display calendar.
```bash
cal                               # Current month
cal 2024                          # Year
cal 12 2024                       # December 2024
```

### `whoami` - Current User
Display current username.
```bash
whoami                            # Show current user
```

### `who` - Logged In Users
Show who is logged in.
```bash
who                               # Show logged in users
who -a                            # All information
```

### `w` - Who and What
Show who is logged in and what they're doing.
```bash
w                                 # Detailed user activity
```

---

## Process Management

### `ps` - Process Status
Display running processes.
```bash
ps                                # Current shell processes
ps aux                            # All processes (detailed)
ps -ef                            # All processes (full format)
ps -u username                    # Processes for specific user
ps aux | grep process_name        # Find specific process
```

### `top` - Real-Time Process Viewer
Interactive process viewer.
```bash
top                               # Real-time processes
top -u username                   # Processes for user
# q (quit), k (kill), M (sort by memory), P (sort by CPU)
```

### `htop` - Interactive Process Viewer
Enhanced version of top.
```bash
htop                              # Interactive viewer (if installed)
# F9 (kill), F6 (sort), F5 (tree view)
```

### `kill` - Terminate Process
Send signal to process.
```bash
kill PID                          # Terminate process
kill -9 PID                       # Force kill
kill -15 PID                      # Graceful termination
killall process_name              # Kill by name
pkill process_name                # Kill by pattern
```

### `bg` - Background Process
Resume suspended job in background.
```bash
bg                                # Resume last suspended job
bg %1                             # Resume job 1
```

### `fg` - Foreground Process
Bring background job to foreground.
```bash
fg                                # Bring last job to foreground
fg %1                             # Bring job 1 to foreground
```

### `jobs` - List Jobs
Show background jobs.
```bash
jobs                              # List jobs
jobs -l                           # With process IDs
```

### `nohup` - Run Immune to Hangups
Run command immune to hangups.
```bash
nohup command &                   # Run in background
nohup ./script.sh > output.log &  # With output redirect
```

---

## Disk Usage

### `df` - Disk Free Space
Show disk space usage.
```bash
df                                # All filesystems
df -h                             # Human-readable
df -T                             # Show filesystem type
df /home                          # Specific filesystem
```

### `du` - Disk Usage
Show directory space usage.
```bash
du                                # Current directory
du -h                             # Human-readable
du -sh *                          # Summary for each item
du -sh directory                  # Total for directory
du -h --max-depth=1               # One level deep
```

### `free` - Memory Usage
Display memory usage.
```bash
free                              # Show memory usage
free -h                           # Human-readable
free -m                           # In megabytes
free -g                           # In gigabytes
```

---

## Networking

### `ping` - Test Network Connectivity
Send ICMP echo requests.
```bash
ping google.com                   # Ping host
ping -c 4 google.com              # Send 4 packets
ping -i 2 google.com              # 2 second interval
```

### `ifconfig` - Network Interface Configuration
Configure network interfaces (older).
```bash
ifconfig                          # Show all interfaces
ifconfig eth0                     # Show specific interface
```

### `ip` - Network Configuration
Modern network configuration tool.
```bash
ip addr show                      # Show IP addresses
ip link show                      # Show network interfaces
ip route show                     # Show routing table
ip addr add 192.168.1.10/24 dev eth0  # Add IP address
```

### `netstat` - Network Statistics
Show network connections and statistics.
```bash
netstat -tuln                     # Listening ports
netstat -an                       # All connections
netstat -r                        # Routing table
netstat -i                        # Interface statistics
```

### `ss` - Socket Statistics
Modern replacement for netstat.
```bash
ss -tuln                          # Listening TCP/UDP ports
ss -s                             # Summary statistics
ss -at                            # All TCP connections
```

### `curl` - Transfer Data from URLs
Transfer data from/to servers.
```bash
curl https://example.com          # GET request
curl -o file.html https://example.com  # Save to file
curl -I https://example.com       # Headers only
curl -X POST https://api.com/data # POST request
curl -d "param=value" https://api.com  # POST with data
```

### `wget` - Download Files
Download files from web.
```bash
wget https://example.com/file.zip # Download file
wget -c url                       # Continue interrupted download
wget -r https://example.com       # Recursive download
wget -b url                       # Download in background
```

### `scp` - Secure Copy
Copy files over SSH.
```bash
scp file.txt user@host:/path/     # Copy to remote
scp user@host:/path/file.txt .    # Copy from remote
scp -r directory user@host:/path/ # Copy directory
scp -P 2222 file.txt user@host:/path/  # Custom port
```

### `ssh` - Secure Shell
Connect to remote server.
```bash
ssh user@hostname                 # Connect to host
ssh -p 2222 user@hostname         # Custom port
ssh -i key.pem user@hostname      # Use specific key
ssh user@host 'command'           # Run remote command
```

### `rsync` - Remote Sync
Efficiently sync files.
```bash
rsync -av source/ dest/           # Archive mode, verbose
rsync -avz source/ user@host:/dest/  # Over SSH with compression
rsync -av --delete source/ dest/  # Delete extra files in dest
rsync -av --progress source/ dest/  # Show progress
```

---

## Compression and Archives

### `tar` - Archive Files
Create and extract tar archives.
```bash
tar -czf archive.tar.gz files/    # Create gzip archive
tar -xzf archive.tar.gz           # Extract gzip archive
tar -cjf archive.tar.bz2 files/   # Create bzip2 archive
tar -xjf archive.tar.bz2          # Extract bzip2 archive
tar -tf archive.tar.gz            # List contents
tar -xzf archive.tar.gz -C /path/ # Extract to specific path
```

### `gzip` - Compress Files
Compress files with gzip.
```bash
gzip file.txt                     # Compress (creates file.txt.gz)
gzip -d file.txt.gz               # Decompress
gzip -k file.txt                  # Keep original
gzip -9 file.txt                  # Maximum compression
```

### `gunzip` - Decompress Gzip
Decompress gzip files.
```bash
gunzip file.txt.gz                # Decompress
gunzip -c file.txt.gz > output    # Keep compressed file
```

### `zip` - Create ZIP Archive
Create zip archives.
```bash
zip archive.zip file1 file2       # Create archive
zip -r archive.zip directory/     # Recursive
zip -e archive.zip file.txt       # Encrypt archive
```

### `unzip` - Extract ZIP Archive
Extract zip archives.
```bash
unzip archive.zip                 # Extract archive
unzip -l archive.zip              # List contents
unzip archive.zip -d /path/       # Extract to path
unzip -q archive.zip              # Quiet mode
```

---

## Package Management

### APT (Debian/Ubuntu)

```bash
sudo apt update                   # Update package list
sudo apt upgrade                  # Upgrade packages
sudo apt install package          # Install package
sudo apt remove package           # Remove package
sudo apt purge package            # Remove with config files
sudo apt autoremove               # Remove unused dependencies
sudo apt search package           # Search for package
sudo apt show package             # Show package details
```

### YUM/DNF (RedHat/CentOS/Fedora)

```bash
sudo yum update                   # Update all packages
sudo yum install package          # Install package
sudo yum remove package           # Remove package
sudo yum search package           # Search package
sudo dnf install package          # DNF (newer)
```

---

## User Management

### `useradd` - Add User
Create new user.
```bash
sudo useradd username             # Create user
sudo useradd -m username          # Create with home directory
sudo useradd -m -s /bin/bash user # With specific shell
```

### `usermod` - Modify User
Modify existing user.
```bash
sudo usermod -aG groupname user   # Add to group
sudo usermod -s /bin/bash user    # Change shell
sudo usermod -L username          # Lock user
```

### `userdel` - Delete User
Remove user.
```bash
sudo userdel username             # Delete user
sudo userdel -r username          # Delete with home directory
```

### `passwd` - Change Password
Change user password.
```bash
passwd                            # Change your password
sudo passwd username              # Change other user's password
```

### `su` - Switch User
Switch to another user.
```bash
su username                       # Switch to user
su -                              # Switch to root
su - username                     # Switch with environment
```

### `sudo` - Execute as Superuser
Run command with elevated privileges.
```bash
sudo command                      # Run as root
sudo -u username command          # Run as specific user
sudo -i                           # Login shell as root
sudo !!                           # Repeat last command with sudo
```

---

## System Control

### `systemctl` - System Service Manager
Manage systemd services.
```bash
sudo systemctl start service      # Start service
sudo systemctl stop service       # Stop service
sudo systemctl restart service    # Restart service
sudo systemctl status service     # Check status
sudo systemctl enable service     # Enable at boot
sudo systemctl disable service    # Disable at boot
systemctl list-units --type=service  # List all services
```

### `service` - Service Control (older)
Manage services (older systems).
```bash
sudo service nginx start          # Start service
sudo service nginx stop           # Stop service
sudo service nginx restart        # Restart service
sudo service nginx status         # Check status
```

### `shutdown` - Shutdown/Reboot
Shutdown or reboot system.
```bash
sudo shutdown now                 # Shutdown immediately
sudo shutdown -h now              # Halt system
sudo shutdown -r now              # Reboot now
sudo shutdown -h +10              # Shutdown in 10 minutes
sudo shutdown -c                  # Cancel shutdown
```

### `reboot` - Reboot System
Restart the system.
```bash
sudo reboot                       # Reboot now
sudo reboot -f                    # Force reboot
```

---

## Miscellaneous

### `history` - Command History
Show command history.
```bash
history                           # Show all history
history 20                        # Show last 20 commands
history | grep command            # Search history
!123                              # Run command 123 from history
!!                                # Repeat last command
!$                                # Last argument of previous command
```

### `alias` - Create Alias
Create command shortcuts.
```bash
alias ll='ls -la'                 # Create alias
alias                             # List all aliases
unalias ll                        # Remove alias
```

### `man` - Manual Pages
Display command manual.
```bash
man command                       # Show manual
man -k keyword                    # Search manuals
man 5 passwd                      # Specific section
```

### `clear` - Clear Screen
Clear terminal screen.
```bash
clear                             # Clear screen
# Or press Ctrl+L
```

### `exit` - Exit Shell
Exit current shell or terminal.
```bash
exit                              # Exit shell
exit 0                            # Exit with status code
```

### `ln` - Create Links
Create symbolic or hard links.
```bash
ln -s /path/to/file link          # Create symbolic link
ln /path/to/file hardlink         # Create hard link
ln -sf /path/to/file link         # Force overwrite symbolic link
```

### `diff` - Compare Files
Show differences between files.
```bash
diff file1.txt file2.txt          # Show differences
diff -u file1.txt file2.txt       # Unified format
diff -r dir1 dir2                 # Compare directories
```

### `xargs` - Build Command Lines
Build and execute commands from input.
```bash
find . -name "*.txt" | xargs rm   # Delete all .txt files
echo "file1 file2" | xargs touch  # Create multiple files
ls | xargs -n 1 echo              # One argument per line
```

### `tee` - Read from Input and Write to Output
Write to file and stdout simultaneously.
```bash
command | tee output.txt          # Write to file and screen
command | tee -a output.txt       # Append to file
```

---

## Keyboard Shortcuts

```
Ctrl + C        - Interrupt/kill current process
Ctrl + Z        - Suspend current process
Ctrl + D        - Exit current shell (EOF)
Ctrl + L        - Clear screen
Ctrl + A        - Move to beginning of line
Ctrl + E        - Move to end of line
Ctrl + U        - Clear line before cursor
Ctrl + K        - Clear line after cursor
Ctrl + W        - Delete word before cursor
Ctrl + R        - Search command history
Tab             - Auto-complete
!!              - Repeat last command
```

---

## Redirection and Pipes

```bash
command > file.txt                # Redirect output (overwrite)
command >> file.txt               # Redirect output (append)
command < file.txt                # Redirect input
command 2> error.log              # Redirect stderr
command &> output.log             # Redirect stdout and stderr
command1 | command2               # Pipe output to another command
command > /dev/null 2>&1          # Suppress all output
```

---

## Examples of Command Combinations

```bash
# Find and delete old log files
find /var/log -name "*.log" -mtime +30 -delete

# Find largest files in directory
du -ah /path | sort -rh | head -20

# Search for text in files and show with line numbers
grep -rn "search_term" /path/to/search

# Count number of files in directory
ls -1 | wc -l

# Monitor log file in real-time
tail -f /var/log/syslog | grep error

# Create backup with timestamp
tar -czf backup-$(date +%Y%m%d).tar.gz /path/to/backup

# Find and replace in multiple files
find . -name "*.txt" -exec sed -i 's/old/new/g' {} \;

# Show processes using most memory
ps aux --sort=-%mem | head -10

# Show processes using most CPU
ps aux --sort=-%cpu | head -10

# Disk usage sorted by size
du -sh * | sort -rh

# Network connections by IP
netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn
```
