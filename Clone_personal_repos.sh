#!/bin/bash

# This is a minimal set of ANSI/VT100 color codes
END="\e[0m"
BOLD="\e[1m"
ITALIC="\e[3m"

# Colors
GREEN="\e[32m"
BLUE="\e[36m"
LYELLOW="\e[93m"
RED="\e[31m"

# Replace <YOUR_TOKEN> with your personal GitHub access token
TOKEN="<YOUR_TOKEN>"
ARG=( "${@}" )
private_opt=false

function usage () {
    echo -e $BLUE$BOLD"USAGE: "$END"./get_repos.sh [ -p | --private ]\n"
    echo -e $BLUE$BOLD"DESCRIPTION:"$END
	echo -e "\tThis script allows you to"$BOLD" clone all your personal repositories"$END
	echo -e "\tYou can also specify to clone your private repositories with the "$ITALIC"-p"$END" or "$ITALIC"--private"$END" option\n"
	echo -e "\tTo do this, you need to specify a personal GitHub access token."
    echo -e $ITALIC"\tIf you need help for this => "$END"https://docs.github.com/fr/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens"
	exit 0
}

if [[ "$1" == "-h" ]] || [[ "$1" == "-help" ]] || [[ "$1" == "--help" ]]; then usage ; fi

# Installing jq if it's not already done so
if ! [ -x "$(command -v jq)" ]; then
    echo -e $GREEN"=> Installing jq..."
    if [ -x "$(command -v dnf)" ]; then
        sudo dnf install -qq jq > /dev/null 2>&1 || (echo -e $RED"=> Error: jq install went wrong"$END; exit 1)
    elif [ -x "$(command -v apt-get)" ]; then
        sudo apt-get install -q jq > /dev/null 2>&1 || (echo -e $RED"=> Error: jq install went wrong"$END; exit 1)
    elif [ -x "$(command -v zypper)" ]; then
        sudo zypper install --non-interactive jq > /dev/null 2>&1 || (echo -e $RED"=> Error: jq install went wrong"$END; exit 1)
    elif [ -x "$(command -v pacman)" ]; then
        sudo pacman -S --noconfirm jq > /dev/null 2>&1 || (echo -e $RED"=> Error: jq install went wrong"$END; exit 1)
    else
        echo -e $RED"=> Error: Your distribution is not supported"$END
        exit 1
    fi
fi

repositories=$(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/user/repos?affiliation=owner")

# Verify is token is valid
if [[ $repositories == *"Bad credentials"* ]]; then
    echo -e $RED"Invalid token. Please provide a valid GitHub token."
    exit 1
fi

get() {
    echo ${row} | base64 --decode | jq -r ${1}
}

clone() {
    if [ -d "$repo_name" ]; then
        echo -e $BOLD"$repo_name"$END$LYELLOW" is already cloned or a directory with the same name exist"$END
    else
        git clone $ssh_url --quiet
        echo -e $BOLD"$repo_name"$END$GREEN" cloned"$END
    fi
}

for option in ${ARG[@]}; do
    if [ $option == "-p" ] || [ $option == "--private" ]; then
        private_opt=true
    fi
done

for row in $(echo "${repositories}" | jq -r '.[] | @base64'); do
    ssh_url=$(get '.ssh_url')
    repo_name=$(get '.name')
    is_private=$(get '.private')

    if [ "$is_private" == "false" ]; then clone; continue; fi
    if [ $private_opt == true ]; then clone; fi
done
