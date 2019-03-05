#!/bin/bash

ONEY_CONFIG_DIR="$1"
IMPOSTERS_JSON="$2"/"$3"
CONTAINER_SCRIPT="$4"

CHECK_JSON_SCRIPT=$CONTAINER_SCRIPT/check_json.sh
# exit when any command fails
set -e

echo "build_imposters.sh is starting in $ONEY_CONFIG_DIR, checking JSON with $CHECK_JSON_SCRIPT"
echo "cd into $ONEY_CONFIG_DIR"
cd $ONEY_CONFIG_DIR

# Find all imposters
IMPOSTERS_FILES=()
while IFS=  read -r -d $'\0'; do
    IMPOSTERS_FILES+=("$REPLY")
done < <(find ./ -maxdepth 1 -mindepth 1 -type d -regex "./mountebank_[1-9][0-9]*_.*" -print0)

IMPOSTERS_FILES_LEN=${#IMPOSTERS_FILES[@]}
echo "$IMPOSTERS_FILES_LEN imposters found !"
if [ -z "$IMPOSTERS_FILES_LEN" ]; then
    exit
fi

# Create imposters json file
echo '{"imposters":[' >> $IMPOSTERS_JSON
i=0
for IMPOSTER_FILE_PATH in "${IMPOSTERS_FILES[@]}"; do
    echo "cd into $ONEY_CONFIG_DIR"
    cd $ONEY_CONFIG_DIR
    # create imposter json file
    echo ".cd into $IMPOSTER_FILE_PATH"
    cd $IMPOSTER_FILE_PATH
    IMPOSTER_DIRECTORY_NAME=${PWD##*/} 
    IFS='_' read -r MOUNTEBANK IMPOSTER_PORT IMPOSTER_NAME <<< "$IMPOSTER_DIRECTORY_NAME"
    #IMPOSTER_PORT=${PWD##*/}
    echo ".making Mountebank imposter for $IMPOSTER_PORT"
    IMPOSTER_JSON=$ONEY_CONFIG_DIR/$IMPOSTER_PORT.json
    echo '{' >> $IMPOSTER_JSON
    echo "\"port\": ${IMPOSTER_PORT}," >> $IMPOSTER_JSON
    echo '"protocol": "http",' >> $IMPOSTER_JSON
    echo "\"name\": \"$IMPOSTER_NAME\"," >> $IMPOSTER_JSON
    echo '"defaultResponse":' >> $IMPOSTER_JSON
    # Include default response
    DEFAULT_RESPONSE_JSON='defaultResponse.json'
    if [ -f $DEFAULT_RESPONSE_JSON ]; then
        echo ".defaultResponse.json found"
        # check JSON
        $CHECK_JSON_SCRIPT $DEFAULT_RESPONSE_JSON
        # merge
        cat $DEFAULT_RESPONSE_JSON >> $IMPOSTER_JSON
    else
        # default default response
        echo ".no defaultResponse.json found : put default one"
        echo '{
    "statusCode": 404,
    "body": "404 : DEFAULT ONEY RESPONSE",
    "headers": {}}' >> $IMPOSTER_JSON
    fi

    # start stubs
    echo ',"stubs":[' >> $IMPOSTER_JSON
    # find all stubs
    STUBS_FILES=()
    while IFS=  read -r -d $'\0'; do
        STUBS_FILES+=("$REPLY")
    done < <(find ./ -maxdepth 1 -mindepth 1 -type f -regex "./stub_.*\.json" -print0)
    STUBS_FILES_LEN=${#STUBS_FILES[@]}
    echo ".$STUBS_FILES_LEN stubs found !"
    j=0
    echo "" >> $IMPOSTER_JSON
    # Put each stub in imposter json file
    for STUB_FILE in "${STUBS_FILES[@]}"; do
        echo "..Stub file $STUB_FILE"
        # check JSON
        $CHECK_JSON_SCRIPT $STUB_FILE
        # merge
        cat $STUB_FILE >> $IMPOSTER_JSON
        j=$((j+1))
        if [ $j -eq $STUBS_FILES_LEN ]; then
            echo ".. END OF STUBS"
        else
            echo "," >> $IMPOSTER_JSON
        fi
    done
    echo ']' >> $IMPOSTER_JSON
    # end Stubs

    i=$((i+1))
    if [ $i -eq $IMPOSTERS_FILES_LEN ]; then
        echo ".END OF IMPOSTERS"
        echo "}" >> $IMPOSTER_JSON
    else
        echo "}," >> $IMPOSTER_JSON
    fi
    # end imposter
    # concatenate imposter json file in imposters json file
    cat $IMPOSTER_JSON >> $IMPOSTERS_JSON
done
echo ']}' >> $IMPOSTERS_JSON
# end imposters