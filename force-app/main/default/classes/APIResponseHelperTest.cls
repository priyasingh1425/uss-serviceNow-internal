@isTest
private class APIResponseHelperTest {

    private static MulesoftApiClient.HttpDetails buildHttpDetails(
        String method, String endpoint, String requestBody,
        Integer statusCode, String statusMessage, String responseBody
    ) {
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(endpoint);
        if (requestBody != null) {
            req.setBody(requestBody);
        }

        HttpResponse res = new HttpResponse();
        res.setStatusCode(statusCode);
        res.setStatus(statusMessage);
        res.setBody(responseBody);

        MulesoftApiClient.HttpDetails details = new MulesoftApiClient.HttpDetails();
        details.request  = req;
        details.response = res;
        return details;
    }

    private static final String SUCCESS_RESPONSE_BODY =
        '{"status":"success","message":"OK","result":{"response":"CHG0012345"}}';

    private static final String ERROR_RESPONSE_BODY =
        '{"Details":{"status":"failure","error":{"message":"Bad Request","detail":"Missing field"}}}';

    @isTest
    static void test_processApiResponse_status200_returnsDeserializedResponse() {
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'POST', 'callout:MulesoftExternalCallout/api/v1/com/change-requests',
            '{"u_cherwell_rec_id":"500001"}',
            200, 'OK', SUCCESS_RESPONSE_BODY
        );

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            ApiResponseHelper.processApiResponse(details, 'TestContext createCR', '500001');
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'processApiResponse should return a non-null CRCreateResponse on HTTP 200');
        System.assertEquals(true, resp.isSuccess(),
            'isSuccess() should be true for a 200 response with result payload');
        System.assertEquals('CHG0012345', resp.result.response,
            'result.response should contain the deserialized change number');

        List<API_Response__c> logs = [
            SELECT Success__c, Status_Code__c, Message__c, Method__c
            FROM API_Response__c
        ];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created');
        System.assertEquals('true', logs[0].Success__c,
            'Log Success__c should be "true" for HTTP 200');
        System.assertEquals('200', logs[0].Status_Code__c,
            'Log Status_Code__c should be "200"');
    }

    @isTest
    static void test_processApiResponse_status201_returnsDeserializedResponse() {
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'POST', 'callout:MulesoftExternalCallout/api/v1/com/incidents',
            '{"u_description":"Test"}',
            201, 'Created', SUCCESS_RESPONSE_BODY
        );

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            ApiResponseHelper.processApiResponse(details, 'TestContext createIncident', '500002');
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'processApiResponse should return a non-null CRCreateResponse on HTTP 201');

        List<API_Response__c> logs = [SELECT Success__c, Status_Code__c FROM API_Response__c];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created for 201');
        System.assertEquals('true', logs[0].Success__c,
            'Log Success__c should be "true" for HTTP 201');
        System.assertEquals('201', logs[0].Status_Code__c,
            'Log Status_Code__c should be "201"');
    }

    @isTest
    static void test_processApiResponse_status202_returnsDeserializedResponse() {
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'PATCH', 'callout:MulesoftExternalCallout/api/v1/com/incidents/INC001',
            '{"status":"pending"}',
            202, 'Accepted', SUCCESS_RESPONSE_BODY
        );

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            ApiResponseHelper.processApiResponse(details, 'TestContext updateStatus', '500003');
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'processApiResponse should return a non-null CRCreateResponse on HTTP 202');

        List<API_Response__c> logs = [SELECT Success__c, Status_Code__c FROM API_Response__c];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created for 202');
        System.assertEquals('true', logs[0].Success__c,
            'Log Success__c should be "true" for HTTP 202');
    }

    @isTest
    static void test_processApiResponse_status400_returnsNull_logsFailure() {
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'POST', 'callout:MulesoftExternalCallout/api/v1/com/change-requests',
            '{"u_cherwell_rec_id":"500004"}',
            400, 'Bad Request', ERROR_RESPONSE_BODY
        );

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            ApiResponseHelper.processApiResponse(details, 'TestContext createCR error', '500004');
        Test.stopTest();

        System.assertEquals(null, resp,
            'processApiResponse should return null on HTTP 400');

        List<API_Response__c> logs = [SELECT Success__c, Status_Code__c, Code__c FROM API_Response__c];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created for 400');
        System.assertEquals('false', logs[0].Success__c,
            'Log Success__c should be "false" for HTTP 400');
        System.assertEquals('400', logs[0].Status_Code__c,
            'Log Status_Code__c should be "400"');
        System.assertEquals('Bad Request', logs[0].Code__c,
            'Log Code__c should contain the HTTP status text');
    }

    @isTest
    static void test_processApiResponse_status500_returnsNull_logsFailure() {
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'PATCH', 'callout:MulesoftExternalCallout/api/v1/com/incidents/INC001',
            '{"CloseNote":"Resolved"}',
            500, 'Internal Server Error', '{"error":"Internal failure"}'
        );

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            ApiResponseHelper.processApiResponse(details, 'TestContext resolve error', '500005');
        Test.stopTest();

        System.assertEquals(null, resp,
            'processApiResponse should return null on HTTP 500');

        List<API_Response__c> logs = [SELECT Success__c, Status_Code__c, Code__c FROM API_Response__c];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created for 500');
        System.assertEquals('false', logs[0].Success__c,
            'Log Success__c should be "false" for HTTP 500');
        System.assertEquals('500', logs[0].Status_Code__c,
            'Log Status_Code__c should be "500"');
        System.assertEquals('Internal Server Error', logs[0].Code__c,
            'Log Code__c should contain the HTTP status text');
    }

    @isTest
    static void test_processApiResponse_status404_returnsNull_logsFailure() {
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'GET', 'callout:MulesoftExternalCallout/api/v1/com/incidents/INC999',
            null,
            404, 'Not Found', '{"error":"Resource not found"}'
        );

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            ApiResponseHelper.processApiResponse(details, 'TestContext notFound', '500006');
        Test.stopTest();

        System.assertEquals(null, resp,
            'processApiResponse should return null on HTTP 404');

        List<API_Response__c> logs = [SELECT Success__c, Status_Code__c FROM API_Response__c];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created for 404');
        System.assertEquals('false', logs[0].Success__c,
            'Log Success__c should be "false" for HTTP 404');
        System.assertEquals('404', logs[0].Status_Code__c,
            'Log Status_Code__c should be "404"');
    }

    @isTest
    static void test_processApiResponse_logsEndpointAndBodies() {
        String reqBody = '{"u_cherwell_rec_id":"500007"}';
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'POST', 'callout:MulesoftExternalCallout/api/v1/com/change-requests',
            reqBody,
            200, 'OK', SUCCESS_RESPONSE_BODY
        );

        Test.startTest();
        ApiResponseHelper.processApiResponse(details, 'LogVerify createCR', '500007');
        Test.stopTest();

        List<API_Response__c> logs = [
            SELECT Endpoint__c, Http_Request__c, Http_Response__c,
                   Message__c, Internal_Record_Identifier__c
            FROM API_Response__c
        ];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created');
        System.assert(logs[0].Endpoint__c.contains('/api/v1/com/change-requests'),
            'Log Endpoint__c should contain the request endpoint path');
        System.assertEquals(reqBody, logs[0].Http_Request__c,
            'Log Http_Request__c should contain the original request body');
        System.assertEquals(SUCCESS_RESPONSE_BODY, logs[0].Http_Response__c,
            'Log Http_Response__c should contain the raw response body');
        System.assertEquals('LogVerify createCR', logs[0].Message__c,
            'Log Message__c should contain the logContext string');
        System.assertEquals('500007', logs[0].Internal_Record_Identifier__c,
            'Log Internal_Record_Identifier__c should contain the recordId');
    }

    @isTest
    static void test_logException_createsAPIResponseRecord() {
        Exception testException;
        try {
            Integer x = 1 / 0;
        } catch (Exception e) {
            testException = e;
        }

        Test.startTest();
        ApiResponseHelper.logException('API_TestService', 'testMethod', testException);
        Test.stopTest();

        List<API_Response__c> logs = [
            SELECT Message__c, Http_Response__c, Success__c, Status_Code__c, Code__c
            FROM API_Response__c
        ];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created by logException');
        System.assertEquals('false', logs[0].Success__c,
            'Log Success__c should be "false" for an exception');
        System.assertEquals('500', logs[0].Status_Code__c,
            'Log Status_Code__c should be "500" for an exception');
        System.assertEquals('Exception', logs[0].Code__c,
            'Log Code__c should be "Exception"');

        System.assert(logs[0].Http_Response__c.contains('An error occurred in'),
            'Log Http_Response__c should contain the "An error occurred" prefix');
        System.assert(logs[0].Http_Response__c.contains('API_TestService'),
            'Log Http_Response__c should contain the logPrefix');
        System.assert(logs[0].Http_Response__c.contains('testMethod'),
            'Log Http_Response__c should contain the method name');
        System.assert(logs[0].Http_Response__c.contains('Divide by 0'),
            'Log Http_Response__c should contain the original exception message');
    }

    @isTest
    static void test_logException_customException_logsCorrectly() {
        Exception testException;
        try {
            throw new IllegalArgumentException('Custom validation failed');
        } catch (Exception e) {
            testException = e;
        }

        Test.startTest();
        ApiResponseHelper.logException('MyService', 'validateInput', testException);
        Test.stopTest();

        List<API_Response__c> logs = [
            SELECT Http_Response__c, Message__c
            FROM API_Response__c
        ];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created');
        System.assert(logs[0].Http_Response__c.contains('Custom validation failed'),
            'Log should contain the custom exception message');
        System.assert(logs[0].Http_Response__c.contains('MyService'),
            'Log should contain the service prefix');
        System.assertEquals('MyService validateInput', logs[0].Message__c,
            'Log Message__c should combine logPrefix and methodName');
    }

    @isTest
    static void test_processApiResponse_status503_returnsNull_logsFailure() {
        MulesoftApiClient.HttpDetails details = buildHttpDetails(
            'POST', 'callout:MulesoftExternalCallout/api/v1/com/change-requests',
            '{"u_cherwell_rec_id":"500008"}',
            503, 'Service Unavailable', '{"error":"Service temporarily unavailable"}'
        );

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            ApiResponseHelper.processApiResponse(details, 'TestContext 503', '500008');
        Test.stopTest();

        System.assertEquals(null, resp,
            'processApiResponse should return null on HTTP 503');

        List<API_Response__c> logs = [
            SELECT Success__c, Status_Code__c, Code__c
            FROM API_Response__c
        ];
        System.assertEquals(1, logs.size(),
            'Exactly one API_Response__c log should be created for 503');
        System.assertEquals('false', logs[0].Success__c,
            'Log Success__c should be "false" for HTTP 503');
        System.assertEquals('503', logs[0].Status_Code__c,
            'Log Status_Code__c should be "503"');
        System.assertEquals('Service Unavailable', logs[0].Code__c,
            'Log Code__c should be "Service Unavailable"');
    }
}
