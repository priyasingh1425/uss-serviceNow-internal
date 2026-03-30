@isTest
public with sharing class API_OM_RequestLogger_Test {
    @isTest
    public static void log_randomMessage(){
        API_OM_RequestLogger logger = new API_OM_RequestLogger();

        HttpRequest req = EBTLS.HttpRequestBuilder.get()
            .endpoint('https://www.google.com')
            .body('Test')
            .build();

        HttpResponse resp = EBTLS.HttpResponseBuilder.init()
            .statusCode(200)
            .body('Test')
            .build();

        Test.startTest();

        logger.log(req, resp);

        Test.stopTest();

        API_Response__c log =
            [SELECT
                Id,
                Method__c,
                Endpoint__c,
                Status_Code__c
            FROM API_Response__c];

        Assert.areEqual('GET', log.Method__c);
        Assert.areEqual('https://www.google.com', log.Endpoint__c);
        Assert.areEqual('200', log.Status_Code__c);
    }

    @isTest
    public static void log_response(){
        API_OM_RequestLogger logger = new API_OM_RequestLogger();

        HttpRequest req = EBTLS.HttpRequestBuilder.get()
            .endpoint('https://www.google.com')
            .body('Test')
            .build();

        HttpResponse resp = EBTLS.HttpResponseBuilder.init()
            .statusCode(200)
            .body('{'+
                '"success": true,'+
                '"messages": ['+
                '{}'+
                '],'+
                '"code": "CREATE_ORDER_RESPONSE",'+
                '"data": {'+
                '"payload_reference_id": "ABC123",'+
                '"payload_state": "review"'+
                '}}')
            .build();

        Test.startTest();

        logger.log(req, resp);

        Test.stopTest();

        API_Response__c log =
            [SELECT
                Success__c,
                Code__c,
                Message__c
            FROM API_Response__c];

        Assert.areEqual('true', log.Success__c);
        Assert.areEqual('CREATE_ORDER_RESPONSE', log.Code__c);
        Assert.areEqual('[{"type":null,"message":null,"field":null}]', log.Message__c);
    }

    @isTest
    public static void extractQuoteId_Failure(){
        API_OM_RequestLogger logger = new API_OM_RequestLogger();

        Test.startTest();

        String quoteId = logger.extractQuoteId('Hello World');

        Test.stopTest();

        Assert.isNull(quoteId);
    }
}