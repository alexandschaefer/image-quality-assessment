#!/bin/bash
set -e

MACHINE=$1
CONFIG_FILE=$2
SAMPLES_FILE=$3
IMAGE_DIR=$4

REMOTE="docker-machine ssh $MACHINE"
REMOTE_COPY="docker-machine scp"

# parse config file and assign parameters to variables
eval "$(jq -r "to_entries|map(\"export \(.key)=\(.value|tostring)\")|.[]" $CONFIG_FILE)"

# login to ECR on remote machine
eval $REMOTE "eval 'sudo $(aws ecr get-login --no-include-email --region eu-west-1)'"

# pull docker image on remote machine
eval $REMOTE "sudo docker pull $docker_image"

# create job dir on remote machine
TIMESTAMP=$(date +%Y_%m_%d_%H_%M_%S)
TRAIN_JOB_DIR=train_jobs/$TIMESTAMP
eval $REMOTE "sudo mkdir -p -m 777 $TRAIN_JOB_DIR"

# copy config and labels file to remote MACHINE
eval $REMOTE_COPY "$CONFIG_FILE $MACHINE:/home/ubuntu/$TRAIN_JOB_DIR/config.json"
eval $REMOTE_COPY "$SAMPLES_FILE $MACHINE:/home/ubuntu/$TRAIN_JOB_DIR/samples.json"

# start training
DOCKER_REMOTE_RUN="sudo nvidia-docker run -d
  -v $IMAGE_DIR:/src/images
  -v /home/ubuntu/$TRAIN_JOB_DIR:/src/$TRAIN_JOB_DIR
  -e S3_BUCKET=$s3_bucket
  -e TRAIN_JOB_DIR=$TRAIN_JOB_DIR
  $docker_image"

eval $REMOTE $DOCKER_REMOTE_RUN

# stream logs from container
CONTAINER_ID=$($REMOTE sudo docker ps -l -q)
$REMOTE "sudo docker logs $CONTAINER_ID --follow"
