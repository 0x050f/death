#!/bin/bash

exec=$1

if [ -z "$exec" ]
then
	exec=Death
fi

signature="Death version 1.0 (c)oded by lmartin"

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
	wait_for_process $exec
	assertEquals "" "$output"
	mkdir -p /tmp/test
	output=$(./$exec)
	wait_for_process $exec
	assertEquals "" "$output"
	mkdir -p /tmp/test2
	output=$(./$exec)
	wait_for_process $exec
	assertEquals "" "$output"
	rm -rf /tmp/test
	output=$(./$exec)
	wait_for_process $exec
	assertEquals "" "$output"
	mkdir -p /tmp/test
	output=$(./$exec)
	wait_for_process $exec
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
	wait_for_process ls
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
	wait_for_process echo
	output=$(/tmp/test/echo "UwU")
	wait_for_process echo
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
	wait_for_process pwd
	output=$(/tmp/test2/pwd)
	wait_for_process pwd
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

test_no_multiple_infection() {
	cp -f /bin/ls /tmp/test/ls
	cp -f /bin/whoami /tmp/test/whoami
	cp -f /bin/echo /tmp/test/echo
	./$exec
	wait_for_process $exec
	./$exec
	wait_for_process $exec
	/tmp/test/ls &> /dev/null
	wait_for_process ls
	/tmp/test/ls &> /dev/null
	wait_for_process ls
	output=$(strings /tmp/test/whoami | grep "$signature" | wc -l)
	assertEquals "1" "$output"
	output=$(strings /tmp/test/echo | grep "$signature" | wc -l)
	assertEquals "1" "$output"
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
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test/ls | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	output_cmd=$(/bin/ls)
	output=$(/tmp/test/ls)
	assertEquals "$output_cmd" "$output"
	kill -9 $pid
	wait_for_process cat

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
	output_cmd=$(/bin/ls)
	wait_for_process ls
	output=$(/tmp/test/ls)
	wait_for_process ls
	assertEquals "$output_cmd" "$output"
	output=$(strings /tmp/test2/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "" "$output"
	kill -9 $pid
	wait_for_process cat

	# infect
	output_cmd=$(/bin/ls)
	wait_for_process ls
	output=$(/tmp/test/ls)
	wait_for_process ls
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

test_machine_code_diff() {
	cp -f /bin/ls /tmp/test/ls
	cp -f /bin/ls /tmp/test/ls2
	./$exec
	wait_for_process $exec
	output=$(objdump -b binary -D /tmp/test/ls -m i386:x86-64 > ls && objdump -b binary -D /tmp/test/ls2 -m i386:x86-64 > ls2; diff -y --suppress-common-lines ls ls2 | grep '^' | wc -l)
	echo "$output line diff"
	assertNotEquals "$output" "1"
	cp -f /bin/ls /tmp/test/ls
	./$exec
	wait_for_process $exec
	cp -f /bin/pwd /tmp/test/pwd
	cp -f /bin/pwd /tmp/test/pwd2
	/tmp/test/ls &> /dev/null
	wait_for_process ls
	output=$(strings /tmp/test/pwd | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(strings /tmp/test/pwd2 | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	output=$(objdump -b binary -D /tmp/test/pwd -m i386:x86-64 > pwd && objdump -b binary -D /tmp/test/pwd2 -m i386:x86-64 > pwd2; diff -y --suppress-common-lines pwd pwd2 | grep '^' | wc -l)
	echo "$output line diff"
	assertNotEquals "$output" "1"
}

test_cascade_infection(){
	cp -f /bin/ls /tmp/test2/ls1
	./$exec
	wait_for_process $exec
	output=$(strings /tmp/test2/ls1 | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	cp -f /bin/ls /tmp/test2/ls2
	/tmp/test2/ls1 &> /dev/null
	wait_for_process ls1
	output=$(strings /tmp/test2/ls2 | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	cp -f /bin/ls /tmp/test2/ls3
	/tmp/test2/ls2 &> /dev/null
	wait_for_process ls2
	output=$(strings /tmp/test2/ls3 | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	cp -f /bin/ls /tmp/test2/ls4
	/tmp/test2/ls3 &> /dev/null
	wait_for_process ls3
	output=$(strings /tmp/test2/ls4 | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
	cp -f /bin/ls /tmp/test2/ls5
	/tmp/test2/ls4 &> /dev/null
	wait_for_process ls4
	output=$(strings /tmp/test2/ls5 | grep "$signature" | cut -d'-' -f1 | sed 's/.$//')
	assertEquals "$signature" "$output"
}

. shunit2
