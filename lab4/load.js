import http from 'k6/http';
import { check, sleep } from 'k6';

// Target URL: Pass this via environment variable, or edit it here
// Usage: k6 run -e TARGET_URL=https://<your-frontdoor>.z01.azurefd.net load.js
const url = __ENV.TARGET_URL || 'https://afd-dt4tlc23l2xd2-cgdphgd7dzhnfraz.z03.azurefd.net/';

export let options = {
    vus: 50,             // Number of virtual users (start smaller for cloud to avoid throttling if free tier)
    duration: '30s',     // Duration of the test
};

export default function () {
    // We expect the Front Door URL (HTTPS)
    let res = http.get(url);

    check(res, {
        'status is 200': (r) => r.status === 200,
    });

    sleep(1);
}
