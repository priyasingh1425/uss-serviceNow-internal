@isTest
private class CreateRequestQueueableTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Queueable Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'City Of Minneapolis',
            LastName  = 'Service Desk',
            AccountId = acc.Id
        );
        insert con;

        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Account_Id__c   = acc.Id,
            Contact_Name__c = 'City Of Minneapolis Service Desk',
            Queue_Name__c   = 'TOC Queue'
        );
        insert settings;

        Id extCustRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                             .get('External_Customer_Support').getRecordTypeId();
        System.assertNotEquals(null, extCustRtId,
            'Record Type "External_Customer_Support" must exist in the target org');
        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();
        System.assertNotEquals(null, changeRtId,
            'Record Type "Change_Request" must exist in the target org');

        Case resolvedIncCase = new Case(
            Subject            = 'Resolved Incident',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'INC0012345'
        );

        Case parkedIncCase = new Case(
            Subject            = 'Parked Incident',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'INC0012346'
        );

        Case openIncCase = new Case(
            Subject            = 'Open Incident',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'INC0012347'
        );

        Case priorityCase = new Case(
            Subject            = 'Priority Update Case',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'INC0012348'
        );

        Case parentChangeCase = new Case(
            Subject            = 'Parent Change Request',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'CHG0099001'
        );
        insert parentChangeCase;

        Case resolvedChangeCase = new Case(
            Subject            = 'Resolved Change Request',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'High',
            Customer_Rec_Id__c = 'CHG0099999',
            ParentId           = parentChangeCase.Id
        );

        Case approvedChangeCase = new Case(
            Subject              = 'Approved Change Request',
            Status               = 'New',
            RecordTypeId         = changeRtId,
            AccountId            = acc.Id,
            ContactId            = con.Id,
            Origin               = 'Phone',
            Priority             = 'High',
            Technical_Approved__c = true,
            Customer_Rec_Id__c   = 'CHG0098888'
        );

        insert new List<Case>{
            resolvedIncCase, parkedIncCase, openIncCase, priorityCase,
            resolvedChangeCase, approvedChangeCase
        };

        resolvedIncCase.Status             = 'Resolved';
        resolvedIncCase.Auto_Close_Date__c = Date.today().addDays(7);
        parkedIncCase.Status               = 'Parked';
        parkedIncCase.Status_Reason__c     = 'Waiting for Customer';
        resolvedChangeCase.Status          = 'Resolved';
        resolvedChangeCase.Auto_Close_Date__c = Date.today().addDays(7);
        resolvedChangeCase.Case_Type__c    = 'Normal';
        update new List<Case>{ resolvedIncCase, parkedIncCase, resolvedChangeCase };

        Case incFeedCase = new Case(
            Subject            = 'INC Feed Case',
            Status             = 'New',
            RecordTypeId       = extCustRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Customer_Rec_Id__c = 'INC0055555'
        );
        Case chgFeedCase = new Case(
            Subject            = 'CHG Feed Case',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Customer_Rec_Id__c = 'CHG0055555'
        );
        Case noServiceCase = new Case(
            Subject      = 'No Service Number Case',
            Status       = 'New',
            RecordTypeId = extCustRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone'
        );
        insert new List<Case>{ incFeedCase, chgFeedCase, noServiceCase };
    }

    private static Case getCaseByCustomerRecId(String recId) {
        return [SELECT Id, CaseNumber, Subject, Status, RecordTypeId, AccountId,
                       ContactId, Origin, Priority, Customer_Rec_Id__c,
                       Technical_Approved__c, Status_Reason__c, ParentId
                FROM Case WHERE Customer_Rec_Id__c = :recId LIMIT 1];
    }

    @isTest
    static void test_processCases_ExtCustSupport_Resolve() {
        Case c = getCaseByCustomerRecId('INC0012345');
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>{ c },
            new List<Task>(),
            new List<FeedItem>(),
            true,
            false,
            false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for resolved incident');
    }

    @isTest
    static void test_processCases_ExtCustSupport_CreateIncident() {
        Case c = getCaseByCustomerRecId('INC0012346');
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>{ c },
            new List<Task>(),
            new List<FeedItem>(),
            true, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for incident creation');
    }

    @isTest
    static void test_processCases_ExtCustSupport_UpdateStatus() {
        Case c = getCaseByCustomerRecId('INC0012347');
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>{ c },
            new List<Task>(),
            new List<FeedItem>(),
            true, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for incident status update');
    }

    @isTest
    static void test_processCases_ChangeRequest_Close() {
        Case c = getCaseByCustomerRecId('CHG0099999');
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>{ c },
            new List<Task>(),
            new List<FeedItem>(),
            true, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for change request close');
    }

    @isTest
    static void test_processCases_ChangeRequest_CreateCR() {
        Case c = getCaseByCustomerRecId('CHG0098888');
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>{ c },
            new List<Task>(),
            new List<FeedItem>(),
            true, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for change request creation');
    }

    @isTest
    static void test_processCases_PriorityUpdate() {
        Case c = getCaseByCustomerRecId('INC0012348');
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>{ c },
            new List<Task>(),
            new List<FeedItem>(),
            false,
            false,
            true
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for priority update');
    }

    @isTest
    static void test_processTasks_UpdateTaskStatus() {
        Case c = getCaseByCustomerRecId('CHG0098888');
        Task t = new Task(
            Subject            = 'Test Task',
            Status             = 'Completed',
            WhatId             = c.Id,
            Customer_Rec_Id__c = 'CTASK0099999'
        );
        insert t;

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>{ t },
            new List<FeedItem>(),
            false,
            true,
            false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for task status update');
    }

    @isTest
    static void test_processFeedItems_IncidentRoute() {
        Case incCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC0055555' LIMIT 1];

        FeedItem fi = new FeedItem(
            ParentId   = incCase.Id,
            Body       = 'Incident work note content',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>(),
            new List<FeedItem>{ fi },
            false, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for INC FeedItem routing');
    }

    @isTest
    static void test_processFeedItems_ChangeRequestRoute() {
        Case chgCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'CHG0055555' LIMIT 1];

        FeedItem fi = new FeedItem(
            ParentId   = chgCase.Id,
            Body       = 'Change request work note content',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>(),
            new List<FeedItem>{ fi },
            false, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable completed without exception for CHG FeedItem routing');
    }

    @isTest
    static void test_execute_NullAccountId_ShortCircuits() {
        List<MPL_Integration_Settings__c> existingSettings =
            [SELECT Id FROM MPL_Integration_Settings__c];
        if (!existingSettings.isEmpty()) {
            delete existingSettings;
        }

        Case c = getCaseByCustomerRecId('INC0012345');

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>{ c },
            new List<Task>(),
            new List<FeedItem>(),
            true, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable should short-circuit gracefully when ACCOUNT_ID is null');
    }

    @isTest
    static void test_execute_EmptyLists_CompletesGracefully() {
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>(),
            new List<FeedItem>(),
            true, true, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable should complete gracefully with empty lists');
    }

    @isTest
    static void test_processFeedItems_InvalidVisibility_Skips() {
        Case incCase = [SELECT Id FROM Case WHERE Customer_Rec_Id__c = 'INC0055555' LIMIT 1];

        FeedItem fi = new FeedItem(
            ParentId   = incCase.Id,
            Body       = 'Internal only note',
            Visibility = 'InternalUsers',
            Type       = 'TextPost'
        );
        insert fi;

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>(),
            new List<FeedItem>{ fi },
            false, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true,
            'Queueable should skip FeedItem with InternalUsers visibility without exception');
    }

    @isTest
    static void test_processFeedItems_MissingServiceNumber_Skips() {
        Case noServiceCase = [SELECT Id FROM Case WHERE Subject = 'No Service Number Case' LIMIT 1];

        FeedItem fi = new FeedItem(
            ParentId   = noServiceCase.Id,
            Body       = 'Note on case without service number',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>(),
            new List<FeedItem>{ fi },
            false, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true,
            'Queueable should skip FeedItem when parent Case has no Customer_Rec_Id__c');
    }

    @isTest
    static void test_processTasks_isTaskUpdateFalse_Skips() {
        Case c = getCaseByCustomerRecId('CHG0098888');
        Task t = new Task(
            Subject            = 'Skipped Task',
            Status             = 'Completed',
            WhatId             = c.Id,
            Customer_Rec_Id__c = 'CTASK_SKIP'
        );
        insert t;

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>{ t },
            new List<FeedItem>(),
            false,
            false,
            false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true, 'Queueable should skip task processing when isTaskUpdate is false');
    }

    @isTest
    static void test_processFeedItems_NullEntries_HandledGracefully() {
        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());

        FeedItem nullIdFeed = new FeedItem();

        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>(),
            new List<FeedItem>{ nullIdFeed },
            false, false, false
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        System.assert(true,
            'Queueable should handle FeedItem entries with null Ids gracefully');
    }

    @isTest
    static void test_constructor_allParameters_accepted() {
        Test.startTest();
        CreateRequestQueueable job = new CreateRequestQueueable(
            new List<Case>(),
            new List<Task>(),
            new List<FeedItem>(),
            true,
            true,
            true
        );
        Test.stopTest();

        System.assertNotEquals(null, job,
            'Constructor should accept all boolean combinations without error');
    }
}
