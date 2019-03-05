#/bin/bash

JSON_FILE="$1"
echo "check_json.sh is starting for $JSON_FILE"

if [ -f "$JSON_FILE" ]; then
    echo "Checking $JSON_FILE"
    # call jq to test json and get stderr from it
    JQ_ERROR="$(cat $JSON_FILE | jq -e 2>&1 > /dev/null)"
    if [ -z "$JQ_ERROR" ]; then
        echo "Parsed JSON successfully"
        exit 0
    else
        echo "Displaying $JSON_FILE with line numbers"
        cat -n $JSON_FILE
        echo "ERROR : Failed to parse JSON. Take a look at file content (above) to solve the issue (below)."
        echo "$JQ_ERROR"
        exit 1
    fi
    #cat $JSON_FILE | jq -e
else
    echo "$JSON_FILE not found"
    exit 0
fi