// SC-0000100
// Test class for API_CB_DealModel_INS
@isTest
public class API_CB_DealModel_INS_TEST {
    
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
        
        Product2 p = new Product2();
        p.Name = 'Product1';
        p.isActive = true;
        insert p;
        
        Term__c term = new Term__c();        
        term.Text2__c = 'Text';
        term.Sort_Order__c = 1;
        insert term;
        
        Product_Term__c pt = new Product_Term__c();
        pt.Product__c = p.id;
        pt.Term__c = term.id;
        insert pt;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
    }


    @isTest
    static void testCreateDeal_Success() {
        String accName = 'Test Company';
        String accId = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        
        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = accId;
        sfQuote.SBQQ__Opportunity2__c = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        String sfQuoteId = sfQuote.Id;
        Test.startTest();
            String dealId = API_CB_DealModel_INS.createDeal(accName, 'Test Deal', sfQuoteId);
        Test.stopTest();

        SBQQ__Quote__c testQuote = [SELECT External_Connectbase_Id__c, Is_Errored__c, Error_Status__c FROM SBQQ__Quote__c WHERE Id = :sfQuoteId];
        System.assertEquals(false, testQuote.Is_Errored__c);
    }

    @isTest
    static void testCreateDeal_Failure() {
        // Insert a test Quote record
        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        sfQuote.SBQQ__Opportunity2__c = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        String sfQuoteId = sfQuote.Id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());
        
        Test.startTest();
            String dealId = API_CB_DealModel_INS.createDeal('A123', 'Test Deal', sfQuoteId);
        Test.stopTest();

        SBQQ__Quote__c testQuote = [SELECT External_Connectbase_Id__c, Is_Errored__c, Error_Status__c FROM SBQQ__Quote__c WHERE Id = :sfQuote.Id];
    }
    
    @isTest
    static void testCreateDeal_Failure2() {
        // Insert a test Quote record
        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        sfQuote.SBQQ__Opportunity2__c = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        String sfQuoteId = sfQuote.Id;
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());
        
        Test.startTest();
            String dealId = API_CB_DealModel_INS.createDeal('A123', 'Test Deal', sfQuoteId);
        Test.stopTest();

        SBQQ__Quote__c testQuote = [SELECT External_Connectbase_Id__c, Is_Errored__c, Error_Status__c FROM SBQQ__Quote__c WHERE Id = :sfQuote.Id];
    }

    @IsTest
    static void testParseResponse(){
        String responseBody = '{"status": "success","data": {"deal_id": "123","deal_name": "Test Deal","company_name":"Test Company","isbulk_deal":0,"createddate":"2024-01-01","deal_currency":"USD"}}';

        API_CB_DealModel_INS handler = new API_CB_DealModel_INS();
        API_CB_DealModel_INS result = (API_CB_DealModel_INS) handler.parseResponse(responseBody);
    }

    @isTest
    static void testCreateDeal_Exception() {

        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        sfQuote.SBQQ__Opportunity2__c = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        String sfQuoteId = sfQuote.Id;
        String dealId = API_CB_DealModel_INS.createDeal('A123', 'Test Deal', sfQuoteId);
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
    
    private class MockHttpResponseGenerator2 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{"error":"Invalid request"}');
            return res;
        }
    }
    
    private class MockHttpResponseGenerator3 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"fail","data":[{"deal_id":"D123","deal_name":"Test Deal","company_name":"Test Company","isbulk_deal":0,"createddate":"2024-01-01","deal_currency":"USD"}]}');
            return res;
        }
    }
}