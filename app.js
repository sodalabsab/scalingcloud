// app.js
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Function to get Azure region from environment variables
const getAzureRegion = () => {
    return process.env.REGION_NAME || 'Unknown region';
  };
  
  // Main route that prints the Azure region
  app.get('/', (req, res) => {
    const region = getAzureRegion();
    res.send(`This app is running in the Azure region: ${region}`);
  });

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});