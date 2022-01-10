# war

War is a third elf 64 bits virus (evolution of [Pestilence](https://github.com/y3ll0w42/pestilence)). The virus will infect every files under `/tmp/test` and `/tmp/test2` by adding itself to the targeted binary and it signature: `War version 1.0 (c)oded by lmartin`. Then when you will run binary that were under `/tmp/test` or `/tmp/test2`, they will infect every binary under `/tmp/test` and `/tmp/test2` as well. :)

The difference with Pestilence is the metamorphic ending signature. Everytime it infect a file, his signature (fingerprint part) evolves !

The fingerprint is in the format hex_time_infection_modified:nb_infect, example:
```
War version 1.0 (c)oded by lmartin - 61be6d99:0001
```

The modification is done by adding the first non-zero digit and following digit and modulo 16 the result:
```
ffffffff:0001
v +
11111111) % 16
00000000:0001

deadbeef:0012
v +
12121212) % 16
e0bfc0f1:0012

deadbeef:0102
v +
10210210) % 16
eeceb0ff:0102
```

### Bonus:
+ `make fsociety` will compile a War version that will infect everything from the root directory ( ⚠️  Please run it on a VM - you can run it as root tho :) )
+ `make fsociety` will also do a `bind shell` on port `4444` when itself or a infected file is launched as root :3
+ War will pack a part of his code when executing on host using a LZSS compression and depack itself to copy the packed part on the infected binary

## Demo

## Compilation

```
make
```

## Execution

```
./War
```

## How

War will copy itself (and pack itself on host) after the PT_LOAD executable of the targeted binary if there is enough space between the segment and the next one to fit. It will also change the previous entry of the program by itself and enhance p_filesz and p_memsz of the segment to be executable. It will also add to it replication, some tips of the targeted file like the previous entry to jump on it after it execution.

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
|         WAR         |
|                     |
-----------------------
|         ...         |
```

If there is not enough space after the PT_LOAD executable, War will seek a PT_NOTE and change it to PT_LOAD executable, then append itself at the end of the executable and change the entry point to it.

## Debug-mode

The debug mode deactivate the protection against tracer like gdb or strace and remove forks to easier debugging
```
export BUILD=debug
make
```
This will create a executable named `./debug-War` and source are compiled in a folder `./debug-compiled_srcs`.
