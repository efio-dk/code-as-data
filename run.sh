#!/bin/bash

clear

while [[ $# -gt 0 ]]; do
  case $1 in
    -p|--project)
      PROJECT="/projects/$2"
      shift # past argument
      shift # past value
      ;;
    -c|--cicd)
      PROJECT="/pipelines"
      shift # past argument
      ;;
    -i|--init)
      INIT=YES
      shift
      ;;
    -u|--upgrade)
      INIT=YES
      UPGRADE=-upgrade
      shift
      ;;
    -f|--format)
      FORMAT=YES
      shift
      ;;
    -l|--lint)
      LINT=YES
      shift
      ;;
    -s|--silent)
      SILENT="-auto-approve"
      shift;;
    --help)
      HELP=YES
      shift # past argument
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      ACTION="$1" # save positional arg
      shift # past argument
      ;;
  esac
done

if [[ -n $FORMAT ]]; then
  terraform fmt --recursive
fi

if [[ -n $INIT ]]; then
  terraform -chdir=".$PROJECT" init $UPGRADE
fi

if [[ -n $LINT ]]; then
  CD=$(pwd)
  cd ".$PROJECT"
  terrascan init
  terrascan scan
  cd $CD
fi

if [[ -n $ACTION ]]; then
  echo terraform -chdir=".$PROJECT" $ACTION -var-file=$(pwd)/global.tfvars $SILENT
  terraform -chdir=".$PROJECT" $ACTION -var-file=$(pwd)/global.tfvars $SILENT
fi
