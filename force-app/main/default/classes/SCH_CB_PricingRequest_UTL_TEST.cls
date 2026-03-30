@IsTest
public class SCH_CB_PricingRequest_UTL_TEST {
    @isTest
    static void testCallFutureMethod() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id
        );
        insert testGroup;
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '27888 N Beech St',
            City__c = 'Island Lake',
            State__c = 'IL',
            Zip__c = '60042',
            Site_Bandwidth_Mbps__c = 700
        );
        insert testQuoteLine;
        String sfQuoteLines = testQuoteLine.Id + '=' + testQuoteLine.Id;
        Get_Pricing_Request__c testPricingRequest = new Get_Pricing_Request__c(
            Connectbase_Quote_Id__c = '123456',
            SF_Quote__c = testQuote.Id,
            User__c = UserInfo.getUserId(),
            Page_Number__c = 0,
            Total_Pages__c = 0,
            SF_Quote_Line_Ids__c = sfQuoteLines,
            Connectbase_Product__c = 'Ethernet - Switched'
        );
        insert testPricingRequest;
        Quote_Line_Request__c testQLR = new Quote_Line_Request__c(Get_Pricing_Request__c = testPricingRequest.id,
                                                                  MRC__c = 1000,
                                                                  NRC__c = 1000,
                                                                  Provider__c = 'test',
                                                                  Quote_Line__c = testQuoteLine.Id,
                                                                  Media_Type__c = 'Fiber' ,
                                                                  Receiver_Quote_Line__c = testQuoteLine.Id,
                                                                  Download_Speed__c = 700,
                                                                  Upload_Speed__c = 700
                                                                 );
        insert testQLR;
        /*SBQQ__QuoteLine__c testQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '27888 N Beech St',
            City__c = 'Island Lake',
            State__c = 'IL',
            Zip__c = '60042',
            Site_Bandwidth_Mbps__c = 700
        );
        insert testQuoteLine2;
        String sfQuoteLines2 = testQuoteLine2.Id + '=' + testQuoteLine2.Id;
         Get_Pricing_Request__c testPricingRequest2 = new Get_Pricing_Request__c(
            Connectbase_Quote_Id__c = '654321',
            SF_Quote__c = testQuote.Id,
            User__c = UserInfo.getUserId(),
            Page_Number__c = 0,
            Total_Pages__c = 0,
            SF_Quote_Line_Ids__c = sfQuoteLines2,
            Connectbase_Product__c = 'Ethernet - Switched'
        );
        insert testPricingRequest2;*/
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockAPI_CB_PricingModel_QRY());
        SCH_CB_PricingRequest_UTL.callFutureMethod();
        Test.stopTest();
    }
    
    @isTest
    static void testCallFutureMethod_1() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;
        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id
        );
        insert testGroup;
        /*SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '27888 N Beech St',
            City__c = 'Island Lake',
            State__c = 'IL',
            Zip__c = '60042',
            Site_Bandwidth_Mbps__c = 700
        );
        insert testQuoteLine;
        String sfQuoteLines = testQuoteLine.Id + '=' + testQuoteLine.Id;
        Get_Pricing_Request__c testPricingRequest = new Get_Pricing_Request__c(
            Connectbase_Quote_Id__c = '123456',
            SF_Quote__c = testQuote.Id,
            User__c = UserInfo.getUserId(),
            Page_Number__c = 0,
            Total_Pages__c = 0,
            SF_Quote_Line_Ids__c = sfQuoteLines,
            Connectbase_Product__c = 'Ethernet - Switched'
        );
        insert testPricingRequest;
        Quote_Line_Request__c testQLR = new Quote_Line_Request__c(Get_Pricing_Request__c = testPricingRequest.id,
                                                                  MRC__c = 1000,
                                                                  NRC__c = 1000,
                                                                  Provider__c = 'test',
                                                                  Quote_Line__c = testQuoteLine.Id,
                                                                  Media_Type__c = 'Fiber' ,
                                                                  Receiver_Quote_Line__c = testQuoteLine.Id,
                                                                  Download_Speed__c = 700,
                                                                  Upload_Speed__c = 700
                                                                 );
        insert testQLR;*/
        SBQQ__QuoteLine__c testQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '27888 N Beech St',
            City__c = 'Island Lake',
            State__c = 'IL',
            Zip__c = '60042',
            Site_Bandwidth_Mbps__c = 700
        );
        insert testQuoteLine2;
        String sfQuoteLines2 = testQuoteLine2.Id + '=' + testQuoteLine2.Id;
         Get_Pricing_Request__c testPricingRequest2 = new Get_Pricing_Request__c(
            Connectbase_Quote_Id__c = '654321',
            SF_Quote__c = testQuote.Id,
            User__c = UserInfo.getUserId(),
            Page_Number__c = 0,
            Total_Pages__c = 0,
            SF_Quote_Line_Ids__c = sfQuoteLines2,
            Connectbase_Product__c = 'Ethernet - Switched'
        );
        insert testPricingRequest2;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockAPI_CB_PricingModel_QRY());
        SCH_CB_PricingRequest_UTL.callFutureMethod();
        Test.stopTest();
    }
    
    private class MockAPI_CB_PricingModel_QRY implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Extract the page number from the request (assuming it's in the URL as a query parameter)
            String requestUrl = req.getEndpoint();
            Integer pageNumber = extractPageNumberFromUrl(requestUrl);
            
            // Respond with different data based on the page number
            if (pageNumber == 1 && requestUrl.contains('123456')) {
                res.setBody('{\n' +
                            '  "status": "success",\n' +
                            '  "pagination": {\n' +
                            '    "page": 1,\n' +
                            '    "pageSize": 2,\n' +
                            '    "totalPages": 2\n' +
                            '  },\n' +
                            '  "data": {\n' +
                            '    "totalLocations": 1,\n' +
                            '    "totalLocationSolutions": 2,\n' +
                            '    "numSolutions": 1,\n' +
                            '    "pricingStatus": {\n' +
                            '      "quoteId": 1874249,\n' +
                            '      "quoteName": "Ethernet - Switched 2025-01-07 07:03:11",\n' +
                            '      "accountId": 1221751,\n' +
                            '      "accountName": "Chris Likes Baseball",\n' +
                            '      "dealId": 1225258,\n' +
                            '      "dealName": "Q-01469",\n' +
                            '      "prices": [\n' +
                            '        {\n' +
                            '          "id": 256825475,\n' +
                            '          "provider": "COMCAST",\n' +
                            '          "mrcTotalPrice": 819,\n' +
                            '          "nrcTotalPrice": 500,\n' +
                            '          "address": "27888 N Beech St",\n' +
                            '          "city": "Island Lake",\n' +
                            '          "state": "IL",\n' +
                            '          "zip": "60042",\n' +
                            '          "downloadSpeed": 700,\n' +
                            '          "uploadSpeed": 700,\n' +
                            '          "mediaType": "Fiber"\n' +
                            '        }\n' +
                            '      ],\n' +
                            '      "transactionStatus": "Success",\n' +
                            '      "message": "Solutions Found"\n' +
                            '    }\n' +
                            '  }\n' +
                            '}');
            } else if (pageNumber == 2 && requestUrl.contains('123456')) {
                res.setBody('{\n' +
                            '  "status": "success",\n' +
                            '  "pagination": {\n' +
                            '    "page": 2,\n' +
                            '    "pageSize": 2,\n' +
                            '    "totalPages": 2\n' +
                            '  },\n' +
                            '  "data": {\n' +
                            '    "totalLocations": 1,\n' +
                            '    "totalLocationSolutions": 2,\n' +
                            '    "numSolutions": 1,\n' +
                            '    "pricingStatus": {\n' +
                            '      "quoteId": 1874249,\n' +
                            '      "quoteName": "Ethernet - Switched 2025-01-07 07:03:11",\n' +
                            '      "accountId": 1221751,\n' +
                            '      "accountName": "Chris Likes Baseball",\n' +
                            '      "dealId": 1225258,\n' +
                            '      "dealName": "Q-01469",\n' +
                            '      "prices": [\n' +
                            '        {\n' +
                            '          "id": 256825476,\n' +
                            '          "provider": "AT&T",\n' +
                            '          "mrcTotalPrice": 600,\n' +
                            '          "nrcTotalPrice": 600,\n' +
                            '          "address": "27888 N Beech St",\n' +
                            '          "city": "Island Lake",\n' +
                            '          "state": "IL",\n' +
                            '          "zip": "60042",\n' +
                            '          "downloadSpeed": 700,\n' +
                            '          "uploadSpeed": 700,\n' +
                            '          "mediaType": "Fiber"\n' +
                            '        },\n' +
                            '        {\n' +
                            '          "id": 256825476,\n' +
                            '          "provider": "US SIGNAL",\n' +
                            '          "mrcTotalPrice": 950,\n' +
                            '          "nrcTotalPrice": 300,\n' +
                            '          "address": "27888 N Beech St",\n' +
                            '          "city": "Island Lake",\n' +
                            '          "state": "IL",\n' +
                            '          "zip": "60042",\n' +
                            '          "downloadSpeed": 700,\n' +
                            '          "uploadSpeed": 700,\n' +
                            '          "mediaType": "Fiber"\n' +
                            '        }\n' +
                            '      ],\n' +
                            '      "transactionStatus": "Success",\n' +
                            '      "message": "Solutions Found"\n' +
                            '    }\n' +
                            '  }\n' +
                            '}');
            }
            else if (requestUrl.contains('654321')) {
                res.setBody('{\n' +
                            '  "status": "success",\n' +
                            '  "pagination": {\n' +
                            '    "page": 1,\n' +
                            '    "pageSize": 1,\n' +
                            '    "totalPages": 0\n' +
                            '  },\n' +
                            '  "data": {\n' +
                            '    "totalLocations": 1,\n' +
                            '    "totalLocationSolutions": 1,\n' +
                            '    "numSolutions": 0,\n' +
                            '    "pricingStatus": {\n' +
                            '      "quoteId": 1874249,\n' +
                            '      "quoteName": "Ethernet - Switched 2025-01-07 07:03:11",\n' +
                            '      "accountId": 1221751,\n' +
                            '      "accountName": "Chris Likes Baseball",\n' +
                            '      "dealId": 1225258,\n' +
                            '      "dealName": "Q-01469",\n' +
                            '      "prices": [],\n' +
                            '      "transactionStatus": "Success",\n' +
                            '      "message": "No Solutions Found"\n' +
                            '    }\n' +
                            '  }\n' +
                            '}');
            }
            res.setStatusCode(200);
            return res;
        }
        private Integer extractPageNumberFromUrl(String url) {
            if (url.contains('page=')) {
                String pageParam = url.substringAfter('page=').split('&')[0];
                return Integer.valueOf(pageParam);
            }
            return 1;
        }
    }
    
    
    
    
}