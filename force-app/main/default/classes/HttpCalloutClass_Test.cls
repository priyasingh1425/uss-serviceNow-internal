@isTest
public class HttpCalloutClass_Test {
     @isTest static void testCallout() {
        Test.setMock(HttpCalloutMock.class, new HttpMockCallout());
        HttpResponse res = HttpCalloutClass.getInfoFromExternalService();
        String actualValue = res.getBody();
        String expectedValue = '{"success":"true","message":"The Order for Service has been created.","code":"API_OFS_CREATED","data":{"token":"OFS!","order_for_service_id":12345,"description":"Just a description"}}';
        System.assertEquals(actualValue, expectedValue);
        System.assertEquals(200, res.getStatusCode());
    }
}