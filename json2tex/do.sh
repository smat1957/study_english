#!/bin/sh
#xattr -d com.apple.quarantine do0.sh
#xattr -d com.apple.quarantine do1.sh
#xattr -d com.apple.quarantine do2.sh
#!/bin/sh
echo "Running main.py"
/usr/bin/python3 ./main.py

echo "Running do1.sh"
sh ./do1.sh "$1"

echo "Running do2.sh"
sh ./do2.sh "$1"

