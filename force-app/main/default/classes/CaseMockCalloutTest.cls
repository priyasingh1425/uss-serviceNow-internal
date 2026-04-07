@isTest
private class CaseMockCalloutTest {

    @isTest
    static void test_GenericCalloutMock_returns200WithSuccessBody() {
        CaseMockCallout.GenericCalloutMock mock = new CaseMockCallout.GenericCalloutMock();

        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setEndpoint('https://example.com/api');

        Test.startTest();
        HttpResponse res = mock.respond(req);
        Test.stopTest();

        System.assertEquals(200, res.getStatusCode(),
            'Mock should return status code 200');
        System.assertEquals('application/json', res.getHeader('Content-Type'),
            'Mock should return Content-Type application/json');
        System.assert(res.getBody().contains('"status":"success"'),
            'Mock body should contain success status');
        System.assert(res.getBody().contains('"response":"OK"'),
            'Mock body should contain result response OK');
    }

    @isTest
    static void test_outerClass_canBeInstantiated() {
        Test.startTest();
        CaseMockCallout instance = new CaseMockCallout();
        Test.stopTest();

        System.assertNotEquals(null, instance,
            'CaseMockCallout outer class should be instantiable');
    }
}
