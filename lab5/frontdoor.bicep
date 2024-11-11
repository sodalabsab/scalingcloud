// Parameters
param location string = 'swedencentral'
param containerGroupName string = 'nginxContainerGroup'
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'
param frontDoorSkuName string = 'Standard_AzureFrontDoor'
param storageAccountName string = 'sodalabscourse'
param blobContainerName string = 'website-content'

// Variables for names
var frontDoorProfileName = 'MyFrontDoorProfile'
var frontDoorOriginGroupName = 'MyOriginGroup'
var frontDoorOriginName = 'MyNginxOrigin'
var frontDoorRouteName = 'MyRoute'

// SAS Token for Downloading massively.zip
var sasToken = 'sv=2022-11-02&ss=bfqt&srt=o&sp=rwdlacupiytfx&se=2024-10-31T00:25:54Z&st=2024-10-30T16:25:54Z&spr=https&sig=AzNs68nR1Kn1o0kGmWLhW%2FKVywDfNEsnfMau%2B9sSfu0%3D'

// Nginx Container Group with Storage Mount and Startup Command
resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    containers: [
      {
        name: 'nginx'
        properties: {
          image: 'nginx:latest'
          ports: [
            {
              port: 80
            }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 1
            }
          }
          command: [
            '/bin/sh', '-c', 'apk add --no-cache unzip && wget --quiet --output-document=/usr/share/nginx/html/massively.zip "https://${storageAccountName}.blob.core.windows.net/${blobContainerName}/massively.zip?${sasToken}" && unzip /usr/share/nginx/html/massively.zip -d /usr/share/nginx/html && rm /usr/share/nginx/html/massively.zip && nginx -g "daemon off;"'
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
      dnsNameLabel: containerGroupName
    }
  }
}

// Front Door Profile
resource frontDoorProfile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoorProfileName
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

// Front Door Endpoint
resource frontDoorEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: frontDoorEndpointName
  parent: frontDoorProfile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}

// Front Door Origin Group
resource frontDoorOriginGroup 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: frontDoorOriginGroupName
  parent: frontDoorProfile
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 120
    }
  }
}

// Front Door Origin
resource frontDoorOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = {
  name: frontDoorOriginName
  parent: frontDoorOriginGroup
  properties: {
    hostName: containerGroup.properties.ipAddress.fqdn
    httpPort: 80
    originHostHeader: containerGroup.properties.ipAddress.fqdn
    priority: 1
    weight: 1000
  }
}

// Front Door Route
resource frontDoorRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: frontDoorRouteName
  parent: frontDoorEndpoint
  dependsOn: [
    frontDoorOrigin
  ]
  properties: {
    originGroup: {
      id: frontDoorOriginGroup.id
    }
    supportedProtocols: [
      'Http'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Disabled'
  }
}

// Outputs
output containerGroupHostName string = containerGroup.properties.ipAddress.fqdn
output frontDoorEndpointHostName string = frontDoorEndpoint.properties.hostName
