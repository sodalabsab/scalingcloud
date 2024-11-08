import http from 'k6/http';
import { check } from 'k6';

// Target URL (modify to point to your Nginx load-balanced endpoint)
const url = 'http://my-nginx';

export let options = {
  vus: 100,           // Number of virtual users
  duration: '15s'     // Duration of the test
}

export default function () {
  let res = http.get(url);
  check(res, {
    'status is 200': (r) => r.status === 200
  });
}