#!/bin/bash
set -e
if [ -d "$HOME/conda/envs/training_env" ]
then
    rm -rf "$HOME/conda/envs/training_env"
fi

conda create -n training_env
conda activate training_env
conda env list
conda install pip -n training_env
cd $HOME/conda/envs/training_env
git clone https://github.com/phandaiduonghcb/local_mlops
# echo "Install dependencies..."
$HOME/conda/envs/training_env/bin/pip install -r ./local_mlops/requirements-dev.txt --no-cache-dir
$HOME/conda/envs/training_env/bin/pip cache purge
pip cache purge
cd local_mlops
echo "Current working dir: $PWD"
dvc pull -AaR -r dvc-flower-bucket
ls ./ml/data/*
echo "Create env successfully!"