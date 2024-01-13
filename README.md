# camelCase_to_snake

Kill those camels!

# Description
This program takes a list of files/directories and will search through each file.
If a variable encountered is in the camelCase format, it will *_fix_* it and make
it snake_case.

# Requirements
* OCaml - https://ocaml.org/install

# Usage
```
ccts <file1> <file2> <dir1> <file3> ...
```
`ccts` will go through each file, scanning and replace any disgusting camels encountered.
If one of the entries is a directory, it will recursively go through each item inside of it.

Before dealing with a file, it will ask what to do, namely: `Replace all? (y)es / (n)o / (c)ustom`.
If `y` is entered, it will *de-camel-ify* the file, immediately proceeding to the next. If `n` is
entered, that file will be skipped. If `c` is entered, you will be taken into a mode where you choose
which variables should be changed by highlighting them and showing the current line (*fancy*).
When in this custom mode, more options will appear: `Replace? (y)es / (n)o / ! [replace rest]`. The first
two options are self-explanatory, but the third option `!` will go ahead and kill the rest of the camels in
the file (including the current selection).

## Rules
So what even is camel case? In `ccts`, camel case is:

1. The first letter is lowercase
2. Some variable (except for the first) must be uppercase
3. If a variable only has one uppercase letter *and* it's
the last letter, it is _not_ camelcase.

### Examples
`myTestVariable`: camel case

`mytestvariabLe`: camel case

`MyTestVariable`: not camel case

`mytestvariablE`: not camel case

# Build
```
cd ./CamelCase_to_snake/src/
./build.sh
```
[Note]: (`./build.sh clean` will remove all .cmi and .cmo files.)

# Install
```
cd ./CamelCase_to_snake/src/
./install.sh
```
[Note]: `install.sh` will `./build.sh clean` and then `./build.sh` for you.

<small> *"Just like in code, where snake_case gracefully slithers through the syntax, effortlessly gliding from variable to variable, leaving no humps in its path, it's clear that in the programming desert, snakes are simply superior to camels. No need for extra bumps when you can have the smooth elegance of snake_case."*

\- ChatGPT for some reason </small>

