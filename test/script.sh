#!/bin/bash

exec=$1

if [ -z "$exec" ]
then
	exec=Famine
fi

signature="Famine version 1.0 (c)oded by lmartin"

test_path_no_exec() {
	rm -rf /tmp/test /tmp/test2
	./$exec &> output
	mkdir -p /tmp/test
	./$exec &>> output
	mkdir -p /tmp/test2
	./$exec &>> output
	rm -rf /tmp/test
	./$exec &>> output
	mkdir -p /tmp/test
	output=$(cat output)
	assertEquals "$output" ""
	rm -rf ouput
}

test_host_infection() {
	cp -f /bin/ls /tmp/test/ls
	output=$(strings /tmp/test/ls | grep Famine)
	assertEquals "$ouput" ""
	./$exec
	output=$(strings /tmp/test/ls | grep Famine)
	assertEquals "$output" "$signature"
	output=$(/tmp/test/ls /tmp/test)
	assertEquals "$output" "ls"
}

test_simple_infection(){
	cp -f /bin/pwd /tmp/test2/pwd
	output=$(strings /tmp/test2/pwd | grep Famine)
	assertEquals "$output" ""
	/tmp/test/ls &> /dev/null
	output=$(strings /tmp/test2/pwd | grep Famine)
	assertEquals "$output" "$signature"
	output_cmd=$(/bin/pwd)
	output=$(/tmp/test2/pwd)
	assertEquals "$output" "$output_cmd"
}

. shunit2
