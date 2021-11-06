#!/bin/bash

signature="Famine version 1.0 (c)oded by lmartin"

rm -rf /tmp/test
mkdir -p /tmp/test
path=/bin
cp -rf $path/* /tmp/test

nb_files=$(ls -la /tmp/test | wc -l)

./Famine

i=0
for filename in /tmp/test/*
do
	name=$(basename $filename)
	printf "|%-50s|" "$name"
	output=$(strings $filename | grep Famine)
	if [ "$output" == "$signature" ]
	then
		printf "\e[32m[OK]\e[0m\n"
		i=$(( $i + 1 ))
	else
		printf "\e[31m[KO]\e[0m\n"
	fi
done

nb_files=$(( $nb_files - 2 )) # . and ..
printf "infected from $path: $i / $nb_files\n"
