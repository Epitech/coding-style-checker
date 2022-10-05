#!/bin/bash

function my_readlink() {
    cd $1
    pwd
    cd - > /dev/null
}

function cat_readme() {
    echo ""
    echo "Usage: ./coding-style.sh DELIVERY_DIR REPORTS_DIR"
    echo "       DELIVERY_DIR      Should be the directory where your project files are"
    echo "       REPORTS_DIR       Should be the directory where we output the reports"
    echo "                         Take note that existing reports will be overriden"
    echo ""
}

if [ $# == 1 ] && [ $1 == "--help" ]; then
    cat_readme
elif [ $# = 2 ];
then
    DELIVERY_DIR=$(my_readlink "$1")
    REPORTS_DIR=$(my_readlink "$2")
    EXPORT_FILE="$REPORTS_DIR"/coding-style-reports.log
    ### delete existing report file
    rm -f "$EXPORT_FILE"

    ### Pull new version of docker image and clean olds
    sudo docker pull ghcr.io/epitech/coding-style-checker:latest && sudo docker image prune -f

    ### generate reports
    sudo docker run --rm -i -v "$DELIVERY_DIR":"/mnt/delivery" -v "$REPORTS_DIR":"/mnt/reports" ghcr.io/epitech/coding-style-checker:latest "/mnt/delivery" "/mnt/reports"
    [[ -f "$EXPORT_FILE" ]] && echo "$(wc -l < "$EXPORT_FILE") coding style error(s) reported in "$EXPORT_FILE", $(grep -c ": MAJOR:" "$EXPORT_FILE") major, $(grep -c ": MINOR:" "$EXPORT_FILE") minor, $(grep -c ": INFO:" "$EXPORT_FILE") info"
else
    cat_readme
fi
