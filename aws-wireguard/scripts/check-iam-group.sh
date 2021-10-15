#!/bin/bash
eval "$(jq -r '@sh "GROUP_NAME=\(.group_name)"')"

group=$(aws --output json iam get-group --group-name $GROUP_NAME 2> /dev/null | jq length)
if [ -z $group ]; then
  echo "{\"exist\":\"false\"}"
  else echo "{\"exist\":\"true\"}"
fi
