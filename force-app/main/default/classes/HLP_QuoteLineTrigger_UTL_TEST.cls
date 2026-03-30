// SC-0000100
// Test class for HLP_QuoteLineTrigger_UTL
/**
 * @modification    Added Billing_Display__c = 'Display' to all Product2 inserts
 *                  to satisfy required field validation rule.
 * @modified-by     Seth Sheppard
 * @modified-date   2025-12-29
 */
@IsTest
public class HLP_QuoteLineTrigger_UTL_TEST {
    
    @TestSetup
    static void setupTestData() {
        Product2 testProduct = new Product2(Name = 'Test Product', ICB__c = true, Billing_Display__c = 'Display');
        insert testProduct;

        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testBundleProduct;

        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
		Test.startTest();
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Test.stopTest();
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
    }
    
    
    @IsTest
    static void testNotifyICBProducts_Success() {
        Test.startTest();
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 WHERE ICB__c = true];
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quote__c = testQuote.Id
        );
        insert testQuoteLine;
        Test.stopTest();
    }
    
    @IsTest
    static void testNotifyICBProducts_Exception() {
        // Test the exception handling by passing invalid data
        Test.startTest();
        try {
            HLP_QuoteLineTrigger_UTL.notifyICBProducts(null); // Null data to force an exception
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateFields_Success() {
        
        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Second Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity2',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
		SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;        
        // Create test data
        Test.startTest();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Site_Bandwidth_Mbps__c = 200
        );
        
        insert testChildQuoteLine;
        testChildQuoteLine.Site_Bandwidth_Mbps__c = 300;
        update testChildQuoteLine;
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateFields_Exception() {
        Test.startTest();
        List<SBQQ__QuoteLine__c> newLst = new List<SBQQ__QuoteLine__c>{null};
        Map<Id,SBQQ__QuoteLine__c> oldMap = new Map<Id,SBQQ__QuoteLine__c>();
        try {
            HLP_QuoteLineTrigger_UTL.nullCostingFields(newLst, oldMap); // Null data to force an exception
        } catch (Exception e) {
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testAmendFields_Success() {
        
        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Third Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity2',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
		SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true,
            SBQQ__Type__c = 'Amendment'
        );
        insert testQuote;        
        // Create test data
        Test.startTest();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Site_Bandwidth_Mbps__c = 200
        );
        
        insert testChildQuoteLine;
        testChildQuoteLine.Site_Bandwidth_Mbps__c = 300;
        update testChildQuoteLine;
        Test.stopTest();
    }
    
    @IsTest
    static void testAmendFields_Exception() {
        Test.startTest();
        List<SBQQ__QuoteLine__c> newLst = new List<SBQQ__QuoteLine__c>{null};
        Map<Id,SBQQ__QuoteLine__c> oldMap = new Map<Id,SBQQ__QuoteLine__c>();
        try {
            HLP_QuoteLineTrigger_UTL.markAsChanged(newLst, oldMap); // Null data to force an exception
        } catch (Exception e) {
        }
        Test.stopTest();
    }

    @IsTest
    static void testUpdateAddresses_Exception() {
        // Test the exception handling by passing invalid data
        Test.startTest();
        Set<Id> dataSet = new Set<Id>();
        try {
            HLP_QuoteLineTrigger_UTL.updateAddresses(null); // Null data to force an exception
        } catch (Exception e) {
        }
        Test.stopTest();
    }
     @IsTest
    static void testUpdateAddresses_Success() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testBundleProduct;

        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Fourth Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity2',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
		SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c qAddress = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = false
        );
        insert qAddress;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group2',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;

        SBQQ__QuoteLineGroup__c testGroup2 = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group3',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = qAddress.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup2;
        
        // Create test data
        Test.startTest();
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true
        );
        insert testBundleQuoteLine;
        /*SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id
        );
        qlInsert.add(testChildQuoteLine);
        insert qlInsert;*/
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateAmendGroups_Success() {
        
        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Fifth Test Account');
        insert acc;
		
        List<Opportunity> oppLst = new List<Opportunity>();
        Opportunity oppOld = new Opportunity(
            Name = 'Test Opportunity Old',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        oppLst.add(oppOld);
        Opportunity oppNew = new Opportunity(
            Name = 'Test Opportunity New',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        oppLst.add(oppNew);
        insert oppLst;
        SBQQ__Quote__c testQuoteOld = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = oppOld.Id,
            SBQQ__Primary__c = true
        );
        insert testQuoteOld;
        Contract testContract = new Contract(Name = 'Test Contract', Status = 'Draft', AccountId = acc.Id, SBQQ__Quote__c = testQuoteOld.Id);
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;
        
        SBQQ__Quote__c testQuoteNew = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = oppNew.Id,
            SBQQ__Primary__c = true,
            SBQQ__Type__c = 'Amendment',
            SBQQ__MasterContract__c = testContract.Id
        );
        insert testQuoteNew;
        Quote_Address__c qAddress = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = false
        );
        insert qAddress;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        HLP_QuoteLineTrigger_UTL.createAmendGroups(testQuoteNew.Id);
        
    }
    
     @IsTest
    static void testCreateAmendGroups_Success2() {
        
        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Sixth Test Account');
        insert acc;

        Opportunity oppOld = new Opportunity(
            Name = 'Test Opportunity Old',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert oppOld;
        SBQQ__Quote__c testQuoteOld = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = oppOld.Id,
            SBQQ__Primary__c = true
        );
        insert testQuoteOld;
        Contract testContract = new Contract(Name = 'Test Contract', Status = 'Draft', AccountId = acc.Id, SBQQ__Quote__c = testQuoteOld.Id);
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;
        
        SBQQ__Quote__c testQuoteNew = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = oppOld.Id,
            SBQQ__Primary__c = true,
            SBQQ__Type__c = 'Amendment',
            SBQQ__MasterContract__c = testContract.Id
        );
        insert testQuoteNew;
        Quote_Address__c qAddress = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = false
        );
        insert qAddress;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group2',
            SBQQ__Quote__c = testQuoteOld.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;

        SBQQ__QuoteLineGroup__c testGroup2 = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group3',
            SBQQ__Quote__c = testQuoteOld.Id,
            Quote_Address__c = qAddress.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup2;
        HLP_QuoteLineTrigger_UTL.createAmendGroups(testQuoteNew.Id);
        
    }
    
     @IsTest
    static void testUpdateAddresses_Success_2() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testBundleProduct;

        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Seventh Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity2',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
		SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c qAddress = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = false
        );
        insert qAddress;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group2',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;

        SBQQ__QuoteLineGroup__c testGroup2 = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group3',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = qAddress.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup2;
        
        // Create test data
        Test.startTest();
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
       /* SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true
        );
        insert testBundleQuoteLine;*/
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = null
        );
        qlInsert.add(testChildQuoteLine);
        insert qlInsert;
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateAddresses_Success_3() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testBundleProduct;

        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Eighth Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity2',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
		SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c qAddress = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = false
        );
        insert qAddress;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group2',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;

        SBQQ__QuoteLineGroup__c testGroup2 = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group3',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = qAddress.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup2;
        
        // Create test data
        Test.startTest();
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
       /* SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true
        );
        insert testBundleQuoteLine;*/
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup2.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = null
        );
        qlInsert.add(testChildQuoteLine);
        insert qlInsert;
        Test.stopTest();
    }

    // ============================================================================
    // Test methods below merged from Priya Singh's sandbox to avoid overwrite
    // @merged-by   Seth Sheppard
    // @merged-date 2025-12-30
    // ============================================================================

    @IsTest
    static void testCreateAmendGroups_AB() {

        Product2 testChildProduct = new Product2(Name = 'Test Child Product2', Send_To_Connectbase__c = true, Billing_Display__c = 'Display');
        insert testChildProduct;
        Account acc = new Account(Name = 'Sixth Test Account');
        insert acc;

        Opportunity oppOld = new Opportunity(
            Name = 'Test Opportunity Old',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert oppOld;

        SBQQ__Quote__c testQuoteOld = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = oppOld.Id,
            SBQQ__Primary__c = true
        );
        insert testQuoteOld;
        Contract testContract = new Contract(Name = 'Test Contract', Status = 'Draft', AccountId = acc.Id, SBQQ__Quote__c = testQuoteOld.Id);
        insert testContract;
        testContract.Status = 'Activated';
        update testContract;
        Opportunity oppNew = new Opportunity(
            Name = 'Test Opportunity New',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert oppNew;

        Quote_Address__c qAddress = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = false
        );
        insert qAddress;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = oppOld.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group2',
            SBQQ__Quote__c = testQuoteOld.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;

        SBQQ__QuoteLineGroup__c testGroup2 = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group3',
            SBQQ__Quote__c = testQuoteOld.Id,
            Quote_Address__c = qAddress.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup2;

        SBQQ__QuoteLine__c testChildQuoteLineOld = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuoteOld.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id
        );
        insert testChildQuoteLineOld;
        SBQQ__Subscription__c sub = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__QuoteLine__c = testChildQuoteLineOld.id,
            SBQQ__Quantity__c = 1
        );
        insert sub;
        Test.startTest();
        SBQQ__Quote__c testQuoteNew = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = oppNew.Id,
            SBQQ__Primary__c = true,
            SBQQ__Type__c = 'Amendment',
            SBQQ__MasterContract__c = testContract.Id
        );
        insert testQuoteNew;

        SBQQ__QuoteLine__c testChildQuoteLineNew = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuoteNew.Id,
            SBQQ__Product__c = testChildProduct.Id
        );
        insert testChildQuoteLineNew;

        HLP_QuoteLineTrigger_UTL.createAmendGroups(testQuoteNew.Id);
        Test.stopTest();

    }

    @isTest
    static void testdeleteQuoteLegalTerm(){

        // Create Term records
        List<Term__c> terms = new List<Term__c>{
            new Term__c(Name = 'Term1', Sort_Order__c = 1, Text2__c = 'Sample Text'),
            new Term__c(Name = 'Term2', Sort_Order__c = 2, Text2__c = 'Sample Text2')
        };
        insert terms;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'ABC', isActive = true, Billing_Display__c = 'Display');
        insert prod;
        Product2 prod2 = new Product2(Name = 'Test Product2', ProductCode = 'ABCD', isActive = true, Billing_Display__c = 'Display');
        insert prod2;

        // Create Product_Term__c
        List<Product_Term__c> pts = new List<Product_Term__c>{
            new Product_Term__c(Product__c = prod.Id, Term__c = terms[0].Id),
            new Product_Term__c(Product__c = prod2.Id, Term__c = terms[1].Id)
        };
        insert pts;

        // 1. Create Account
        Account acc = new Account(Name='Test');
        insert acc;

        // 2. Create Opportunity
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name='Test Opp',
            StageName = 'Prospect',
            CloseDate=Date.today()
        );
        insert opp;

        // 3. Create Product
        Product2 p = new Product2(Name='Test Prod', IsActive=true, Billing_Display__c = 'Display');
        insert p;

        // 4. Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = p.Id,
            UnitPrice = 100,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        insert pbe;

        // 5. Create Quote (MUST NOT BE PRIMARY)
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c  = opp.Id,
            SBQQ__Primary__c = false
        );
        insert quote;

        List<Quote_Legal_Term__c> qltList = new  List<Quote_Legal_Term__c>{
            new Quote_Legal_Term__c(Quote__c = quote.Id,Term__c = terms[0].Id),
            new Quote_Legal_Term__c(Quote__c = quote.Id,Term__c = terms[1].Id)
        };
        insert qltList;

        // 6. Add MULTIPLE Quote Lines
        List<SBQQ__QuoteLine__c> qls = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = prod.Id, SBQQ__Quantity__c = 1),
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 2)
        };
        insert qls;

        Test.startTest();
        delete qls[0];
        Test.stopTest();

    }

    @isTest
    static void testdeleteQuoteLegalTerm2(){

        // Create Term records
        List<Term__c> terms = new List<Term__c>{
            new Term__c(Name = 'Term1', Sort_Order__c = 1, Text2__c = 'Sample Text'),
            new Term__c(Name = 'Term2', Sort_Order__c = 2, Text2__c = 'Sample Text2')
        };
        insert terms;

        // Create Product
        Product2 prod = new Product2(Name = 'Test Product', ProductCode = 'ABC', isActive = true, Billing_Display__c = 'Display');
        insert prod;
        Product2 prod2 = new Product2(Name = 'Test Product2', ProductCode = 'ABCD', isActive = true, Billing_Display__c = 'Display');
        insert prod2;

        // Create Product_Term__c
        List<Product_Term__c> pts = new List<Product_Term__c>{
            new Product_Term__c(Product__c = prod.Id, Term__c = terms[0].Id),
            new Product_Term__c(Product__c = prod2.Id, Term__c = terms[1].Id)
        };
        insert pts;

        // 1. Create Account
        Account acc = new Account(Name='Test');
        insert acc;

        Contact con = new Contact(
            FirstName = 'Test',
            LastName  = 'User',
            AccountId = acc.Id
        );
        insert con;

        // 2. Create Opportunity
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name='Test Opp',
            StageName = 'Prospect',
            CloseDate=Date.today()
        );
        insert opp;

        // 3. Create Product
        Product2 p = new Product2(Name='Test Prod', IsActive=true, Billing_Display__c = 'Display');
        insert p;

        // 4. Create PricebookEntry
        PricebookEntry pbe = new PricebookEntry(
            Product2Id = p.Id,
            UnitPrice = 100,
            Pricebook2Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        insert pbe;

        // 5. Create Quote (MUST NOT BE PRIMARY)
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Opportunity2__c  = opp.Id,
            SBQQ__Primary__c = false
        );
        insert quote;

        List<Quote_Legal_Term__c> qltList = new  List<Quote_Legal_Term__c>{
            new Quote_Legal_Term__c(Quote__c = quote.Id,Term__c = terms[0].Id),
            new Quote_Legal_Term__c(Quote__c = quote.Id,Term__c = terms[1].Id)
        };
        insert qltList;

        // 6. Add MULTIPLE Quote Lines
        List<SBQQ__QuoteLine__c> qls = new List<SBQQ__QuoteLine__c>{
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = prod.Id, SBQQ__Quantity__c = 1),
            new SBQQ__QuoteLine__c(SBQQ__Quote__c = quote.Id, SBQQ__Product__c = prod2.Id, SBQQ__Quantity__c = 2)
        };
        insert qls;

        Test.startTest();
        delete qls;
        Test.stopTest();

    }
}