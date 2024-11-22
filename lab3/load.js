import http from 'k6/http';
import { check, sleep } from 'k6';

// Target URL (modify to point to your Nginx load-balanced endpoint)
const url = 'https://my-website.agreeablesky-896f72b6.swedencentral.azurecontainerapps.io';

export let options = {
  vus: 50,           // Number of virtual users
  duration: '3m',     // Duration of the test
};

export default function () {
  let res = http.get(url);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}