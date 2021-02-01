#!/bin/bash

# Uses these env variables: USER HOME
# From https://puppet.com/blog/how-automate-windows-patching-puppet/

PROJECT=$1
GIT_BRANCH=$2
CLIENT_COUNT=$3
GIT_USER=spp@unixsa.net
GIT_NAME='Stephen P. Potter'

if [ "x${PROJECT}" == "x" ];
then
	echo "usage: $0 [project] <env> <num_nodes>"
	exit 1
fi
if [ "x${GIT_BRANCH}" == "x" ];
then
	GIT_BRANCH=development
fi
if [ "x${CLIENT_COUNT}" == "x" ];
then
	CLIENT_COUNT=2
fi

CR_BASE="${HOME}/patch_demo/files"
CR_WORK="${HOME}/${PROJECT}/control-repo"

TOKEN=`curl -s -S -k -X POST -H 'Content-Type: application/json' -d '{"login": "admin", "password": "puppetlabs", "lifetime": "24h"}' https://${PROJECT}-master.classroom.puppet.com:4433/rbac-api/v1/auth/token |jq -r '.token'`

# Setup code in control-repo
#Clone git instance 
mkdir ~/${PROJECT}
cd ~/${PROJECT}
echo "https://root:PuppetClassroomGitlabForYou@${PROJECT}-gitlab.classroom.puppet.com" >> ~/.git-credentials
git config --global user.email ${GIT_USER}
git config --global user.name "${GIT_NAME}"
git config --global credential.helper store
git clone https://${PROJECT}-gitlab.classroom.puppet.com/puppet/control-repo.git

cd ${CR_WORK}

git checkout -b ${GIT_BRANCH}
git push origin ${GIT_BRANCH}

echo "

Log into CD4PE and create a Pipeline for the Development branch:
	Go to Workspaces/Demo
	Go to Control Repos/control-repo
	Click on 'Add Pipeline' (blue Philips head icon)
	Select 'development' branch
	Click 'Add Pipeline'
	Click 'Done' after 'The pipeline has been successfully added'
	Click '+ Add default pipeline'
	Click the checkbox next 'Auto promote' between Impact Analysis and Deployment stages
	Click '+ Add a deployment' under the Deployment stage
	Select 'Development environment' (cd4pe_development) for the node group
	Use the 'Direct deployment policy'
	Leave the default parameters and timeout'
	Click 'Add Deployment to Stage'
	Click 'Done' after the success notice
"

read -rsp $"Press any key to continue..." -n1 key
#Add to Puppetfile
#	albatrossflavour-os_patching 0.13.0
#	traggiccode-wsusserver 1.1.2
#	noma4i-windows_updates 0.3.0
#	puppetlabs-wsus_client 3.1.0
PFILE_SRC="${CR_BASE}/Puppetfile"
PFILE_WORK="${CR_WORK}/Puppetfile"
cp $PFILE_SRC $PFILE_WORK

touch ${CR_WORK}/bolt.yaml

PROFILE_DIR="${CR_WORK}/site-modules/profile/manifests"
#Add profile::platform::baseline::windows::patch_mgmt (.pp file) from blog
PROFILE_WIN_DIR="platform/baseline/windows"
cp ${CR_BASE}/patch_mgmt.pp ${PROFILE_DIR}/${PROFILE_WIN_DIR}/

#Add patch_mgmt to profile/platform/baseline/windows.pp
cp ${CR_BASE}/windows.pp ${PROFILE_DIR}/platform/baseline/

#Add profile::app:wsus (.pp file) from blog
cp ${CR_BASE}/wsus.pp ${PROFILE_DIR}/app/

cp ${CR_BASE}/RunSync.ps1 ${PROFILE_DIR}/../tasks/wsus_sync.ps1

#Commit to git
cd ${CR_WORK}
git add .
git diff
git commit -m "Added patch_mgmt stuff"

#Deploy code to git branch
git push origin ${GIT_BRANCH}

echo "

	ensure CD4PE run has completed

	"
read -rsp $"Press any key to continue after confirming CD4PE pipeline setup is completed without errors..." -n1 key

## Setup classifications in PE console
#Create Dev and Production Groups
curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Development", "parent": "00000000-0000-4000-8000-000000000000", "environment": "cd4pe_development", "rule": ["~",["fact", "clientcert"], "[13579]"], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8000-000000000001

curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Production", "parent": "00000000-0000-4000-8000-000000000000", "environment": "cd4pe_production", "rule": [ "~",["fact", "clientcert"], "[02468]"], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8000-000000000002

# Create Windows Dev and Prod Groups with kernel = windows
curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Windows Development", "parent": "00000000-2112-4000-8000-000000000001", "environment": "cd4pe_development", "rule": ["=",["fact","kernel"],"windows"], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000001

curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Windows Production", "parent": "00000000-2112-4000-8000-000000000002", "environment": "cd4pe_production", "rule": ["=",["fact","kernel"],"windows"], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000002

curl -s -S -k -X POST -H 'Content-Type:application/json' -H "X-Authentication: $TOKEN" https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/update-classes

# Create WSUS group under production, pin win0
curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test WSUS Production", "parent": "00000000-2112-4000-8001-000000000002", "environment": "cd4pe_production", "classes": {"profile::app::wsus": {} } }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000003

curl -s -S -k -X POST -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d "{ \"nodes\": [ \"${PROJECT}win0.classroom.puppet.com\"] }" https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000003/pin

echo "

	take a coffee break as WSUS setup is completed (about 20 minutes)

"
bolt command run 'puppet agent -t' --targets ${PROJECT}win0.classroom.puppet.com --transport winrm --user administrator --password Puppetlabs! --no-ssl

bolt task run 'profile::wsus_sync' --targets ${PROJECT}win0.classroom.puppet.com --transport winrm --user administrator --password Puppetlabs! --no-ssl

#read -rsp $"Press any key to continue after confirming WSUS setup is completed without errors..." -n1 key

read -rsp $"Press any key to continue after confirming WSUS synchronization is completed without errors..." -n1 key

echo "

Add patch_mgmt to Windows Prod classification
	set server_url parameter to \"http://*win0.classroom.puppet.com:8530/\" (watch for stringification)
	run puppet, should see new os_patching facts and KBs not applied
"

read -rsp $"Press any key to continue after confirming os_patching facts include KBs to be applied..." -n1 key
echo "

	change blacklist parameter to include all listed KBs except one (do not use KB2267602)
	change patch_window parameter to be around current time
	   Although patch_window will automatically show up in Puppet DSC, 
	   to save, it must be in YAML format and ALL strings must be
	   enclosed in double quotes or PE console will attempt to stringify
	   and cause compilation errors
	   For exmaple:

	   {
		   "range": "01:00 - 23:00",
		   "weekday": "Sunday",
		   "retry": 3
	   }

	run puppet, one patch should be applied
"
read -r -s -p $"Press any key to continue..." -n1 key
