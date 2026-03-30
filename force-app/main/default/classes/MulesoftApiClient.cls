public with sharing class MulesoftApiClient {

    public static HttpDetails sendRequest(String method, String path, Map<String, String> queryParams, Map<String, String> headers, String body, String type) {
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint('callout:MulesoftExternalCallout' + path);

        if (queryParams != null && !queryParams.isEmpty()) {
            List<String> q = new List<String>();
            for (String key : queryParams.keySet()) {
                q.add(key + '=' + EncodingUtil.urlEncode(queryParams.get(key), 'UTF-8'));
            }
            req.setEndpoint(req.getEndpoint() + '?' + String.join(q, '&'));
        }
        req.setTimeout(120000);

        if (headers != null) {
            for (String h : headers.keySet()) {
                req.setHeader(h, headers.get(h));
            }
        }

        if (body != null) {
            req.setBody(body);
        }
        HttpDetails details = new HttpDetails();
        details.request = req;
        details.response = new Http().send(req);
        return details;
    }

    public class HttpDetails {
        public HttpRequest request;
        public HttpResponse response;
    }
}