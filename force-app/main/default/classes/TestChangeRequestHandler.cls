/**
 * @description  Enterprise-standard test class for ChangeRequestHandler.
 *               Validates the afterUpdate() and afterTaskUpdate() trigger
 *               handler dispatch logic including:
 *               - TriggerBypass short-circuit
 *               - Record Type eligibility filtering
 *               - Status change detection (general, parked-waiting, tech approval)
 *               - Priority change detection
 *               - New CR/INC number FeedItem back-sync
 *               - Task eligibility filtering (status + subject changes)
 *               - Queueable governor limit fallback logging
 *
 *               Uses an embedded HttpCalloutMock to absorb cascading callouts
 *               from the enqueued CreateRequestQueueable jobs.
 */
@isTest
private class TestChangeRequestHandler {

    // ════════════════════════════════════════════════════════════════════
    //  MOCK — absorbs callouts from enqueued CreateRequestQueueable
    // ════════════════════════════════════════════════════════════════════

    private class GenericCalloutMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","result":{"response":"OK"}}');
            return res;
        }
    }

    // ════════════════════════════════════════════════════════════════════
    //  TEST SETUP
    // ════════════════════════════════════════════════════════════════════

    @testSetup
    static void setupTestData() {
        // 1. Account
        Account acc = new Account(Name = 'CR Handler Test Account');
        insert acc;

        // 2. Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'Handler',
            AccountId = acc.Id
        );
        insert con;

        // 3. Custom Setting (required by CreateRequestQueueable)
        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Account_Id__c   = acc.Id,
            Contact_Name__c = 'Test Contact',
            Queue_Name__c   = 'TOC Queue'
        );
        insert settings;

        // 4. Record Type IDs
        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();
        Id extSupportRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                                .get('External_Customer_Support').getRecordTypeId();

        // 5. Change Request Case (for status/priority/tech approval tests)
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

        // 6. External Customer Support Case
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

        // 7. Case for FeedItem back-sync test (no Customer_Rec_Id__c yet)
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

        // 8. FeedItem attached to the feedCase (pre-existing work note)
        FeedItem fi = new FeedItem(
            ParentId   = feedCase.Id,
            Body       = 'Pre-existing work note for back-sync',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;

        // 9. Task for afterTaskUpdate tests
        Task t = new Task(
            Subject            = 'CR Task',
            Status             = 'Not Started',
            WhatId             = crCase.Id,
            Customer_Rec_Id__c = 'CTASK001'
        );
        insert t;

        // 10. Task without Customer_Rec_Id__c (ineligible)
        Task tIneligible = new Task(
            Subject = 'Ineligible Task',
            Status  = 'Not Started',
            WhatId  = crCase.Id
        );
        insert tIneligible;
    }

    // ════════════════════════════════════════════════════════════════════
    //  HELPERS
    // ════════════════════════════════════════════════════════════════════

    private static Case getCaseBySubject(String subj) {
        return [SELECT Id, Subject, Status, Priority, RecordTypeId, AccountId,
                       ContactId, Origin, Customer_Rec_Id__c, ParentId,
                       Technical_Approved__c, Status_Reason__c
                FROM Case WHERE Subject = :subj LIMIT 1];
    }

    // ════════════════════════════════════════════════════════════════════
    //  A. BYPASS — TriggerBypass short-circuits execution
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_bypassEnabled_shortCircuits() {
        Case c = getCaseBySubject('CR Handler Case');

        // Build old/new maps with a status change that would normally enqueue
        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        // Enable bypass
        TriggerBypass.setChangeRequestBypass(true);

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        // Reset bypass for other tests
        TriggerBypass.setChangeRequestBypass(false);

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued when bypass is enabled');
    }

    // ════════════════════════════════════════════════════════════════════
    //  B. INELIGIBLE RECORD TYPE — skips non-matching Cases
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_ineligibleRecordType_skipped() {
        // Create a Case with a non-eligible record type (e.g., standard)
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Case stdCase = new Case(
            Subject   = 'Standard Case',
            Status    = 'New',
            AccountId = acc.Id,
            ContactId = con.Id,
            Origin    = 'Phone',
            Priority  = 'Medium'
            // No RecordTypeId => uses default, which is not Change_Request or External_Customer_Support
        );
        insert stdCase;

        Case oldCase = stdCase.clone(true, true);
        Case newCase = stdCase.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ stdCase.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued for ineligible record types');
    }

    // ════════════════════════════════════════════════════════════════════
    //  C. STATUS CHANGED — enqueues status update job
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_statusChanged_enqueuesJob() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable job should be enqueued for a status change');
    }

    // ════════════════════════════════════════════════════════════════════
    //  D. PRIORITY CHANGED — enqueues priority update job
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_priorityChanged_enqueuesJob() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Priority = 'High';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable job should be enqueued for a priority change');
    }

    // ════════════════════════════════════════════════════════════════════
    //  E. PARKED + WAITING — enqueues status update job
    // ════════════════════════════════════════════════════════════════════

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

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable job should be enqueued for a Parked/Waiting transition');
    }

    // ════════════════════════════════════════════════════════════════════
    //  F. TECHNICAL APPROVAL GRANTED — enqueues status update job
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_techApprovalGranted_enqueuesJob() {
        Case c = getCaseBySubject('CR Handler Case');

        Case oldCase = c.clone(true, true);
        oldCase.Technical_Approved__c = false;

        Case newCase = c.clone(true, true);
        newCase.Technical_Approved__c = true;

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable job should be enqueued when Technical_Approved changes to true');
    }

    // ════════════════════════════════════════════════════════════════════
    //  G. NEW CHANGE REQUEST NUMBER — FeedItem back-sync
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_newRecId_syncsFeedItems() {
        Case c = getCaseBySubject('FeedItem BackSync Case');

        Case oldCase = c.clone(true, true);
        oldCase.Customer_Rec_Id__c = null;

        Case newCase = c.clone(true, true);
        newCase.Customer_Rec_Id__c = 'CHG001';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        // The FeedItem inserted in @testSetup should be found by the SOQL
        // and dispatched via a CreateRequestQueueable job
        System.assert(Limits.getQueueableJobs() >= 1,
            'At least one queueable job should be enqueued for FeedItem back-sync');
    }

    // ════════════════════════════════════════════════════════════════════
    //  H. NEW INC PREFIX — also triggers FeedItem back-sync
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_newIncRecId_syncsFeedItems() {
        Case c = getCaseBySubject('FeedItem BackSync Case');

        Case oldCase = c.clone(true, true);
        oldCase.Customer_Rec_Id__c = null;

        Case newCase = c.clone(true, true);
        newCase.Customer_Rec_Id__c = 'INC001';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assert(Limits.getQueueableJobs() >= 1,
            'At least one queueable should be enqueued for INC-prefixed FeedItem back-sync');
    }

    // ════════════════════════════════════════════════════════════════════
    //  I. NO CHANGES — nothing enqueued
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_noChanges_nothingEnqueued() {
        Case c = getCaseBySubject('CR Handler Case');

        // Old and new are identical — no changes
        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued when no relevant fields changed');
    }

    // ════════════════════════════════════════════════════════════════════
    //  J. EXT SUPPORT RECORD TYPE — also eligible
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_extSupportRecordType_enqueuesJob() {
        Case c = getCaseBySubject('Ext Support Case');

        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status = 'In Progress';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'Queueable should be enqueued for External_Customer_Support record type');
    }

    // ════════════════════════════════════════════════════════════════════
    //  K. afterTaskUpdate — eligible Task (status changed)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterTaskUpdate_statusChanged_enqueuesJob() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'CR Task' LIMIT 1];

        Task oldTask = t.clone(true, true);
        Task newTask = t.clone(true, true);
        newTask.Status = 'Completed';

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => oldTask };
        List<Task> newList = new List<Task>{ newTask };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable job should be enqueued for an eligible Task status change');
    }

    // ════════════════════════════════════════════════════════════════════
    //  L. afterTaskUpdate — eligible Task (subject changed)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterTaskUpdate_subjectChanged_enqueuesJob() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'CR Task' LIMIT 1];

        Task oldTask = t.clone(true, true);
        Task newTask = t.clone(true, true);
        newTask.Subject = 'Updated CR Task Subject';

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => oldTask };
        List<Task> newList = new List<Task>{ newTask };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable job should be enqueued for an eligible Task subject change');
    }

    // ════════════════════════════════════════════════════════════════════
    //  M. afterTaskUpdate — ineligible Task (no Customer_Rec_Id__c)
    // ════════════════════════════════════════════════════════════════════

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
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued for Task without Customer_Rec_Id__c');
    }

    // ════════════════════════════════════════════════════════════════════
    //  N. afterTaskUpdate — no changes on Task (skipped)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterTaskUpdate_noChanges_skipped() {
        Task t = [SELECT Id, Subject, Status, Customer_Rec_Id__c
                  FROM Task WHERE Subject = 'CR Task' LIMIT 1];

        // Old and new are identical
        Task oldTask = t.clone(true, true);
        Task newTask = t.clone(true, true);

        Map<Id, Task> oldMap = new Map<Id, Task>{ t.Id => oldTask };
        List<Task> newList = new List<Task>{ newTask };

        Test.startTest();
        ChangeRequestHandler.afterTaskUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued when Task has no relevant changes');
    }

    // ════════════════════════════════════════════════════════════════════
    //  O. QUEUEABLE LIMIT — status + priority concurrent (hits fallback)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_queueableLimitHit_logsAPIResponse() {
        Case c = getCaseBySubject('CR Handler Case');

        // Trigger BOTH status AND priority changes simultaneously.
        // In test context, Limits.getLimitQueueableJobs() = 1.
        // The first dispatch (statusUpdateCases) will consume the slot.
        // The second dispatch (priorityUpdateCases) will hit the fallback.
        Case oldCase = c.clone(true, true);
        Case newCase = c.clone(true, true);
        newCase.Status   = 'In Progress';
        newCase.Priority = 'High';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.setMock(HttpCalloutMock.class, new GenericCalloutMock());
        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        // One queueable should have been enqueued (the first one that fit)
        System.assertEquals(1, Limits.getQueueableJobs(),
            'Exactly 1 queueable should be enqueued (the first dispatch)');

        // The second dispatch should have logged an API_Response__c
        List<API_Response__c> logs = [
            SELECT Http_Response__c, Code__c
            FROM API_Response__c
            WHERE Code__c = 'QueueableLimitExceeded'
        ];
        System.assertEquals(1, logs.size(),
            'Exactly one QueueableLimitExceeded log should be created');
        System.assert(logs[0].Http_Response__c.contains('Queueable limit reached'),
            'Log should contain the limit-reached message');
    }

    // ════════════════════════════════════════════════════════════════════
    //  P. INVALID PREFIX — Customer_Rec_Id__c with non-CHG/INC prefix
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterUpdate_invalidPrefix_noFeedItemSync() {
        Case c = getCaseBySubject('FeedItem BackSync Case');

        Case oldCase = c.clone(true, true);
        oldCase.Customer_Rec_Id__c = null;

        Case newCase = c.clone(true, true);
        // Prefix is neither CHG nor INC — should not trigger FeedItem sync
        newCase.Customer_Rec_Id__c = 'REQ001';

        Map<Id, Case> oldMap = new Map<Id, Case>{ c.Id => oldCase };
        List<Case> newList = new List<Case>{ newCase };

        Test.startTest();
        ChangeRequestHandler.afterUpdate(oldMap, newList);
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable should be enqueued for invalid prefix on Customer_Rec_Id__c');
    }
}