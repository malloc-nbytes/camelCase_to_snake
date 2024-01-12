#!/bin/bash

set -xe

ocamlfind ocamlc -o main main.ml -linkpkg -package unix
