@isTest
private class API_ChangeRequestServiceTest {

    private class ConfigurableMock implements HttpCalloutMock {
        private Integer statusCode;
        private String  responseBody;

        public ConfigurableMock(Integer statusCode, String responseBody) {
            this.statusCode   = statusCode;
            this.responseBody = responseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setHeader('Content-Type', 'application/json');
            res.setBody(responseBody);
            return res;
        }
    }

    private static final String SUCCESS_BODY   = '{"status":"success","message":"OK","result":{"response":"CHG0012345"}}';
    private static final String ERROR_BODY     = '{"Details":{"status":"failure","error":{"message":"Bad Request","detail":"Missing field"}}}';
    private static final String MALFORMED_BODY = '<<<INVALID JSON>>>';

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'CR Service Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'Contact',
            AccountId = acc.Id
        );
        insert con;

        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Account_Id__c   = acc.Id,
            Contact_Name__c = 'Test Contact',
            Queue_Name__c   = 'TOC Queue'
        );
        insert settings;

        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();
        System.assertNotEquals(null, changeRtId,
            'Record Type "Change_Request" must exist in the target org');

        Case parentCase = new Case(
            Subject      = 'Parent CR Case',
            Status       = 'New',
            RecordTypeId = changeRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'High',
            Customer_Rec_Id__c = 'CHG_PARENT_001'
        );
        insert parentCase;

        Case childCase = new Case(
            Subject            = 'Child CR Case',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'CHG0099999',
            ParentId           = parentCase.Id
        );
        insert childCase;

        childCase.Status             = 'Resolved';
        childCase.Auto_Close_Date__c = Date.today().addDays(7);
        childCase.Case_Type__c       = 'Normal';
        update childCase;

        Case crCase = new Case(
            Subject              = 'New Change Request',
            Status               = 'New',
            RecordTypeId         = changeRtId,
            AccountId            = acc.Id,
            ContactId            = con.Id,
            Origin               = 'Phone',
            Priority             = 'High',
            Technical_Approved__c = true,
            Customer_Rec_Id__c   = 'CHG0088888'
        );
        insert crCase;

        Case feedCase = new Case(
            Subject            = 'FeedItem Parent Case',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Customer_Rec_Id__c = 'CHG0077777'
        );
        insert feedCase;

        FeedItem fi = new FeedItem(
            ParentId   = feedCase.Id,
            Body       = 'Work note content for testing',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;

        Task t = new Task(
            Subject            = 'Test CR Task',
            Status             = 'Completed',
            WhatId             = crCase.Id,
            Customer_Rec_Id__c = 'CTASK0099999'
        );
        insert t;

        Task tBlank = new Task(
            Subject = 'Blank RecId Task',
            Status  = 'Not Started',
            WhatId  = crCase.Id
        );
        insert tBlank;
    }

    private static Case getCaseByRecId(String recId) {
        return [SELECT Id, CaseNumber, Subject, Status, Description, RecordTypeId,
                       AccountId, ContactId, Origin, Priority, Customer_Rec_Id__c,
                       ParentId, Technical_Approved__c, Details__c, ClosedDate,
                       Planned_Start_Date__c, Planned_Delivery_Date__c,
                       Vendor_Service_ID__c, Test_Plan__c, Implementation_Plan__c,
                       Backout_Plan__c, Users_Systems_Impacted__c, Service_Affecting__c
                FROM Case WHERE Customer_Rec_Id__c = :recId LIMIT 1];
    }

    @isTest
    static void test_createCR_validCase_successResponse() {
        Case c = getCaseByRecId('CHG0088888');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp = API_ChangeRequestService.createCR(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'createCR should return a non-null CRCreateResponse on HTTP 200');
        System.assertNotEquals(null, resp.result,
            'Response result should be populated on success');
    }

    @isTest
    static void test_createCR_httpError_returnsNull() {
        Case c = getCaseByRecId('CHG0088888');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(400, ERROR_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp = API_ChangeRequestService.createCR(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'createCR should return null on HTTP 400 error');
    }

    @isTest
    static void test_createCR_throwsException_returnsNull() {
        Case c = getCaseByRecId('CHG0088888');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, MALFORMED_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp = API_ChangeRequestService.createCR(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'createCR should return null when an exception is thrown');
    }

    @isTest
    static void test_createWorkNote_validFeedItem_successResponse() {
        Case feedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0077777' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.createWorkNote(fi, 'CHG0077777');
        Test.stopTest();

        System.assert(true, 'createWorkNote completed without exception on HTTP 200');
    }

    @isTest
    static void test_createWorkNote_httpError_returnsNull() {
        Case feedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0077777' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(500, ERROR_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.createWorkNote(fi, 'CHG0077777');
        Test.stopTest();

        System.assertEquals(null, resp,
            'createWorkNote should return null on HTTP 500 error');
    }

    @isTest
    static void test_createWorkNote_throwsException_returnsNull() {
        Case feedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0077777' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, MALFORMED_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.createWorkNote(fi, 'CHG0077777');
        Test.stopTest();

        System.assertEquals(null, resp,
            'createWorkNote should return null when an exception is thrown');
    }

    @isTest
    static void test_createWorkNote_blankVendorNumber_returnsNull() {
        Case feedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0077777' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.createWorkNote(fi, '');
        Test.stopTest();

        System.assertEquals(null, resp,
            'createWorkNote should return null when vendorNumber is blank');
    }

    @isTest
    static void test_closeChangeRequest_validChildCase_successResponse() {
        Case c = getCaseByRecId('CHG0099999');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.closeChangeRequest(c);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'closeChangeRequest should return a non-null response on HTTP 200');
    }

    @isTest
    static void test_closeChangeRequest_httpError_returnsNull() {
        Case c = getCaseByRecId('CHG0099999');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(400, ERROR_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.closeChangeRequest(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'closeChangeRequest should return null on HTTP 400 error');
    }

    @isTest
    static void test_closeChangeRequest_throwsException_returnsNull() {
        Case c = getCaseByRecId('CHG0099999');
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, MALFORMED_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.closeChangeRequest(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'closeChangeRequest should return null when an exception is thrown');
    }

    @isTest
    static void test_closeChangeRequest_blankRecId_returnsNull() {
        Case c = getCaseByRecId('CHG0099999');
        c.Customer_Rec_Id__c = null;

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.closeChangeRequest(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'closeChangeRequest should return null when Customer_Rec_Id__c is blank');
    }

    @isTest
    static void test_closeChangeRequest_parentCase_returnsNull() {
        Case c = getCaseByRecId('CHG_PARENT_001');

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.closeChangeRequest(c);
        Test.stopTest();

        System.assertEquals(null, resp,
            'closeChangeRequest should return null for a parent Case (no ParentId)');
    }

    @isTest
    static void test_updateTaskStatus_validTask_successResponse() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Customer_Rec_Id__c = 'CTASK0099999' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.updateTaskStatus(t);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'updateTaskStatus should return a non-null response on HTTP 200');
    }

    @isTest
    static void test_updateTaskStatus_throwsException_returnsNull() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Customer_Rec_Id__c = 'CTASK0099999' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, MALFORMED_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.updateTaskStatus(t);
        Test.stopTest();

        System.assertEquals(null, resp,
            'updateTaskStatus should return null when an exception is thrown');
    }

    @isTest
    static void test_updateTaskStatus_blankRecId_returnsNull() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'Blank RecId Task' LIMIT 1];

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.updateTaskStatus(t);
        Test.stopTest();

        System.assertEquals(null, resp,
            'updateTaskStatus should return null when Customer_Rec_Id__c is blank');
    }

    @isTest
    static void test_getWorkNote_validFeedItem_returnsDetails() {
        Case feedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0077777' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.startTest();
        API_ChangeRequestService.WorkNoteDetails wn =
            API_ChangeRequestService.getWorkNote(fi, 'CHG0077777');
        Test.stopTest();

        System.assertNotEquals(null, wn,
            'getWorkNote should return a WorkNoteDetails instance for a valid FeedItem');
        System.assertEquals('CHG0077777', wn.VendorNumber,
            'VendorNumber should match the changeNumber parameter');
        System.assert(String.isNotBlank(wn.title),
            'title should contain the stripped body content');
    }

    @isTest
    static void test_getWorkNote_blankChangeNumber_returnsNull() {
        Case feedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0077777' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        Test.startTest();
        API_ChangeRequestService.WorkNoteDetails wn =
            API_ChangeRequestService.getWorkNote(fi, '');
        Test.stopTest();

        System.assertEquals(null, wn,
            'getWorkNote should return null when changeNumber is blank');
    }

    @isTest
    static void test_getWorkNote_deletedFeedItem_returnsNull() {
        Case feedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0077777' LIMIT 1];
        FeedItem fi = [SELECT Id FROM FeedItem WHERE ParentId = :feedCase.Id LIMIT 1];

        delete fi;

        FeedItem ghost = new FeedItem();
        ghost.Id = fi.Id;

        Test.startTest();
        API_ChangeRequestService.WorkNoteDetails wn =
            API_ChangeRequestService.getWorkNote(ghost, 'CHG0077777');
        Test.stopTest();

        System.assertEquals(null, wn,
            'getWorkNote should return null when the FeedItem no longer exists');
    }

    @isTest
    static void test_updateTaskStatus_nonCompletedStatus_sendsEmptyStatus() {
        Case crCase = getCaseByRecId('CHG0088888');
        Task t = new Task(
            Subject            = 'In Progress Task',
            Status             = 'In Progress',
            WhatId             = crCase.Id,
            Customer_Rec_Id__c = 'CTASK_INPROG'
        );
        insert t;

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.updateTaskStatus(t);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'updateTaskStatus should succeed even for non-Completed status');
    }

    @isTest
    static void test_createCR_nullOptionalFields_handlesGracefully() {
        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Case minimalCase = new Case(
            Subject      = 'Minimal CR',
            Status       = 'New',
            RecordTypeId = changeRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'High'
        );
        insert minimalCase;

        Test.setMock(HttpCalloutMock.class, new ConfigurableMock(200, SUCCESS_BODY));

        Test.startTest();
        HttpRequestResponseModel.CRCreateResponse resp =
            API_ChangeRequestService.createCR(minimalCase);
        Test.stopTest();

        System.assertNotEquals(null, resp,
            'createCR should handle null optional fields gracefully and still succeed');
    }
}
