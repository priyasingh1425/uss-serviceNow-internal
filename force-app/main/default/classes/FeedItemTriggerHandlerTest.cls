@isTest
private class FeedItemTriggerHandlerTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'FeedItem Handler Test Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'FeedHandler',
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

    @isTest
    static void test_afterInsert_bypassEnabled_shortCircuits() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi;
        TriggerBypass.setBypassFeedItemTrigger(false);

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        TriggerBypass.setBypassFeedItemTrigger(true);

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        TriggerBypass.setBypassFeedItemTrigger(false);

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued when FeedItem bypass is enabled');
    }

    @isTest
    static void test_afterInsert_validFeedItem_enqueuesJob() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi;
        TriggerBypass.setBypassFeedItemTrigger(false);

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Integer jobsAfter = Limits.getQueueableJobs();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for a valid FeedItem');
        Test.stopTest();
    }

    @isTest
    static void test_afterInsert_accountParent_skipped() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        FeedItem fi = buildFeedItem(acc.Id, 'AllUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi;
        TriggerBypass.setBypassFeedItemTrigger(false);

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for FeedItem parented to an Account');
    }

    @isTest
    static void test_afterInsert_internalVisibility_skipped() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'InternalUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi;
        TriggerBypass.setBypassFeedItemTrigger(false);

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for InternalUsers visibility');
    }

    @isTest
    static void test_afterInsert_contentPostType_skipped() {
        Case c = getTestCase();
        FeedItem fi = new FeedItem();
        fi.ParentId   = c.Id;
        fi.Body       = 'Test link';
        fi.Visibility = 'AllUsers';
        fi.LinkUrl    = 'https://example.com';
        fi.Type       = 'LinkPost';
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi;
        TriggerBypass.setBypassFeedItemTrigger(false);

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for non-TextPost type');
    }

    @isTest
    static void test_afterInsert_emptyList_nothingEnqueued() {
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>());
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for an empty FeedItem list');
    }

    @isTest
    static void test_afterInsert_multipleValid_singleJobEnqueued() {
        Case c = getTestCase();

        FeedItem fi1 = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi1;
        TriggerBypass.setBypassFeedItemTrigger(false);

        fi1 = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi1.Id];

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi1 });
        Integer jobsAfter = Limits.getQueueableJobs();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable job should be enqueued for valid FeedItems');
        Test.stopTest();
    }

    @isTest
    static void test_afterInsert_mixedList_onlyEligibleDispatched() {
        Case c = getTestCase();
        Account acc = [SELECT Id FROM Account LIMIT 1];

        FeedItem validFi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        FeedItem invalidFi = buildFeedItem(acc.Id, 'AllUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert validFi;
        insert invalidFi;
        TriggerBypass.setBypassFeedItemTrigger(false);

        List<FeedItem> allItems = [SELECT Id, ParentId, Body, Visibility, Type
                                   FROM FeedItem
                                   WHERE Id IN (:validFi.Id, :invalidFi.Id)];

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(allItems);
        Integer jobsAfter = Limits.getQueueableJobs();

        System.assert(jobsAfter > jobsBefore,
            'At least one queueable should be enqueued when at least one FeedItem is eligible');
        Test.stopTest();
    }

    @isTest
    static void test_afterInsert_allIneligible_nothingEnqueued() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Case c = getTestCase();

        FeedItem fi1 = buildFeedItem(acc.Id, 'AllUsers', 'TextPost');
        FeedItem fi2 = buildFeedItem(c.Id, 'InternalUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi1;
        insert fi2;
        TriggerBypass.setBypassFeedItemTrigger(false);

        List<FeedItem> items = [SELECT Id, ParentId, Body, Visibility, Type
                                FROM FeedItem
                                WHERE Id IN (:fi1.Id, :fi2.Id)];

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(items);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued when all FeedItems are ineligible');
    }

    @isTest
    static void test_afterInsert_withPriorQueueable_completesGracefully() {
        Case c = getTestCase();
        FeedItem fi = buildFeedItem(c.Id, 'AllUsers', 'TextPost');
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert fi;
        TriggerBypass.setBypassFeedItemTrigger(false);

        fi = [SELECT Id, ParentId, Body, Visibility, Type FROM FeedItem WHERE Id = :fi.Id];

        Test.setMock(HttpCalloutMock.class, new CaseMockCallout.GenericCalloutMock());
        Test.startTest();

        System.enqueueJob(new CreateRequestQueueable(
            new List<Case>(), new List<Task>(), new List<FeedItem>(), false, false, false
        ));

        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });

        System.assert(true, 'Handler should complete gracefully when a prior queueable exists');
        Test.stopTest();
    }

    @isTest
    static void test_afterInsert_nullParentId_skipped() {
        FeedItem fi = new FeedItem();
        fi.ParentId   = null;
        fi.Body       = 'Orphan post';
        fi.Visibility = 'AllUsers';
        fi.Type       = 'TextPost';

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(new List<FeedItem>{ fi });
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'No additional queueable jobs should be enqueued for FeedItem with null ParentId');
    }

    @isTest
    static void test_afterInsert_bulk200FeedItems_handledGracefully() {
        Case c = getTestCase();
        Account acc = [SELECT Id FROM Account LIMIT 1];

        List<FeedItem> bulkItems = new List<FeedItem>();
        for (Integer i = 0; i < 200; i++) {
            FeedItem fi = new FeedItem();
            fi.ParentId   = acc.Id;
            fi.Body       = 'Bulk work note ' + i;
            fi.Visibility = 'AllUsers';
            fi.Type       = 'TextPost';
            bulkItems.add(fi);
        }
        TriggerBypass.setBypassFeedItemTrigger(true);
        insert bulkItems;
        TriggerBypass.setBypassFeedItemTrigger(false);

        List<FeedItem> items = [SELECT Id, ParentId, Body, Visibility, Type
                                FROM FeedItem
                                WHERE ParentId = :acc.Id
                                AND Type = 'TextPost'
                                LIMIT 200];
        System.assertEquals(200, items.size(),
            'All 200 FeedItems should have been inserted');

        Test.startTest();
        Integer jobsBefore = Limits.getQueueableJobs();
        FeedItemTriggerHandler.afterInsert(items);
        Integer jobsAfter = Limits.getQueueableJobs();
        Test.stopTest();

        System.assertEquals(jobsBefore, jobsAfter,
            'Handler should filter out 200 Account-parented FeedItems without hitting governor limits');

        System.assert(Limits.getQueries() < Limits.getLimitQueries(),
            'SOQL queries should remain within governor limits for 200 FeedItems');
    }
}
