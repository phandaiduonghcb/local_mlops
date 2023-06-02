#!/bin/bash
set -e
REPO_NAME=local_mlops
LOCAL_REPO_DIRECTORY=$HOME
REPO_OWNER=phandaiduonghcb

cd $LOCAL_REPO_DIRECTORY
if [ -d "$LOCAL_REPO_DIRECTORY/$REPO_NAME" ]
then
    cd $REPO_NAME
    # Get the SHA of the latest commit on the remote main branch
    LATEST_SHA=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches/main | jq -r '.commit.sha')

    # Get the SHA of the commit that was last pulled on the local main branch
    LOCAL_SHA=$(git rev-parse main)

    # Compare the SHA of the latest commit on the remote main branch to the SHA of the commit that was last pulled on the local main branch
    if [[ $LATEST_SHA != $LOCAL_SHA ]]
    then
        echo 0
        exit 0
    else
        echo 1
        exit 0
    fi
else
    # echo "The repository doesn't exist at $LOCAL_REPO_DIRECTORY/$REPO_NAME."
    git clone https://github.com/$REPO_OWNER/$REPO_NAME
    echo 0
    exit 0
fi