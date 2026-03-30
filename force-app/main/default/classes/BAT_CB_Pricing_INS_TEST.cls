// SC-0000100
// Test class for BAT_CB_Pricing_INS
@isTest
public class BAT_CB_Pricing_INS_TEST {
	@isTest
    public static void testBatchExecution() {
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

        SBQQ__QuoteLine__c senderLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            Network_Status__c = 'Off Net',
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'TX',
            Zip__c = '75001',
            Country__c = 'USA',
            Site_Bandwidth_Mbps__c = 100
        );
        insert senderLine;


        Map<String, List<Map<String, SBQQ__QuoteLine__c>>> cbProductToQLMap = new Map<String, List<Map<String, SBQQ__QuoteLine__c>>>();
        Map<String, SBQQ__QuoteLine__c> qlMap = new Map<String, SBQQ__QuoteLine__c>{
            'sender' => senderLine, 'receiver' => senderLine
        };
        cbProductToQLMap.put('Test Connectbase Product', new List<Map<String, SBQQ__QuoteLine__c>>{qlMap});

        

        Test.startTest();
        BAT_CB_Pricing_INS batch = new BAT_CB_Pricing_INS(
            acc.Id,
            'TestDeal123',
            cbProductToQLMap,
            testQuote,
            'Bulk',
            null
        );
        Database.executeBatch(batch,200);
        Test.stopTest();
    }
    
    
    @isTest
    static void testErrorHandling() {
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

        SBQQ__QuoteLine__c senderLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testBundleProduct.Id,
            Network_Status__c = 'Off Net',
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'TX',
            Zip__c = '75001',
            Country__c = 'USA',
            Site_Bandwidth_Mbps__c = 100
        );
        insert senderLine;

       /* SBQQ__QuoteLine__c receiverLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testBundleProduct.Id
        );*/


        Map<String, List<Map<String, SBQQ__QuoteLine__c>>> cbProductToQLMap = new Map<String, List<Map<String, SBQQ__QuoteLine__c>>>();
        Map<String, SBQQ__QuoteLine__c> qlMap = new Map<String, SBQQ__QuoteLine__c>{
            'sender' => senderLine
        };
        cbProductToQLMap.put('Error Connectbase Product', new List<Map<String, SBQQ__QuoteLine__c>>{qlMap});

        Test.startTest();
        BAT_CB_Pricing_INS batch = new BAT_CB_Pricing_INS(
            acc.Id,
            'ErrorDeal123',
            cbProductToQLMap,
            testQuote,
            'Single',
            null
        );
        Database.executeBatch(batch,1);
        Test.stopTest();
    }
}