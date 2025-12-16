import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 20 }, // Simulate ramp-up of traffic from 1 to 20 users over 30 seconds.
    { duration: '45s', target: 20 }, // Stay at 20 users for 45 seconds
    { duration: '10s', target: 0 },  // Ramp-down to 0 users
  ],
};

export default function () {
  // Use BASE_URL from env or default to localhost
  const BASE_URL = __ENV.BASE_URL || 'http://localhost:8080';
  
  const res = http.get(BASE_URL);
  
  check(res, { 'status was 200': (r) => r.status == 200 });
  sleep(1);
}
