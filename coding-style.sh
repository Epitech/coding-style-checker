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
    SOCKET_ACCESS=$(test -r /var/run/docker.sock; echo "$?")
    BASE_CMD="docker"
    EXPORT_FILE="$REPORTS_DIR"/coding-style-reports.log
    ### delete existing report file
    rm -f "$EXPORT_FILE"

    ### Pull new version of docker image and clean olds

    if [ $SOCKET_ACCESS -eq 1 ]; then
        echo "WARNING: Socket access denied... will use sudo"
        echo "To fix this add user to docker group with : sudo usermod -a -G docker $USER"
        BASE_CMD="sudo ${BASE_CMD}"
    fi

    echo "Check connect to ghcr.io registry..."
    
    echo -e "GET http://ghcr.io HTTP/1.0\n\n" | nc ghcr.io 80  > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        echo "OK: Downloading image"
        $BASE_CMD pull ghcr.io/epitech/coding-style-checker:latest && $BASE_CMD image prune -f
    else
        echo "WARNING: Skip image download..."
    fi
   

    ### generate reports
    $BASE_CMD run --rm -i -v "$DELIVERY_DIR":"/mnt/delivery" -v "$REPORTS_DIR":"/mnt/reports" ghcr.io/epitech/coding-style-checker:latest "/mnt/delivery" "/mnt/reports"
    [[ -f "$EXPORT_FILE" ]] && echo "$(wc -l < "$EXPORT_FILE") coding style error(s) reported in "$EXPORT_FILE", $(grep -c ": MAJOR:" "$EXPORT_FILE") major, $(grep -c ": MINOR:" "$EXPORT_FILE") minor, $(grep -c ": INFO:" "$EXPORT_FILE") info"
else
    cat_readme
fi
