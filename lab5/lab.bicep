
// Simple k6 load testing script embedded as a multi-line string
var k6Script = 'import http from "k6/http";\nimport { sleep } from "k6";\n\nexport let options = {\n vus: 10,\n  duration: "30s",\n};\n\nexport default function () {\n  http.get("https://afd-ofxe7iasj32su-a6f2b6a3eeage3df.z01.azurefd.net/");\n  sleep(1);\n}'

// Command to run the k6 script
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
