@IsTest
public class API_CB_PricingModel_QRY_TEST {

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

       /* SBQQ__QuoteLine__c receiverLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = sfQuote.Id,
            SBQQ__Product__c = testBundleProduct.Id
        );
        insert receiverLine;*/

        Map<String, List<Map<String, SBQQ__QuoteLine__c>>> cbProductToQLMap = new Map<String, List<Map<String, SBQQ__QuoteLine__c>>>();
        Map<String, SBQQ__QuoteLine__c> qlMap = new Map<String, SBQQ__QuoteLine__c>{
            'sender' => senderLine
           
        };
        cbProductToQLMap.put('Test Connectbase Product', new List<Map<String, SBQQ__QuoteLine__c>>{qlMap});
    }

    @IsTest
    static void testGetPricingSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorSuccess());

        String quoteId = [Select Id from SBQQ__Quote__c LIMIT 1].Id;
        List<String> sfQuoteLineIds = new List<String>();
        for(SBQQ__QuoteLine__c line: [Select Id from SBQQ__QuoteLine__c where  SBQQ__Quote__c = :quoteId]){
            sfQuoteLineIds.add(line.Id);
        }
        Integer pageNumber = 1;

        Test.startTest();
        API_CB_PricingModel_QRY.ApiResultWrapper result = API_CB_PricingModel_QRY.getPricing(quoteId, sfQuoteLineIds, pageNumber, UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals(12345, result.parsedResponse.data.pricingStatus.quoteId, 'Quote ID should match');
    }

    @IsTest
    static void testGetPricingErrorResponse() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError());

        String quoteId = '';
        List<String> sfQuoteLineIds = new List<String>();
        for(SBQQ__QuoteLine__c line: [Select Id from SBQQ__QuoteLine__c]){
            sfQuoteLineIds.add(line.Id);
        }
        Integer pageNumber = 1;

        Test.startTest();
        API_CB_PricingModel_QRY.ApiResultWrapper result = API_CB_PricingModel_QRY.getPricing('123456', sfQuoteLineIds, pageNumber, UserInfo.getUserId());
        Test.stopTest();
    }

    @IsTest
    static void testGetPricingErrorResponse2() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGeneratorError2());

        String quoteId = '';
        String quotesId = [Select Id from SBQQ__Quote__c LIMIT 1].Id;
        List<String> sfQuoteLineIds = new List<String>();
        for(SBQQ__QuoteLine__c line: [Select Id from SBQQ__QuoteLine__c where  SBQQ__Quote__c = :quotesId]){
            sfQuoteLineIds.add(line.Id);
        }
        Integer pageNumber = 1;

        Test.startTest();
        API_CB_PricingModel_QRY.ApiResultWrapper result = API_CB_PricingModel_QRY.getPricing(quoteId, sfQuoteLineIds, pageNumber, UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals('', quoteId);
    }
    
    @IsTest
    static void testGetPricingErrorResponse3() {

        String quoteId = '';
        String quotesId = [Select Id from SBQQ__Quote__c LIMIT 1].Id;
        List<String> sfQuoteLineIds = new List<String>();
        for(SBQQ__QuoteLine__c line: [Select Id from SBQQ__QuoteLine__c where  SBQQ__Quote__c = :quotesId]){
            sfQuoteLineIds.add(line.Id);
        }
        Integer pageNumber = 1;

        Test.startTest();
        API_CB_PricingModel_QRY.ApiResultWrapper result = API_CB_PricingModel_QRY.getPricing(quoteId, sfQuoteLineIds, pageNumber, UserInfo.getUserId());
        Test.stopTest();
        System.assertEquals('', quoteId);
    }

   @IsTest
    static void testBuildRequest() {
        List<Object> params = new List<Object>{'12345'};
        API_CB_PricingModel_QRY instance = new API_CB_PricingModel_QRY();

        Test.startTest();
            HttpRequest req = instance.buildRequest(params);
        Test.stopTest();
    }

    @IsTest
    static void testParseResponse() {
        String jsonResponse = '{"status":"success","data":{"totalLocations":10,"pricingStatus":{"quoteId":12345,"quoteName":"TestQuote"}}}';
        API_CB_PricingModel_QRY instance = new API_CB_PricingModel_QRY();

        Test.startTest();
            Object result = instance.parseResponse(jsonResponse);
        Test.stopTest();
        System.assertEquals(12345, ((API_CB_PricingModel_QRY)result).data.pricingStatus.quoteId, 'Quote ID should match');
    }

    @IsTest
    static void testParseResponseError() {
        String invalidJsonResponse = '{"status":"success","data"}';
        API_CB_PricingModel_QRY instance = new API_CB_PricingModel_QRY();
        Test.startTest();
            Object result = instance.parseResponse(invalidJsonResponse);
        Test.stopTest();
    }

    private class MockHttpResponseGeneratorSuccess implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success","data":{"totalLocations":10,"pricingStatus":{"quoteId":12345,"quoteName":"TestQuote"}}}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class MockHttpResponseGeneratorError implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"error":"Invalid request"}');
            res.setStatusCode(400);
            return res;
        }
    }
    
    private class MockHttpResponseGeneratorError2 implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"fail","data":{"totalLocations":10,"pricingStatus":{"quoteId":12345,"quoteName":"TestQuote"}}}');
            res.setStatusCode(200);
            return res;
        }
    }
    
}