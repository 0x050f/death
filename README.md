# death

Death is a fourth elf 64 bits virus (evolution of [War](https://github.com/y3ll0w42/war)). The virus will infect every files under `/tmp/test` and `/tmp/test2` by adding itself to the targeted binary and it signature: `Death version 1.0 (c)oded by lmartin`. Then when you will run binary that were under `/tmp/test` or `/tmp/test2`, they will infect every binary under `/tmp/test` and `/tmp/test2` as well. :)

The difference with War is the metamorphic behaviour on most of the machine code. Everytime it infect a file, it change !

```
cp -f /bin/ls /tmp/test/ls && cp -f /bin/ls /tmp/test/ls2
./Death
objdump -b binary -D /tmp/test/ls -m i386:x86-64 > ls && objdump -b binary -D /tmp/test/ls2 -m i386:x86-64 > ls2; diff -y --suppress-common-lines ls ls2 | grep '^' | wc -l
```

### Bonus:
+ `make fsociety` will compile a Death version that will infect everything from the root directory ( ⚠️  Please run it on a VM - you can run it as root tho :) )
+ `make fsociety` will also do a `bind shell` on port `4444` when itself or a infected file is launched as root :3
+ Death will pack a part of his code when executing on host using a LZSS compression and depack itself to copy the packed part on the infected binary

## Demo
fsociety mode infection:
![alt text](https://raw.githubusercontent.com/y3ll0w42/death/main/img/demo1.png)
Try running the debugger on it:
![alt text](https://raw.githubusercontent.com/y3ll0w42/death/main/img/demo2.png)

## Compilation

```
make
```

## Execution

```
./Death
```

## How

Death will copy itself (and pack itself on host) after the PT_LOAD executable of the targeted binary if there is enough space between the segment and the next one to fit. It will also change the previous entry of the program by itself and enhance p_filesz and p_memsz of the segment to be executable. It will also add to it replication, some tips of the targeted file like the previous entry to jump on it after it execution.

```
-----------------------
|       HEADER        |
-----------------------
|         ...         |
-----------------------
|                     |
|       PT_LOAD       |
|        [R E]        |
|                     |
| - - - - - - - - - - |
|       PARAMS        |
|   -   -   -   -   - |
|      SIGNATURE      |
|   -   -   -   -   - |
|                     |
|       DEATH         |
|                     |
-----------------------
|         ...         |
```

If there is not enough space after the PT_LOAD executable, Death will seek a PT_NOTE and change it to PT_LOAD executable, then append itself at the end of the executable and change the entry point to it.

## Debug-mode

The debug mode deactivate the protection against tracer like gdb or strace and remove forks to easier debugging
```
export BUILD=debug
make
```
This will create a executable named `./debug-Death` and source are compiled in a folder `./debug-compiled_srcs`.
