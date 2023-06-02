#!/bin/bash
conda activate training_env
conda env list
set -e
export MLFLOW_TRACKING_URI='http://mlops-load-balancer-1733374265.us-east-2.elb.amazonaws.com/'
EXPERIMENT_NAME='classification_runs'
NEWEST_ARTIFACT_PATH=$(python << EOF
import mlflow
current_experiment=dict(mlflow.get_experiment_by_name("$EXPERIMENT_NAME"))
experiment_id=current_experiment['experiment_id']
client = mlflow.tracking.MlflowClient()
newest_run = client.search_runs(experiment_id, "", order_by=["start_time DESC"], max_results=1)[0]
print(newest_run.info.artifact_uri.replace("file://", ""))
EOF
)
BEST_ARTIFACT_PATH=$(python << EOF
import mlflow
current_experiment=dict(mlflow.get_experiment_by_name("$EXPERIMENT_NAME"))
experiment_id=current_experiment['experiment_id']
client = mlflow.tracking.MlflowClient()
best_run = client.search_runs(experiment_id, "", order_by=["metrics.test_accuracy DESC"], max_results=1)[0]
print(best_run.info.artifact_uri.replace("file://", ""))
EOF
)

if [[ $BEST_ARTIFACT_PATH != $NEWEST_ARTIFACT_PATH ]]
then
    echo "The newest run is not the best one!"
    exit 0
else
    echo "The newest run is the best one!"
fi
export MLFLOW_HTTP_REQUEST_TIMEOUT=600
RUN_ID=$(basename $(dirname $BEST_ARTIFACT_PATH))
EXPERIMENT_ID=$(basename $(dirname $(dirname $BEST_ARTIFACT_PATH)))
REMOTE_MODEL_PATH=$(mlflow runs describe --run-id $RUN_ID |\
                jq '.data.params.test_model_path'
                )
REMOTE_MODEL_PATH=${REMOTE_MODEL_PATH//\"/}

cd $HOME/conda/envs/training_env/local_mlops/development/docker

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text --profile duongpd7)
AWS_ACCOUNT_LOCATION=$(aws configure get region --profile duongpd7)
REMOTE_REPOSITORY_NAME=mlflow-model-serve

aws ecr get-login-password --profile duongpd7 \
| docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_ACCOUNT_LOCATION}.amazonaws.com
docker build -t ${REMOTE_REPOSITORY_NAME} . --build-arg dst_model_path=/opt/airflow/training_runs/1685343230/best.pth
docker tag ${REMOTE_REPOSITORY_NAME}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_ACCOUNT_LOCATION}.amazonaws.com/${REMOTE_REPOSITORY_NAME}:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_ACCOUNT_LOCATION}.amazonaws.com/${REMOTE_REPOSITORY_NAME}:latest
aws ecs update-service --cluster mlops-ecs-cluster --service mlops-service --force-new-deployment --profile duongpd7 &>/dev/null
conda deactivate
# conda env remove -n training_env