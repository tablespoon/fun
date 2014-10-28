#!/bin/sh

# adblocker.sh - by Todd Stein (toddbstein@gmail.com), Saturday, October 25, 2014

# Periodically download lists of known ad and malware servers, and prevents traffic from being sent to them.
# This is a complete rewrite of a script originally written by teffalump (https://gist.github.com/teffalump/7227752).


HOST_LISTS="
	http://adaway.org/hosts.txt
	http://www.malwaredomainlist.com/hostslist/hosts.txt
	http://www.mvps.org/winhelp2002/hosts.txt
"

BLOCKLIST=/tmp/adblocker_hostlist
BLACKLIST=/etc/adblocker_blacklist
WHITELIST=/etc/adblocker_whitelist
SCRIPT_NAME=/root/bin/adblocker.sh


# initialize block list
>$BLOCKLIST

# grab blacklisted domains if any have been specified
[ -s "$BLACKLIST" ] && awk '/^[^#]/ { print "0.0.0.0",$1 }' $BLACKLIST >>$BLOCKLIST

# grab host lists from the internet
wget -qO- $HOST_LISTS | sed -rn 's/^(127.0.0.1|0.0.0.0)/0.0.0.0/p' | awk '{ print $1,$2 }' | sort -uk2 >>$BLOCKLIST

# remove any whitelisted domains from the block list
if [ -s "$WHITELIST" ]; then
	# create a pipe-delimited list of all non-commented words in whitelist
	white_listed_regex=`echo \`grep -o '^[^#]\+' $WHITELIST\` | tr ' ' '|'`
	sed -ri "/$white_listed_regex/d" $BLOCKLIST
fi

# add IPv6 blocking
sed -ri 's/([^ ]+)$/\1\n::      \1/' $BLOCKLIST

# add block list to dnsmasq config if it's not already there
if ! uci get dhcp.@dnsmasq[0].addnhosts | grep -q "$BLOCKLIST"; then
	uci add_list dhcp.@dnsmasq[0].addnhosts=$BLOCKLIST && uci commit
fi

# restart dnsmasq service
/etc/init.d/dnsmasq restart

# add script to root's crontab if it's not already there
grep -q "$SCRIPT_NAME" /etc/crontabs/root || cat >>/etc/crontabs/root <<-:EOF:
	# Download updated ad and malware server lists every Tuesday at 3 AM
	0 3 * * 2 /bin/sh $SCRIPT_NAME
:EOF:
