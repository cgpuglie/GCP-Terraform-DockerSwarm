#!/bin/bash

# print usage
usage () {
  echo "swarm -m <manager1>,<manager2> -w <worker1>,<worker2> -u <remote-user>"
}

# process inputs
while [[ $# -gt 1 ]]
do
  key="$1"

  case $key in
    -m|--manager)
    managers="$2"
    shift
    ;;
    -w|--worker)
    workers="$2"
    shift
    ;;
    -u|--user)
    user="$2"
    shift
    ;;
  esac
  shift
done

# if input missing, print usage
if [ -z $managers ] || [ -z $workers ]; then
  usage;
fi


for manager in ${managers//\,/ }
do
  echo
  echo "${manager} - checking for existing swarm"
  if ssh -o StrictHostKeyChecking=no "$user@$manager" "sudo docker info | grep ClusterID"
  then
    echo "${manager} - found a swarm"
    echo
    break
  fi
  echo "${manager} - did not find a swarm"
  echo
done

if [[ -z "$manager" ]]
then
  echo "manager doesn't exist yet"
  exit 404
fi
echo "selected manager is now ${manager}"

ssh -o StrictHostKeyChecking=no "$user@$manager" "sudo docker swarm init | grep -v SWMTKN"
cluster_id=`ssh -o StrictHostKeyChecking=no "$user@$manager" "sudo docker info | grep ClusterID | cut -d' ' -f3"`
manager_token=`ssh -o StrictHostKeyChecking=no "$user@$manager" sudo "docker swarm join-token -q manager"`
worker_token=`ssh -o StrictHostKeyChecking=no "$user@$manager" sudo "docker swarm join-token -q worker"`
join_port=2377

echo "cluster_id: $cluster_id"
echo "manager_token: $manager_token"
echo "worker_token: $worker_token"
echo

if [[ -z "$cluster_id" ]]
then
  echo "cluster_id doesn't exist"
  exit 401
fi
if [[ -z "$manager_token" ]]
then
  echo "manager_token doesn't exist"
  exit 401
fi
if [[ -z "$worker_token" ]]
then
  echo "worker_token doesn't exist"
  exit 401
fi

for engine in ${managers//\,/ }
do
  echo "${engine} - joining cluster as manager"
  ssh -o StrictHostKeyChecking=no "$user@$engine" "sudo docker swarm join --token $manager_token $manager:$join_port"
done
for engine in ${workers//\,/ }
do
  echo "${engine} - joining cluster as worker"
  ssh -o StrictHostKeyChecking=no "$user@$engine" "sudo docker swarm join --token $worker_token $manager:$join_port"
done

echo
echo 'Ensured Cluster State.'