# pestilence

Pestilence is a second elf 64 bits virus (evolution of [Famine](https://github.com/ska42/famine)). The virus will infect every files under `/tmp/test` and `/tmp/test2` by adding itself to the targeted binary and it signature: `Pestilence version 1.0 (c)oded by lmartin`. Then when you will run binary that were under `/tmp/test` or `/tmp/test2`, they will infect every binary under `/tmp/test` and `/tmp/test2` as well. :)

The difference with Famine is the code obfuscation.

### Bonus:
+ `make fsociety` will compile a Pestilence version that will infect everything from the root directory ( ⚠️  Please run it on a VM - you can run it as root tho :) )
+ Pestilence will pack a part of his code when executing on host using a LZSS compression and depack itself to copy the packed part on the infected binary

## Demo

## Compilation

```
make
```

## Execution

```
./Pestilence
```

## How

Pestilence will copy itself (and pack itself on host) after the PT_LOAD executable of the targeted binary if there is enough space between the segment and the next one to fit. It will also change the previous entry of the program by itself and enhance p_filesz and p_memsz of the segment to be executable. It will also add to it replication, some tips of the targeted file like the previous entry to jump on it after it execution.

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
|      PESTILENCE     |
|                     |
-----------------------
|         ...         |
```
