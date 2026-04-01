/**
 * @description  Enterprise-standard test class for FeedItemTriggerHandler.
 *               Validates the afterInsert() trigger handler logic including:
 *               - TriggerBypass short-circuit
 *               - 3-part filtering: Case ParentId, AllUsers Visibility, TextPost Type
 *               - Queueable dispatch for eligible FeedItems
 *               - Queueable governor limit fallback logging
 *               - Empty list passthrough
 *               - Multiple eligible FeedItems in a single batch
 *               - Bulk 200-record governor limit validation
 *
 *               Uses TestDataFactory.GenericCalloutMock to absorb cascading
 *               callouts from the enqueued CreateRequestQueueable jobs.
 */
@isTest
private class TestFeedItemTriggerHandler {

    // ════════════════════════════════════════════════════════════════════
    //  TEST SETUP
    // ════════════════════════════════════════════════════════════════════

    @testSetup
    static void setupTestData() {
        // 1. Account
        Account acc = new Account(Name = 'FeedItem Handler Test Account');
        insert acc;

        // 2. Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'FeedHandler',
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

        // 4. Case (serves as FeedItem parent) — with defensive RT assertion (R5)
        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();
        System.assertNotEquals(null, changeRtId,
            'Record Type "Change_Request" must exist in the target org');

        Case c = new Case(
            Subject            = 'FeedItem Handler Case',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'Medium',
            Customer_Rec_Id__c = 'CHG0055555'
        );
        insert c;
    }

    // ════════════════════════════════════════════════════════════════════
    //  HELPERS
    // ════════════════════════════════════════════════════════════════════

    private static Case getTestCase() {
        return [SELECT Id FROM Case WHERE Subject = 'FeedItem Handler Case' LIMIT 1];
    }

    private static FeedItem buildFeedItem(Id parentId, String visibility, String feedType) {
        FeedItem fi = new FeedItem();
        fi.ParentId   = parentId;
        fi.Body       = 'Test work note content';
        fi.Visibility = visibility;
        fi.Type       = feedType;
        return fi;
    }

    // ════════════════════════════════════════════════════════════════════
    //  A. BYPASS — TriggerBypass short-circuits execution
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_bypassEnabled_shortCircuits() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        insert fi;

        // Re-query to get the fully populated FeedItem
        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        TriggerBypass.setBypassFeedItemTrigger(true);

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Test.stopTest();

        TriggerBypass.setBypassFeedItemTrigger(false);

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued when FeedItem bypass is enabled');
    }

    // ════════════════════════════════════════════════════════════════════
    //  B. VALID FEEDITEM — enqueues job
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_validFeedItem_enqueuesJob() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        insert fi;

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable job should be enqueued for a valid FeedItem');
    }

    // ════════════════════════════════════════════════════════════════════
    //  C. INVALID PARENT — Account instead of Case (skipped)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_accountParent_skipped() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = buildFeedItem(acc.Id, 'AllUsers', 'TextPost');
        insert fi;

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.startTest();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued for FeedItem parented to an Account');
    }

    // ════════════════════════════════════════════════════════════════════
    //  D. INVALID VISIBILITY — InternalUsers (skipped)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_internalVisibility_skipped() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'InternalUsers', 'TextPost');
        insert fi;

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.startTest();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued for InternalUsers visibility');
    }

    // ════════════════════════════════════════════════════════════════════
    //  E. INVALID TYPE — ContentPost (skipped)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_contentPostType_skipped() {
        Case c = getTestCase();
        // ContentPost requires ContentData, so we build a LinkPost instead
        FeedItem fi = new FeedItem();
        fi.ParentId   = c.Id;
        fi.Body       = 'Test link';
        fi.Visibility = 'AllUsers';
        fi.LinkUrl    = 'https://example.com';
        fi.Type       = 'LinkPost';
        insert fi;

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.startTest();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued for non-TextPost type');
    }

    // ════════════════════════════════════════════════════════════════════
    //  F. EMPTY LIST — nothing enqueued
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_emptyList_nothingEnqueued() {
        Test.startTest();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>());
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued for an empty FeedItem list');
    }

    // ════════════════════════════════════════════════════════════════════
    //  G. MULTIPLE VALID FEEDITEMS — single job enqueued
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_multipleValid_singleJobEnqueued() {
        Case c = getTestCase();

        FeedItem fi1 = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        FeedItem fi2 = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        fi2.Body = 'Second work note';
        insert new List<FeedItem>{ fi1, fi2 };

        List<FeedItem> items = [SELECT Id, ParentId, Body, Visibility, Type
                                FROM FeedItem
                                WHERE ParentId = :c.Id AND Type = 'TextPost'
                                ORDER BY CreatedDate DESC LIMIT 2];

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        FeedItemTriggerHandler.afterInsert(items);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'Exactly one queueable job should be enqueued for multiple valid FeedItems');
    }

    // ════════════════════════════════════════════════════════════════════
    //  H. MIXED LIST — only eligible items dispatched
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_mixedList_onlyEligibleDispatched() {
        Case c = getTestCase();
        Account acc = [SELECT Id FROM Account LIMIT 1];

        // Valid FeedItem (Case parent, AllUsers, TextPost)
        FeedItem validFi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        insert validFi;

        // Invalid FeedItem (Account parent)
        FeedItem invalidFi = buildFeedItem(acc.Id, 'AllUsers', 'TextPost');
        insert invalidFi;

        List<FeedItem> allItems = [SELECT Id, ParentId, Body, Visibility, Type
                                   FROM FeedItem
                                   WHERE Id IN (:validFi.Id, :invalidFi.Id)];

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        FeedItemTriggerHandler.afterInsert(allItems);
        Test.stopTest();

        System.assertEquals(1, Limits.getQueueableJobs(),
            'One queueable should be enqueued when at least one FeedItem is eligible');
    }

    // ════════════════════════════════════════════════════════════════════
    //  I. ALL INELIGIBLE — nothing enqueued
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_allIneligible_nothingEnqueued() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case c = getTestCase();

        // FeedItem parented to Account
        FeedItem fi1 = buildFeedItem(acc.Id, 'AllUsers', 'TextPost');
        insert fi1;

        // FeedItem with InternalUsers visibility
        FeedItem fi2 = buildFeedItem(c.Id, 'InternalUsers', 'TextPost');
        insert fi2;

        List<FeedItem> items = [SELECT Id, ParentId, Body, Visibility, Type
                                FROM FeedItem
                                WHERE Id IN (:fi1.Id, :fi2.Id)];

        Test.startTest();
        FeedItemTriggerHandler.afterInsert(items);
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued when all FeedItems are ineligible');
    }

    // ════════════════════════════════════════════════════════════════════
    //  J. QUEUEABLE LIMIT EXHAUSTION — fallback logging
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_queueableLimitHit_logsAPIResponse() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        insert fi;

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();

        // Consume the single available queueable slot in test context
        System.enqueueJob(new CreateRequestQueueable(
            new List<Case>(), new List<Task>(), new List<FeedItem>(), false, false, false
        ));

        // Now invoke the handler — it should detect no queueable slots remain
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Test.stopTest();

        // Verify fallback API_Response__c was created
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
    //  K. NULL PARENTID — skipped gracefully
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_nullParentId_skipped() {
        // FeedItem with null ParentId (edge case, unlikely but defensive)
        FeedItem fi = new FeedItem();
        fi.ParentId   = null;
        fi.Body       = 'Orphan post';
        fi.Visibility = 'AllUsers';
        fi.Type       = 'TextPost';
        // Cannot insert a FeedItem with null ParentId, so we test with
        // a memory-only object passed directly to the handler
        // Note: In reality FeedItem requires ParentId, but the handler
        // must still guard against it

        Test.startTest();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Test.stopTest();

        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued for FeedItem with null ParentId');
    }

    // ════════════════════════════════════════════════════════════════════
    //  L. BULK 200 FEEDITEMS — governor limit validation (BP1)
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_bulk200FeedItems_handledGracefully() {
        Case c = getTestCase();

        // Insert 200 valid FeedItems
        List<FeedItem> bulkItems = new List<FeedItem>();
        for (Integer i = 0; i < 200; i++) {
            FeedItem fi = new FeedItem();
            fi.ParentId   = c.Id;
            fi.Body       = 'Bulk work note ' + i;
            fi.Visibility = 'AllUsers';
            fi.Type       = 'TextPost';
            bulkItems.add(fi);
        }
        insert bulkItems;

        // Re-query to get fully populated records
        List<FeedItem> items = [SELECT Id, ParentId, Body, Visibility, Type
                                FROM FeedItem
                                WHERE ParentId = :c.Id
                                AND Type = 'TextPost'
                                AND Body LIKE 'Bulk work note %'
                                LIMIT 200];
        System.assertEquals(200, items.size(),
            'All 200 FeedItems should have been inserted');

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        FeedItemTriggerHandler.afterInsert(items);
        Test.stopTest();

        // In test context only 1 queueable slot is available.
        // The handler collects all 200 eligible FeedItems into a single list
        // and calls System.enqueueJob once, so exactly 1 job is enqueued.
        System.assertEquals(1, Limits.getQueueableJobs(),
            'Exactly 1 queueable should be enqueued in test context for 200 FeedItems');
    }
}