// SC-0000100
// Test class for CTL_CB_ReConfiguration_UTL
@isTest
public class CTL_CB_ReConfiguration_UTL_TEST {
    
    @isTest
    static void testAssignValues() {
        // Create a test page reference and set parameters
        PageReference testPage = new PageReference('/apex/TestPage');
        testPage.getParameters().put('costing', 'true');
        testPage.getParameters().put('name', 'TestGroup');

        // Set the page reference in the test context
        Test.setCurrentPage(testPage);

        // Call the method to be tested
        CTL_CB_ReConfiguration_UTL.assignValues();
    }

    @isTest
    public static void testPriceGroup() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test', External_Connectbase_Id__c = 'test');
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
        testQuote.External_Connectbase_Id__c = 'test';
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
          //  SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testGroup.Id);
        ApexPages.currentPage().getParameters().put('costing', 'false');

        CTL_CB_ReConfiguration_UTL.priceGroup();
        Test.stopTest();
    }
    
     @isTest
    public static void testPriceGroup_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test', External_Connectbase_Id__c = 'test');
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
        testQuote.External_Connectbase_Id__c = 'test';
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
        
     /*   SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testGroup.Id);
        ApexPages.currentPage().getParameters().put('costing', 'false');

        CTL_CB_ReConfiguration_UTL.priceGroup();
        Test.stopTest();
    }
    
    @isTest
    public static void testPriceGroup2() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = false);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = false);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test', External_Connectbase_Id__c = 'test');
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
        testQuote.External_Connectbase_Id__c = 'test';
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
        ApexPages.currentPage().getParameters().put('id', testGroup.Id);
        ApexPages.currentPage().getParameters().put('costing', 'false');

        CTL_CB_ReConfiguration_UTL.priceGroup();
        Test.stopTest();
    }
    
     @isTest
    public static void testPriceGroup2_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = false);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true, Receive_From_Connectbase__c = false);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test', External_Connectbase_Id__c = 'test');
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
        testQuote.External_Connectbase_Id__c = 'test';
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
        
     /*   SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testGroup.Id);
        ApexPages.currentPage().getParameters().put('costing', 'false');

        CTL_CB_ReConfiguration_UTL.priceGroup();
        Test.stopTest();
    }
    
    @isTest
    public static void testPriceGroup3() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = false, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = false, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test', External_Connectbase_Id__c = 'test');
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
        testQuote.External_Connectbase_Id__c = 'test';
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
        ApexPages.currentPage().getParameters().put('id', testGroup.Id);
        ApexPages.currentPage().getParameters().put('costing', 'false');

        CTL_CB_ReConfiguration_UTL.priceGroup();
        Test.stopTest();
    }
    
      @isTest
    public static void testPriceGroup3_1() {
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', Send_To_Connectbase__c = false, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = false, Receive_From_Connectbase__c = true);
        insert testChildProduct;
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test', External_Connectbase_Id__c = 'test');
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
        testQuote.External_Connectbase_Id__c = 'test';
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
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testGroup.Id);
        ApexPages.currentPage().getParameters().put('costing', 'false');

        CTL_CB_ReConfiguration_UTL.priceGroup();
        Test.stopTest();
    }

    @isTest
    public static void testBundlesFromQuote() {
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
        
        /*SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;*/
        Test.startTest();
        List<SBQQ__QuoteLine__c> bundles = CTL_CB_ReConfiguration_UTL.bundlesFromQuote(testQuote.Id);
        List<SBQQ__QuoteLine__c> bundlesEx = CTL_CB_ReConfiguration_UTL.bundlesFromQuote(null);
        Test.stopTest();
    }
    
    @isTest
    public static void testBundlesFromQuote_1() {
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

        /*SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
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
          //  SBQQ__RequiredBy__c = testBundleQuoteLine.Id,
            Network_Status__c = 'Off Net'
        );
        insert testChildQuoteLine;
        Test.startTest();
        List<SBQQ__QuoteLine__c> bundles = CTL_CB_ReConfiguration_UTL.bundlesFromQuote(testQuote.Id);
        Test.stopTest();
    }

    @isTest
    public static void testPriceGroupWithError() {
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

        /*SBQQ__QuoteLine__c testBundleQuoteLine = new SBQQ__QuoteLine__c(
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
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', null);
        ApexPages.currentPage().getParameters().put('costing', 'false');        
        CTL_CB_ReConfiguration_UTL.priceGroup();    
        Test.stopTest();
    }
    
     @isTest
    public static void testPriceGroupWithError_1() {
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
        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', null);
        ApexPages.currentPage().getParameters().put('costing', 'false');        
        CTL_CB_ReConfiguration_UTL.priceGroup();    
        Test.stopTest();
    }
}