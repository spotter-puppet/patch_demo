#!/bin/bash

# Uses these env variables: USER HOME
# From https://puppet.com/blog/how-automate-windows-patching-puppet/

PROJECT=spotter
GIT_BRANCH=development
GIT_USER=spp@unixsa.net
GIT_NAME="Stephen P. Potter"

CR_BASE="${HOME}/control-repo.base"
CR_WORK="${HOME}/${PROJECT}/control-repo"

# Setup code in control-repo
#Clone git instance 
mkdir ~/${PROJECT}
cd ~/${PROJECT}
echo "https://root:PuppetClassroomGitlabForYou@${PROJECT}-gitlab.classroom.puppet.com" >> ~/.git-credentials
git clone -b ${GIT_BRANCH} https://${PROJECT}-gitlab.classroom.puppet.com/puppet/control-repo.git
git config --global user.email ${GIT_USER}
git config --global user.name ${GIT_NAME}
git config --global credential.helper store

#Add to Puppetfile
#	albatrossflavour-os_patching 0.13.0
#	traggiccode-wsusserver 1.1.2
#	noma4i-windows_updates 0.3.0
#	puppetlabs-wsus_client 3.1.0
PFILE_SRC="${CR_BASE}/Puppetfile"
PFILE_WORK="${CR_WORK}/Puppetfile"
cp $PFILE_SRC $PFILE_WORK

PROFILE_DIR="site-modules/profile/manifests"
#Add profile::platform::baseline::windows::patch_mgmt (.pp file) from blog
PROFILE_WIN_DIR="platform/baseline/windows"
cp ${CR_BASE}/${PROFILE_DIR}/${PROFILE_WIN_DIR}/patch_mgmt.pp ${CR_WORK}/${PROFILE_DIR}/${PROFILE_WIN_DIR}/

#Add patch_mgmt to profile/platform/baseline/windows.pp
cp ${CR_BASE}/${PROFILE_DIR}/platform/baseline/windows.pp ${CR_WORK}/${PROFILE_DIR}/platform/baseline/

#Add profile::app:wsus (.pp file) from blog
cp ${CR_BASE}/${PROFILE_DIR}/app/wsus.pp ${CR_WORK}/${PROFILE_DIR}/app/

#Commit to git
cd ${CR_WORK}
git add .
git diff
git commit -m "Added patch_mgmt stuff"

#Deploy code to git branch
git push origin ${GIT_BRANCH}

# Here, CD4PE takes over, checks the code, and pushes it to the puppetmaster.  No longer have to create a
# code deployment manager in PE console, log into a VM use "puppet access login" and "puppet code deploy"

## Setup classifications in PE console
echo "Create Windows Prod environment group under Production
	use kernel = \"windows\" (lower case)
"

read -rsp $"Press any key to continue..." -n1 key
echo "Create WSUS environment under Windows Prod
	pin win0 node as rule
	add class profile::app:wsus
	run Puppet and take a coffee break as WSUS setup is completed (about 20 minutes)
"

read -rsp $"Press any key to continue after confirming WSUS setup is completed without errors..." -n1 key
echo "on win0, go into WSUS and force a sync to ensure patches are updated, take another break (could be hours)"

read -rsp $"Press any key to continue after confirming WSUS synchronization is completed without errors..." -n1 key
echo "Add patch_mgmt to Windows Prod classification
	set server_url parameter to \"http://*win0.classroom.puppet.com:8530/\" (watch for stringification)
	run puppet, should see new os_patching facts and KBs not applied
"

read -rsp $"Press any key to continue after confirming os_patching facts include KBs to be applied..." -n1 key
echo " 	change blacklist parameter to include all listed KBs except one (do not use KB2267602)
	change patch_window parameter to be around current time
	run puppet, one patch should be applied
"
read -r -s -p $"Press any key to continue..." -n1 key
