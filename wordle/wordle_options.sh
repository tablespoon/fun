#!/usr/bin/env bash

# This script should only be used to see how many valid options remained after completing a Worldle puzzle.
# This can also be used to cheat, but doing so only cheats yourself. We all know you're better than that.

file=solution_set

# parse and process arguments
for clue in ${@}; do
	color=${clue:0:1}
	position=${clue:1:1}
	letter=${clue:2}

	case $color in
		g) green[$position]=$letter;;
		y) yellow[$position]+=$letter;;
		x) eliminated+=${clue:1};;
	esac

done

# compile regex from what we know about each position
for ((i=1; i<=$(wc -L <$file); i++)); do
	if [[ ${green[$i]} ]]; then
		word[$i]=${green[$i]}
	elif [[ ${yellow[$i]} ]]; then
		word[$i]=[^${yellow[$i]}]
		yellows+=${yellow[$i]}
	else
		word[$i]=.
	fi
done
word=${word[@]} 
word=${word// /}

# build initial wordlist - remove words with eliminated letters and grab words that match regex from remaining set
words=$(grep -v "[${eliminated:- }]" $file | grep -E "^$word$")

# get unique list of yellows
yellows=$(sed 's/./&\n/g' <<<$yellows | sort -u)

# remove words that don't contain all yellows
for i in $yellows; do
	words=$(grep ${i} <<<"$words")
done

echo "$words"
