/**
 * @description  Enterprise-standard test class for APIResponseTrigger.
 *               This trigger fires after insert on API_Response__c and:
 *               - Parses Http_Response__c JSON for CHG/INC numbers via regex
 *               - Updates the corresponding Case Customer_Rec_Id__c
 *               - Calls syncFeedItemsForCases() for Cases whose
 *                 Customer_Rec_Id__c was previously blank
 *
 *               Uses TestDataFactory.GenericCalloutMock to absorb any
 *               downstream callouts triggered by syncFeedItemsForCases
 *               enqueuing CreateRequestQueueable jobs.
 */
@isTest
private class TestAPIResponseTrigger {

    // ════════════════════════════════════════════════════════════════════
    //  TEST SETUP
    // ════════════════════════════════════════════════════════════════════

    @testSetup
    static void setupTestData() {
        // 1. Account
        Account acc = new Account(Name = 'API Response Trigger Test Account');
        insert acc;

        // 2. Contact
        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'APIResp',
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

        // 4. Record Type — with defensive assertion (R5)
        Id changeRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                            .get('Change_Request').getRecordTypeId();
        System.assertNotEquals(null, changeRtId,
            'Record Type "Change_Request" must exist in the target org');

        // 5. Case with blank Customer_Rec_Id__c (primary test case)
        Case blankCase = new Case(
            Subject      = 'Blank RecId Case',
            Status       = 'New',
            RecordTypeId = changeRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert blankCase;

        // 6. Case with existing Customer_Rec_Id__c
        Case existingCase = new Case(
            Subject            = 'Existing RecId Case',
            Status             = 'New',
            RecordTypeId       = changeRtId,
            AccountId          = acc.Id,
            ContactId          = con.Id,
            Origin             = 'Phone',
            Priority           = 'Medium',
            Customer_Rec_Id__c = 'CHG0000001'
        );
        insert existingCase;

        // 7. FeedItem on blankCase (for syncFeedItemsForCases test)
        FeedItem fi = new FeedItem(
            ParentId   = blankCase.Id,
            Body       = 'Pre-existing work note for trigger sync',
            Visibility = 'AllUsers',
            Type       = 'TextPost'
        );
        insert fi;
    }

    // ════════════════════════════════════════════════════════════════════
    //  HELPERS
    // ════════════════════════════════════════════════════════════════════

    private static Case getCaseBySubject(String subj) {
        return [SELECT Id, Customer_Rec_Id__c FROM Case WHERE Subject = :subj LIMIT 1];
    }

    // ════════════════════════════════════════════════════════════════════
    //  A. createCR response — updates Case Customer_Rec_Id__c with CHG
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_createCRResponse_updatesCaseRecId() {
        Case blankCase = getCaseBySubject('Blank RecId Case');

        API_Response__c resp = new API_Response__c(
            Message__c                     = 'API_ChangeRequestService CreateCR',
            Code__c                        = 'Created',
            Http_Response__c               = '{"status":"success","result":{"response":"CHG0012345"}}',
            Internal_Record_Identifier__c  = blankCase.Id
        );

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        insert resp;
        Test.stopTest();

        Case updated = [SELECT Customer_Rec_Id__c FROM Case WHERE Id = :blankCase.Id];
        System.assertEquals('CHG0012345', updated.Customer_Rec_Id__c,
            'Customer_Rec_Id__c should be updated with the CHG number from the API response');
    }

    // ════════════════════════════════════════════════════════════════════
    //  B. createIncident response — updates Case Customer_Rec_Id__c with INC
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_createIncidentResponse_updatesCaseRecId() {
        Case blankCase = getCaseBySubject('Blank RecId Case');

        API_Response__c resp = new API_Response__c(
            Message__c                     = 'API_IncidentService createIncident',
            Code__c                        = 'Created',
            Http_Response__c               = '{"status":"success","result":{"response":"INC0054321"}}',
            Internal_Record_Identifier__c  = blankCase.Id
        );

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        insert resp;
        Test.stopTest();

        Case updated = [SELECT Customer_Rec_Id__c FROM Case WHERE Id = :blankCase.Id];
        System.assertEquals('INC0054321', updated.Customer_Rec_Id__c,
            'Customer_Rec_Id__c should be updated with the INC number from the API response');
    }

    // ════════════════════════════════════════════════════════════════════
    //  C. No matching CHG/INC pattern — Case remains unchanged
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_noMatchingPattern_caseUnchanged() {
        Case blankCase = getCaseBySubject('Blank RecId Case');

        API_Response__c resp = new API_Response__c(
            Message__c                     = 'API_ChangeRequestService CreateCR',
            Code__c                        = 'Created',
            Http_Response__c               = '{"status":"success","result":{"response":"TASK001"}}',
            Internal_Record_Identifier__c  = blankCase.Id
        );

        Test.startTest();
        insert resp;
        Test.stopTest();

        Case updated = [SELECT Customer_Rec_Id__c FROM Case WHERE Id = :blankCase.Id];
        System.assertEquals(null, updated.Customer_Rec_Id__c,
            'Customer_Rec_Id__c should remain blank when response has no matching CHG/INC pattern');
    }

    // ════════════════════════════════════════════════════════════════════
    //  D. Case already has Customer_Rec_Id__c — updates but no FeedItem sync
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_caseAlreadyHasRecId_noFeedItemSync() {
        Case existingCase = getCaseBySubject('Existing RecId Case');

        API_Response__c resp = new API_Response__c(
            Message__c                     = 'API_ChangeRequestService CreateCR',
            Code__c                        = 'Created',
            Http_Response__c               = '{"status":"success","result":{"response":"CHG0099999"}}',
            Internal_Record_Identifier__c  = existingCase.Id
        );

        Test.startTest();
        insert resp;
        Test.stopTest();

        Case updated = [SELECT Customer_Rec_Id__c FROM Case WHERE Id = :existingCase.Id];
        System.assertEquals('CHG0099999', updated.Customer_Rec_Id__c,
            'Customer_Rec_Id__c should be updated even when it already had a value');

        // No syncFeedItemsForCases should have been called
        // (the Case was not in the casesWithBlankRecId set)
        System.assertEquals(0, Limits.getQueueableJobs(),
            'No queueable jobs should be enqueued since the Case already had a Customer_Rec_Id__c');
    }

    // ════════════════════════════════════════════════════════════════════
    //  E. Non-'Created' Code — trigger ignores the record
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_nonCreatedCode_ignored() {
        Case blankCase = getCaseBySubject('Blank RecId Case');

        API_Response__c resp = new API_Response__c(
            Message__c                     = 'API_ChangeRequestService CreateCR',
            Code__c                        = 'Success',
            Http_Response__c               = '{"status":"success","result":{"response":"CHG0012345"}}',
            Internal_Record_Identifier__c  = blankCase.Id
        );

        Test.startTest();
        insert resp;
        Test.stopTest();

        Case updated = [SELECT Customer_Rec_Id__c FROM Case WHERE Id = :blankCase.Id];
        System.assertEquals(null, updated.Customer_Rec_Id__c,
            'Customer_Rec_Id__c should remain blank when Code__c is not "Created"');
    }

    // ════════════════════════════════════════════════════════════════════
    //  F. Blank RecId → triggers FeedItem sync after update
    // ════════════════════════════════════════════════════════════════════

    @isTest
    static void test_afterInsert_blankRecId_triggersFeedItemSync() {
        Case blankCase = getCaseBySubject('Blank RecId Case');

        API_Response__c resp = new API_Response__c(
            Message__c                     = 'API_ChangeRequestService CreateCR',
            Code__c                        = 'Created',
            Http_Response__c               = '{"status":"success","result":{"response":"CHG0067890"}}',
            Internal_Record_Identifier__c  = blankCase.Id
        );

        Test.setMock(HttpCalloutMock.class, new TestDataFactory.GenericCalloutMock());
        Test.startTest();
        insert resp;
        Test.stopTest();

        // Case should be updated
        Case updated = [SELECT Customer_Rec_Id__c FROM Case WHERE Id = :blankCase.Id];
        System.assertEquals('CHG0067890', updated.Customer_Rec_Id__c,
            'Customer_Rec_Id__c should be set to CHG0067890');

        // syncFeedItemsForCases should have been called because
        // the Case previously had a blank Customer_Rec_Id__c and
        // we inserted a FeedItem in @testSetup. At least 1 queueable
        // should be enqueued (or a QueueableLimitExceeded log).
        Integer queuedJobs = Limits.getQueueableJobs();
        List<API_Response__c> fallbackLogs = [
            SELECT Id FROM API_Response__c
            WHERE Code__c = 'QueueableLimitExceeded'
        ];
        System.assert(queuedJobs >= 1 || !fallbackLogs.isEmpty(),
            'Either a queueable job should be enqueued for FeedItem sync, '
            + 'or a QueueableLimitExceeded fallback log should exist');
    }
}
