
@description('Location for the Container App Environment.')
param location string = resourceGroup().location

@description('Application Container Image.')
param applicationImage string

@description('The ACR Login Server (e.g. sodalabs001.azurecr.io)')
param acrServer string

@description('The Resource ID of the User Assigned Identity used to pull images')
param userAssignedIdentityId string

@description('The Name of the Container App (Unused in Lab 5)')
param containerAppName string = ''

@description('Simple k6 load testing script embedded as a multi-line string')
var k6Script = 'import http from "k6/http";\nimport { sleep } from "k6";\n\nexport let options = {\n vus: 10,\n  duration: "30s",\n};\n\nexport default function () {\n  http.get("https://afd-nc4rwlerxxjps-etb6hygffsdhb9f3.z03.azurefd.net");\n  sleep(1);\n}'

@description('Command to run the k6 script')
var k6Command = '''echo "$K6_SCRIPT" > /tmp/script.js && k6 run /tmp/script.js'''

// Container Group
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: 'k6-container'
  location: 'westus'
  properties: {
    containers: [
      {
        name: 'k6-container'
        properties: {
          image: 'grafana/k6'
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          environmentVariables: [
            {
              name: 'K6_SCRIPT'
              value: k6Script
            }
          ]
          command: [
            '/bin/sh', '-c', k6Command
          ]
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: 'Never' // The container will run once and then stop
  }
}
