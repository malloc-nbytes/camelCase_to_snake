#!/bin/bash

set -xe

if [ "$1" == "clean" ];
then
    rm ./*.cmo ./*.cmi ./ccts
else
    ocamlfind ocamlc -o ccts main.ml -linkpkg -package unix
fi
