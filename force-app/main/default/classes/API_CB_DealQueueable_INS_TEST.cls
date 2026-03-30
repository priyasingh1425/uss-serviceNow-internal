// SC-0000100
// Test class for API_CB_DealQueueable_INS

@IsTest
public class API_CB_DealQueueable_INS_TEST {

    @TestSetup
    private static void doSetup()
    {
        Account a = new Account();
        a.name = 'Acme Inc.';        
        insert a;
        
        Contact c = new Contact();
        c.AccountId = a.id;
        c.FirstName = 'John';
        c.LastName = 'Doe';
        insert c;
        
        Product2 testBundleProduct = new Product2(Name = 'Test Bundle Product', IsActive=true, Send_To_Connectbase__c = true, Receive_From_Connectbase__c = true);
        insert testBundleProduct;
        
        Term__c term = new Term__c();        
        term.Text2__c = 'Text';
        term.Sort_Order__c = 1;
        insert term;
        
        Product_Term__c pt = new Product_Term__c();
        pt.Product__c = testBundleProduct.id;
        pt.Term__c = term.id;
        insert pt;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = a.Id;
        sfQuote.SBQQ__Opportunity2__c = opp.Id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;

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
            SBQQ__Quote__c = sfQuote.Id,
            Quote_Address__c =  aAdd.Id
        );
        insert testGroup;

        SBQQ__QuoteLine__c senderLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = sfQuote.Id,
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

     /*   SBQQ__QuoteLine__c receiverLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = sfQuote.Id,
            SBQQ__Product__c = testBundleProduct.Id
        );
        insert receiverLine;*/

        Map<String, List<Map<String, SBQQ__QuoteLine__c>>> cbProductToQLMap = new Map<String, List<Map<String, SBQQ__QuoteLine__c>>>();
        Map<String, SBQQ__QuoteLine__c> qlMap = new Map<String, SBQQ__QuoteLine__c>{
            'sender' => senderLine
      
        };
                 // 'receiver' => receiverLine
        cbProductToQLMap.put('Test Connectbase Product', new List<Map<String, SBQQ__QuoteLine__c>>{qlMap});
    }

    @isTest
    static void testQueueableExecution_Success(){
        String accName = 'Test Company';
        String accId = [Select Id from Account where Name = 'Acme Inc.' LIMIT 1].Id;
        SBQQ__Quote__c sfQuote = [Select Id,name from SBQQ__Quote__c LIMIT 1];
        String sfQuoteId = sfQuote.Id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Test.startTest();       
            API_CB_DealQueueable_INS queueableInstance = new API_CB_DealQueueable_INS(accId,'Test Deal', sfQuoteId, null);
            System.enqueueJob(queueableInstance);
        Test.stopTest();
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","data":[{"deal_id":"D123","deal_name":"Test Deal","company_name":"Test Company","isbulk_deal":0,"createddate":"2024-01-01","deal_currency":"USD"}]}');
            return res;
        }
    }
}