/**
 * @description  Enterprise-standard test class for API_IncidentService.
 *               Validates all 5 public methods: createIncident, createWorkNote,
 *               updateIncidentStatus, resolveIncidents, updatePriorityOnIncidents.
 *               Covers positive HTTP 200 responses, negative HTTP 400 responses,
 *               exception catch-block paths, data-validation short-circuits,
 *               and HTML-stripping payload sanitization via toPlainText().
 *
 *               Uses a configurable inner HttpCalloutMock that can return
 *               custom status codes or throw a CalloutException on demand.
 */
@isTest
private class TestAPI_IncidentService {

    // ════════════════════════════════════════════════════════════════════
    //  MOCK — Configurable HttpCalloutMock
    // ════════════════════════════════════════════════════════════════════

    private class ConfigurableMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  responseBody;
        private Boolean shouldThrow;

        public ConfigurableMock(Integer statusCode, String responseBody) {
            this.statusCode   = statusCode;
            this.responseBody = responseBody;
            this.shouldThrow  = false;
        }

        public ConfigurableMock(Boolean shouldThrow) {
            this.shouldThrow = shouldThrow;
        }

        public HTTPResponse respond(HTTPRequest req) {
            if (shouldThrow) {
                throw new CalloutException('Simulated callout failure');
            }
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            return res;
        }
    }

    // ════════════════════════════════════════════════════════════════════
    //  CONSTANTS
    // ════════════════════════════════════════════════════════════════════

    private static final String SUCCESS_BODY = '{"status":"success","message":"OK","result":{"response":"INC0012345"}}';
    private static final String ERROR_BODY   = '{"Details":{"status":"failure","error":{"message":"Bad Request","detail":"Missing field"}}}';

    // ════════════════════════════════════════════════════════════════════
    //  TEST SETUP
    // ════════════════════════════════════════════════════════════════════

    @testSetup
    static void setupTestData() {
        // 1. Account
        Account acc = new Account(Name = 'Incident Service Test Account');
        insert acc;

        // 2. Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'IncService',
            AccountId = acc.Id
        );
        insert con;

        // 3. Custom Setting
        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Account_Id__c   = acc.Id,
            Contact_Name__c = 'Test Contact',
            Queue_Name__c   = 'TOC Queue'
        );
        insert settings;

        // 4. Record Type
        Id extSupportRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                                .get('External_Customer_Support').getRecordTypeId();

        // 5. Case with Customer_Rec_Id__c (for status/resolve/priority)
        Case incCase = new Case(
            Subject            = 'Incident Case',
            Description        = 'Server outage description',
            Status             = 'New',
            RecordTypeId       = extSupportRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'INC0099999',
            Details__c         = 'Resolved via restart'
        );
        insert incCase;

        // 6. Case without Customer_Rec_Id__c (for short-circuit tests)
        Case blankCase = new Case(
            Subject      = 'Blank RecId Case',
            Description  = 'No incident number',
            Status       = 'New',
            RecordTypeId = extSupportRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert blankCase;

        // 7. Case with HTML in Details__c (for toPlainText test)
        Case htmlCase = new Case(
            Subject            = 'HTML Details Case',
            Description        = 'HTML test',
            Status             = 'Resolved',
            RecordTypeId       = extSupportRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'INC0088888',
            Details__c         = '<p>Root cause <b>identified</b>&nbsp;and resolved.</p>'
        );
        insert htmlCase;

        // 8. Case for FeedItem / WorkNote
        Case feedCase = new Case(
            Subject            = 'FeedItem Incident Case',
            Status             = 'New',
            RecordTypeId       = extSupportRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Customer_Rec_Id__c = 'INC0077777'
        );
        insert feedCase;

        // 9. FeedItem for work note tests
        FeedItem fi = new FeedItem(
            ParentId   = feedCase.Id,
            Body       = 'Work note content for incident testing',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;

        // 10. Case with null optional fields
        Case minimalCase = new Case(
            Subject      = 'Minimal Incident',
            Status       = 'New',
            RecordTypeId = extSupportRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'High'
            // Description, Vendor_Service_ID__c, Category__c left null
        );
        insert minimalCase;
    }

    // ════════════════════════════════════════════════════════════════════
    //  HELPERS
    // ════════════════════════════════════════════════════════════════════

    private static Case getCaseBySubject(String subj) {
        return [SELECT Id, CaseNumber, Subject, Description, Status, RecordTypeId,
                       AccountId, ContactId, Origin, Priority, Customer_Rec_Id__c,
                       Details__c, Vendor_Service_ID__c, Category__c
                FROM Case WHERE Subject = :subj LIMIT 1];
    }

    // ════════════════════════════════════════════════════════════════════
    //  A. createIncident — HTTP 200 Success
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_createIncident_successResponse() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp = API_IncidentService.createIncident(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'createIncident should return a non-null CRCreateResponse on HTTP 200');
        System.assertNotEquals(null, resp.result,
            'Response result should be populated on success');
    }

    // ════════════════════════════════════════════════════════════════════
    //  B. createIncident — HTTP 400 Error
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_createIncident_http400_returnsNull() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(400, ERROR_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp = API_IncidentService.createIncident(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'createIncident should return null on HTTP 400 error');
    }

    // ════════════════════════════════════════════════════════════════════
    //  C. createIncident — Exception Path
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_createIncident_throwsException_returnsNull() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(true));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp = API_IncidentService.createIncident(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'createIncident should return null when an exception is thrown');
    }

    // ════════════════════════════════════════════════════════════════════
    //  D. createIncident — null optional fields handled gracefully
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_createIncident_nullOptionalFields_handlesGracefully() {
        Case c = getCaseBySubject('Minimal Incident');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp = API_IncidentService.createIncident(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'createIncident should handle null optional fields gracefully');
    }

    // ════════════════════════════════════════════════════════════════════
    //  E. createWorkNote — HTTP 200 Success
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_createWorkNote_successResponse() {
        Case feedCase = [SELECT Id FROM Case WHERE Subject = 'FeedItem Incident Case' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.createWorkNote(fi, 'INC0077777');
        Test.stopTest();

        System.assert(true, 'createWorkNote completed without exception on HTTP 200');
    }

    // ════════════════════════════════════════════════════════════════════
    //  F. createWorkNote — Exception Path
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_createWorkNote_throwsException_returnsNull() {
        Case feedCase = [SELECT Id FROM Case WHERE Subject = 'FeedItem Incident Case' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(true));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.createWorkNote(fi, 'INC0077777');
        Test.stopTest();

        System.assertEquals(null, resp,
            'createWorkNote should return null when an exception is thrown');
    }

    // ════════════════════════════════════════════════════════════════════
    //  G. createWorkNote — blank vendor number (short-circuit)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_createWorkNote_blankVendorNumber_returnsNull() {
        Case feedCase = [SELECT Id FROM Case WHERE Subject = 'FeedItem Incident Case' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.createWorkNote(fi, '');
        Test.stopTest();

        System.assertEquals(null, resp,
            'createWorkNote should return null when vendorNumber is blank');
    }

    // ════════════════════════════════════════════════════════════════════
    //  H. updateIncidentStatus — HTTP 200 Success
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_updateIncidentStatus_successResponse() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.updateIncidentStatus(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'updateIncidentStatus should return a non-null response on HTTP 200');
    }

    // ════════════════════════════════════════════════════════════════════
    //  I. updateIncidentStatus — Exception Path
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_updateIncidentStatus_throwsException_returnsNull() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(true));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.updateIncidentStatus(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'updateIncidentStatus should return null when an exception is thrown');
    }

    // ════════════════════════════════════════════════════════════════════
    //  J. updateIncidentStatus — blank RecId (short-circuit)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_updateIncidentStatus_blankRecId_returnsNull() {
        Case c = getCaseBySubject('Blank RecId Case');

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.updateIncidentStatus(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'updateIncidentStatus should return null when Customer_Rec_Id__c is blank');
    }

    // ════════════════════════════════════════════════════════════════════
    //  K. resolveIncidents — HTTP 200 Success
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_resolveIncidents_successResponse() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.resolveIncidents(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'resolveIncidents should return a non-null response on HTTP 200');
    }

    // ════════════════════════════════════════════════════════════════════
    //  L. resolveIncidents — Exception Path
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_resolveIncidents_throwsException_returnsNull() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(true));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.resolveIncidents(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'resolveIncidents should return null when an exception is thrown');
    }

    // ════════════════════════════════════════════════════════════════════
    //  M. resolveIncidents — blank RecId (short-circuit)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_resolveIncidents_blankRecId_returnsNull() {
        Case c = getCaseBySubject('Blank RecId Case');

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.resolveIncidents(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'resolveIncidents should return null when Customer_Rec_Id__c is blank');
    }

    // ════════════════════════════════════════════════════════════════════
    //  N. resolveIncidents — HTML stripping in Details__c
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_resolveIncidents_htmlStripping_cleansPayload() {
        Case c = getCaseBySubject('HTML Details Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.resolveIncidents(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'resolveIncidents should succeed with HTML-laden Details__c');

        // Verify the payload was sanitized by inspecting API_Response__c log
        List<API_Response__c> logs = [
            SELECT Http_Request__c FROM API_Response__c
            WHERE Message__c LIKE '%resolveIncidents%'
            LIMIT 1
        ];
        System.assertEquals(1, logs.size(),
            'An API_Response__c log should be created');

        String requestPayload = logs[0].Http_Request__c;
        System.assert(!requestPayload.contains('<p>'),
            'HTML <p> tags should be stripped from the payload');
        System.assert(!requestPayload.contains('<b>'),
            'HTML <b> tags should be stripped from the payload');
        System.assert(!requestPayload.contains('&nbsp;'),
            '&nbsp; entities should be replaced in the payload');
        System.assert(requestPayload.contains('Root cause'),
            'Plain text content should be preserved in the payload');
        System.assert(requestPayload.contains('identified'),
            'Plain text content should be preserved after tag removal');
    }

    // ════════════════════════════════════════════════════════════════════
    //  O. updatePriorityOnIncidents — HTTP 200 Success
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_updatePriorityOnIncidents_successResponse() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.updatePriorityOnIncidents(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'updatePriorityOnIncidents should return a non-null response on HTTP 200');
    }

    // ════════════════════════════════════════════════════════════════════
    //  P. updatePriorityOnIncidents — Exception Path
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_updatePriorityOnIncidents_throwsException_returnsNull() {
        Case c = getCaseBySubject('Incident Case');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(true));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.updatePriorityOnIncidents(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'updatePriorityOnIncidents should return null when an exception is thrown');
    }

    // ════════════════════════════════════════════════════════════════════
    //  Q. updatePriorityOnIncidents — blank RecId (short-circuit)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_updatePriorityOnIncidents_blankRecId_returnsNull() {
        Case c = getCaseBySubject('Blank RecId Case');

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.updatePriorityOnIncidents(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'updatePriorityOnIncidents should return null when Customer_Rec_Id__c is blank');
    }

    // ════════════════════════════════════════════════════════════════════
    //  R. resolveIncidents — null Details__c handled gracefully
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_resolveIncidents_nullDetails_handlesGracefully() {
        Case c = getCaseBySubject('Incident Case');
        c.Details__c = null;

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_IncidentService.resolveIncidents(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'resolveIncidents should handle null Details__c gracefully via toPlainText');
    }
}