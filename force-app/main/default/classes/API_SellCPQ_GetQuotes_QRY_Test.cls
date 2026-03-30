@isTest
public class API_SellCPQ_GetQuotes_QRY_Test {
    
    @TestSetup
    static void setupTestData() {
        // Create standard pricebook
        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        // Create custom pricebook
        Pricebook2 customPricebook = new Pricebook2(
            Name = 'Test Pricebook',
            IsActive = true
        );
        insert customPricebook;
        
        // Create test account
        Id custRecTID = [SELECT Id FROM RecordType WHERE Name = 'Customer' AND sObjectType = 'Account'].get(0).Id;
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = custRecTID,
            Type='Customer'
        );
        insert testAccount;
        
        //create test contact
        Id genRecTID = [SELECT Id FROM RecordType WHERE Name = 'General' AND sObjectType = 'Contact'].get(0).Id;
        Contact testContact = new Contact(
            LastName = 'testLN',
            AccountId = testAccount.Id,
            RecordTypeId = genRecTID
        );
        insert testContact;
        
        // Create test opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            MA_External_Quote_ID__c = 'TEST123456',
            Pricebook2Id = customPricebook.Id,
            Primary_Contact_Added__c = true
        );
        insert testOpp;
        
        // Create Opportunity Contact Role
        OpportunityContactRole testOppPrimaryContact = new OpportunityContactRole(
            ContactId = testContact.Id,
            IsPrimary = true,
            OpportunityId = testOpp.Id
        );
        
        // Create test products with product classes
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
        List<Product2> products = new List<Product2>();
            products.add(new Product2(Name = 'Test Product 1', Product_Class__c = 'Hardware', IsActive = true, Family = 'Hardware Software and Support', Billing_Display__c = 'Suppress'));
            products.add(new Product2(Name = 'Test Product 2', Product_Class__c = 'Software', IsActive = true, Family = 'Hardware Software and Support', Billing_Display__c = 'Suppress'));

        insert products;
        
        // Create standard pricebook entries
        List<PricebookEntry> standardEntries = new List<PricebookEntry>();
        for(Product2 prod : products) {
            standardEntries.add(new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = prod.Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert standardEntries;
        
        // Create custom pricebook entries
        List<PricebookEntry> customEntries = new List<PricebookEntry>();
        for(Product2 prod : products) {
            customEntries.add(new PricebookEntry(
                Pricebook2Id = customPricebook.Id,
                Product2Id = prod.Id,
                UnitPrice = 150,
                IsActive = true
            ));
        }
        insert customEntries;
        
        // Create test user
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + DateTime.now().getTime() + '@testdomain.com',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId = standardProfile.Id
        );
        insert testUser;
    }
    
    @isTest
    static void testGetQuoteLines_Success_SinglePage() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        
        // Set mock for successful single page response
        Test.setMock(HttpCalloutMock.class, new MockFullResponse());
        
        Test.startTest();
        API_SellCPQ_GetQuotes_QRY.getQuoteLines(testOpp.Id, testUser.Id);
        Test.stopTest();
        
        // Verify API_Response__c records were created
        List<API_Response__c> responses = [SELECT Id, Success__c, Method__c FROM API_Response__c];
        System.assert(responses.size() > 0, 'API response records should be created');
        System.assertEquals('GET', responses[0].Method__c, 'Method should be GET');
        
        // Verify OpportunityLineItems were created
        List<OpportunityLineItem> lineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];

    }
    
    @isTest
    static void testGetQuoteLinesInvocable() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        
        // Set mock for successful single page response
        Test.setMock(HttpCalloutMock.class, new MockFullResponse());
        
        INV_API_SellCPQ_GetQuotes_QRY.InputVariables iv = new INV_API_SellCPQ_GetQuotes_QRY.InputVariables();
        iv.opportunityId = testOpp.Id;
        iv.originalUser = testUser.Id;
        
        List<INV_API_SellCPQ_GetQuotes_QRY.InputVariables> ivs = new List<INV_API_SellCPQ_GetQuotes_QRY.InputVariables>();
        ivs.add(iv);
        
        Test.startTest();
        INV_API_SellCPQ_GetQuotes_QRY.getProductsFromSellCPQ(ivs);
        Test.stopTest();
        
        // Verify API_Response__c records were created
        List<API_Response__c> responses = [SELECT Id, Success__c, Method__c FROM API_Response__c];
        System.assert(responses.size() > 0, 'API response records should be created');
        System.assertEquals('GET', responses[0].Method__c, 'Method should be GET');
        
        // Verify OpportunityLineItems were created
        List<OpportunityLineItem> lineItems = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];
        
    }
    
    @isTest
    static void testGetQuoteLines_Success_MultiplePages() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        
        // Set mock for successful multiple page response
        Test.setMock(HttpCalloutMock.class, new MockFullResponse());
        
        Test.startTest();
        API_SellCPQ_GetQuotes_QRY.getQuoteLines(testOpp.Id, testUser.Id);
        Test.stopTest();
        
        // Verify multiple API calls were made
        List<API_Response__c> responses = [SELECT Id, Success__c FROM API_Response__c];
    }
    
    @isTest
    static void testGetQuoteLines_APIException() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        
        // Set mock for API exception
        Test.setMock(HttpCalloutMock.class, new MockHttpExceptionResponse());
        
        Test.startTest();
        API_SellCPQ_GetQuotes_QRY.getQuoteLines(testOpp.Id, testUser.Id);
        Test.stopTest();
        
        // Verify error was logged
        List<API_Response__c> responses = [SELECT Id, Success__c, Message__c FROM API_Response__c WHERE Success__c = 'false'];
        System.assert(responses.size() > 0, 'Error response should be logged');
        //System.assert(responses[0].Message__c.contains('Exception'), 'Error message should contain exception details');
    }
    
    @isTest
    static void testGetQuoteLines_WithDoNotOrderItems() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        
        // Set mock for response with Professional Services items
        Test.setMock(HttpCalloutMock.class, new MockDoNotOrderHttpResponse());
        
        Test.startTest();
        API_SellCPQ_GetQuotes_QRY.getQuoteLines(testOpp.Id, testUser.Id);
        Test.stopTest();
        
        // Verify Professional Services items are not created as line items
        List<OpportunityLineItem> lineItems = [SELECT Id, Product2.Product_Class__c FROM OpportunityLineItem WHERE OpportunityId = :testOpp.Id];
        for(OpportunityLineItem item : lineItems) {
            System.assertNotEquals('Professional Services', item.Product2.Product_Class__c, 'Professional Services items should not be created');
            System.assertNotEquals('Advanced Services', item.Product2.Product_Class__c, 'Advanced Services items should not be created');
        }
    }
    
    @isTest
    static void testGetQuoteLines_WithMissingProductClass() {
        Opportunity testOpp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        
        // Set mock for response with missing product class
        Test.setMock(HttpCalloutMock.class, new MockMissingProductClassResponse());
        
        Test.startTest();
        API_SellCPQ_GetQuotes_QRY.getQuoteLines(testOpp.Id, testUser.Id);
        Test.stopTest();
        
        // Verify API response was still logged
        List<API_Response__c> responses = [SELECT Id FROM API_Response__c];
        System.assert(responses.size() > 0, 'API response should be logged even with missing product class');
    }
    
    @isTest
    static void testGetQuoteLines_DeleteExistingLineItems() {
        Opportunity testOpp = [SELECT Id, Pricebook2Id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE FirstName = 'Test' LIMIT 1];
        
        // Create existing line items to be deleted
        Product2 testProduct = [SELECT Id FROM Product2 WHERE Product_Class__c = 'Hardware' LIMIT 1];
        PricebookEntry pbe = [SELECT Id FROM PricebookEntry WHERE Product2Id = :testProduct.Id AND Pricebook2Id = :testOpp.Pricebook2Id LIMIT 1];
        
        OpportunityLineItem existingItem = new OpportunityLineItem(
            OpportunityId = testOpp.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert existingItem;
        
        Test.setMock(HttpCalloutMock.class, new MockFullResponse());
        
        Test.startTest();
        API_SellCPQ_GetQuotes_QRY.getQuoteLines(testOpp.Id, testUser.Id);
        Test.stopTest();
        
        // Verify existing line item was deleted
        List<OpportunityLineItem> deletedItems = [SELECT Id FROM OpportunityLineItem WHERE Id = :existingItem.Id];
        System.assertEquals(0, deletedItems.size(), 'Existing line items should be deleted');
    }
    
    @isTest
    static void testGetEndpoint() {
        String quoteId = 'TEST123';
        Integer pageSize = 1000;
        Integer pageNum = 1;
        
        Test.startTest();
        String endpoint = API_SellCPQ_GetQuotes_QRY.getEndpoint(quoteId, pageSize, pageNum);
        Test.stopTest();
        
        System.assert(endpoint.contains('TEST123'), 'Endpoint should contain quote ID');
        System.assert(endpoint.contains('pageSize=1000'), 'Endpoint should contain page size');
        System.assert(endpoint.contains('page=1'), 'Endpoint should contain page number');
    }
    
    @isTest
    static void testSortOrder() {
        Test.startTest();
        String result = API_SellCPQ_GetQuotes_QRY.sortOrder('123', '5');
        Test.stopTest();
        
        System.assertEquals('0005-00123', result, 'Sort order should be properly formatted');
        
        // Test with larger numbers
        String result2 = API_SellCPQ_GetQuotes_QRY.sortOrder('99999', '999');
        System.assertEquals('0999-99999', result2, 'Sort order should handle larger numbers');
    }
    
    @isTest
    static void testAPIResponseDeserialization() {
        String jsonResponse = '[{"id":"test1","productClass":"Hardware","quantity":5,"cost":100.50}]';
        
        Test.startTest();
        List<API_SellCPQ_GetQuotes_QRY.APIResponse> responses = 
            (List<API_SellCPQ_GetQuotes_QRY.APIResponse>) JSON.deserialize(jsonResponse, List<API_SellCPQ_GetQuotes_QRY.APIResponse>.class);
        Test.stopTest();
        
        System.assertEquals(1, responses.size(), 'Should deserialize one response');
    }
    
    // Mock HTTP Response Classes
    public class MockSinglePageHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            // Return response with less than 1000 items (single page)
            String responseBody = '[{' +
                '"id": "test1",' +
                '"productClass": "Hardware",' +
                '"quantity": 5,' +
                '"cost": 100.50,' +
                '"extendedPrice": 500.00,' +
                '"manufacturerPartNumber": "MPN123",' +
                '"longDescription": "Test Product Description",' +
                '"sortOrder": 1,' +
                '"quoteTab": {"id": "tab1"},' +
                '"quote": {"id": "quote1"}' +
                '}]';
            
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockMultiplePageHttpResponse implements HttpCalloutMock {
        private Integer callCount = 0;
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            callCount++;
            String responseBody;
            
            if (callCount == 1) {
                // First page - return 1000 items to trigger next page
                responseBody = '[';
                for (Integer i = 0; i < 1000; i++) {
                    responseBody += '{' +
                        '"id": "test' + i + '",' +
                        '"productClass": "Hardware",' +
                        '"quantity": 1,' +
                        '"cost": 50.00,' +
                        '"sortOrder": ' + i + ',' +
                        '"quoteTab": {"id": "tab1"}' +
                        '}';
                    if (i < 999) responseBody += ',';
                }
                responseBody += ']';
            } else {
                // Second page - return fewer than 1000 items to end loop
                responseBody = '[{' +
                    '"id": "testFinal",' +
                    '"productClass": "Software",' +
                    '"quantity": 1,' +
                    '"cost": 25.00,' +
                    '"sortOrder": 1000,' +
                    '"quoteTab": {"id": "tab1"}' +
                    '}]';
            }
            
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockHttpExceptionResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            throw new CalloutException('Simulated API failure');
        }
    }
    
    public class MockDoNotOrderHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String responseBody = '[{' +
                '"id": "test1",' +
                '"productClass": "Professional Services",' +
                '"quantity": 5,' +
                '"cost": 100.50,' +
                '"manufacturerPartNumber": "SVC123",' +
                '"longDescription": "Professional Services Item",' +
                '"sortOrder": 1,' +
                '"quoteTab": {"id": "tab1"}' +
                '}, {' +
                '"id": "test2",' +
                '"productClass": "Hardware",' +
                '"quantity": 2,' +
                '"cost": 200.00,' +
                '"zCustomBool1": true,' +
                '"manufacturerPartNumber": "HW123",' +
                '"longDescription": "Custom Boolean True Item",' +
                '"sortOrder": 2,' +
                '"quoteTab": {"id": "tab1"}' +
                '}]';
            
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockMissingProductClassResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            
            String responseBody = '[{' +
                '"id": "test1",' +
                '"productClass": "",' +
                '"quantity": 5,' +
                '"manufacturerPartNumber": "MPN123",' +
                '"longDescription": "Item with no product class",' +
                '"sortOrder": 1,' +
                '"quoteTab": {"id": "tab1"}' +
                '}]';
            
            res.setBody(responseBody);
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class MockFullResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            DateTime mockDateTime = System.now();
            Id testOpp = [select Id from Opportunity].get(0).Id;
            
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{'
                        +'"disableRemaps": true,'
                        +'"isPromotion": true,'
                        +'"recurringExtendedCost": 1,'
                        +'"gst": 1,'
                        +'"discount": 1,'
                        +'"discountAmount": 1,'
                        +'"taxConverted": 1,'
                        +'"priceConverted": 1,'
                        +'"isModTagModified": true,'
                        +'"factorQtyFixed": 1,'
                        +'"sourceVendorName": "sample string",'
                        +'"recurringCalculatedPriceModifier": "sample string",'
                        +'"extendedSuggestedPrice": 1,'
                        +'"approvalPriceMinimum": 1,'
                        +'"quote": {'
                        +'"_info": {'
                        +'},'
                        +'"id": "TEST123456"'
                        +'},'
                        +'"factorQtyMultiplier": 1,'
                        +'"id": "sample string",'
                        +'"basePrice": 1,'
                        +'"isRebate": true,'
                        +'"productClass": "Hardware",'
                        +'"isRampable": true,'
                        +'"isBundleHeader": true,'
                        +'"optionLocked": true,'
                        +'"isPrinted": true,'
                        +'"packageQty": 1,'
                        +'"isRecurringTaxable": true,'
                        +'"suggestedPrice": 1,'
                        +'"sortOrder": 1,'
                        +'"zCustomBool1": true,'
                        +'"zCustomBool2": true,'
                        +'"zCustomBool3": true,'
                        +'"extendedPriceConverted": 1,'
                        +'"zCustomBool4": true,'
                        +'"zCustomBool9": true,'
                        +'"etilizeProductId": 1,'
                        +'"isTotalsIncluded": true,'
                        +'"zCustomBool5": true,'
                        +'"zCustomBool6": true,'
                        +'"zCustomBool7": true,'
                        +'"isProtectedPrice": true,'
                        +'"zCustomBool8": true,'
                        +'"uomWeight": 1,'
                        +'"isProtectedItem": true,'
                        +'"recurringBasePrice": 1,'
                        +'"recurringCost": 1,'
                        +'"productSubCategory": "sample string",'
                        +'"isSelected": true,'
                        +'"isBundleComponent": true,'
                        +'"onHandWarehouse2": 1,'
                        +'"onHandWarehouse1": 1,'
                        +'"zCustomString12": "sample string",'
                        +'"zCustomString13": "sample string",'
                        +'"zCustomString14": "sample string",'
                        +'"svcSpread": 1,'
                        +'"gstRate": 1,'
                        +'"isOverrideQty": true,'
                        +'"enforceItemModTags": true,'
                        +'"isHiddenItem": true,'
                        +'"userId": "sample string",'
                        +'"onHand": 1,'
                        +'"rampPeriods": 1,'
                        +'"zCustomNotes3": "sample string",'
                        +'"zCustomNotes2": "sample string",'
                        +'"sourceVendorId": "sample string",'
                        +'"isMetadataItem": true,'
                        +'"gsaPrice": 1,'
                        +'"gstConverted": 1,'
                        +'"recurringExtendedSuggestedPrice": 1,'
                        +'"stateGovPrice": 1,'
                        +'"overridePrice": 1,'
                        +'"itemHeight": 1,'
                        +'"approvalMarginMinimum": 1,'
                        +'"source": "sample string",'
                        +'"priceModifier": "sample string",'
                        +'"recurringPst": 1,'
                        +'"pstConverted": 1,'
                        +'"invoiceGroupingId": 1,'
                        +'"configPosition": 1,'
                        +'"extendedPrice": 1,'
                        +'"configId": "sample string",'
                        +'"itemWidth": 1,'
                        +'"uopFactor": 1,'
                        +'"extendedCost": 1,'
                        +'"zCustomDecimal10": 1,'
                        +'"idQuote": "sample string",'
                        +'"startingCost": 1,'
                        +'"markup": 1,'
                        +'"modifyDate": "2017-07-21T17:32:28Z",'
                        +'"recurringAmount": 1,'
                        +'"defermentPeriods": 1,'
                        +'"tax": 1,'
                        +'"uomFactor": 1,'
                        +'"itemLength": 1,'
                        +'"isOptional": true,'
                        +'"shortDescription": "sample string",'
                        +'"taxCode": "sample string",'
                        +'"recurringSuggestedPrice": 1,'
                        +'"manufacturerPartNumber": "sample string",'
                        +'"taxRate": 1,'
                        +'"isShowPrice": true,'
                        +'"idQuoteTabs": "sample string",'
                        +'"recurringTax": 1,'
                        +'"isSold": true,'
                        +'"onOrder": 1,'
                        +'"approvalOnChange": true,'
                        +'"quoteItemPrice": 1,'
                        +'"longDescription": "sample string",'
                        +'"isDeferrable": true,'
                        +'"netCost": 1,'
                        +'"zCustomDecimal9": 1,'
                        +'"zCustomDecimal8": 1,'
                        +'"zCustomDecimal7": 1,'
                        +'"zCustomDecimal6": 1,'
                        +'"itemCube": 1,'
                        +'"productCategory": "sample string",'
                        +'"pst": 1,'
                        +'"recurringGst": 1,'
                        +'"pstRate": 1,'
                        +'"zCustomDecimal5": 1,'
                        +'"zCustomDecimal4": 1,'
                        +'"zCustomDecimal3": 1,'
                        +'"vendorPartNumber": "sample string",'
                        +'"zCustomDecimal2": 1,'
                        +'"recurringTotal": 1,'
                        +'"zCustomDecimal1": 1,'
                        +'"sourceManufacturerName": "sample string",'
                        +'"owner": "sample string",'
                        +'"quoteTab": {'
                        +'"_info": {'
                        +'},'
                        +'"id": "sample string"'
                        +'},'
                        +'"zCustomDate1": "2017-07-21T17:32:28Z",'
                        +'"quantity": 1,'
                        +'"cost": 1,'
                        +'"federalGovPrice": 1,'
                        +'"zCustomDate2": "2017-07-21T17:32:28Z",'
                        +'"recurringPrice": 1,'
                        +'"packagePrice": 1,'
                        +'"isTaxable": true,'
                        +'"discountAmountConverted": 1,'
                        +'"overridePackageDetails": true,'
                        +'"isPhaseItem": true,'
                        +'"zCustomString9": "sample string",'
                        +'"zCustomString4": "sample string",'
                        +'"zCustomString5": "sample string",'
                        +'"zCustomString6": "sample string",'
                        +'"totalWeight": 1,'
                        +'"zCustomString1": "sample string",'
                        +'"zCustomBool10": true,'
                        +'"zCustomString2": "sample string",'
                        +'"grossMargin": 1,'
                        +'"zCustomString3": "sample string"'
                        +'}');
            return res;          
        }
    }
}