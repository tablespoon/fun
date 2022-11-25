#!/usr/bin/env bash

# This script should only be used to see how many valid options remained after completing a Worldle puzzle.
# This can also be used to cheat, but doing so only cheats yourself. We all know you're better than that.

file=solution_set

# parse and process arguments
for clue in ${@}; do
	color=${clue:0:1}
	position=${clue:1:1}
	value=${clue:2}

	case $color in
		g) green[$position]=$value;;
		y) yellow[$position]+=$value;;
		x) eliminated+=${clue:1};;
	esac

done

# compile regex from what we know about each position
for ((i=1; i<=$(wc -L <$file); i++)); do
	if [[ ${green[$i]} ]]; then
		word+=${green[$i]}
	elif [[ ${yellow[$i]} ]]; then
		word+=[^${yellow[$i]}]
	else
		word+=.
	fi
done

# build initial wordlist
words=$(grep -E "^$word$" "$file")

# remove words containing any eliminated letters
[[ $eliminated ]] && words=$(grep -v "[${eliminated}]" <<<"$words")

# get list of unique yellows
yellows=$(sed 's/./&\n/g' <<<${yellow[@]} | sort -u)

# discard words that don't include the known yellows
for letter in $yellows; do
	words=$(grep $letter <<<"$words")
done

# print matches
echo "$words"
