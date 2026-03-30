@isTest
global class HttpMockCallout implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        //System.assertEquals('http://abc.com/abc', req.getEndpoint());
		//System.assertEquals('GET', req.getMethod());      
        HttpResponse resp = new HttpResponse();
        resp.setStatusCode(200);
        resp.setBody('{"success":"true","message":"The Order for Service has been created.","code":"API_OFS_CREATED","data":{"token":"OFS!","order_for_service_id":12345,"description":"Just a description"}}');
        return resp;
    }
}