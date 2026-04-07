public class CaseMockCallout {

    public class GenericCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","result":{"response":"OK"}}');
            return res;
        }
    }
}
