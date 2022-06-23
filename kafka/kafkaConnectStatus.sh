#!/bin/bash
## lhiggins

## pull experience-kafka-connect pods and retrieve status
## have your kube config updated and pointed to the correct stuff (context/namespace)
## have jq installed

###############################################
## Variables...for stuff that changes

# What pods to match on? put your grep pattern here
matchPod='experience-kafka-connect'

# baseURL
baseURL='curl http://localhost:8084/connectors/'

# action
action='/status'

## script vars
RED='\033[0;31m'
NC='\033[0m' # No Color
###############################################

echo $(date)
echo ""

if [[ -d "./status" ]]
   then
	#echo "status dir exists"
   else
        echo "making subdir 'status'"
        mkdir status
fi

echo ""
# if you need the list, uncomment below and read from file
#kubectl get pod | grep "$matchPod" | head -1 |cut -d ' ' -f 1 > tmpPodList

# getting a pod to pull connectors/status/restart/make coffee
pod=`kubectl get pod | grep "$matchPod" | head -1 |cut -d ' ' -f 1`

# exec into pod and retrieve connector list
#k exec --stdin --tty experience-kafka-connect-ddd6bb5c7-5qs4w -- curl http://localhost:8084/connectors | jq . | less

#kubectl exec --stdin --tty "$pod" -- curl http://localhost:8084/connectors | jq . > tmpConnList

kubectl exec --stdin --tty "$pod" -- curl http://localhost:8084/connectors | jq -r '. | join("\n")' > tmpConnList

# file clean up time; replaced by jq join
#sed -i '/^\[/d' tmpConnList
#sed -i '/^\]/d' tmpConnList
#sed -i 's/  "//g' tmpConnList
#sed -i 's/",//g' tmpConnList
#sed -i 's/"//g' tmpConnList


# 
#awk -v a="$baseURL" -v b="$action" -v c="$pod" '{print "kubectl exec --stdin --tty " c " -- " a $0 b " | jq . > "}' tmpConnList > curlCommands

awk -v a="$baseURL" -v b="$action" -v c="$pod" 'BEGIN {RS = "\n"}{print "kubectl exec --stdin --tty " c " -- " a $0 b " | jq . > " $0".status"}' tmpConnList > ./status/statusCommands

#cat curlCommands

echo ""
echo $(date)
echo "checking the status for each connector"
cd status
bash statusCommands
echo ""
echo $(date)

echo ""
echo "You can also find the commands in ./status/statusCommands"
echo ""

echo  "TASK COUNTS:"

echo -e "Below is the ${RED}FAILED${NC} task count:"
grep -c FAILED *.status

echo ""
echo ""
echo "Below is the running task count:"
grep -c RUNNING *.status

echo ""
echo -e "${RED}DONE!"
echo -e "${NC}"
