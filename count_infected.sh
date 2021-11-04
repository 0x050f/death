#!/bin/bash

signature="Famine version 1.0 (c)oded by lmartin"

i=0
for filename in /tmp/test/*
do
	output=$(strings $filename | grep Famine)
	if [ "$output" == "$signature" ]
	then
		i=$(( $i + 1 ))
	fi
done

nb_files=$(ls -la /tmp/test | wc -l)
nb_files=$(( $nb_files - 2 )) # . and ..
echo "infected $i / $nb_files"
