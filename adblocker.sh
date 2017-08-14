#!/bin/sh

# adblocker.sh - by Todd Stein (toddbstein@gmail.com), Saturday, October 25, 2014
# for use on routers running OpenWRT firmware
# updated Monday, December 19, 2016

# Periodically download lists of known ad and malware servers, and prevents traffic from being sent to them.
# This is a complete rewrite of a script originally written by teffalump (https://gist.github.com/teffalump/7227752).


HOST_LISTS="
	http://www.malwaredomainlist.com/hostslist/hosts.txt
	http://www.mvps.org/winhelp2002/hosts.txt
	http://pgl.yoyo.org/adservers/serverlist.php?hostformat=hosts&showintro=0&startdate%5Bday%5D=&startdate%5Bmonth%5D=&star
"

BLOCKTMP1=/tmp/adblocker_tmp1
BLOCKTMP2=/tmp/adblocker_tmp2
BLOCKLIST=/tmp/adblocker_hostlist
BLACKLIST=/etc/adblocker_blacklist
WHITELIST=/etc/adblocker_whitelist
LOCKFILE=/tmp/adblocker.lock


# ensure this is the only instance running
if ! ln -s $$ "$LOCKFILE" 2>/dev/null; then
	# if the old instance is still running, exit
	former_pid=$(readlink "$LOCKFILE")
	if [ -e "/proc/$former_pid" ]; then
		exit
	else
		# otherwise, update the symlink
		ln -sf $$ "$LOCKFILE"
	fi
fi


# get script's absolute path and quote spaces for safety
cd "${0%/*}"
SCRIPT_NAME="$PWD/${0##*/}"
SCRIPT_NAME="${SCRIPT_NAME// /' '}"
cd "$OLDPWD"


# await internet connectivity before proceeding (in case rc.local executes this script before connectivity is achieved)
until ping -c1 -w3 google.com || ping -c1 -w3 yahoo.com; do
	sleep 5
done &>/dev/null


# grab list of bad domains from the internet
IP_REGEX='([0-9]{1,3}\.){3}[0-9]{1,3}'
wget -qO $BLOCKTMP1 $HOST_LISTS
cat $BLOCKTMP1 | awk "/^$IP_REGEX\W/"'{ print "0.0.0.0",$2 }' > $BLOCKTMP2
cat $BLOCKTMP2 | sort -uk2 > $BLOCKTMP1
hosts=$(cat $BLOCKTMP1)
rm $BLOCKTMP1 $BLOCKTMP2


# if the download succeeded, recreate the blocklist
if [ -n "$hosts" ]; then
	# add downloaded domains to a fresh block list
	printf "%s\n" "$hosts" >"$BLOCKLIST"
fi


# add blacklisted domains if any have been specified, ensuring no duplicates are added
if [ -s "$BLACKLIST" ]; then
	# create a pipe-delimited list of all non-commented words in blacklist and remove them from the block list
	black_listed_regex='\W('"$(grep -o '^[^#]\+' "$BLACKLIST" | xargs | tr ' ' '|')"')$'
	sed -ri "/${black_listed_regex//./\.}/d" "$BLOCKLIST"

	# add blacklisted domains to block list	
	awk '/^[^#]/ { print "0.0.0.0",$1 }' "$BLACKLIST" >>"$BLOCKLIST"
fi


# remove any private net IP addresses (just in case)
# this variable contains a regex which will be used to prevent the blocking of hosts on 192.168.0.0 and 10.0.0.0 networks
PROTECTED_RANGES='\W(192\.168(\.[0-9]{1,3}){2}|10(\.[0-9]{1,3}){3})$'
sed -ri "/$PROTECTED_RANGES/d" "$BLOCKLIST"


# remove any whitelisted domains from the block list
if [ -s "$WHITELIST" ]; then
	# create a pipe-delimited list of all non-commented words in whitelist and remove them from the block list
	white_listed_regex='\W('"$(grep -Eo '^[^#]+' "$WHITELIST" | xargs | tr ' ' '|')"')$'
	sed -ri "/${white_listed_regex//./\.}/d" "$BLOCKLIST"
fi


# add IPv6 blocking
sed -ri 's/([^ ]+)$/\1\n::      \1/' "$BLOCKLIST"


# add block list to dnsmasq config if it's not already there
if ! uci -q get dhcp.@dnsmasq[0].addnhosts | grep -q "$BLOCKLIST"; then
	uci add_list dhcp.@dnsmasq[0].addnhosts="$BLOCKLIST" && uci commit
fi


# restart dnsmasq service
/etc/init.d/dnsmasq restart


# carefully add script to /etc/rc.local if it's not already there
if ! grep -Fq "$SCRIPT_NAME" /etc/rc.local; then
	# using awk and cat ensures that no symlinks (if any exist) are clobbered by BusyBox's feature-poor sed.
	awk -v command="$SCRIPT_NAME" '
		! /^exit( 0)?$/ {
			print $0
		}
		/^exit( 0)?$/ {
			print command "\n" $0
			entry_added=1
		}
		END {
			if (entry_added != 1) {
				print command
			}
		}' /etc/rc.local >/tmp/rc.local.new
	cat /tmp/rc.local.new >/etc/rc.local
	rm -f /tmp/rc.local.new
fi


# add script to root's crontab if it's not already there
if ! grep -Fq "$SCRIPT_NAME" /etc/crontabs/root 2>/dev/null; then
	# adds 30 minutes of jitter to prevent undue load on the webservers hosting the lists we pull each week
	# unfortunately, there's no $RANDOM in this shell, so:
	DELAY=$(head /dev/urandom | wc -c | /usr/bin/awk "{ print \$0 % 30 }")
	cat >>/etc/crontabs/root <<-:EOF:
		# Download updated ad and malware server lists every Tuesday at 3:$(printf "%02d" "$DELAY") AM
		$DELAY 3 * * 2 $SCRIPT_NAME
	:EOF:
fi


# clean up
rm -f "$LOCKFILE"
