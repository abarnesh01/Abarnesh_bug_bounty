Flo_Bugcrowd commented on Permissive CORS Policy on content-server.ibotta.com/graphql Allows Arbitrary Origins.
Hi prxsanth_exe,

Thank you for your submission. Before we can validate this submission, we require a proof-of-concept (PoC) that demonstrates the impact of a Cross-Origin Resource Sharing (CORS) vulnerability as a valid security issue.

To create a PoC that shows the impact of the vulnerability, you should identify an endpoint that allows cross-origin requests, that also returns sensitive data in the response. Then, create an HTML file that contains JavaScript code to make a cross-origin request to the vulnerable endpoint and extract the sensitive data. When opened by the victim, the HTML file should display the sensitive information obtained from the cross-origin request.

Note that exploiting a CORS vulnerability aims to access data that wouldn't be accessible to the attacker by simply navigating to a specific URL. The sensitive data must belong to the victim's account and not be publicly accessible. It is also important to note that, in some cases, endpoints may appear to respond like they are vulnerable to CORS, however do not return sensitive data. It is for this reason why we only consider CORS on endpoints that return sensitive information. To learn more about CORS, refer to <https://portswigger.net/web-security/cors>.

As you have yet to provide a valid proof-of-concept, we will close this submission as Not Reproducible. If you still believe this is valid, we encourage you to submit a new report with a full proof-of-concept per the description above. All the best in your future bug hunting!

Best regards,

- Flo_Bugcrowd

View Submission Details
Copyright © 2014 – 2026 Bugcrowd, Inc. All rights reserved.
300 California Street, Suite 220, San Francisco, CA 94104

The Bugcrowd Team <support@bugcrowd.com>
4:12 AM (5 hours ago)
to me

Flo_Bugcrowd 
Flo_Bugcrowd changed Permissive CORS Policy on content-server.ibotta.com/graphql Allows Arbitrary Origins to not applicable
This submission was marked not applicable. It is not a rewardable submission at this time.

Please note: This engagement does not allow disclosure. You may not release information about vulnerabilities found in this engagement to the public.

View Submission Details
