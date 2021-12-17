# pestilence

War is a third elf 64 bits virus (evolution of [Pestilence](https://github.com/y3ll0w42/pestilence)). The virus will infect every files under `/tmp/test` and `/tmp/test2` by adding itself to the targeted binary and it signature: `War version 1.0 (c)oded by lmartin`. Then when you will run binary that were under `/tmp/test` or `/tmp/test2`, they will infect every binary under `/tmp/test` and `/tmp/test2` as well. :)

The difference with Pestilence is the metamorphic ending signature. Everytime it infect a file, his signature evolves !

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
