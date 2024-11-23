#!/bin/bash

# Check for Dependencies
for cmd in gobuster ffuf; do
    command -v $cmd &>/dev/null || { echo "Error: $cmd is not installed. Please install it and try again."; exit 1; }
done

#Use predefined wordlist or choose your own
list_finder() {
    echo -e "\033[32mPlease choose a wordlist:\033[0m"
    echo "1. Small"
    echo "2. Big"
    echo "3. Common"
    echo "4. Rock You"
    echo -e "5. Choose your own adventure\n"
    
    read -p "Enter your choice (1-5): " choice
    sleep .75
    
    case $choice in
        1)
            wordlist="/usr/share/wordlists/dirb/small.txt"
            echo -e "\n\033[32mYou chose Small.\033[0m"
        ;;
        2)
            wordlist="/usr/share/wordlists/dirb/big.txt"
            echo -e "\n\033[32mYou chose Big.\033[0m"
        ;;
        3)
            wordlist="/usr/share/wordlists/dirb/common.txt"
            echo -e "\n\033[32mYou chose Common.\033[0m"
        ;;
        4)
            wordlist="/usr/share/wordlists/rockyou.txt"
            echo -e "\n\033[32mYou chose Rock You.\033[0m"
        ;;
        5)
            read -p "Enter the full path to your wordlist: " custom_path
            if [ -f "$custom_path" ]; then
                wordlist="$custom_path"
                echo -e "\n\033[32mCustom wordlist set to '$wordlist'.\033[0m"
            else
                echo "Error: File not found. Please try again."
                choose_wordlist
            fi
        ;;
        *)
            echo "Invalid choice. Please try again.\n"
            choose_wordlist
        ;;
    esac
}

# Fn to Verify Wordlist
list_server() {
    echo -e "Would you like to use the same wordlist? (y or n): "
    read -r yorn
    [ "$yorn" = "y" ] && { echo -e "\n\033[32mUsing the previously chosen wordlist.\n\033[0m"; return; }
    
    list_finder
}

######Start######
echo -e "\n                        WELCOME TO \033[93m
DDDD   III  RRRR     H   H  U   U  N   N  TTTTT  EEEE  RRRR
D   D   I   R   R    H   H  U   U  NN  N    T    E     R   R
D   D   I   RRRR   - HHHHH  U   U  N N N    T    EEE   RRRR
D   D   I   R   R    H   H  U   U  N  NN    T    E     R   R
DDDD   III  R   R    H   H   UUU   N   N    T    EEEE  R   R
============================================================>
\033[0m"

# Get URL
echo -e "\033[32mLet's find some sub-Directories.\033[0m\nPlease enter a URL: "
read url
sleep .75

# Get save path
saveFolder=SubDirs
echo -e "\n\033[32mOutput will be saved at $saveFolder\033[0m"
mkdir -p $saveFolder
echo -e "Directory $saveFolder created\n"
sleep .75

# Get Wordlist
list_finder
echo -e "Using $wordlist\n"
sleep 1.25

# GOBUSTER
echo -e "\033[32mRunning gobuster on $url using wordlist at $wordlist\033[0m\n"
gobuster dir -u $url -w $wordlist --exclude-length 118 -o $saveFolder/goBusterSubDirs.txt
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


