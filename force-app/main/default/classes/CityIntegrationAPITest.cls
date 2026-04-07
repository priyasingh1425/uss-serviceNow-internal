@isTest
private class CityIntegrationAPITest {

    private static final String CONTACT_NAME = 'City Of Minneapolis Service Desk';
    private static final String QUEUE_NAME   = 'TOC Queue';

    @testSetup
    static void setupTestData() {

        Account acc = new Account(Name = 'MPL Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'City Of Minneapolis',
            LastName  = 'Service Desk',
            AccountId = acc.Id
        );
        insert con;

        MPL_Integration_Settings__c settings = MPL_Integration_Settings__c.getInstance();
        if (settings == null || settings.Id == null) {
            settings = new MPL_Integration_Settings__c();
        }
        settings.Account_Id__c    = acc.Id;
        settings.Contact_Name__c  = CONTACT_NAME;
        settings.Queue_Name__c    = QUEUE_NAME;
        upsert settings;

        Id extCustRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                             .get('External_Customer_Support').getRecordTypeId();

        Case reopenCase = new Case(
            Subject            = 'Reopen Test Case',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'API',
            Customer_Rec_Id__c = 'INC_REOPEN_001'
        );

        Case resolvedCase = new Case(
            Subject            = 'Resolved Test Case',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'API',
            Customer_Rec_Id__c = 'INC_RESOLVED_001'
        );

        Case closedCase = new Case(
            Subject            = 'Closed Test Case',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'API',
            Customer_Rec_Id__c = 'INC_CLOSED_001'
        );

        Case newStatusCase = new Case(
            Subject            = 'New Status Test Case',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'API',
            Customer_Rec_Id__c = 'INC_NEW_001'
        );

        Case workNoteCase = new Case(
            Subject            = 'WorkNote Parent Case',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'API',
            Customer_Rec_Id__c = 'INC_WORKNOTE_001'
        );

        insert new List<Case>{ reopenCase, resolvedCase, closedCase, newStatusCase, workNoteCase };

        reopenCase.Status              = 'Reopen';
        resolvedCase.Status            = 'Resolved';
        resolvedCase.Auto_Close_Date__c = Date.today().addDays(7);
        closedCase.Status              = 'Closed';
        update new List<Case>{ reopenCase, resolvedCase, closedCase };

        Case ctaskChild = new Case(
            Subject            = 'CTASK Child',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            ParentId           = workNoteCase.Id,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'API',
            Customer_Rec_Id__c = 'CTASK0012345'
        );
        insert ctaskChild;

        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();

        Case changeCase = new Case(
            Subject            = 'Change Request For Approval',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Customer_Rec_Id__c = 'CHG_APPROVAL_001'
        );
        insert changeCase;

        Approval_Participants__c ap = new Approval_Participants__c(
            Case__c          = changeCase.Id,
            Approval_Type__c = 'Customer Approval',
            Status__c        = 'Not Started'
        );
        insert ap;
    }

    private static void setupRestContext(String action, String jsonBody) {
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI   = '/services/apexrest/mpl/int';
        req.httpMethod   = 'POST';
        req.addHeader('Content-Type', 'application/json');
        if (action != null) {
            req.params.put('apiAction', action);
        }
        req.requestBody = Blob.valueOf(jsonBody != null ? jsonBody : '{}');

        RestContext.request  = req;
        RestContext.response = res;
    }

    private static void setupPatchRestContext(String action, String jsonBody) {
        RestRequest req  = new RestRequest();
        RestResponse res = new RestResponse();
        req.requestURI   = '/services/apexrest/mpl/int';
        req.httpMethod   = 'PATCH';
        req.addHeader('Content-Type', 'application/json');
        if (action != null) {
            req.params.put('apiAction', action);
        }
        req.requestBody = Blob.valueOf(jsonBody != null ? jsonBody : '{}');

        RestContext.request  = req;
        RestContext.response = res;
    }

    @isTest
    static void testCreateIncident_Success() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Server is down in DC-1',
            'ShortDescription' => 'DC-1 Outage',
            'Priority'         => '2',
            'APITicketID'      => 'INC_NEW_TEST_001',
            'Category'         => 'break fix',
            'Subcategory'      => 'Hardware'
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status, 'Expected success status');
        System.assert(result.message.contains('Case successfully created'), 'Message should confirm creation');
        System.assertNotEquals(null, result.IncidentRecID, 'IncidentRecID should be populated');
        System.assertNotEquals(null, result.IncidentID, 'IncidentID (CaseNumber) should be populated');

        Case createdCase = [SELECT Id, Case_Type__c, Priority, Origin, Status, Customer_Rec_Id__c
                            FROM Case WHERE Customer_Rec_Id__c = 'INC_NEW_TEST_001' LIMIT 1];
        System.assertEquals('Break/Fix', createdCase.Case_Type__c, 'Category "break fix" should map to Break/Fix');
        System.assertEquals('High', createdCase.Priority, 'Priority 2 should map to High');
        System.assertEquals('API', createdCase.Origin);
        System.assertEquals('New', createdCase.Status);

        List<API_Response__c> logs = [SELECT Id FROM API_Response__c WHERE Message__c = 'CityIntegrationAPI createIncident'];
        System.assert(!logs.isEmpty(), 'API Response log should exist');
    }

    @isTest
    static void testCreateIncident_ServiceRequestCategory() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Need new VPN access',
            'ShortDescription' => 'VPN Request',
            'Priority'         => '3',
            'APITicketID'      => 'INC_SR_001',
            'Category'         => 'service request',
            'Subcategory'      => 'Access'
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        Case c = [SELECT Case_Type__c, Priority FROM Case WHERE Customer_Rec_Id__c = 'INC_SR_001' LIMIT 1];
        System.assertEquals('Request', c.Case_Type__c, 'Category "service request" should map to Request');
        System.assertEquals('Medium', c.Priority, 'Priority 3 should map to Medium');
    }

    @isTest
    static void testCreateIncident_DefaultCategory() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'General inquiry',
            'ShortDescription' => 'General',
            'Priority'         => '4',
            'APITicketID'      => 'INC_DEF_001',
            'Category'         => 'monitoring',
            'Subcategory'      => ''
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        Case c = [SELECT Case_Type__c, Priority FROM Case WHERE Customer_Rec_Id__c = 'INC_DEF_001' LIMIT 1];
        System.assertEquals('Standard', c.Case_Type__c, 'Unmapped category should default to Standard');
        System.assertEquals('Low', c.Priority, 'Priority 4 should map to Low');
    }

    @isTest
    static void testCreateIncident_AlreadyExists() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Duplicate attempt',
            'ShortDescription' => 'Dup',
            'Priority'         => '1',
            'APITicketID'      => 'INC_REOPEN_001',
            'Category'         => null,
            'Subcategory'      => null
        });

        Integer caseCountBefore = [SELECT COUNT() FROM Case];

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('Case already exists'), 'Should indicate duplicate');

        Integer caseCountAfter = [SELECT COUNT() FROM Case];
        System.assertEquals(caseCountBefore, caseCountAfter, 'No new Case should be created');
    }

    @isTest
    static void testCreateWorkNote_Success() {
        Case parentCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_WORKNOTE_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'ParentRecID' => parentCase.Id,
            'Details'     => 'Technician dispatched to site.'
        });

        Test.startTest();
        setupRestContext('createWorkNote', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('Notes created successfully'), 'Should confirm note creation');

        List<FeedItem> feeds = [SELECT Id, Body FROM FeedItem WHERE ParentId = :parentCase.Id];
        System.assert(!feeds.isEmpty(), 'FeedItem should be created');
        System.assertEquals('Technician dispatched to site.', feeds[0].Body);
    }

    @isTest
    static void testCreateWorkNote_CTASK_Success() {
        Case parentCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_WORKNOTE_001' LIMIT 1];
        Case ctaskCase  = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CTASK0012345' LIMIT 1];

        String noteContent = 'Work Notes from CTASK0012345: This is a CTASK work note';
        String payload = JSON.serialize(new Map<String, Object>{
            'ParentRecID' => parentCase.Id,
            'Details'     => noteContent
        });

        Test.startTest();
        setupRestContext('createWorkNote', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status, 'CTASK work note should succeed');

        List<FeedItem> ctaskFeeds = [SELECT Id, Body FROM FeedItem WHERE ParentId = :ctaskCase.Id];
        System.assert(!ctaskFeeds.isEmpty(), 'FeedItem should be created on the CTASK child case');
        System.assert(ctaskFeeds[0].Body.contains('This is a CTASK work note'), 'Body should contain the parsed note details');
    }

    @isTest
    static void testResolveIncident_Success() {
        Case reopenCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_REOPEN_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID'    => reopenCase.Id,
            'CloseDescription' => 'Root cause identified and fixed.'
        });

        Test.startTest();
        setupRestContext('resolveIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status, 'Should fail because Auto_Close_Date__c is required to resolve');
    }

    @isTest
    static void testReopenIncident_FromResolved() {
        Case resolvedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_RESOLVED_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID' => resolvedCase.Id
        });

        Test.startTest();
        setupRestContext('reopenIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('Case reopened successfully'), 'Should confirm reopen');

        Case updated = [SELECT Status FROM Case WHERE Id = :resolvedCase.Id];
        System.assertEquals('Reopen', updated.Status);
    }

    @isTest
    static void testReopenIncident_FromClosed() {
        Case closedCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_CLOSED_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID' => closedCase.Id
        });

        Test.startTest();
        setupRestContext('reopenIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        Case updated = [SELECT Status FROM Case WHERE Id = :closedCase.Id];
        System.assertEquals('Reopen', updated.Status);
    }

    @isTest
    static void testCreateChangeRequest_New_Success() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'        => 'Scheduled router upgrade',
            'ShortDescription'   => 'Router Upgrade CHG',
            'ScheduledStartDate' => String.valueOf(DateTime.now()),
            'ScheduledEndDate'   => String.valueOf(DateTime.now().addHours(4)),
            'Priority'           => '2',
            'APIChangeID'        => 'CHG_NEW_001',
            'tasks' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Title'              => 'Pre-check connectivity',
                    'Description'        => 'Verify all links',
                    'Priority'           => '3',
                    'APITicketID'        => 'CTASK_A',
                    'ScheduledStartDate' => String.valueOf(DateTime.now()),
                    'ScheduledEndDate'   => String.valueOf(DateTime.now().addHours(1))
                },
                new Map<String, Object>{
                    'Title'              => 'Perform upgrade',
                    'Description'        => 'Flash firmware',
                    'Priority'           => '2',
                    'APITicketID'        => 'CTASK_B',
                    'ScheduledStartDate' => String.valueOf(DateTime.now().addHours(1)),
                    'ScheduledEndDate'   => String.valueOf(DateTime.now().addHours(3))
                },
                new Map<String, Object>{
                    'Title'              => 'Post-check validation',
                    'Description'        => 'Verify services',
                    'Priority'           => '1',
                    'APITicketID'        => 'CTASK_C',
                    'ScheduledStartDate' => null,
                    'ScheduledEndDate'   => null
                }
            }
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status, 'Change request creation should succeed');
        System.assert(result.message.contains('Change request created successfully'), 'Message should confirm creation');
        System.assertNotEquals(null, result.ChangeRecID, 'ChangeRecID should be populated');

        Case parentCase = [SELECT Id, Customer_Rec_Id__c, Origin FROM Case WHERE Customer_Rec_Id__c = 'CHG_NEW_001' LIMIT 1];
        System.assertEquals('API', parentCase.Origin);

        List<Case> childTasks = [SELECT Id, Customer_Rec_Id__c FROM Case WHERE ParentId = :parentCase.Id];
        System.assertEquals(3, childTasks.size(), 'Should have created 3 change tasks');
    }

    @isTest
    static void testCreateChangeRequest_Existing_SkipDuplicateTasks() {
        String payload1 = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Initial change',
            'ShortDescription' => 'CHG Existing',
            'Priority'         => '3',
            'APIChangeID'      => 'CHG_EXIST_001',
            'tasks' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Title'       => 'Task Alpha',
                    'Description' => 'Alpha work',
                    'APITicketID' => 'CTASK_ALPHA'
                }
            }
        });

        setupRestContext('createChangeRequest', payload1);
        CityIntegrationAPI.handlePost();

        String payload2 = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Updated change',
            'ShortDescription' => 'CHG Existing',
            'Priority'         => '3',
            'APIChangeID'      => 'CHG_EXIST_001',
            'tasks' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Title'       => 'Task Alpha',
                    'Description' => 'Alpha work',
                    'APITicketID' => 'CTASK_ALPHA'
                },
                new Map<String, Object>{
                    'Title'       => 'Task Beta',
                    'Description' => 'Beta work',
                    'APITicketID' => 'CTASK_BETA'
                }
            }
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload2);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('Change request exists'), 'Should indicate existing case');
        System.assert(result.message.contains('skipped'), 'Should mention skipped duplicate task(s)');

        Case parentCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG_EXIST_001' LIMIT 1];
        List<Case> childTasks = [SELECT Id, Customer_Rec_Id__c FROM Case WHERE ParentId = :parentCase.Id];
        System.assertEquals(2, childTasks.size(), 'Should have exactly 2 tasks (Alpha + Beta, no duplicate Alpha)');
    }

    @isTest
    static void testUpdateChangeRequestApproval_Success() {
        Case changeCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG_APPROVAL_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'SalesforceID'     => changeCase.Id,
            'State'            => 'pending deployment',
            'Description'      => 'Approval update',
            'ShortDescription' => 'Approval',
            'APIChangeID'      => ''
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('Approved'), 'Message should confirm approval update');

        Approval_Participants__c ap = [SELECT Status__c FROM Approval_Participants__c
                                       WHERE Case__c = :changeCase.Id LIMIT 1];
        System.assertEquals('Approved', ap.Status__c, 'Participant status should be Approved');
    }

    @isTest
    static void testUpdateChangeRequestApproval_AlreadyApproved() {
        Case changeCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG_APPROVAL_001' LIMIT 1];

        Approval_Participants__c ap = [SELECT Id, Status__c FROM Approval_Participants__c
                                       WHERE Case__c = :changeCase.Id LIMIT 1];
        ap.Status__c = 'Approved';
        update ap;

        String payload = JSON.serialize(new Map<String, Object>{
            'SalesforceID'     => changeCase.Id,
            'State'            => 'pending deployment',
            'Description'      => 'Already approved',
            'ShortDescription' => 'Already',
            'APIChangeID'      => ''
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('already in Approved status'),
                       'Should indicate participant was already approved');
    }

    @isTest
    static void testHandlePost_MissingAction() {
        setupRestContext(null, '{}');

        Test.startTest();
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Missing action parameter'));
    }

    @isTest
    static void testHandlePost_UnsupportedAction() {
        setupRestContext('deleteIncident', '{}');

        Test.startTest();
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Unsupported POST action'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testHandlePatch_MissingAction() {
        setupPatchRestContext(null, '{}');

        Test.startTest();
        MPLResponse result = CityIntegrationAPI.handlePatch();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Missing action parameter'));
    }

    @isTest
    static void testHandlePatch_UnsupportedAction() {
        setupPatchRestContext('updateSomething', '{}');

        Test.startTest();
        MPLResponse result = CityIntegrationAPI.handlePatch();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Unsupported PATCH action'));
    }

    @isTest
    static void testCreateWorkNote_BlankParent() {
        String payload = JSON.serialize(new Map<String, Object>{
            'ParentRecID' => '',
            'Details'     => 'Some note'
        });

        Test.startTest();
        setupRestContext('createWorkNote', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Parent Id is required'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testCreateWorkNote_InvalidIdFormat() {
        String payload = JSON.serialize(new Map<String, Object>{
            'ParentRecID' => 'INVALID_ID_XYZ',
            'Details'     => 'Some note'
        });

        Test.startTest();
        setupRestContext('createWorkNote', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Invalid Salesforce ID format'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testCreateWorkNote_NonExistentParent() {
        String fakeId = Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        String payload = JSON.serialize(new Map<String, Object>{
            'ParentRecID' => fakeId,
            'Details'     => 'Some note'
        });

        Test.startTest();
        setupRestContext('createWorkNote', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Parent Id does not exist'));
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testCreateWorkNote_CTASK_NotFound() {
        Case parentCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_WORKNOTE_001' LIMIT 1];
        String noteContent = 'Work Notes from CTASK9999999: Details here';
        String payload = JSON.serialize(new Map<String, Object>{
            'ParentRecID' => parentCase.Id,
            'Details'     => noteContent
        });

        Test.startTest();
        setupRestContext('createWorkNote', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Change task not found'), 'Should report CTASK not found');
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testResolveIncident_BlankId() {
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID'    => '',
            'CloseDescription' => 'Closing'
        });

        Test.startTest();
        setupRestContext('resolveIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Parent Id is required'));
    }

    @isTest
    static void testResolveIncident_InvalidIdFormat() {
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID'    => 'NOT_A_REAL_ID',
            'CloseDescription' => 'Closing'
        });

        Test.startTest();
        setupRestContext('resolveIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Invalid Salesforce ID format'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testResolveIncident_CaseNotFound() {
        String fakeId = Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID'    => fakeId,
            'CloseDescription' => 'Closing'
        });

        Test.startTest();
        setupRestContext('resolveIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Parent Id does not exist'));
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testResolveIncident_InvalidStatus() {
        Case newCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_NEW_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID'    => newCase.Id,
            'CloseDescription' => 'Attempt to resolve'
        });

        Test.startTest();
        setupRestContext('resolveIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Unable to resolve'), 'Should report invalid status for resolution');
        System.assert(result.message.contains('Reopen'), 'Should mention required Reopen status');
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testReopenIncident_BlankId() {
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID' => ''
        });

        Test.startTest();
        setupRestContext('reopenIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Parent Id is required'));
    }

    @isTest
    static void testReopenIncident_InvalidIdFormat() {
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID' => 'BAD_FORMAT'
        });

        Test.startTest();
        setupRestContext('reopenIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Invalid Salesforce ID format'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testReopenIncident_CaseNotFound() {
        String fakeId = Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID' => fakeId
        });

        Test.startTest();
        setupRestContext('reopenIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Parent Id does not exist'));
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testReopenIncident_InvalidStatus() {
        Case newCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_NEW_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'IncidentRecID' => newCase.Id
        });

        Test.startTest();
        setupRestContext('reopenIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('not in a Resolved or Closed Status'),
                       'Should report invalid status for reopen');
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testUpdateChangeRequestApproval_NonPendingStatus() {
        Case changeCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG_APPROVAL_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'SalesforceID'     => changeCase.Id,
            'State'            => 'scheduled',
            'Description'      => 'Non-pending',
            'ShortDescription' => 'Non-pending',
            'APIChangeID'      => ''
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('Change request created successfully'),
                       'Non-pending state should fall through to create path');
    }

    @isTest
    static void testUpdateChangeRequestApproval_InvalidId() {
        String payload = JSON.serialize(new Map<String, Object>{
            'SalesforceID'     => 'GARBAGE',
            'State'            => 'pending deployment',
            'Description'      => 'Bad Id',
            'ShortDescription' => 'Bad',
            'APIChangeID'      => ''
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Invalid Salesforce ID format'));
        System.assertEquals(400, RestContext.response.statusCode);
    }

    @isTest
    static void testUpdateChangeRequestApproval_BlankIdAndStatus() {
        String payload = JSON.serialize(new Map<String, Object>{
            'SalesforceID'     => '',
            'State'            => 'pending deployment',
            'Description'      => 'Blank',
            'ShortDescription' => 'Blank',
            'APIChangeID'      => ''
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status,
                       'Blank SalesforceID falls through to create path');
    }

    @isTest
    static void testUpdateChangeRequestApproval_ChangeNotFound() {
        String fakeId = Case.SObjectType.getDescribe().getKeyPrefix() + '000000000000';
        String payload = JSON.serialize(new Map<String, Object>{
            'SalesforceID'     => fakeId,
            'State'            => 'pending deployment',
            'Description'      => 'Not found',
            'ShortDescription' => 'Not found',
            'APIChangeID'      => ''
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Change request not found'));
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testUpdateChangeRequestApproval_NoParticipants() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();

        Case noApprovalCase = new Case(
            Subject      = 'No Approval Participants',
            Status       = 'New',
            RecordTypeId = changeRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone'
        );
        insert noApprovalCase;

        String payload = JSON.serialize(new Map<String, Object>{
            'SalesforceID'     => noApprovalCase.Id,
            'State'            => 'pending deployment',
            'Description'      => 'No participants',
            'ShortDescription' => 'No participants',
            'APIChangeID'      => ''
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('No Customer Approval participant found'));
        System.assertEquals(404, RestContext.response.statusCode);
    }

    @isTest
    static void testCreateIncident_NullCategory() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'No category provided',
            'ShortDescription' => 'Null Cat',
            'Priority'         => '1',
            'APITicketID'      => 'INC_NULL_CAT',
            'Category'         => null,
            'Subcategory'      => null
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        Case c = [SELECT Case_Type__c FROM Case WHERE Customer_Rec_Id__c = 'INC_NULL_CAT' LIMIT 1];
        System.assertEquals('Standard', c.Case_Type__c, 'Null category should default to Standard');
    }

    @isTest
    static void testCreateIncident_BreakfixVariant() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Breakfix variant test',
            'ShortDescription' => 'Breakfix',
            'Priority'         => '2',
            'APITicketID'      => 'INC_BRKFIX',
            'Category'         => 'breakfix',
            'Subcategory'      => ''
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        Case c = [SELECT Case_Type__c FROM Case WHERE Customer_Rec_Id__c = 'INC_BRKFIX' LIMIT 1];
        System.assertEquals('Break/Fix', c.Case_Type__c, '"breakfix" should also map to Break/Fix');
    }

    @isTest
    static void testCreateChangeRequest_NoTasks() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Change with no tasks',
            'ShortDescription' => 'No Tasks CHG',
            'Priority'         => '4',
            'APIChangeID'      => 'CHG_NOTASK_001'
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        System.assert(result.message.contains('Change request created successfully'));

        Case parentCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG_NOTASK_001' LIMIT 1];
        List<Case> childTasks = [SELECT Id FROM Case WHERE ParentId = :parentCase.Id];
        System.assertEquals(0, childTasks.size(), 'No child tasks should be created');
    }

    @isTest
    static void testCreateChangeRequest_TasksWithNullTicketIds() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Tasks missing IDs',
            'ShortDescription' => 'Null Ticket IDs',
            'Priority'         => '3',
            'APIChangeID'      => 'CHG_NULLTASK_001',
            'tasks' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Title'       => 'Anonymous Task',
                    'Description' => 'No ticket ID'
                }
            }
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
        Case parentCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG_NULLTASK_001' LIMIT 1];
        List<Case> childTasks = [SELECT Id FROM Case WHERE ParentId = :parentCase.Id];
        System.assertEquals(1, childTasks.size(), 'Task with null APITicketID should still be created');
    }

    @isTest
    static void testCreateWorkNote_NullNoteContent() {
        Case parentCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC_WORKNOTE_001' LIMIT 1];
        String payload = JSON.serialize(new Map<String, Object>{
            'ParentRecID' => parentCase.Id,
            'Details'     => null
        });

        Test.startTest();
        setupRestContext('createWorkNote', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
    }

    @isTest
    static void testCreateIncident_MissingAccountConfig() {
        MPL_Integration_Settings__c settings = [SELECT Id, Account_Id__c FROM MPL_Integration_Settings__c LIMIT 1];
        settings.Account_Id__c = null;
        update settings;

        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'No account configured',
            'ShortDescription' => 'No Account',
            'Priority'         => '2',
            'APITicketID'      => 'INC_NOACCT',
            'Category'         => 'break fix'
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Required account not configured'));
        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testCreateIncident_MissingContact() {
        MPL_Integration_Settings__c settings = [SELECT Id, Contact_Name__c FROM MPL_Integration_Settings__c LIMIT 1];
        settings.Contact_Name__c = 'NonExistent Contact Name XYZ';
        update settings;

        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'No contact found',
            'ShortDescription' => 'No Contact',
            'Priority'         => '2',
            'APITicketID'      => 'INC_NOCON',
            'Category'         => 'break fix'
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('Required contact not found'));
        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testCreateChangeRequest_MissingQueue() {
        MPL_Integration_Settings__c settings = [SELECT Id, Queue_Name__c FROM MPL_Integration_Settings__c LIMIT 1];
        settings.Queue_Name__c = 'Non_Existent_Queue_XYZ_12345';
        update settings;

        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Queue missing test',
            'ShortDescription' => 'No Queue',
            'Priority'         => '3',
            'APIChangeID'      => 'CHG_NOQUEUE_001'
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('error', result.status);
        System.assert(result.message.contains('TOC Queue not found'));
        System.assertEquals(500, RestContext.response.statusCode);
    }

    @isTest
    static void testCreateIncident_BlankAPITicketID() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'No ticket ID at all',
            'ShortDescription' => 'Blank Ticket',
            'Priority'         => '3',
            'APITicketID'      => '',
            'Category'         => ''
        });

        Test.startTest();
        setupRestContext('createIncident', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status, 'Should create case even with blank APITicketID');
    }

    @isTest
    static void testCreateChangeRequest_NullPriorityAndDates() {
        String payload = JSON.serialize(new Map<String, Object>{
            'Description'      => 'Null priority change',
            'ShortDescription' => 'Null priority',
            'Priority'         => null,
            'APIChangeID'      => 'CHG_NULLPRI_001',
            'ScheduledStartDate' => null,
            'ScheduledEndDate'   => null,
            'tasks' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'Title'              => 'Null priority task',
                    'Description'        => 'Task with no priority',
                    'APITicketID'        => 'CTASK_NULLPRI',
                    'Priority'           => null,
                    'ScheduledStartDate' => null,
                    'ScheduledEndDate'   => null
                }
            }
        });

        Test.startTest();
        setupRestContext('createChangeRequest', payload);
        MPLResponse result = CityIntegrationAPI.handlePost();
        Test.stopTest();

        System.assertEquals('success', result.status);
    }
}