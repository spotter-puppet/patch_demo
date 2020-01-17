https://puppet.com/blog/how-automate-windows-patching-puppet/

# Setup code in control-repo
Clone git instance 
	git clone -b production https://spp-gitlab.classroom.puppet.com/puppet/control-repo.git
Add to Puppetfile
	albatrossflavour-os_patching 0.13.0
	traggiccode-wsusserver 1.1.2
	noma4i-windows_updates 0.3.0
	puppetlabs-wsus_client 3.1.0
Add profile::platform::baseline::windows::patch_mgmt (.pp file) from blog
Add patch_mgmt to profile/platform/baseline/windows.pp
Add profile::app:wsus (.pp file) from blog
Commit to git
Deploy code to production

# Setup classifications in PE console
Create Windows Prod environment group under Production
	use kernel = "windows" (lower case)
Create WSUS environment under Windows Prod
	pin win0 node as rule
	add class profile::app:wsus
	run Puppet and take a coffee break as WSUS setup is completed (about 20 minutes)
	on win0, go into WSUS and force a sync to ensure patches are updated, take another break (could be hours)
Add patch_mgmt to Windows Prod classification
	set server_url parameter to http://*win0.classroom.puppet.com:8530/ (watch for stringification)
	run puppet, should see new os_patching facts and KBs not applied
	change blacklist parameter to include all listed KBs except one
	change patch_window parameter to be around current time
	run puppet, one patch should be applied
