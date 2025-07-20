#!/bin/sh
cd /Users/mat/Documents/PycharmProjects/json2tex
#open -a Skim "$1".pdf
#/Applications/Skim.app/Contents/MacOS/Skim "$1".pdf
open -a Skim "$1".pdf
sleep 1
osascript -e 'tell application "Skim" to revert front document'

