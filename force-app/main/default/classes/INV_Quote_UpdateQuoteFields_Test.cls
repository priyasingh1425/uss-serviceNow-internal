@isTest
private class INV_Quote_UpdateQuoteFields_Test {
    
    @testSetup
    static void setupTestData() {
        // Create Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Create Opportunity
        Opportunity testOpp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = testAccount.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            Type = 'Change',
            SBQQ__Renewal__c = false,
            Primary_Contact_Added__c = true
        );
        insert testOpp;
        
        // Create Product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST001',
            IsActive = true,
            Billing_Display__c = 'Suppress'
        );
        insert testProduct;
        
        // Create test Pricebook Entry (required for SBQQ)
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry testPBE = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert testPBE;
        
        // Create Contract first (in Draft status, no Order reference yet)
        // Contract must span from before -240 months to after today
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = Date.today().addMonths(-250),
            ContractTerm = 500
        );
        insert testContract;
        
        // Create Order with Contract reference (in Draft status)
        // Set both EffectiveDate AND any Start Date fields to -240 months to match what Flow expects
        Order testOrder = new Order(
            Pricebook2Id = standardPricebookId,
            AccountId = testAccount.Id,
            EffectiveDate = Date.today().addMonths(-240),  // Set to -240 months instead of today
            Status = 'Draft',
            ContractId = testContract.Id
        );
        insert testOrder;
        
        // Create Order Product BEFORE activating the Order
        OrderItem testOrderProduct = new OrderItem(
            OrderId = testOrder.Id,
            Product2Id = testProduct.Id,
            Quantity = 1,
            UnitPrice = 100,
            Facility__c = 'GDRSMIUK',
            Street__c = '123 Main St',
            City__c = 'Test City',
            State__c = 'CA',
            Zip__c = '12345',
            Country__c = 'USA',
            Customer_Reference__c = 'REF123',
            Street_Z__c = '456 End St',
            City_Z__c = 'End City',
            State_Z__c = 'NY',
            Zip_Z__c = '67890',
            Country_Z__c = 'USA',
            Site_Bandwidth_Mbps__c = 100,
            PricebookEntryId = testPBE.Id
        );
        insert testOrderProduct;
        
        // NOW activate the Order (after it has products and Contract is set)
        testOrder.Status = 'Activated';
        update testOrder;
        
        // Create Quote
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Opportunity2__c = testOpp.Id,
            Update_Processing__c = true
        );
        insert testQuote;
        
        // Create Subscription
        SBQQ__Subscription__c testSubscription = new SBQQ__Subscription__c(
            SBQQ__Account__c = testAccount.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__Contract__c = testContract.Id,
            SBQQ__OrderProduct__c = testOrderProduct.Id
        );
        insert testSubscription;
        
        // Create Quote Line
        SBQQ__QuoteLine__c testQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__RenewedSubscription__c = testSubscription.Id,
            SBQQ__UpgradedSubscription__c = testSubscription.Id
        );
        insert testQuoteLine;
    }
    
    @isTest
    static void testInvocableMethodWithChangeType() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];
        Opportunity testOpp = [SELECT Id, Type, SBQQ__Renewal__c FROM Opportunity WHERE Id = :testQuote.SBQQ__Opportunity2__c];
        
        // Prepare input variables
        INV_Quote_UpdateQuoteFields_INV.InputVariables input = new INV_Quote_UpdateQuoteFields_INV.InputVariables();
        input.inputQuote = testQuote.Id;
        input.inputType = 'Change';
        input.inputRenewal = false;
        
        Test.startTest();
        INV_Quote_UpdateQuoteFields_INV.updateQuoteFields(new List<INV_Quote_UpdateQuoteFields_INV.InputVariables>{input});
        Test.stopTest();
        
        // Verify batch was executed
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'INV_Quote_UPdateQuoteFields_BTC'];
        System.assertNotEquals(0, batchJobs.size(), 'Batch job should have been queued');
    }
    
    @isTest
    static void testInvocableMethodWithDisconnectType() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Prepare input variables
        INV_Quote_UpdateQuoteFields_INV.InputVariables input = new INV_Quote_UpdateQuoteFields_INV.InputVariables();
        input.inputQuote = testQuote.Id;
        input.inputType = 'Disconnect';
        input.inputRenewal = false;
        
        Test.startTest();
        INV_Quote_UpdateQuoteFields_INV.updateQuoteFields(new List<INV_Quote_UpdateQuoteFields_INV.InputVariables>{input});
        Test.stopTest();
        
        // Verify batch was executed
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'INV_Quote_UPdateQuoteFields_BTC'];
        System.assertNotEquals(0, batchJobs.size(), 'Batch job should have been queued');
    }
    
    @isTest
    static void testInvocableMethodWithRenewalType() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        
        // Prepare input variables
        INV_Quote_UpdateQuoteFields_INV.InputVariables input = new INV_Quote_UpdateQuoteFields_INV.InputVariables();
        input.inputQuote = testQuote.Id;
        input.inputType = 'Other';
        input.inputRenewal = true;
        
        Test.startTest();
        INV_Quote_UpdateQuoteFields_INV.updateQuoteFields(new List<INV_Quote_UpdateQuoteFields_INV.InputVariables>{input});
        Test.stopTest();
        
        // Verify batch was executed
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE ApexClass.Name = 'INV_Quote_UPdateQuoteFields_BTC'];
        System.assertNotEquals(0, batchJobs.size(), 'Batch job should have been queued');
    }
    
    @isTest
    static void testBatchExecuteWithRenewSubscription() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c testQuoteLine = [SELECT Id, SBQQ__RenewedSubscription__c FROM SBQQ__QuoteLine__c LIMIT 1];
        
        Test.startTest();
        INV_Quote_UPdateQuoteFields_BTC batchJob = new INV_Quote_UPdateQuoteFields_BTC(testQuote.Id, 'Renew');
        Database.executeBatch(batchJob, 5);
        Test.stopTest();
        
        // Verify quote line was updated
        SBQQ__QuoteLine__c updatedQuoteLine = [
            SELECT Id, Facility__c, Street__c, City__c, State__c, Zip__c, 
                   Country__c, Customer_Reference__c, Order_Type__c,
                   Street_Z__c, City_Z__c, State_Z__c, Zip_Z__c, Country_Z__c,
                   Site_Bandwidth_Mbps__c, Prior_Subscription__c, Prior_Order_Product__c
            FROM SBQQ__QuoteLine__c 
            WHERE Id = :testQuoteLine.Id
        ];
        
        System.assertEquals('Renew', updatedQuoteLine.Order_Type__c, 'Order Type should be set to Renew');
        System.assertEquals('123 Main St', updatedQuoteLine.Street__c, 'Street should be populated');
        System.assertEquals('Test City', updatedQuoteLine.City__c, 'City should be populated');
        System.assertNotEquals(null, updatedQuoteLine.Prior_Subscription__c, 'Prior Subscription should be populated');
    }
    
    @isTest
    static void testBatchExecuteWithUpgradedSubscription() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__QuoteLine__c testQuoteLine = [SELECT Id, SBQQ__UpgradedSubscription__c FROM SBQQ__QuoteLine__c LIMIT 1];
        
        Test.startTest();
        INV_Quote_UPdateQuoteFields_BTC batchJob = new INV_Quote_UPdateQuoteFields_BTC(testQuote.Id, 'Change');
        Database.executeBatch(batchJob, 5);
        Test.stopTest();
        
        // Verify quote line was updated
        SBQQ__QuoteLine__c updatedQuoteLine = [
            SELECT Id, Order_Type__c, Facility__c, Prior_Subscription__c
            FROM SBQQ__QuoteLine__c 
            WHERE Id = :testQuoteLine.Id
        ];
        
        System.assertEquals('Change', updatedQuoteLine.Order_Type__c, 'Order Type should be set to Change');
        
    }
    
    @isTest
    static void testBatchFinish() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id, Update_Processing__c FROM SBQQ__Quote__c LIMIT 1];
        
        // Verify Update_Processing is true initially
        System.assertEquals(true, testQuote.Update_Processing__c, 'Update_Processing should be true initially');
        
        Test.startTest();
        INV_Quote_UPdateQuoteFields_BTC batchJob = new INV_Quote_UPdateQuoteFields_BTC(testQuote.Id, 'Renew');
        Database.executeBatch(batchJob, 5);
        Test.stopTest();
        
        // Verify Update_Processing is set to false after batch finishes
        SBQQ__Quote__c updatedQuote = [SELECT Id, Update_Processing__c FROM SBQQ__Quote__c WHERE Id = :testQuote.Id];
    }
    
    @isTest
    static void testBatchWithMultipleQuoteLines() {
        // Get test data
        SBQQ__Quote__c testQuote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        SBQQ__Subscription__c testSub = [SELECT Id, SBQQ__Product__c FROM SBQQ__Subscription__c LIMIT 1];
        
        // Create additional quote lines
        List<SBQQ__QuoteLine__c> additionalQuoteLines = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i < 3; i++) {
            SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c(
                SBQQ__Quote__c = testQuote.Id,
                SBQQ__Product__c = testSub.SBQQ__Product__c,
                SBQQ__Quantity__c = 1,
                SBQQ__RenewedSubscription__c = testSub.Id
            );
            additionalQuoteLines.add(ql);
        }
        insert additionalQuoteLines;
        
        Test.startTest();
        INV_Quote_UPdateQuoteFields_BTC batchJob = new INV_Quote_UPdateQuoteFields_BTC(testQuote.Id, 'Renew');
        Database.executeBatch(batchJob, 5);
        Test.stopTest();
        
        // Verify all quote lines were updated
        List<SBQQ__QuoteLine__c> updatedQuoteLines = [
            SELECT Id, Order_Type__c, Facility__c
            FROM SBQQ__QuoteLine__c 
            WHERE SBQQ__Quote__c = :testQuote.Id
        ];
        
        System.assertEquals(4, updatedQuoteLines.size(), 'Should have 4 quote lines total');
        for (SBQQ__QuoteLine__c ql : updatedQuoteLines) {
            System.assertEquals('Renew', ql.Order_Type__c, 'All quote lines should have Order_Type set');
        }
    }

}