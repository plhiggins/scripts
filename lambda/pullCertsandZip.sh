#!/bin/bash
## lhiggins

###############################################
## Variables

DEFAULT_BUCKET='efm-poc-userdata'
DEFAULT_PATH='efm-ca'
DEFAULT_LAYER_NAME='complete-cert-layer'
DEFAULT_LAYER_DESCRIPTION='Cert Layer'

## script color vars
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
###############################################

## Check if an argument was passed for S3 Bucket, path, layer name, and layer description.  If not use the default values.

BUCKET_NAME="${1:-$DEFAULT_BUCKET}"
BUCKET_PATH="${2:-$DEFAULT_PATH}"
LAYER_NAME="${3:-$DEFAULT_LAYER_NAME}"
LAYER_DESCRIPTION="${4:-$DEFAULT_LAYER_DESCRIPTION}"

## Delete any previous artifacts in the existing dir
rm -rf ./certs
rm -f complete.pem
rm -f complete_pem.zip

## Read in bucket from argument or user input
##
##if [ "$#" -ge 1 ]; then
##	  BUCKET_NAME=$1
##  else
##    echo -e "${RED}Please enter the S3 bucket name that contains the certs:${NC} "  
##    echo ""
##	    IFS= read -r BUCKET_NAME || exit # on EOF
##fi
##

echo "DEFAULT IS: " $DEFAULT_BUCKET "    " $DEFAULT_PATH
echo ""
echo -e "${RED}Bucket Name/Path to pull certs is: ${NC}" $BUCKET_NAME"/"$BUCKET_PATH

echo ""
echo -e "${RED}Syncing files from S3${NC}"

aws s3 sync s3://$BUCKET_NAME/$BUCKET_PATH ./certs
echo ""

echo -e "${RED}Combining the cer file into a pem${NC}"
## there may need to be more logic put here at some point if additional/unrelated certs are added
for i in $(ls ./certs/*.cer | sort -u); do cat $i >> complete.pem; done
echo ""

sleep 1

echo -e "${RED}Zipping the pem file${NC}"
zip complete_pem.zip complete.pem

echo ""
echo ""

echo -e "${RED}Publishing the layer${NC}"
aws lambda publish-layer-version --layer-name $LAYER_NAME --description "$LAYER_DESCRIPTION" --zip-file fileb://./complete_pem.zip
