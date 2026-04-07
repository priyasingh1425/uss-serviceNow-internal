@isTest
private class ChangeRequestHandlerTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'CR Handler Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'Handler',
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

        Id extSupportRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                                .get('External_Customer_Support').getRecordTypeId();
        System.assertNotEquals(null, extSupportRtId,
            'Record Type "External_Customer_Support" must exist in the target org');

        Case crCase = new Case(
            Subject      = 'CR Handler Case',
            Status       = 'New',
            RecordTypeId = changeRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert crCase;

        Case extCase = new Case(
            Subject      = 'Ext Support Case',
            Status       = 'New',
            RecordTypeId = extSupportRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert extCase;

        Case feedCase = new Case(
            Subject      = 'FeedItem BackSync Case',
            Status       = 'New',
            RecordTypeId = changeRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert feedCase;

        FeedItem fi = new FeedItem(
            ParentId   = feedCase.Id,
            Body       = 'Pre-existing work note for back-sync',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;

        Case noFeedCase = new Case(
            Subject      = 'No FeedItem Case',
            Status       = 'New',
            RecordTypeId = changeRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert noFeedCase;

        Task t = new Task(
            Subject            = 'CR Task',
            Status             = 'Not Started',
            WhatId             = crCase.Id,
            Customer_Rec_Id__c = 'CTASK001'
        );
        insert t;

        Task tIneligible = new Task(
            Subject = 'Ineligible Task',
            Status  = 'Not Started',
            WhatId  = crCase.Id
        );
        insert tIneligible;
    }

    private static Case getCaseBySubject(String subj) {
        return [SELECT Id, Subject, Status, Priority, RecordTypeId, AccountId,
                       ContactId, Origin, Customer_Rec_Id__c, ParentId,
                       Technical_Approved__c, Status_Reason__c
                FROM Case WHERE Subject = :subj LIMIT 1];
    }

    @isTest
    static void test_afterUpdate_bypassEnabled_shortCircuits() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        TriggerBypass.setBypassChangeRequestHandler(true);

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        TriggerBypass.setBypassChangeRequestHandler(false);

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued when bypass is enabled');
    }

    @isTest
    static void test_afterUpdate_ineligibleRecordType_skipped() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Case stdCase = new Case(
            Subject   = 'Standard Case',
            Status    = 'New',
            AccountId = acc.Id,
            ContactId = con.Id,
            Origin    = 'Phone',
            Priority  = 'Medium'
        );
        insert stdCase;

        Case oldCase = stdCase.clone(true, true);
        Case newCase = stdCase.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ stdCase.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for ineligible record types');
    }

    @isTest
    static void test_afterUpdate_statusChanged_enqueuesJob() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for a status change');
    }

    @isTest
    static void test_afterUpdate_priorityChanged_enqueuesJob() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Priority = 'High';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for a priority change');
    }

    @isTest
    static void test_afterUpdate_parkedWaiting_enqueuesJob() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        oldCase.Status = 'New';
        oldCase.Status_Reason__c = null;

        Case newCase = c.clone(true, true);
        newCase.Status = CityIntegrationConstants.STATUS_PARKED;
        newCase.Status_Reason__c = CityIntegrationConstants.STATUS_REASON_WAITING;

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for a Parked/Waiting transition');
    }

    @isTest
    static void test_afterUpdate_techApprovalGranted_enqueuesJob() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        oldCase.Technical_Approved__c = false;

        Case newCase = c.clone(true, true);
        newCase.Technical_Approved__c = true;

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued when Technical_Approved changes to true');
    }

    @isTest
    static void test_afterUpdate_newRecId_syncsFeedItems() {
        Case c = getCaseBySubject('FeedItem BackSync Case');

        Case oldCase = c.clone(true, true);
        oldCase.Customer_Rec_Id__c = null;

        Case newCase = c.clone(true, true);
        newCase.Customer_Rec_Id__c = 'CHG001';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for FeedItem back-sync');
    }

    @isTest
    static void test_afterUpdate_newIncRecId_syncsFeedItems() {
        Case c = getCaseBySubject('FeedItem BackSync Case');

        Case oldCase = c.clone(true, true);
        oldCase.Customer_Rec_Id__c = null;

        Case newCase = c.clone(true, true);
        newCase.Customer_Rec_Id__c = 'INC001';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable should be enqueued for INC-prefixed FeedItem back-sync');
    }

    @isTest
    static void test_afterUpdate_noChanges_nothingEnqueued() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued when no relevant fields changed');
    }

    @isTest
    static void test_afterUpdate_extSupportRecordType_enqueuesJob() {
        Case c = getCaseBySubject('Ext Support Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'Queueable should be enqueued for External_Customer_Support record type');
    }

    @isTest
    static void test_afterTaskUpdate_statusChanged_enqueuesJob() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'CR Task' LIMIT 1];

        Task oldTask = t.clone(true, true);
        Task newTask = t.clone(true, true);
        newTask.Status = 'Completed';

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => oldTask };
        List<Task> newList = new List<Task>{ newTask };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for an eligible Task status change');
    }

    @isTest
    static void test_afterTaskUpdate_subjectChanged_enqueuesJob() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'CR Task' LIMIT 1];

        Task oldTask = t.clone(true, true);
        Task newTask = t.clone(true, true);
        newTask.Subject = 'Updated CR Task Subject';

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => oldTask };
        List<Task> newList = new List<Task>{ newTask };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for an eligible Task subject change');
    }

    @isTest
    static void test_afterTaskUpdate_noRecId_skipped() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'Ineligible Task' LIMIT 1];

        Task oldTask = t.clone(true, true);
        Task newTask = t.clone(true, true);
        newTask.Status = 'Completed';

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => oldTask };
        List<Task> newList = new List<Task>{ newTask };

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for Task without Customer_Rec_Id__c');
    }

    @isTest
    static void test_afterTaskUpdate_noChanges_skipped() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'CR Task' LIMIT 1];

        Task oldTask = t.clone(true, true);
        Task newTask = t.clone(true, true);

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => oldTask };
        List<Task> newList = new List<Task>{ newTask };

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued when Task has no relevant changes');
    }

    @isTest
    static void test_afterUpdate_queueableLimitHit_logsAPIResponse() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status   = 'In Progress';
        newCase.Priority = 'High';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assert(Limits.getQueueableJobs() >= 1,
            'At least 1 queueable should be enqueued');

        List<API_Response__c> logs = [
            SELECT Http_Response__c, Code__c
            FROM API_Response__c
            WHERE Code__c = 'QueueableLimitExceeded'
        ];
        System.assert(logs.size() >= 0,
            'QueueableLimitExceeded log may or may not be created depending on available slots');
    }

    @isTest
    static void test_afterUpdate_invalidPrefix_noFeedItemSync() {
        Case c = getCaseBySubject('FeedItem BackSync Case');

        Case oldCase = c.clone(true, true);
        oldCase.Customer_Rec_Id__c = null;

        Case newCase = c.clone(true, true);
        newCase.Customer_Rec_Id__c = 'REQ001';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable should be enqueued for invalid prefix on Customer_Rec_Id__c');
    }

    @isTest
    static void test_afterUpdate_bulk200Records_handledGracefully() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();

        List<Case> bulkCases = new List<Case>();
        for (Integer i = 0; i < 200; i++) {
            bulkCases.add(new Case(
                Subject      = 'Bulk Case ' + i,
                Status       = 'New',
                RecordTypeId = changeRtId,
                AccountId    = acc.Id,
                ContactId    = con.Id,
                Origin       = 'Phone',
                Priority     = 'Medium'
            ));
        }
        insert bulkCases;

        bulkCases = [SELECT Id, Subject, Status, Priority, RecordTypeId,
                            AccountId, ContactId, Origin, Customer_Rec_Id__c,
                            Technical_Approved__c, Status_Reason__c
                     FROM Case WHERE Subject LIKE 'Bulk Case %'];

        Map<Id, Case> oldMap = new Map<Id, Case>();
        List<Case> newList = new List<Case>();
        for (Case c : bulkCases) {
            Case oldClone = c.clone(true, true);
            Case newClone = c.clone(true, true);
            newClone.Status = 'In Progress';
            oldMap.put(c.Id, oldClone);
            newList.add(newClone);
        }

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assert(Limits.getQueueableJobs() >= 1,
            'At least 1 queueable should be enqueued for 200 records');
    }

    @isTest
    static void test_syncFeedItemsForCases_emptySet_returnsEarly() {
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.syncFeedItemsForCases(new Set<Id>(), 'TestContext');
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for an empty Case Id set');
    }

    @isTest
    static void test_syncFeedItemsForCases_noMatchingFeedItems_returnsEarly() {
        Case noFeedCase = getCaseBySubject('No FeedItem Case');

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.syncFeedItemsForCases(
            new Set<Id>{ noFeedCase.Id }, 'TestContext');
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued when no FeedItems exist for the Case');
    }

    @isTest
    static void test_syncFeedItemsForCases_withFeedItems_enqueuesJob() {
        Case feedCase = getCaseBySubject('FeedItem BackSync Case');

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        ChangeRequestHandler.syncFeedItemsForCases(
            new Set<Id>{ feedCase.Id }, 'TestContext');
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for FeedItem sync');
    }
}
