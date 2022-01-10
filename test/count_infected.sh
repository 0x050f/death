#!/bin/bash

exec=$1

if [ -z "$exec" ]
then
	exec=Death
fi

signature="Death version 1.0 (c)oded by lmartin"
path=/bin

# FROM HOST
rm -rf /tmp/test /tmp/test2
mkdir -p /tmp/test
printf "copying $path/* to /tmp/test...\n"
cp -f $path/* /tmp/test &> /dev/null

nb_files=$(ls -la /tmp/test | wc -l)

printf "infect...\n"
time ./$exec
printf "wait for process to finish...\n"
ps | grep $exec &> /dev/null
while [ $? -eq 0 ]
do
	sleep 1 # wait a bit for infect
	printf "."
	ps | grep $exec &> /dev/null
done

printf "\nchecking files...\n"
i=0
j=0
for filename in /tmp/test/*
do
	output=$(readelf -l $filename &> /dev/null)
	if [ $? -eq 0 ]
    then
		name=$(basename $filename)
#		printf "|%-50s|" "$name"
		output=$(strings $filename | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
		if [ "$output" == "$signature" ]
		then
#			printf "\e[32m[OK]\e[0m\n"
			i=$(( $i + 1 ))
		else
			rm -rf $filename
#			printf "\e[31m[KO]\e[0m\n"
		fi
	else
		j=$(( $j + 1 ))
		rm -rf $filename
	fi
done

nb_files=$(( $nb_files - 2 )) # . and ..
nb_files=$(( $nb_files - $j ))
printf "host: infected from ${path}: ${i} / ${nb_files} elf files\n"
rm -rf /tmp/test /tmp/test2

# FROM binaries
mkdir -p /tmp/test /tmp/test2
cp -f /bin/ls /tmp/test/ls
./$exec
cp -f $path/* /tmp/test2 &> /dev/null
printf "copying $path/* to /tmp/test2...\n"

nb_files=$(ls -la /tmp/test2 | wc -l)

printf "infect...\n"
time $(/tmp/test/ls &> /dev/null)
printf "wait for process to finish...\n"
ps | grep ls &> /dev/null
while [ $? -eq 0 ]
do
	sleep 1 # wait a bit for infect
	printf "."
	ps | grep ls &> /dev/null
done

printf "\nchecking files...\n"
i=0
j=0
for filename in /tmp/test2/*
do
	output=$(readelf -l $filename &> /dev/null)
	if [ $? -eq 0 ]
    then
		name=$(basename $filename)
#		printf "|%-50s|" "$name"
		output=$(strings $filename | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
		if [ "$output" == "$signature" ]
		then
#			printf "\e[32m[OK]\e[0m\n"
			i=$(( $i + 1 ))
		else
			rm -rf $filename
#			printf "\e[31m[KO]\e[0m\n"
		fi
	else
		j=$(( $j + 1 ))
		rm -rf $filename
	fi
done

nb_files=$(( $nb_files - 2 )) # . and ..
nb_files=$(( $nb_files - $j ))
printf "infected_file: infected from $path: $i / $nb_files elf files\n"
#rm -rf /tmp/test /tmp/test2
