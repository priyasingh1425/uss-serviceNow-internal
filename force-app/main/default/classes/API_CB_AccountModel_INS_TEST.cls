// SC-0000100
// Test class for API_CB_AccountModel_INS
@IsTest
public class API_CB_AccountModel_INS_TEST {

    @IsTest
    static void testBuildRequest() {
        // Arrange
        API_CB_AccountModel_INS handler = new API_CB_AccountModel_INS();
        List<Object> params = new List<Object>{ 'Test Company' };

        // Act
        HttpRequest request = handler.buildRequest(params);

        // Assert (manually verify endpoint, method, and body in debug logs)
        System.debug('Request Endpoint: ' + request.getEndpoint());
        System.debug('Request Method: ' + request.getMethod());
        System.debug('Request Body: ' + request.getBody());
    }

    @IsTest
    static void testParseResponse() {
        // Arrange
        API_CB_AccountModel_INS handler = new API_CB_AccountModel_INS();
        String mockResponse = '{"status":"success","data":[{"account_id":"12345","user_account_id":"67890","company_name":"Test Company","user_id":"11111","createddate":"2025-01-01","is_created_by_corporate_user":1}]}';

        // Act
        Object response = handler.parseResponse(mockResponse);

        // Assert (manually verify parsed response in debug logs)
        System.debug('Parsed Response: ' + response);
    }

    @IsTest
    static void testCreateAccountSuccess() {
        // Arrange
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
        String sfQuoteId = sfQuote.Id;
        // Mock HTTP response
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success","data":[{"account_id":"12345"}]}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Act
        String accountId = API_CB_AccountModel_INS.createAccount(accName, sfQuoteId);

        // Assert (manually verify accountId in debug logs)
        System.debug('Created Account ID: ' + accountId);

        Test.stopTest();
    }
    
     @IsTest
    static void testCreateAccountSuccessFail() {
        // Arrange
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
        String sfQuoteId = sfQuote.Id;
        // Mock HTTP response
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"fail","data":[{"account_id":"12345"}]}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Act
        String accountId = API_CB_AccountModel_INS.createAccount(accName, sfQuoteId);

        // Assert (manually verify accountId in debug logs)
        System.debug('Created Account ID: ' + accountId);

        Test.stopTest();
    }
    
    @IsTest
    static void testCreateAccountFailure() {
        // Arrange
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
        String sfQuoteId = sfQuote.Id;
        // Mock HTTP response
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"error":"Invalid request"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Act
        String accountId = API_CB_AccountModel_INS.createAccount(accName, sfQuoteId);

        // Assert (manually verify accountId is null in debug logs)
        System.debug('Created Account ID: ' + accountId);
        
        Test.stopTest();
    }
    
    @IsTest
    static void testCreateAccountFailureCatch() {
        // Arrange
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
        String sfQuoteId = sfQuote.Id;
        // Mock HTTP response
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"error":"Invalid request"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));

        // Act
        String accountId = API_CB_AccountModel_INS.createAccount(null, null);

        // Assert (manually verify accountId is null in debug logs)
        System.debug('Created Account ID: ' + accountId);

        Test.stopTest();
    }
    
    @IsTest
    static void testCreateAccountFailureBuildRequest() {
        // Arrange
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
        String sfQuoteId = sfQuote.Id;
        // Mock HTTP response
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(400);
        mockResponse.setBody('{"error":"Invalid request"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseCatch());

        String accountId = API_CB_AccountModel_INS.createAccount(accName, sfQuote.Id);
        Test.stopTest();
    }

    // Mock class for HTTP responses
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;

        MockHttpResponseGenerator(HttpResponse response) {
            this.mockResponse = response;
        }

        public HttpResponse respond(HttpRequest request) {
            return mockResponse;
        }
    }
    
    public class MockHttpResponseCatch implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Simulate an exception
            throw new System.CalloutException('Simulated callout exception');
        }
}
}