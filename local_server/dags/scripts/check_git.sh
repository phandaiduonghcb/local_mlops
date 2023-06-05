#!/bin/bash
set -e
REPO_NAME=local_mlops
LOCAL_REPO_DIRECTORY=$HOME
REPO_OWNER=phandaiduonghcb

cd $LOCAL_REPO_DIRECTORY
if [ -d "$LOCAL_REPO_DIRECTORY/$REPO_NAME" ]
then
    cd $REPO_NAME
    git fetch
    # Get the SHA of the latest commit on the remote main branch
    LATEST_SHA=$(curl -s -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/branches/main | jq -r '.commit.sha')
    # LATEST_SHA=$(git rev-parse `git branch -r --sort=committerdate | tail -1`)
    # Get the SHA of the commit that was last pulled on the local main branch
    LOCAL_SHA=$(git rev-parse main)

    # Compare the SHA of the latest commit on the remote main branch to the SHA of the commit that was last pulled on the local main branch
    echo $LATEST_SHA $LOCAL_SHA
    if [[ $LATEST_SHA != $LOCAL_SHA ]]
    then
        MESSAGES=$(git log --pretty=format:%s $LOCAL_SHA..$LATEST_SHA | grep "Airflow" || true)
        if [[ -n "$MESSAGES" ]]
        then
            echo 0
        else
            echo 1
        fi
        exit 0
    else
        echo 1
        exit 0
    fi
else
    # echo "The repository doesn't exist at $LOCAL_REPO_DIRECTORY/$REPO_NAME."
    git clone https://github.com/$REPO_OWNER/$REPO_NAME
    conda create -n training_env
    conda activate training_env
    conda env list
    conda install pip -n training_env
    $HOME/conda/envs/training_env/bin/pip install -r $LOCAL_REPO_DIRECTORY/$REPO_NAME/requirements-dev.txt --no-cache-dir
    echo 0
    exit 0
fi