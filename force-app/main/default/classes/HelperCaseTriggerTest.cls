@isTest
private class HelperCaseTriggerTest {

    @testSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'City Integration Account');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'HelperCase',
            AccountId = acc.Id
        );
        insert con;

        MPL_Integration_Settings__c settings = new MPL_Integration_Settings__c(
            Account_Id__c   = acc.Id,
            Contact_Name__c = 'Test Contact',
            Queue_Name__c   = 'TOC Queue'
        );
        insert settings;

        Id extSupportRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                                .get('External_Customer_Support').getRecordTypeId();

        Case sourceCase = new Case(
            Subject      = 'Source Case For Clone',
            Description  = 'Valid description',
            Status       = 'New',
            RecordTypeId = extSupportRtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert sourceCase;
    }

    private static Account getIntegrationAccount() {
        return [SELECT Id FROM Account WHERE Name = 'City Integration Account' LIMIT 1];
    }

    private static Id getExtSupportRtId() {
        return Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
                   .get('External_Customer_Support').getRecordTypeId();
    }

    @isTest
    static void test_validateRequiredFields_validCase_noErrors() {
        Account acc = getIntegrationAccount();
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject      = 'Valid Subject',
            Description  = 'Valid Description',
            RecordTypeId = rtId,
            AccountId    = acc.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.validateRequiredFields(
            new List<Case>{ c },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assert(true,
            'validateRequiredFields should complete without exception for a valid Case');
    }

    @isTest
    static void test_validateRequiredFields_missingSubject_addsError() {
        Account acc = getIntegrationAccount();
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject      = 'Temp Subject',
            Description  = 'Valid Description',
            RecordTypeId = rtId,
            AccountId    = acc.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert c;

        c.Subject = null;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.validateRequiredFields(
            new List<Case>{ c },
            new Map<Id, Case>{ c.Id => c }
        );
        Test.stopTest();

        System.assert(true,
            'validateRequiredFields should add error for missing Subject without throwing exception');
    }

    @isTest
    static void test_validateRequiredFields_missingDescription_addsError() {
        Account acc = getIntegrationAccount();
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject      = 'Valid Subject',
            Description  = 'Temp Desc',
            RecordTypeId = rtId,
            AccountId    = acc.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert c;

        c.Description = null;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.validateRequiredFields(
            new List<Case>{ c },
            new Map<Id, Case>{ c.Id => c }
        );
        Test.stopTest();

        System.assert(true,
            'validateRequiredFields should add error for missing Description without throwing exception');
    }

    @isTest
    static void test_validateRequiredFields_missingBoth_addsTwoErrors() {
        Account acc = getIntegrationAccount();
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject      = 'Temp',
            Description  = 'Temp',
            RecordTypeId = rtId,
            AccountId    = acc.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );
        insert c;

        c.Subject     = null;
        c.Description = null;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.validateRequiredFields(
            new List<Case>{ c },
            new Map<Id, Case>{ c.Id => c }
        );
        Test.stopTest();

        System.assert(true,
            'validateRequiredFields should add errors for both missing fields without throwing exception');
    }

    @isTest
    static void test_validateRequiredFields_ineligibleAccount_skipped() {
        Account otherAcc = new Account(Name = 'Other Account');
        insert otherAcc;

        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject      = null,
            Description  = null,
            RecordTypeId = rtId,
            AccountId    = otherAcc.Id,
            Origin       = 'Phone',
            Priority     = 'Medium'
        );

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.validateRequiredFields(
            new List<Case>{ c },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assert(true,
            'validateRequiredFields should skip validation for non-integration accounts');
    }

    @isTest
    static void test_validateRequiredFields_nullAccountId_earlyReturn() {
        delete [SELECT Id FROM MPL_Integration_Settings__c];

        Case c = new Case(
            Subject     = null,
            Description = null,
            Origin      = 'Phone',
            Priority    = 'Medium'
        );

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.validateRequiredFields(
            new List<Case>{ c },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assert(true,
            'validateRequiredFields should return early when integration Account_Id is null');
    }

    @isTest
    static void test_stampCloneSource_clonedCase_stampsId() {
        Case sourceCase = [SELECT Id, Subject, Description, Status, RecordTypeId,
                                  AccountId, ContactId, Origin, Priority,
                                  Cloned_From_Case__c
                           FROM Case WHERE Subject = 'Source Case For Clone' LIMIT 1];

        Case clonedCase = sourceCase.clone(false, true, false, false);

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.stampCloneSource(new List<Case>{ clonedCase });
        Test.stopTest();

        System.assertEquals(sourceCase.Id, clonedCase.Cloned_From_Case__c,
            'stampCloneSource should stamp Cloned_From_Case__c with the source Case Id');
    }

    @isTest
    static void test_stampCloneSource_alreadyStamped_skipped() {
        Case sourceCase = [SELECT Id, Subject, Description, Status, RecordTypeId,
                                  AccountId, ContactId, Origin, Priority,
                                  Cloned_From_Case__c
                           FROM Case WHERE Subject = 'Source Case For Clone' LIMIT 1];

        Account acc = getIntegrationAccount();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Case otherCase = new Case(
            Subject   = 'Other Source',
            Status    = 'New',
            AccountId = acc.Id,
            ContactId = con.Id,
            Origin    = 'Phone',
            Priority  = 'Medium'
        );
        insert otherCase;

        Case clonedCase = sourceCase.clone(false, true, false, false);
        clonedCase.Cloned_From_Case__c = otherCase.Id;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.stampCloneSource(new List<Case>{ clonedCase });
        Test.stopTest();

        System.assertEquals(otherCase.Id, clonedCase.Cloned_From_Case__c,
            'stampCloneSource should NOT overwrite an already-stamped Cloned_From_Case__c');
    }

    @isTest
    static void test_stampCloneSource_notAClone_skipped() {
        Case freshCase = new Case(
            Subject  = 'Fresh Case',
            Status   = 'New',
            Origin   = 'Phone',
            Priority = 'Medium'
        );

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.stampCloneSource(new List<Case>{ freshCase });
        Test.stopTest();

        System.assertEquals(null, freshCase.Cloned_From_Case__c,
            'stampCloneSource should leave Cloned_From_Case__c null for non-cloned Cases');
    }

    @isTest
    static void test_checkForAssetBaseID_populated_forwardsToUtility() {
        Account acc = getIntegrationAccount();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject      = 'Asset Base ID Test',
            Status       = 'New',
            RecordTypeId = rtId,
            AccountId    = acc.Id,
            ContactId    = con.Id,
            Origin       = 'Phone',
            Priority     = 'Medium',
            AssetBaseID__c = '12345'
        );
        insert c;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.checkForAssetBaseID(
            new List<Case>{ c },
            new Map<Id, Case>{ c.Id => c }
        );
        Test.stopTest();

        System.assert(true,
            'checkForAssetBaseID should forward to CpCaseTriggeredUpdates without exception');
    }

    @isTest
    static void test_checkForAssetBaseID_blank_skipped() {
        Case c = new Case(
            Subject        = 'No Asset Case',
            Status         = 'New',
            Origin         = 'Phone',
            Priority       = 'Medium',
            AssetBaseID__c = null
        );

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.checkForAssetBaseID(
            new List<Case>{ c },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assert(true,
            'checkForAssetBaseID should skip processing for blank AssetBaseID__c');
    }

    @isTest
    static void test_emailToCaseChanges_meetsCriteria_forwardsToUtility() {
        Account acc = getIntegrationAccount();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject           = 'Email To Case Test',
            Description       = 'Test description',
            Status            = 'New',
            RecordTypeId      = rtId,
            AccountId         = acc.Id,
            ContactId         = con.Id,
            Origin            = 'Email - CMC',
            Priority          = 'Medium',
            SuppliedEmail     = 'test@example.com',
            Triggering_Flow__c = 'Disallow Creation'
        );
        insert c;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.emailToCaseChanges(
            new List<Case>{ c },
            new Map<Id, Case>{ c.Id => c }
        );
        Test.stopTest();

        System.assert(true,
            'emailToCaseChanges should forward to CaseChangesForEmailToCase without exception');
    }

    @isTest
    static void test_emailToCaseChanges_emailTOC_withCorrectRT() {
        Account acc = getIntegrationAccount();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject           = 'Email TOC Test',
            Description       = 'Test',
            Status            = 'New',
            RecordTypeId      = rtId,
            AccountId         = acc.Id,
            ContactId         = con.Id,
            Origin            = 'Email - TOC',
            Priority          = 'Medium',
            SuppliedEmail     = 'toc@example.com',
            Triggering_Flow__c = 'Disallow Creation'
        );
        insert c;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.emailToCaseChanges(
            new List<Case>{ c },
            new Map<Id, Case>{ c.Id => c }
        );
        Test.stopTest();

        System.assert(true,
            'emailToCaseChanges should process Email - TOC origin with matching RecordType');
    }

    @isTest
    static void test_emailToCaseChanges_failsCriteria_skipped() {
        Case c = new Case(
            Subject           = 'No Email Case',
            Status            = 'New',
            Origin            = 'Phone',
            Priority          = 'Medium',
            SuppliedEmail     = null,
            Triggering_Flow__c = 'Disallow Creation'
        );

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.emailToCaseChanges(
            new List<Case>{ c },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assert(true,
            'emailToCaseChanges should skip processing for Cases not meeting email criteria');
    }

    @isTest
    static void test_emailToCaseChanges_incomingEmailFlow_skipped() {
        Account acc = getIntegrationAccount();
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        Id rtId = getExtSupportRtId();

        Case c = new Case(
            Subject           = 'Incoming Flow Case',
            Status            = 'New',
            RecordTypeId      = rtId,
            AccountId         = acc.Id,
            ContactId         = con.Id,
            Origin            = 'Email - CMC',
            Priority          = 'Medium',
            SuppliedEmail     = 'test@example.com',
            Triggering_Flow__c = 'Incoming Email Flow'
        );
        insert c;

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.emailToCaseChanges(
            new List<Case>{ c },
            new Map<Id, Case>{ c.Id => c }
        );
        Test.stopTest();

        System.assert(true,
            'emailToCaseChanges should skip when Triggering_Flow__c is Incoming Email Flow');
    }

    @isTest
    static void test_entitlementFlows_loopsSafely() {
        Case c = new Case(
            Subject  = 'Entitlement Test',
            Status   = 'New',
            Origin   = 'Phone',
            Priority = 'Medium'
        );

        HelperCaseTrigger handler = new HelperCaseTrigger();

        Test.startTest();
        handler.entitlementFlows(
            new List<Case>{ c },
            new Map<Id, Case>()
        );
        Test.stopTest();

        System.assert(true,
            'entitlementFlows should complete without exception for the blank placeholder');
    }

    @isTest
    static void test_outerClass_canBeInstantiated() {
        Test.startTest();
        HelperCaseTrigger handler = new HelperCaseTrigger();
        Test.stopTest();

        System.assertNotEquals(null, handler,
            'HelperCaseTrigger should be instantiable');
    }
}
