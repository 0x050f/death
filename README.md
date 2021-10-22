# famine

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
|                     |
|       PT_LOAD       |
|        [R E]        |
|                     |
- - - - - - - - - - - -
|       INJECT        |
- - - - - - - - - - - -
|                     |
|       FAMINE        |
|                     |
- - - - - - - - - - - -
|      SIGNATURE      |
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