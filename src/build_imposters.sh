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

# START imposters
# Create imposters json file
echo '{
"imposters":[
    ]
}' > $IMPOSTERS_JSON

# Find all imposters : directory like mountebank_PORT
IMPOSTERS_FILES=()
while IFS=  read -r -d $'\0'; do
    IMPOSTERS_FILES+=("$REPLY")
done < <(find ./ -maxdepth 1 -mindepth 1 -type d -regex "./mountebank_[1-9][0-9]*" -print0)

# For each imposter found
for IMPOSTER_FILE_PATH in "${IMPOSTERS_FILES[@]}"; do
    echo "cd into $ONEY_CONFIG_DIR"
    cd $ONEY_CONFIG_DIR

    # START imposter
    # find imposter data
    echo ".cd into $IMPOSTER_FILE_PATH"
    cd $IMPOSTER_FILE_PATH
    IMPOSTER_DIRECTORY_NAME=${PWD##*/} 
    IFS='_' read -r MOUNTEBANK IMPOSTER_PORT <<< "$IMPOSTER_DIRECTORY_NAME"

    echo ".making Mountebank imposter for $IMPOSTER_PORT"
    # File for current imposter
    IMPOSTER_JSON=$ONEY_CONFIG_DIR/$IMPOSTER_PORT.json
    echo "" > $IMPOSTER_JSON    
    # root configuration of imposter
    # searching for specific one from configuration
    CUSTOM_ROOT_IMPOSTER_DATA_JSON='imposter.json'
    if [ -f $CUSTOM_ROOT_IMPOSTER_DATA_JSON ]; then
        echo ".imposter.json found"
        # check JSON
        $CHECK_JSON_SCRIPT $CUSTOM_ROOT_IMPOSTER_DATA_JSON
        # merge
        cat $CUSTOM_ROOT_IMPOSTER_DATA_JSON >> $IMPOSTER_JSON
    else
        # default imposter root configuration
        echo ".no imposter.json found : put default one"
        echo "{
    \"port\": $IMPOSTER_PORT,
    \"protocol\": \"http\",
    \"name\": \"Oney mockup default name\",
    \"recordRequests\": \"true\",
    \"defaultResponse\": {
        \"statusCode\": 404,
        \"body\": \"Oney default response : NOT FOUND\",
        \"headers\": {}
    }
}" >> $IMPOSTER_JSON
        echo "you COULD create 'imposter.json' file with such following data (will be used instead of default one) :"
        cat $IMPOSTER_JSON
    fi
    # add port
    jq --arg port "$IMPOSTER_PORT" '{"port" : $port} + .' $IMPOSTER_JSON > $IMPOSTER_JSON.tmp && mv $IMPOSTER_JSON.tmp $IMPOSTER_JSON

    # START stubs
    # add "stubs" attribute to current imposter if necessary
    jq '. + {"stubs" : []}' $IMPOSTER_JSON > $IMPOSTER_JSON.tmp && mv $IMPOSTER_JSON.tmp $IMPOSTER_JSON
    # find all stubs
    STUBS_FILES=()
    while IFS=  read -r -d $'\0'; do
        STUBS_FILES+=("$REPLY")
    done < <(find ./ -maxdepth 1 -mindepth 1 -type f -regex "./stub_.*\.json" -print0)

    # Put each stub in imposter json file
    for STUB_FILE in "${STUBS_FILES[@]}"; do
        echo "..Stub file $STUB_FILE"
        # check JSON
        $CHECK_JSON_SCRIPT $STUB_FILE
        # merging using jq
        jq --argjson json "$(<$STUB_FILE)" '.stubs += [$json]' $IMPOSTER_JSON > $IMPOSTER_JSON.tmp && mv $IMPOSTER_JSON.tmp $IMPOSTER_JSON
    done
    # END stubs

    # END imposter

    # merging imposter json file in imposters json file
    jq --argjson json "$(<$IMPOSTER_JSON)" '.imposters += [$json]' $IMPOSTERS_JSON > $IMPOSTERS_JSON.tmp && mv $IMPOSTERS_JSON.tmp $IMPOSTERS_JSON
done
# END imposters