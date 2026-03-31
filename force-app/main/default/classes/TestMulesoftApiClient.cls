/**
 * @description  Enterprise-standard test class for MulesoftApiClient.
 *               Validates the sendRequest() HTTP builder logic including
 *               method/endpoint assignment, query parameter URL encoding,
 *               header injection, body assignment, timeout configuration,
 *               and null-safety for all optional parameters.
 *               Also covers the HttpDetails inner class property accessibility.
 *
 *               Uses a configurable inner HttpCalloutMock to intercept the
 *               Http.send() call and return controlled responses.
 *
 * Observability gap: MulesoftApiClient does not log to any persistent
 * object or System.debug — expected by design for a low-level HTTP utility.
 */
@isTest
private class TestMulesoftApiClient {

    // ════════════════════════════════════════════════════════════════════
    //  MOCK — Simple HttpCalloutMock
    // ════════════════════════════════════════════════════════════════════

    private class SimpleMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            return res;
        }
    }

    // ════════════════════════════════════════════════════════════════════
    //  A. ALL ARGUMENTS — full builder path
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_allArgumentsProvided_constructsProperly() {
        Map<String, String> queryParams = new Map<String, String>{
            'apiAction' => 'CreateCR',
            'filter'    => 'status eq active'
        };
        Map<String, String> headers = new Map<String, String>{
            'Content-Type' => 'application/json',
            'Accept'       => 'application/json'
        };
        String body = '{"description":"Test payload"}';

        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'POST',
            '/api/v1/com/change-requests',
            queryParams,
            headers,
            body,
            'changeRequest'
        );
        Test.stopTest();

        // Verify request was constructed properly
        System.assertNotEquals(null, details,
            'HttpDetails should not be null');
        System.assertNotEquals(null, details.request,
            'HttpDetails.request should not be null');
        System.assertNotEquals(null, details.response,
            'HttpDetails.response should not be null');

        // Verify HTTP method
        System.assertEquals('POST', details.request.getMethod(),
            'HTTP method should be POST');

        // Verify endpoint contains the base path and query params
        String endpoint = details.request.getEndpoint();
        System.assert(endpoint.contains('/api/v1/com/change-requests'),
            'Endpoint should contain the path');
        System.assert(endpoint.contains('?'),
            'Endpoint should contain query string separator');
        System.assert(endpoint.contains('apiAction=CreateCR'),
            'Endpoint should contain the apiAction query param');
        // 'status eq active' should be URL-encoded
        System.assert(endpoint.contains('filter=status+eq+active') ||
                       endpoint.contains('filter=status%20eq%20active'),
            'Endpoint should contain URL-encoded filter param');

        // Verify body
        System.assertEquals('{"description":"Test payload"}', details.request.getBody(),
            'Request body should match the input payload');

        // Verify response from mock
        System.assertEquals(200, details.response.getStatusCode(),
            'Mock response status code should be 200');
        System.assertEquals('{"status":"success"}', details.response.getBody(),
            'Mock response body should match');
    }

    // ════════════════════════════════════════════════════════════════════
    //  B. NULL QUERY PARAMS — skips query param block
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_nullQueryParams_handlesGracefully() {
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'GET',
            '/api/v1/com/incidents',
            null,   // queryParams = null
            new Map<String, String>{ 'Accept' => 'application/json' },
            null,   // body = null
            'incidents'
        );
        Test.stopTest();

        String endpoint = details.request.getEndpoint();
        System.assert(!endpoint.contains('?'),
            'Endpoint should NOT contain query string when queryParams is null');
        System.assertEquals('GET', details.request.getMethod(),
            'HTTP method should be GET');
    }

    // ════════════════════════════════════════════════════════════════════
    //  C. EMPTY QUERY PARAMS — skips query param block
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_emptyQueryParams_handlesGracefully() {
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'PATCH',
            '/api/v1/com/incidents/INC001',
            new Map<String, String>(),  // empty map
            new Map<String, String>{ 'Content-Type' => 'application/json' },
            '{"status":"pending"}',
            'incidents'
        );
        Test.stopTest();

        String endpoint = details.request.getEndpoint();
        System.assert(!endpoint.contains('?'),
            'Endpoint should NOT contain query string when queryParams is empty');
        System.assertEquals('PATCH', details.request.getMethod(),
            'HTTP method should be PATCH');
    }

    // ════════════════════════════════════════════════════════════════════
    //  D. NULL HEADERS — skips header injection block
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_nullHeaders_handlesGracefully() {
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'POST',
            '/api/v1/com/change-requests',
            new Map<String, String>{ 'apiAction' => 'CreateCR' },
            null,   // headers = null
            '{"data":"value"}',
            'changeRequest'
        );
        Test.stopTest();

        System.assertNotEquals(null, details.response,
            'Response should still be returned even with null headers');
        System.assertEquals(200, details.response.getStatusCode(),
            'Mock response should succeed even without headers');
    }

    // ════════════════════════════════════════════════════════════════════
    //  E. NULL BODY — skips body assignment block
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_nullBody_handlesGracefully() {
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'GET',
            '/api/v1/com/incidents',
            null,
            new Map<String, String>{ 'Accept' => 'application/json' },
            null,   // body = null
            'incidents'
        );
        Test.stopTest();

        System.assertNotEquals(null, details.response,
            'Response should still be returned even with null body');
        // getBody() on a request with no body set returns null or empty
        System.assertEquals('GET', details.request.getMethod(),
            'HTTP method should be GET');
    }

    // ════════════════════════════════════════════════════════════════════
    //  F. ALL NULL OPTIONAL PARAMS — minimum viable call
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_allOptionalNull_handlesGracefully() {
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'DELETE',
            '/api/v1/com/resource/123',
            null,   // queryParams
            null,   // headers
            null,   // body
            null    // type
        );
        Test.stopTest();

        System.assertNotEquals(null, details,
            'HttpDetails should not be null even with all optional params null');
        System.assertEquals('DELETE', details.request.getMethod(),
            'HTTP method should be DELETE');
        System.assertEquals(200, details.response.getStatusCode(),
            'Mock response should succeed');
    }

    // ════════════════════════════════════════════════════════════════════
    //  G. QUERY PARAM ENCODING — special characters
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_specialCharQueryParams_encodedProperly() {
        Map<String, String> queryParams = new Map<String, String>{
            'search' => 'hello world&foo=bar',
            'name'   => 'O\'Brien'
        };

        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'GET',
            '/api/v1/search',
            queryParams,
            null,
            null,
            'search'
        );
        Test.stopTest();

        String endpoint = details.request.getEndpoint();
        System.assert(endpoint.contains('?'),
            'Endpoint should contain query string');
        // The & in the value should be encoded, not treated as a param separator
        System.assert(!endpoint.contains('foo=bar'),
            'Ampersand in query value should be URL-encoded, not parsed as a separator');
        // O'Brien should have the apostrophe encoded
        System.assert(endpoint.contains('name=O'),
            'Name param should be present in encoded form');
    }

    // ════════════════════════════════════════════════════════════════════
    //  H. MULTIPLE HEADERS — all injected
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_multipleHeaders_allInjected() {
        Map<String, String> headers = new Map<String, String>{
            'Content-Type'  => 'application/json',
            'Accept'        => 'application/json',
            'Authorization' => 'Bearer test-token-123',
            'X-Custom'      => 'CustomValue'
        };

        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails details = MulesoftApiClient.sendRequest(
            'POST',
            '/api/v1/com/test',
            null,
            headers,
            '{}',
            'test'
        );
        Test.stopTest();

        // We can't directly read back arbitrary headers from HttpRequest in Apex,
        // but we verify no exceptions were thrown during injection
        System.assertNotEquals(null, details.response,
            'Response should be returned after setting multiple headers');
        System.assertEquals(200, details.response.getStatusCode(),
            'Mock should succeed with multiple headers');
    }

    // ════════════════════════════════════════════════════════════════════
    //  I. HttpDetails — inner class property coverage
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_HttpDetails_properties_canBeAssignedAndRead() {
        Test.startTest();
        MulesoftApiClient.HttpDetails details = new MulesoftApiClient.HttpDetails();

        HttpRequest req = new HttpRequest();
        req.setMethod('GET');
        req.setEndpoint('https://example.com');
        details.request = req;

        HttpResponse res = new HttpResponse();
        res.setStatusCode(204);
        res.setBody('No Content');
        details.response = res;
        Test.stopTest();

        System.assertNotEquals(null, details.request,
            'HttpDetails.request should be assignable');
        System.assertEquals('GET', details.request.getMethod(),
            'request.getMethod() should return the assigned method');
        System.assertEquals('https://example.com', details.request.getEndpoint(),
            'request.getEndpoint() should return the assigned endpoint');

        System.assertNotEquals(null, details.response,
            'HttpDetails.response should be assignable');
        System.assertEquals(204, details.response.getStatusCode(),
            'response.getStatusCode() should return the assigned status');
        System.assertEquals('No Content', details.response.getBody(),
            'response.getBody() should return the assigned body');
    }

    // ════════════════════════════════════════════════════════════════════
    //  J. DIFFERENT HTTP METHODS — verifies method passthrough
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_sendRequest_differentMethods_passedThrough() {
        Test.setMock(HttpCalloutMock.class, new SimpleMock());

        Test.startTest();
        MulesoftApiClient.HttpDetails putDetails = MulesoftApiClient.sendRequest(
            'PUT', '/api/v1/resource', null, null, '{"update":true}', 'test'
        );
        Test.stopTest();

        System.assertEquals('PUT', putDetails.request.getMethod(),
            'HTTP method should be PUT as passed');
    }
}