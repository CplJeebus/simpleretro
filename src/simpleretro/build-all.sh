#!/bin/bash 

set -e 

buildServer(){
    export GOOS=linux
    export GOARCH=amd64

  go build -o myeircode
}

getLatestTag(){
  i=$(docker image ls | grep gcr.io | grep myeircode | awk '{print $2}' | cut -d '.' -f 2 | head -n 1)
  echo $((i+1))
}

dockerStuff(){
  latest=$2
  base="${GCR_BASE}"
  if [ "$1" == "local" ] 
  then 
    gsed "s/host: \"TheHost\"/$(cat lhost)/g" Xconfig.yaml > config.yaml
  else 
    gsed "s/host: \"TheHost\"/$(cat rhost)/g" Xconfig.yaml > config.yaml 
  fi 
  docker build --tag ${base}:${latest} .
  docker push ${base}:${latest}
}

deploy(){
  case $1 in 
  deploy)
    gcloud run services update myeircode --platform managed --image ${GCR_BASE}:${2} --region europe-west1
    ;;
  local)
    docker container rm $(docker container ls -a | grep local | awk '{print $1}') || true
    docker run -p 8080:8080 --name local ${GCR_BASE}:${2} 
    ;;
  esac
}

main(){
  buildServer 
  tag=$(getLatestTag)
  dockerStuff $1 $tag 
  deploy $1 $tag
}

main "$@"
