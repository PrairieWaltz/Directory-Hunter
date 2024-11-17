#!/bin/bash

# Check for Dependencies
for cmd in gobuster ffuf; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: $cmd is not installed. Please install it and try again."
        exit 1
    fi
done

# Fn to Verify Wordlist
list_server() {
    echo -e "\033[32mWould you like to use the same wordlist? (y or n): \033[0m"
    read -r yorn
    if [ "$yorn" != "y" ]; then
        echo -e "\nPlease enter the path to your preferred wordlist: "
        read -r wordlist
        # Verify if the file exists and is readable
        if [ ! -f "$wordlist" ] || [ ! -r "$wordlist" ]; then
            echo -e "\033[31mError: The provided file does not exist or is not readable. Please try again.\033[0m"
            list_server # Re-prompt for input if invalid
        else
            echo -e "\033[32mUsing wordlist: $wordlist\033[0m"
        fi
    else
        echo -e "\033[32mUsing the previously chosen wordlist.\033[0m"
    fi
}

# Get URL
echo -e "\n\033[32mLet's find some sub-Directories.\033[0m\nPlease enter a URL: "
read url
sleep .75

# Get save path
saveFolder=SubDirs
echo -e "\nOutput will be saved at $saveFolder"
mkdir -p $saveFolder
echo -e "Directory $saveFolder created\n"
sleep .75

# Get Wordlist
echo -e "\nPlease enter a path to your preferred wordlist: "
read wordlist
echo -e "Using $wordlist\n"
sleep .75

# GOBUSTER
echo -e "Running gobuster on $url using wordlist at $wordlist\n"
gobuster dir -u $url -w $wordlist -o $saveFolder/goBusterSubDirs.txt
echo -e "\n$(date +%b-%d-%Y-%H:%M)" >> $saveFolder/goBusterSubDirs.txt
echo -e "Gobuster complete. File saved as goBusterSubDirs.txt\n"
sleep 1

# Verify Wordlist
list_server
sleep .75

# FFUF (trailing)
echo "Running trailing FFUF on $url using wordlist at $wordlist"
ffuf -u $url/FUZZ -mc all -fc 404 -c -t 50 -w $wordlist -of json -o $saveFolder/ffufTrail.json
cat $saveFolder/ffufTrail.json | jq -r '.results[] | "\(.status): \(.input.FUZZ)"' > $saveFolder/ffufTrail.txt
echo -e "\n$(date +%b-%d-%Y-%H:%M)" | tee -a $saveFolder/ffufTrail.json >> $saveFolder/ffufTrail.txt
echo -e "\nTrailing FFUF complete. File(s) saved as ffufTrail.txt\n"
sleep .25

# Verify Wordlist
list_server
sleep .75

# FFUF (leading)
# Clean URL for leading ffuf scan
cleanUrl=$(echo "$url" | sed 's~http[s]\?://~~')

echo "Running forward FFUF on $url2 using wordlist at $wordlist"
ffuf -u http://FUZZ/$cleanUrl -mc all -fc 404 -c -t 50 -w $wordlist -of json -o $saveFolder/ffufFront.json
cat $saveFolder/ffufFront.json | jq -r '.results[] | "\(.status): \(.input.FUZZ)"' > $saveFolder/ffufFront.txt
echo -e "\n$(date +%b-%d-%Y-%H:%M)" | tee -a $saveFolder/ffufFront.json >> $saveFolder/ffufFront.txt

# Uncomment below to automatically delete the JSON file after parsing ffuf data
rm $saveFolder/ffufTrail.json $saveFolder/ffufFront.json
echo -e "\nFront FFUF complete. File(s) saved as ffufFront.txt\n"
sleep 1

echo "Thanks. All done"
exit 0