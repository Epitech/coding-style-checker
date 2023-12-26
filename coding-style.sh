#!/bin/bash

function my_readlink() {
    cd $1
    pwd
    cd - > /dev/null
}

function cat_readme() {
    echo ""
    echo "Usage: $(basename $0) DELIVERY_DIR REPORTS_DIR"
    echo -e "\tDELIVERY_DIR\tShould be the directory where your project files are"
    echo -e "\tREPORTS_DIR\tShould be the directory where we output the reports"
    echo -e "\t\t\tTake note that existing reports will be overriden"
    echo ""
}

if [ $# == 1 ] && [ $1 == "--help" ]; then
    cat_readme
elif [ $# == 1 ] || [ $# = 2 ];
then
    if [ $# == 1 ];
    then
        REPORTS_DIR=$(my_readlink ".")
    elif [ $# = 2 ];
    then
        REPORTS_DIR=$(my_readlink "$2")
    fi

    DELIVERY_DIR=$(my_readlink "$1")
    DOCKER_SOCKET_PATH=/var/run/docker.sock
    HAS_SOCKET_ACCESS=$(test -r $DOCKER_SOCKET_PATH; echo "$?")
    GHCR_REGISTRY_TOKEN=$(curl -s "https://ghcr.io/token?service=ghcr.io&scope=repository:epitech/coding-style-checker:pull" | grep -o '"token":"[^"]*' | grep -o '[^"]*$') 
    GHCR_REPOSITORY_STATUS=$(curl -I -f -s -o /dev/null -H "Authorization: Bearer $GHCR_REGISTRY_TOKEN" "https://ghcr.io/v2/epitech/coding-style-checker/manifests/latest" && echo 0 || echo 1)
    BASE_EXEC_CMD="docker"
    EXPORT_FILE="$REPORTS_DIR"/coding-style-reports.log
    ### delete existing report file
    rm -f "$EXPORT_FILE"

    ### Pull new version of docker image and clean olds

    if [ $HAS_SOCKET_ACCESS -ne 0 ]; then
        echo "WARNING: Socket access is denied"
        echo "To fix this we will add the current user to docker group with : sudo usermod -a -G docker $USER"
        read -p "Do you want to proceed? (yes/no) " yn
        case $yn in 
            yes | Y | y | Yes | YES) echo "ok, we will proceed";
                sudo usermod -a -G docker $USER;
                echo "You must reboot your computer for the changes to take effect";;
            no | N | n | No | NO) echo "ok, Skipping";;
            * ) echo "invalid response, Skipping";;
        esac
        BASE_EXEC_CMD="sudo ${BASE_EXEC_CMD}"
    fi


    if [ $GHCR_REPOSITORY_STATUS -eq 0 ]; then
        echo "Downloading new image and cleaning old one..."
        $BASE_EXEC_CMD pull ghcr.io/epitech/coding-style-checker:latest && $BASE_EXEC_CMD image prune -f
        echo "Download OK"
    else
        echo "WARNING: Skipping image download"
    fi
   

    ### generate reports
    $BASE_EXEC_CMD run --rm --security-opt "label:disable" -i -v "$DELIVERY_DIR":"/mnt/delivery" -v "$REPORTS_DIR":"/mnt/reports" ghcr.io/epitech/coding-style-checker:latest "/mnt/delivery" "/mnt/reports"
    [[ -f "$EXPORT_FILE" ]] && echo "$(wc -l < "$EXPORT_FILE") coding style error(s) reported in "$EXPORT_FILE", $(grep -c ": MAJOR:" "$EXPORT_FILE") major, $(grep -c ": MINOR:" "$EXPORT_FILE") minor, $(grep -c ": INFO:" "$EXPORT_FILE") info"
else
    cat_readme
fi
