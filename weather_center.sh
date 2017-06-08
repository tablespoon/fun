#!/bin/bash

# by Todd

LOCATION=Los_Angeles

# necessary to keep read from mishandling spaces
IFS=$'\n'

while true; do

	date

	# get weather without trailing spaces
	weather=$(curl -s wttr.in/$LOCATION | awk 'NR>1 && NR<=7' | sed -r 's/\s+$//g')

	# determine pad size for centering
	screen_width=$(tput cols)
	# sed strips coloring
	max_width=$(echo "$weather" | sed -r 's/\x1B[^m]+m//g' | wc -L)
	pad_width=$(( (screen_width - max_width) / 2 - 1 ))


	while read -r line; do
		printf "%-${pad_width}s%s\n" " " "$line"
	done <<<"$weather"

	sleep 20m

done
