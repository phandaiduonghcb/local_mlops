#!/bin/bash
set -e
REPO_NAME=local_mlops
LOCAL_REPO_DIRECTORY=$HOME
REPO_OWNER=phandaiduonghcb

cd $LOCAL_REPO_DIRECTORY/$REPO_NAME
conda activate training_env
conda env list
python ./ml/hyp_tuning.py
echo "Train successfully!"