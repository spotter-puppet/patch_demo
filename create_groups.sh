#!/bin/sh
PROJECT=spp-test

TOKEN=`curl -s -S -k -X POST -H 'Content-Type: application/json' -d '{"login": "admin", "password": "puppetlabs"}' https://spp-test-master.classroom.puppet.com:4433/rbac-api/v1/auth/token |jq -r '.token'`
#echo The token is $TOKEN

#curl -k -X GET -H "X-Authentication: $TOKEN" -H "Content-Type: application/json" https://spp-fis-master.classroom.puppet.com:4433/classifier-api/v1/groups

curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Development", "parent": "00000000-0000-4000-8000-000000000000", "environment": "cd4pe_development", "rule": ["~",["fact", "clientcert"], "[13579]"], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8000-000000000001

curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Production", "parent": "00000000-0000-4000-8000-000000000000", "environment": "cd4pe_production", "rule": [ "and", [ "~",["fact", "clientcert"], "[02468]"] ], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8000-000000000002

# Create Windows Dev and Prod Groups with kernel = windows
curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Windows Development", "parent": "00000000-2112-4000-8000-000000000001", "environment": "cd4pe_development", "rule": ["=",["fact","kernel"],"windows"], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000001

curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test Windows Production", "parent": "00000000-2112-4000-8000-000000000002", "environment": "cd4pe_development", "rule": ["=",["fact","kernel"],"windows"], "classes": {} }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000002

# Create WSUS group under production, pin win0
curl -s -S -k -X PUT -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d '{ "name": "My Test WSUS Production", "parent": "00000000-2112-4000-8001-000000000002", "environment": "cd4pe_development", "classes": {"profile::app::wsus": {} } }' https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000003

curl -s -S -k -X POST -H 'Content-Type: application/json' -H "X-Authentication: $TOKEN" -d "{ \"nodes\": [ \"${PROJECT}win0.classroom.puppet.com\"] }" https://${PROJECT}-master.classroom.puppet.com:4433/classifier-api/v1/groups/00000000-2112-4000-8001-000000000003/pin

#bolt command run '(Get-WsusServer).GetSubscription().GetLastSynchronizationInfo()' --targets spp-testwin0.classroom.puppet.com --transport winrm --user administrator --password Puppetlabs! --no-ssl
#bolt command run '(Get-WsusServer).GetSubscription().StartSynchronization()' --targets spp-testwin0.classroom.puppet.com --transport winrm --user administrator --password Puppetlabs! --no-ssl
