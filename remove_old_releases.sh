#!/usr/bin/env bash
set -e

keepReleases=5
currentReleases=$(find ./* -maxdepth 0 -type d | wc -l)

cd current
typo3Live=$(pwd -P)
cd ..

typo3Previous="/"
if [ -L "previous" ]
then
    cd previous
    typo3Previous=$(pwd -P)
    cd ..
fi

while [ $currentReleases -gt $keepReleases ]
do
    cd "$(ls -d */|head -n 1)" #cd into first available directory
    currentDir=$(pwd -P)
    cd ..

    if [ "$currentDir" != "$typo3Live" ] && [ "$currentDir" != "$typo3Previous" ]
    then
        rm -rf $currentDir
    else
        cd "$(ls -d */ | head -n 2 | tail -n 1)" #cd into second available directory
        currentDir=$(pwd -P)
        cd ..

        if [ "$currentDir" != "$typo3Live" ] && [ "$currentDir" != "$typo3Previous" ]
        then
            rm -rf $currentDir
        else
            echo "Something is weird with the folder structure, please check manually"
            exit 1
        fi
    fi
    currentReleases=$(find ./* -maxdepth 0 -type d | wc -l)
done
