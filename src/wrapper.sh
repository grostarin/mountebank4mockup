#!/bin/bash

echo "Mountebank @ Oney is starting"

MOUNTEBANK_IMPOSTER_JSON="$1"

echo "Searching for config $MOUNTEBANK_IMPOSTER_JSON"
# Start process
if [ -f "$MOUNTEBANK_IMPOSTER_JSON" ]; then
  echo "Starting Mountebank with configFile and injection allowed"
  mb --configfile $MOUNTEBANK_IMPOSTER_JSON --allowInjection
else
  echo "Starting vanilla Mountebank"
  mb
fi