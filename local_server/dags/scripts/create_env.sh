#!/bin/bash
set -e
REPO_NAME=local_mlops
LOCAL_REPO_DIRECTORY=$HOME
REPO_OWNER=phandaiduonghcb

cd $LOCAL_REPO_DIRECTORY/$REPO_NAME
git fetch origin main
output=$(git diff origin/main -- requirements-dev.txt)
git pull
if [[ -n "$output" ]]
then
    if [ -d "$HOME/conda/envs/training_env" ]
    then
        rm -rf "$HOME/conda/envs/training_env"
    fi
    conda create -n training_env
    conda activate training_env
    conda env list
    conda install pip -n training_env
    $HOME/conda/envs/training_env/bin/pip install -r $LOCAL_REPO_DIRECTORY/$REPO_NAME/requirements-dev.txt --no-cache-dir
fi

echo "Current working dir: $PWD"
conda activate training_env
dvc pull -AaR -r local-mlops-bucket
ls ./ml/data/*
echo "Create env successfully!"