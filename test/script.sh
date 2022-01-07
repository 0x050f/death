#!/bin/bash

exec=$1

if [ -z "$exec" ]
then
	exec=War
fi

signature="War version 1.0 (c)oded by lmartin"

wait_for_process() {
	process=$1
	ps | grep $process &> /dev/null
	while [ $? -eq 0 ]
	do
		sleep 0.25 # wait a bit for infect
		ps | grep $process &> /dev/null
	done
}

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
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(/tmp/test/ls /tmp/test)
	assertEquals "ls" "$output"
}

test_pt_note_infection() {
	cp -f /bin/echo /tmp/test/echo
	output=$(./$exec)
	assertEquals "" "$output"
	wait_for_process $exec
	output=$(strings /tmp/test/echo | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output_cmd=$(/bin/echo "UwU")
	output=$(/tmp/test/echo "UwU")
	assertEquals "$output_cmd" "$output"
}

test_simple_infection() {
	cp -f /bin/pwd /tmp/test2/pwd
	output=$(strings /tmp/test2/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	/tmp/test/ls &> /dev/null
	wait_for_process ls
	output=$(strings /tmp/test2/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output_cmd=$(/bin/pwd)
	output=$(/tmp/test2/pwd)
	assertEquals "$output_cmd" "$output"
}

test_bullshit_file() {
	cp -f /bin/ls /tmp/test/ls
	cp -f /bin/ls /tmp/test/a
	head -c 500 /bin/ls > /tmp/test/b
	cp -f /bin/ls /tmp/test/c
	cp -f /bin/ls /tmp/test/d
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test/a | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/b | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	output=$(strings /tmp/test/c | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/d | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	cp -f /bin/ls /tmp/test/a
	head -c 500 /bin/ls > /tmp/test/b
	cp -f /bin/ls /tmp/test/c
	cp -f /bin/ls /tmp/test/d
	/tmp/test/ls &> /dev/null
	wait_for_process ls
	output=$(strings /tmp/test/a | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/b | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	output=$(strings /tmp/test/c | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/d | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
}

test_subdir_infection() {
	mkdir -p /tmp/test/lol/xd
	cp -f /bin/ls /tmp/test/lol
	cp -f /bin/pwd /tmp/test/lol/xd
	output=$(strings /tmp/test/lol/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	output=$(strings /tmp/test/lol/xd/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"

	# test from host
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test/lol/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/lol/xd/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"

	cp -f /bin/ls /tmp/test
	./$exec
	wait_for_process $exec
	# test from infected file
	cp -f /bin/ls /tmp/test/lol
	cp -f /bin/pwd /tmp/test/lol/xd
	output=$(/tmp/test/ls)
	wait_for_process ls
	output=$(strings /tmp/test/lol/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/lol/xd/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
}

test_process_no_infection() {
	cp -f /bin/ls /tmp/test/ls
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"

	# test from host
	cat /dev/zero > /dev/null &
	pid=$!
	sleep 0.25
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"
	kill -9 $pid

	# infect /tmp/test/ls
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"

	# test from /tmp/test/ls infected
	cp -f /bin/pwd /tmp/test2/pwd
	cat /dev/zero > /dev/null &
	pid=$!
	wait_for_process ls
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"
	output=$(strings /tmp/test2/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	kill -9 $pid

	# infect
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"
	output=$(strings /tmp/test2/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output_cmd=$(/bin/pwd)
	output=$(/tmp/test2/pwd)
	assertEquals "$output_cmd" "$output"
}

test_process_strace() {
	cp -f /bin/ls /tmp/test/ls
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	output=$(strace ./$exec 2>&1 | grep DEBUGGING..)
	assertEquals "write(2, \"DEBUGGING..\n\", 12DEBUGGING.." "$output"
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	cp -f /bin/pwd /tmp/test2/pwd
	output=$(strings /tmp/test2/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	output=$(strace /tmp/test/ls 2>&1 | grep DEBUGGING..)
	assertEquals "write(2, \"DEBUGGING..\n\", 12DEBUGGING.." "$output"
	/tmp/test/ls > /dev/null
	wait_for_process ls
	output=$(strings /tmp/test2/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
}

. shunit2
