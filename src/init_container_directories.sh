#/bin/bash

echo "init_container_directories.sh is starting"

for dir in "$@"
do
    echo "mkdir -p $dir"
    mkdir -p $dir
done
