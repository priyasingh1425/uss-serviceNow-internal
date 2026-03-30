// SC-0000100
// Test class for API_CB_PricingModel_INS
@isTest
public class API_CB_PricingModel_INS_TEST {
    @isTest
    public static void testBuildRequest_Broadband() {
        List<Object> params = new List<Object>{
            'accountId123', 'dealId123', 'Test Quote Name', 'Broadband',
            '"Fiber"', '"12"', new Map<String, Decimal>{'lowestSpeed' => 100},
            new Set<String>{'123 Main St', '456 Elm St'}
        };

        API_CB_PricingModel_INS handler = new API_CB_PricingModel_INS();
        HttpRequest request = handler.buildRequest(params);
    }
    
    @isTest
    public static void testBuildRequest_NotBroadband() {
        List<Object> params = new List<Object>{
            'accountId123', 'dealId123', 'Test Quote Name', 'NotBroadband',
            '"Fiber"', '"12"', new Map<String, Decimal>{'lowestSpeed' => 100},
            new Set<String>{'123 Main St', '456 Elm St'}
        };

        API_CB_PricingModel_INS handler = new API_CB_PricingModel_INS();
        HttpRequest request = handler.buildRequest(params);
    }

    @isTest
    public static void testBuildRequest_Ethernet() {

        List<Object> params = new List<Object>{
            'accountId123', 'dealId123', 'Test Quote Name', 'Ethernet - Switched',
            '"Fiber"', '"36"', new Map<String, Decimal>{'lowestSpeed' => 50, 'highestSpeed' => 100},
            new Set<String>{'123 Main St', '456 Elm St'}, null
        };

        API_CB_PricingModel_INS handler = new API_CB_PricingModel_INS();
        HttpRequest request = handler.buildRequest(params);
    }

    @isTest
    public static void testParseResponse_Success() {
        String responseBody = '{"status": "success","data": {"quoteId": "quote123","configIds": ["config1", "config2"]}}';

        API_CB_PricingModel_INS handler = new API_CB_PricingModel_INS();
        API_CB_PricingModel_INS result = (API_CB_PricingModel_INS) handler.parseResponse(responseBody);
    }

    @isTest
    public static void testCreatePricing() {
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = acc.id;
        sfQuote.SBQQ__Opportunity2__c = opp.Id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        
        Product2 testProduct = new Product2(Name = 'Test Product', ICB__c = true);
        insert testProduct;
 
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
      //  SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
        insert new List<SBQQ__QuoteLine__c> { quoteLine1 };
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Map<String, Decimal> speedMap = new Map<String, Decimal>{'lowestSpeed' => 50};
        Set<String> addresses = new Set<String>{'123 Main St', '456 Elm St'};
        Map<String, String> senderToReceiverMap = new Map<String, String>{'sender1' => quoteLine1.Id};

        Test.startTest();
        API_CB_PricingModel_INS.createPricing(
            'accountId123', 'dealId123', 'Test Quote', 'Broadband',
            '"Fiber"', '"12"', speedMap, addresses, senderToReceiverMap, null
        );
        Test.stopTest();
    }
    
    @isTest
    public static void testCreatePricing_Fail() {
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = acc.id;
        sfQuote.SBQQ__Opportunity2__c = opp.Id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        
        Product2 testProduct = new Product2(Name = 'Test Product', ICB__c = true);
        insert testProduct;
 
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
      //  SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
        insert new List<SBQQ__QuoteLine__c> { quoteLine1 };
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator3());

        Map<String, Decimal> speedMap = new Map<String, Decimal>{'lowestSpeed' => 50};
        Set<String> addresses = new Set<String>{'123 Main St', '456 Elm St'};
        Map<String, String> senderToReceiverMap = new Map<String, String>{'sender1' => quoteLine1.Id};

        Test.startTest();
        API_CB_PricingModel_INS.createPricing(
            'accountId123', 'dealId123', 'Test Quote', 'Broadband',
            '"Fiber"', '"12"', speedMap, addresses, senderToReceiverMap, null
        );
        Test.stopTest();
    }
    
    @isTest
    public static void testCreatePricingElse() {
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = acc.id;
        sfQuote.SBQQ__Opportunity2__c = opp.Id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        
        Product2 testProduct = new Product2(Name = 'Test Product', ICB__c = true);
        insert testProduct;
 
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
       // SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
        insert new List<SBQQ__QuoteLine__c> { quoteLine1 };
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator2());

        Map<String, Decimal> speedMap = new Map<String, Decimal>{'lowestSpeed' => 50};
        Set<String> addresses = new Set<String>{'123 Main St', '456 Elm St'};
        Map<String, String> senderToReceiverMap = new Map<String, String>{'sender1' => quoteLine1.Id};

        Test.startTest();
        API_CB_PricingModel_INS.createPricing(
            'accountId123', 'dealId123', 'Test Quote', 'Broadband',
            '"Fiber"', '"12"', speedMap, addresses, senderToReceiverMap, null
        );
        Test.stopTest();
    }
    
    @isTest
    public static void testCreatePricingException() {
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c sfQuote = new SBQQ__Quote__c();
        sfQuote.SBQQ__Account__c = acc.id;
        sfQuote.SBQQ__Opportunity2__c = opp.Id;
        sfQuote.SBQQ__Primary__c = true;
        insert sfQuote;
        
        Product2 testProduct = new Product2(Name = 'Test Product', ICB__c = true);
        insert testProduct;
 
        SBQQ__QuoteLine__c quoteLine1 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
        //SBQQ__QuoteLine__c quoteLine2 = new SBQQ__QuoteLine__c(SBQQ__Quote__c = sfQuote.Id,SBQQ__Product__c = testProduct.Id);
        insert new List<SBQQ__QuoteLine__c> { quoteLine1 };

        Map<String, Decimal> speedMap = new Map<String, Decimal>{'lowestSpeed' => 50};
        Set<String> addresses = new Set<String>{'123 Main St', '456 Elm St'};
        Map<String, String> senderToReceiverMap = new Map<String, String>{'sender1' => quoteLine1.Id};

        Test.startTest();
        API_CB_PricingModel_INS.createPricing(
            'accountId123', 'dealId123', 'Test Quote', 'Broadband',
            '"Fiber"', '"12"', speedMap, addresses, senderToReceiverMap, null
        );
        Test.stopTest();
    }

    private class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "status": "success", "data": { "quoteId": "quote123", "configIds": ["config1", "config2"] } }');
            return res;
        }
    }
    
    private class MockHttpResponseGenerator2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('{ "status": "success", "data": { "quoteId": "quote123", "configIds": ["config1", "config2"] } }');
            return res;
        }
    }
    
    private class MockHttpResponseGenerator3 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{ "status": "fail", "data": { "quoteId": "quote123", "configIds": ["config1", "config2"] } }');
            return res;
        }
    }
}