#!/bin/bash

# Some environment variables will be static
# A "master token" will need to be maintained with the scopes needed to read & update all tokens:
# API v1: Read Configuration, Write Configuration, Token Managaement
# DT URL may vary by environment.
# Setting a static token name for the time being
dtEnv="https://TENANT.live.dynatrace.com/api/v1"
masterToken="TOKEN"

# Setting a static token name for PoC. 
# Token ID could possibly be stored in Vault/ Facts for inital subsequent runs?
installerTokenName="roating-passtoken"

# Pulls existing token list, locate the current deployment token ID & set as variable
oldTokenID=$(
curl -X GET \
  $dtEnv/tokens/ \
  -H 'Authorization: Api-Token '$masterToken'' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -H 'Accept: application/json; charset=utf-8' \
    | jq -r '.values[] | select(.name=="'$installerTokenName'") | .id'
)

# Creates new token PaaS token with 15 TTL
newToken=$(
curl -X POST \
  $dtEnv/tokens/ \
  -H 'Authorization: Api-Token '$masterToken'' \
  -H 'Content-Type: application/json; charset=utf-8' \
  -H 'Accept: application/json; charset=utf-8' \
  -d '{
  "name": "'$installerTokenName'",
  "expiresIn": {
    "value": 15,
    "unit": "MINUTES"
  },
  "scopes": [
    "InstallerDownload"
  ]
}' | jq -r '.token'
)

# download/ install....
wget  -O /tmp/Dynatrace-OneAgent.sh \
    "$dtEnv/deployment/installer/agent/unix/default/latest?arch=x86&flavor=default" \
    --header="Authorization: Api-Token $newToken"  

#sudo /bin/sh /tmp/Dynatrace-OneAgent.sh  

# delete old token??
curl -X DELETE \
  $dtEnv/tokens/$oldTokenID \
  -H 'Authorization: Api-Token '$masterToken'' \