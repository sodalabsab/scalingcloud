import http from 'k6/http';
import { check, sleep } from 'k6';

export let options = {
  stages: [
    { duration: '10s', target: 10 }, // Ramp-up to 10 users over 1 minute
    { duration: '10s', target: 10 }, // Stay at 10 users for 3 minutes
    { duration: '10s', target: 0 },  // Ramp-down to 0 users
  ],
  thresholds: {
    http_req_duration: ['p(95)<500'], // 95% of requests should complete below 500ms
  },
};

export default function () {
  const url = 'http://afd-qs37vn6nplytg-hwdxhge6e3b9eheb.z01.azurefd.net'; // Replace with your Front Door endpoint

  const res = http.get(url);

  // Basic checks
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time is < 500ms': (r) => r.timings.duration < 500,
    'content includes expected text': (r) => r.body.includes('Welcome to nginx'), // Adjust if necessary
  });

  sleep(1);
}