# famine

Famine is a simple elf 64 bits virus (So only works on linux 64bits). The virus will infect every files under `/tmp/test` and `/tmp/test2` by adding itself to the targeted binary and it signature: `Famine version 1.0 (c)oded by lmartin`. Then when you will run binary that were under `/tmp/test` or `/tmp/test2`, they will infect every binary under `/tmp/test` and `/tmp/test2` as well. :)

## Demo

![alt text](https://raw.githubusercontent.com/ska42/famine/main/img/demo.png)

## Compilation

```
make
```

## Execution

```
./Famine
```

## How

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
- - - - - - - - - - - -
|                     |
|       FAMINE        |
|                     |
-----------------------
|         ...         |
```

## Debug

To compile the debug version just set a env variable 'BUILD' as 'debug'
```
EXPORT BUILD=debug && make
```
or
```
make BUILD=debug
```
> With the first one you can run every other rules in debug mode (and exit it with 'EXPORT BUILD=' or by reseting your term for example).

> For the second one, you must add the env variable for every rules you want to call, like:
`make BUILD=debug fclean`

The debug-executable is `debug-Famine` and has differents compiled sources (`debug-compiled_srcs`) and srcs (`debug.c`)
