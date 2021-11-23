#!/bin/bash

exec=$1

if [ -z "$exec" ]
then
	exec=Famine
fi

signature="Famine version 1.0 (c)oded by lmartin"

test_path_no_exec() {
	rm -rf /tmp/test /tmp/test2
	output=$(./$exec)
	assertEquals "" "$output"
	mkdir -p /tmp/test
	output=$(./$exec)
	assertEquals "" "$output"
	mkdir -p /tmp/test2
	output=$(./$exec)
	assertEquals "" "$output"
	rm -rf /tmp/test
	output=$(./$exec)
	assertEquals "" "$output"
	mkdir -p /tmp/test
	output=$(./$exec)
	assertEquals "" "$output"
}

test_host_infection() {
	cp -f /bin/ls /tmp/test/ls
	output=$(strings /tmp/test/ls | grep Famine)
	assertEquals "" "$output"
	./$exec
	ps | grep $exec &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep $exec &> /dev/null
	done
	output=$(strings /tmp/test/ls | grep Famine)
	assertEquals "$signature" "$output"
	output=$(/tmp/test/ls /tmp/test)
	assertEquals "ls" "$output"
}

test_simple_infection() {
	cp -f /bin/pwd /tmp/test2/pwd
	output=$(strings /tmp/test2/pwd | grep Famine)
	assertEquals "" "$output"
	/tmp/test/ls &> /dev/null
	ps | grep ls &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep ls &> /dev/null
	done
	output=$(strings /tmp/test2/pwd | grep Famine)
	assertEquals "$signature" "$output"
	output_cmd=$(/bin/pwd)
	output=$(/tmp/test2/pwd)
	assertEquals "$output_cmd" "$output"
}

test_subdir_infection() {
	mkdir -p /tmp/test/lol/xd
	cp -f /bin/ls /tmp/test/lol
	cp -f /bin/pwd /tmp/test/lol/xd
	output=$(strings /tmp/test/lol/ls | grep Famine)
	assertEquals "" "$output"
	output=$(strings /tmp/test/lol/xd/pwd | grep Famine)
	assertEquals "" "$output"

	# test from host
	./$exec
	ps | grep $exec &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep $exec &> /dev/null
	done
	output=$(strings /tmp/test/lol/ls | grep Famine)
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/lol/xd/pwd | grep Famine)
	assertEquals "$signature" "$output"

	cp -f /bin/ls /tmp/test
	./$exec
	# test from infected file
	cp -f /bin/ls /tmp/test/lol
	cp -f /bin/pwd /tmp/test/lol/xd
	output=$(/tmp/test/ls)
	ps | grep ls &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep ls &> /dev/null
	done
	output=$(strings /tmp/test/lol/ls | grep Famine)
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/lol/xd/pwd | grep Famine)
	assertEquals "$signature" "$output"
}

test_process_no_infection() {
	cp -f /bin/ls /tmp/test/ls
	output=$(strings /tmp/test/ls | grep Famine)
	assertEquals "" "$output"

	# test from host
	cat /dev/zero &
	pid=$!
	sleep 0.25
	./$exec
	ps | grep $exec &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep $exec &> /dev/null
	done
	output=$(strings /tmp/test/ls | grep Famine)
	assertEquals "" "$output"
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"
	kill -9 $pid

	# infect /tmp/test/ls
	./$exec
	ps | grep $exec &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep $exec &> /dev/null
	done
	output=$(strings /tmp/test/ls | grep Famine)
	assertEquals "$signature" "$output"
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"

	# test from /tmp/test/ls infected
	cp -f /bin/pwd /tmp/test2/pwd
	cat /dev/zero &
	pid=$!
	ps | grep ls &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep ls &> /dev/null
	done
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"
	output=$(strings /tmp/test2/pwd | grep Famine)
	assertEquals "" "$output"
	kill -9 $pid

	# infect
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"
	output=$(strings /tmp/test2/pwd | grep Famine)
	assertEquals "$signature" "$output"
	output_cmd=$(/bin/pwd)
	output=$(/tmp/test2/pwd)
	assertEquals "$output_cmd" "$output"
}

. shunit2
