#!/bin/bash

red=`tput setaf 1`
green=`tput setaf 2`
reset=`tput sgr0`

echo "${green}Start release command${reset}"

PHPUNIT_COMMAND=""
MEMORY_LIMIT=512M
PHPUNIT_VERSION="5.6.18"

if hash phpunit 2>/dev/null;
then
    PHPUNIT_COMMAND="phpunit"
elif [ -e phpunit.phar ]
then
    PHPUNIT_COMMAND="phpunit.phar"
else
    wget -qO phpunit.phar https://phar.phpunit.de/phpunit-"$PHPUNIT_VERSION".phar --no-check-certificate
    PHPUNIT_COMMAND="phpunit.phar"
fi

echo "${green}Start running unit tests...${reset}"

if [ ! -z "$PHPUNIT_COMMAND" ]
then
    if [ "phpunit.phar" = "$PHPUNIT_COMMAND" ]
    then
        php "$PHPUNIT_COMMAND" --stop-on-error src $*
    else
        "$PHPUNIT_COMMAND" --stop-on-error src $*
    fi
else
    echo "PHPUNIT/PHPUNIT.PHAR NOT FOUND."
fi

if [[ $RESULT =~ FAILURES ]]
then
    echo "${red}Not created tag! We have a problem in the unit tests.${reset}"
    exit;
fi

PHPUNIT_COMMAND=""
MEMORY_LIMIT=512M
PHPUNIT_VERSION="5.6.18"

if hash phpunit 2>/dev/null;
then
    PHPUNIT_COMMAND="phpunit"
elif [ -e phpunit.phar ]
then
    PHPUNIT_COMMAND="phpunit.phar"
else
    wget -qO phpunit.phar https://phar.phpunit.de/phpunit-"$PHPUNIT_VERSION".phar --no-check-certificate
    PHPUNIT_COMMAND="phpunit.phar"
fi


if [ ! -z "$PHPUNIT_COMMAND" ]
then
    if [ "phpunit.phar" = "$PHPUNIT_COMMAND" ]
    then
       RESULT=`php "$PHPUNIT_COMMAND" -d memory_limit="$MEMORY_LIMIT" --stop-on-error src $*`
    else
        RESULT=`"$PHPUNIT_COMMAND" -d memory_limit="$MEMORY_LIMIT" --stop-on-error src $*`
    fi
else
    echo "PHPUNIT/PHPUNIT.PHAR NOT FOUND."
fi

if [[ $RESULT =~ FAILURES ]]
then
    echo "We have a problem in the unit tests.";
fi

if [ -f VERSION ]; then
    BASE_STRING=`cat VERSION`
    BASE_LIST=(`echo $BASE_STRING | tr '.' ' '`)
    V_MAJOR=${BASE_LIST[0]}
    V_MINOR=${BASE_LIST[1]}
    V_PATCH=${BASE_LIST[2]}
    echo "Current version : $BASE_STRING"
    V_MINOR=$((V_MINOR + 1))
    V_PATCH=0
    SUGGESTED_VERSION="$V_MAJOR.$V_MINOR.$V_PATCH"
    read -p "Enter a version number [$SUGGESTED_VERSION]: " INPUT_STRING
    if [ "$INPUT_STRING" = "" ]; then
        INPUT_STRING=$SUGGESTED_VERSION
    fi
    echo "Will set new version to be $INPUT_STRING"
    echo $INPUT_STRING > VERSION
    echo "## Version $INPUT_STRING ($(date +'%Y-%m-%d'))" > tmpfile
    git log --pretty=format:" * %s" "v$BASE_STRING"...HEAD >> tmpfile
    echo "" >> tmpfile
    echo "" >> tmpfile
    cat CHANGELOG.md >> tmpfile
    mv tmpfile CHANGELOG.md
    git add CHANGELOG.md VERSION
    git commit -m "Updated version for $INPUT_STRING"
    git tag -a -m "Created tag $INPUT_STRING" "v$INPUT_STRING"
    git push origin --tags
else
    echo "Could not find a VERSION file"
    read -p "Do you want to create a version file and start from scratch? [y]" RESPONSE
    if [ "$RESPONSE" = "" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "Y" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "Yes" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "yes" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "YES" ]; then RESPONSE="y"; fi
    if [ "$RESPONSE" = "y" ]; then
        echo "0.1.0" > VERSION
        echo "## Version 0.1.0 ($(date +'%Y-%m-%d'))" > CHANGELOG.md
        git log --pretty=format:" * %s" >> CHANGELOG.md
        echo "" >> CHANGELOG.md
        echo "" >> CHANGELOG.md
        git add VERSION CHANGELOG.md
        git commit -m "Added VERSION and CHANGELOG.md files, Version bump to v0.1.0"
        git tag -a -m "Created tag 0.1.0" "v0.1.0"
        git push origin --tags
    fi
fi
