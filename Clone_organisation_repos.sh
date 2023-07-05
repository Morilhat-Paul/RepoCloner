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
TOKEN="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"

# Replace <ORGANISATION> with the GitHub company name
ORGANISATION="EpitechPromo2027"

page=1
repos=()
repos_url=()
repositories=()
has_next_page=true

function usage () {
    echo -e $BLUE$BOLD"USAGE: "$END"./get_repos.sh\n"
    echo -e $BLUE$BOLD"DESCRIPTION:"$END
	echo -e "\tThis script allows you to"$BOLD" clone all Organisation repositories"$END
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

while [ "$has_next_page" == true ]; do
    repositories=$(curl -s -H "Authorization: token $TOKEN" "https://api.github.com/orgs/$ORGANISATION/repos?page=$page&per_page=100")

    # Verify if token is valid
    if [[ $repositories == *"Bad credentials"* ]]; then
        echo -e $RED"Invalid token. Please provide a valid GitHub token."
        exit 1
    fi

    # Verify if organisation is valid
    if [[ $repositories == *"Not Found"* ]]; then
        echo -e $RED"Invalid organisation. Please provide a valid GitHub organisation."
        exit 1
    fi

    if [ "$(echo "$repositories" | jq length)" -eq 0 ]; then has_next_page=false; break; fi

    for row in $(echo "${repositories}" | jq -r '.[] | @base64'); do
        ssh_url=$(get '.ssh_url')
        repo_name=$(get '.name')
        clone
    done

    if [ "$(echo "$repositories" | jq '. | length')" -lt 100 ]; then
        has_next_page=false
    else
        page=$((page + 1))
    fi
done
