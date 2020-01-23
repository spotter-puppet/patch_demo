#!/bin/bash

# Uses these env variables: USER HOME
# From https://puppet.com/blog/how-automate-windows-patching-puppet/

PROJECT=$1
GIT_BRANCH=$2
GIT_USER=spp@unixsa.net
GIT_NAME='Stephen P. Potter'

if [ "x${PROJECT}" == "x" ];
then
	echo "usage: $0 [project] <env>"
	exit 1
fi
if [ "x${GIT_BRANCH}" == "x" ];
then
	GIT_BRANCH=development
fi

CR_BASE="${HOME}/patch_demo/files"
CR_WORK="${HOME}/${PROJECT}/control-repo"

# Setup code in control-repo
#Clone git instance 
mkdir ~/${PROJECT}
cd ~/${PROJECT}
#echo "https://root:PuppetClassroomGitlabForYou@${PROJECT}-gitlab.classroom.puppet.com" >> ~/.git-credentials
git clone https://${PROJECT}-gitlab.classroom.puppet.com/puppet/control-repo.git
git config --global user.email ${GIT_USER}
git config --global user.name "${GIT_NAME}"
git config --global credential.helper store

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
	Click the checkbox next 'Auto promote' between Impace Analysis and Deployment stages
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

PROFILE_DIR="${CR_WORK}/site-modules/profile/manifests"
#Add profile::platform::baseline::windows::patch_mgmt (.pp file) from blog
PROFILE_WIN_DIR="platform/baseline/windows"
cp ${CR_BASE}/patch_mgmt.pp ${PROFILE_DIR}/${PROFILE_WIN_DIR}/

#Add patch_mgmt to profile/platform/baseline/windows.pp
cp ${CR_BASE}/windows.pp ${PROFILE_DIR}/platform/baseline/

#Add profile::app:wsus (.pp file) from blog
cp ${CR_BASE}/wsus.pp ${PROFILE_DIR}/app/

#Commit to git
cd ${CR_WORK}
git add .
git diff
git commit -m "Added patch_mgmt stuff"

#Deploy code to git branch
git push origin ${GIT_BRANCH}

## Setup classifications in PE console
echo "

Create Windows Prod environment group under Production
	use kernel = \"windows\" (lower case)
"

read -rsp $"Press any key to continue..." -n1 key
echo "

Create WSUS environment under Windows Prod
	pin win0 node as rule
	add class profile::app:wsus
	run Puppet and take a coffee break as WSUS setup is completed (about 20 minutes)
"

read -rsp $"Press any key to continue after confirming WSUS setup is completed without errors..." -n1 key
echo "

on win0, go into WSUS and force a sync to ensure patches are updated, take another break (could be hours)"

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
	run puppet, one patch should be applied
"
read -r -s -p $"Press any key to continue..." -n1 key
