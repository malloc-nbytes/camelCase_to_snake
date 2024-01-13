#!/bin/bash

set -xe

ocamlfind ocamlc -o ccts main.ml -linkpkg -package unix
