#!/bin/bash

set -x

MAX_DELAY=3     # maximum delay (in minutes) between queries
VERIFICATION_RETRIES=3	# number of times to retest a site to try to prevent false positives
USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:94.0) Gecko/20100101 Firefox/94.0"


recipients=(
	"123456789@vtext.com"
	"123456789@txt.att.net"
	"example@gmail.com"
)
sites=(
	"https://www.amazon.com/PlayStation-5-Digital/dp/B08FC6MR62/"
	"https://www.target.com/c/playstation-5-video-games/-/N-hj96d?lnk=snav_rd_playstation_5"
	"https://www.gamestop.com/consoles-hardware/playstation-5/consoles?prefn1=buryMaster&prefv1=In%20Stock&view=new"
)
names=(
	"Amazon"
	"Target"
	"GameStop"
)
strings=(
	"Currently unavailable"
	"Consoles will be viewable when inventory is available."
        "Hmm, we didn&rsquo;t find anything for"
)

while true; do

	until curl -s --compressed -A "$USER_AGENT" "www.google.com" >/dev/null; do
		sleep 5
	done

	for ((i=0; i<${#sites[@]}; i++)); do

		[[ ${notification_sent[$i]} ]] && continue

		# if we can't find the string after VERIFICATION_RETRIES, send alert
		retry_counter=0
		while ! grep -q "${strings[$i]}" <<<"$(curl -s --compressed -A "$USER_AGENT" "${sites[$i]}")"; do

			if [[ $retry_counter -eq $VERIFICATION_RETRIES ]]; then
				notification_sent[$i]="yes"
				for recipient in ${recipients[@]}; do
					msmtp "$recipient" <<<"Playstation 5 may be in stock at ${names[$i]}!

${sites[$i]}"
				done
				break
			fi
			((retry_counter++))
				
		done

	done

	# we're done when alerts have been sent for all tracked sites
	[[ ${#notification_sent[@]} -eq ${#sites[@]} ]] && exit

	sleep $((60 + RANDOM % (MAX_DELAY*60-60)))
done
