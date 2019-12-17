# automatic_wondershaper_wombat

A script in bash (with some assorted tools) to automagically shape network 
traffic using a modified version of the wondershaper script (and maintaining 
your high LAN network speeds).

## Contents
 1. [About](#1-about)
 2. [License](#2-license)
 3. [Prerequisites](#3-prerequisites)
 4. [Installation](#4-installation)
 5. [Usage](#5-usage)
 
***

## 1. About

A script in bash (with some assorted tools) to automagically shape network 
traffic using a modified version of the wondershaper script (and maintaining 
your high LAN network speeds).  This is a per-machine setup.

It is designed to be run under Network Manager, but can be invoked manually 
(or from a cron job).

## 2. License

This project is licensed under the GNU general public license. For the full license, see `LICENSE`.

## 3. Prerequisites

* [speedtest-cli](https://github.com/sivel/speedtest-cli)

These are probably already installed or are easily available from your distro:

* [awk](http://www.gnu.org/software/gawk/manual/gawk.html)
* [grep](http://en.wikipedia.org/wiki/Grep)
* [bc](https://www.geeksforgeeks.org/bc-command-linux-examples)
* [ifconfig](https://en.wikipedia.org/wiki/Ifconfig)

Optional:  

* [logger](https://linux.die.net/man/1/logger)

## 4. Installation

* Clone or download the repository; change into the directory.
* Install `wondershaper` (see below) 
* [Edit your sudoers file](https://www.maketecheasier.com/edit-sudoers-file-linux/) and add the following line at the end:  

`ALL ALL=NOPASSWD:/sbin/wondershaper`

* `sudo mkdir /etc/NetworkManager/dispatcher.d` (if it doesn't exist)
* `sudo cp ./autobandwidth.sh /etc/NetworkManager/dispatcher.d/90-autobandwidth` 


### Installing wondershaper

The wondershaper script is rather old, and has one big glaring omission - it 
also rate-limits your LAN connectivity.  My modified copy, using [this guide](http://forums.opensuse.org/english/get-technical-help-here/network-internet/454307-wondershaper-modification-exclude-lan-should-included.html), changes the rate limit for LAN traffic to 85% of a 10MB link 
for subnet 192.168.1.* .  If your LAN subnet is different (or has a higher link 
speed), you will want to change those values.

You are free to utilize your distro's package for wondershaper, or inspect and 
use my modified copy so that LAN traffic is shaped differently than internet 
traffic.  

If you are using *my* script:  

`sudo cp ./wondershaper.sh /sbin/wondershaper`

This guide (and script) are written assuming that `wondershaper` 
is located in `/sbin` and is executable.  So if you're not using mine and are 
using your distro's version, install it normally and then type:

`sudo ln -s $(which wondershaper) /sbin/wondershaper`

to create a symlink to `/sbin/wondershaper` if it does not yet exist.

Then make sure it's executable:

`sudo chmod a+x /sbin/wondershaper`

To install `autobandwidth` for Network Manager, first type

`sudo mkdir /etc/NetworkManager/dispatcher.d`  

so that the directory exists if it's not already there.  Then type

`sudo cp ./autobandwidth.sh /etc/NetworkManager/dispatcher.d/60-autobandwidth`

to copy the script.

If you're using it manually, copy it (or create a symlink to) somewhere in your `$PATH`.

## 5. Usage

If you have installed it properly and Network Manager is installed, it should 
run automagically when the interface changes.  It will (if not specified by 
Network Manager) find the active link, measure bandwidth using speedtest-cli, 
and then shape your internet traffic to 85% of measured bandwidth.

It waits until the load is less than 2 before running; this is hardcoded in 
the script.  It's line 29: `while (( $(echo "$MyLoad > 2" |bc -l) )); do`.  
Change 2 if you want or need to.

If you run `autobandwidth` without any arguments, it will look for links that 
are up.  It will choose the first ethernet link first, and if there's no wired 
connection, it will look for (and choose) the first wireless connection that is up.

**IMPORTANT** `autobandwidth` uses the `eno[0-9]` and `wlp[0-9]s[0-9]` 
interface naming conventions! 

If you run `autobandwidth quit` manually, it will clear the existing queues 
on the automatically chosen link.  If you wish to specify the link in question, 
try this: `autobandwidth eno1 quit` or `autobandwidth wlp2s0 quit`, 
replacing the link names with your own.

This might also be useful to run as a cronjob if your connection changes or is 
funky.  

It will output a minimal result to /tmp/bandwidthqueues as well if you wish to 
use that data in conky, etc.
