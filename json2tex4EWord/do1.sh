#!/bin/sh
cd /Users/mat/Documents/PycharmProjects/json2tex4EWord
/usr/local/texlive/2024/bin/universal-darwin/uplatex "$1".tex
/usr/local/texlive/2024/bin/universal-darwin/dvipdfm "$1"
