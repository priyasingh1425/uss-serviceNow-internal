@isTest
public class HLP_OpsRamp_MockHttpResponse_TST implements HttpCalloutMock{
// Mock HTTP Response Generator for successful responses    
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        
        if (req.getEndpoint().contains('/devices/minimal')) {
            // Mock response for get devices API
            res.setBody('[{"uniqueId":"device-123","hostName":"TestHost1","ipAddress":"192.168.1.100","aliasName":"TestAlias","resourceName":"TestResource","resourceType":"Server"}]');
            res.setStatusCode(200);
        } else if (req.getEndpoint().contains('/scheduleMaintenances')) {
            // Mock response for create maintenance window API
            res.setBody('{"id":"maintenance-123","status":"scheduled"}');
            res.setStatusCode(200);
        } else {
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
        }
        
        return res;
    }
}