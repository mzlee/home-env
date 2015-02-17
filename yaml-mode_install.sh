#!/bin/bash

cd yaml-mode
make
make install INSTALLLIBDIR=${HOME}/.home_env/emacs.d/site-lisp
