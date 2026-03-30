// SC-0000100
// Test class for INV_PricingController_UTL
@isTest
public class INV_PricingController_UTL_TEST {
    
    @isTest
    public static void testPriceQuote_AccountCreation() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

       /* SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;*/
        
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
           // SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }
    
    @isTest
    public static void testPriceQuote_AccountCreation_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

        SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;
        
       /* SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }
    
    
    @isTest
    public static void testPriceQuote_DealCreation() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

       /* SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;*/
        
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
           // SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        
        acc.External_Connectbase_Id__c = 'CB-Acc-001'; 
        update acc;
        
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }
    
     @isTest
    public static void testPriceQuote_DealCreation_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

        SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;
        
       /* SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        
        acc.External_Connectbase_Id__c = 'CB-Acc-001'; 
        update acc;
        
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }
    
    @isTest
    public static void testPriceQuote_DealCreation2() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

       /* SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;*/
        
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
           // SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        
        acc.External_Connectbase_Id__c = 'CB-Acc-001'; 
        update acc;
        
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }
    
      @isTest
    public static void testPriceQuote_DealCreation2_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

        SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;
        
      /*  SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        
        acc.External_Connectbase_Id__c = 'CB-Acc-001'; 
        update acc;
        
        Test.startTest();
        Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }
    
    @isTest
    public static void testPriceQuote_DealCreation3() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

      /*  SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;*/
        
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
           // SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        
        acc.External_Connectbase_Id__c = 'CB-Acc-001'; 
        update acc;
        
        Test.startTest();
        //Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }

@isTest
    public static void testPriceQuote_DealCreation3_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

        SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;
        
       /* SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        
        acc.External_Connectbase_Id__c = 'CB-Acc-001'; 
        update acc;
        
        Test.startTest();
        //Test.setCurrentPage(new PageReference('/apex/somePage?id=' + testQuote.Id));
        INV_PricingController_UTL.priceQuote();
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMasterCreatePricing() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test',External_Connectbase_Id__c = 'CB-Acc-001');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

        SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;
        
       /* SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        
        String accId = acc.External_Connectbase_Id__c;
        String dealId = 'Deal-001';
        
        Test.startTest();
        INV_PricingController_UTL.masterCreatePricing(accId, dealId, testQuote.Id);
        
        Test.stopTest();
    }
     
    @isTest
    public static void testMasterCreatePricing_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test',External_Connectbase_Id__c = 'CB-Acc-001');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

       /* SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;*/
        
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
           // SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        
        String accId = acc.External_Connectbase_Id__c;
        String dealId = 'Deal-001';
        
        Test.startTest();
        INV_PricingController_UTL.masterCreatePricing(accId, dealId, testQuote.Id);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testMasterCreatePricingSingle() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

        SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;
        
      /*  SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        List<Map<String, String>> sfQuoteLineLst = new List<Map<String, String>>();
        Map<String, String> quoteLineData = new Map<String, String>();
        quoteLineData.put('bundle', testBundleQuoteLine.Id);
        quoteLineData.put('sender', testQuote.Id);
        quoteLineData.put('receiver', testQuote.Id);
        sfQuoteLineLst.add(quoteLineData);
        
        Test.startTest();
        INV_PricingController_UTL.masterCreatePricingSingle(sfQuoteLineLst);
        
        Test.stopTest();
    }
    
     @isTest
    public static void testMasterCreatePricingSingle_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c();
        testQuote.SBQQ__Account__c = acc.id;
        testQuote.SBQQ__Opportunity2__c = opp.Id;
        testQuote.SBQQ__Primary__c = true;
        testQuote.External_Connectbase_Id__c = '123';
        insert testQuote;
        String sfQuoteId = testQuote.Id;
        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Facility__c = null,
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
            Facility__c = null,
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

       /* SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            SBQQ__Bundle__c = true,
            Network_Status__c = 'Off Net'
        );
        insert testBundleQuoteLine;*/
        
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            //SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        List<Map<String, String>> sfQuoteLineLst = new List<Map<String, String>>();
        Map<String, String> quoteLineData = new Map<String, String>();
       // quoteLineData.put('bundle', testBundleQuoteLine.Id);
        quoteLineData.put('sender', testQuote.Id);
        quoteLineData.put('receiver', testQuote.Id);
        sfQuoteLineLst.add(quoteLineData);
        
        Test.startTest();
        INV_PricingController_UTL.masterCreatePricingSingle(sfQuoteLineLst);
        
        Test.stopTest();
    }
    
    @isTest
    public static void testErrorHandling() {
        
        Test.startTest();
        INV_PricingController_UTL.masterCreatePricing(null, null, null);
        Test.stopTest();
    }
}