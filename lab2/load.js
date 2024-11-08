import http from 'k6/http';
import { check, sleep } from 'k6';

// Target URL (modify to point to your Nginx load-balanced endpoint)
const url = 'http://localhost:8080';

export let options = {
  vus: 100,           // Number of virtual users
  duration: '10s',     // Duration of the test
};

export default function () {
  let res = http.get(url);
  check(res, {
    'status is 200': (r) => r.status === 200,
  });
}