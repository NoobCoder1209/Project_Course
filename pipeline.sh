#!/bin/bash

set -e

#########BUILD############

image_name=058302395964.dkr.ecr.eu-central-1.amazonaws.com/pragmflask
docker build -t $image_name:$GIT_COMMIT .
port=$(shuf -i 3000-10000 -n 1)
container_name=$(echo $RANDOM)
docker run --name $container_name -dit -p $port:5000 $image_name:$GIT_COMMIT
sleep 5

##########TEST#############
curl localhost:$port
exit_status=$?

if [[ $exit_status == 0 ]]
then echo "SUCCESSFUL TESTS" && docker stop $container_name
else echo "FAILED TESTS" && docker stop $container_name && exit 1
fi

#########PUSH##############
docker login -u AWS https://058302395964.dkr.ecr.eu-central-1.amazonaws.com -p $(aws ecr get-login-password --region eu-central-1)
docker push $image_name:$GIT_COMMIT

########DEPLOY############
helm upgrade flask helm/ --atomic --wait --install --set deployment.tag=$GIT_COMMIT
