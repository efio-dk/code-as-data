#!/bin/bash
clear
USAGE="Usage: $0 <module> [fmt|plan|apply|destroy]"
DIR="./test/modules/"

if [ "$#" == "0" ]; then
    echo "$USAGE"
    exit 1
fi

case "$2" in
    "fmt")
        terraform fmt --recursive
        ;;
    "init")
        terraform -chdir=$DIR$1 init -upgrade
        ;;
    "plan")
        terraform fmt --recursive && terraform -chdir=$DIR$1 plan
        ;;
    "refresh")
        terraform fmt --recursive && terraform -chdir=$DIR$1 refresh
        ;;
    "apply")
        terraform fmt --recursive && terraform -chdir=$DIR$1 apply
        ;;
    "silent")
        terraform fmt --recursive && terraform -chdir=$DIR$1 apply -auto-approve
        ;;
    "destroy")
        terraform -chdir=$DIR$1 destroy -auto-approve
        ;;
    "lint")
        tflint --version 
        tflint --init
        tflint --module ./modules/$1
        cd=$(pwd)
        cd $DIR$1
        terrascan init
        terrascan scan
        ;;
    *)
        echo "$USAGE"
        exit 1
        ;;
esac
