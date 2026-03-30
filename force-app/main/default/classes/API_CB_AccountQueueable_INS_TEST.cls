@IsTest
public class API_CB_AccountQueueable_INS_TEST {
    @IsTest
    static void testQueueableExecution_Success() {
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

        // Execute test
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"status":"success","data":[{"account_id":"12345"}]}');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator(mockResponse));
        // Enqueue the Queueable class
        API_CB_AccountQueueable_INS queueableInstance = new API_CB_AccountQueueable_INS('Test', sfQuote.Id, null);
        System.enqueueJob(queueableInstance);

        Test.stopTest();
    }

    @IsTest
    static void testQueueableExecution_Exception() {
        // Set up test data
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

        // Use a mock/stub to simulate exception in the createAccount method
        Test.startTest();
        
        // Enqueue the Queueable class
        try {
            API_CB_AccountQueueable_INS queueableInstance = new API_CB_AccountQueueable_INS(null, sfQuote.Id, null);
            System.enqueueJob(queueableInstance);
        } catch (Exception e) {
            
        }
    }
    
    private class MockHttpResponseGenerator implements HttpCalloutMock {
        private HttpResponse mockResponse;

        MockHttpResponseGenerator(HttpResponse response) {
            this.mockResponse = response;
        }

        public HttpResponse respond(HttpRequest request) {
            return mockResponse;
        }
    }

   
}