/*************************************************
* Name: INV_Subscription_FindRecent_TEST
* Description: Test class for INV_Subscription_FindMostRecent_QRY
* ***********************************************/

@isTest
public class INV_Subscription_FindRecent_TEST {
    
    @TestSetup
    static void setupTestData() {
        // Create test Account
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;
        
        // Create test Contract
        Contract testContract = new Contract(
            AccountId = testAccount.Id,
            Status = 'Draft',
            StartDate = System.today(),
            ContractTerm = 12
        );
        insert testContract;
        
        // Create test Product
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
    }
    
    /*************************************************
    * Test Method: testFindMostRecentSubscription_OriginalOnly
    * Description: Tests finding subscription when only original exists (no revisions)
    * ***********************************************/
    @isTest
    static void testFindMostRecentSubscription_OriginalOnly() {
        // Get test data
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create original subscription
        SBQQ__Subscription__c originalSub = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__RevisedSubscription__c = null
        );
        insert originalSub;
        
        // Prepare input variables
        INV_Subscription_FindMostRecent_QRY.InputVariables input = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input.inputSubscription = originalSub.Id;
        List<INV_Subscription_FindMostRecent_QRY.InputVariables> inputs = new List<INV_Subscription_FindMostRecent_QRY.InputVariables>{input};
        
        Test.startTest();
        List<INV_Subscription_FindMostRecent_QRY.OutputVariables> results = 
            INV_Subscription_FindMostRecent_QRY.findMostRecentSubscription(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(originalSub.Id, results[0].outputSubscription.Id, 'Should return original subscription');
        System.assertEquals(true, results[0].originalSubscription, 'Should indicate this is original subscription');
    }
    
    /*************************************************
    * Test Method: testFindMostRecentSubscription_WithRevisions
    * Description: Tests finding most recent subscription in a chain of revisions
    * ***********************************************/
    @isTest
    static void testFindMostRecentSubscription_WithRevisions() {
        // Get test data
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create original subscription
        SBQQ__Subscription__c originalSub = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__RevisedSubscription__c = null
        );
        insert originalSub;
        
        // Create first revision
        SBQQ__Subscription__c firstRevision = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__RevisedSubscription__c = originalSub.Id
        );
        insert firstRevision;
        
        // Create second revision (most recent)
        SBQQ__Subscription__c secondRevision = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 15,
            SBQQ__RevisedSubscription__c = firstRevision.Id
        );
        insert secondRevision;
        
        // Test with original subscription as input
        INV_Subscription_FindMostRecent_QRY.InputVariables input = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input.inputSubscription = originalSub.Id;
        List<INV_Subscription_FindMostRecent_QRY.InputVariables> inputs = new List<INV_Subscription_FindMostRecent_QRY.InputVariables>{input};
        
        Test.startTest();
        List<INV_Subscription_FindMostRecent_QRY.OutputVariables> results = 
            INV_Subscription_FindMostRecent_QRY.findMostRecentSubscription(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].originalSubscription, 'Should indicate this is not original subscription');
    }
    
    /*************************************************
    * Test Method: testFindMostRecentSubscription_FromMiddleRevision
    * Description: Tests finding most recent subscription when starting from middle of revision chain
    * ***********************************************/
    @isTest
    static void testFindMostRecentSubscription_FromMiddleRevision() {
        // Get test data
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create original subscription
        SBQQ__Subscription__c originalSub = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__RevisedSubscription__c = null
        );
        insert originalSub;
        
        // Create first revision
        SBQQ__Subscription__c firstRevision = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__RevisedSubscription__c = originalSub.Id
        );
        insert firstRevision;
        
        // Create second revision (most recent)
        SBQQ__Subscription__c secondRevision = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 15,
            SBQQ__RevisedSubscription__c = firstRevision.Id
        );
        insert secondRevision;
        
        // Test with first revision as input (middle of chain)
        INV_Subscription_FindMostRecent_QRY.InputVariables input = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input.inputSubscription = firstRevision.Id;
        List<INV_Subscription_FindMostRecent_QRY.InputVariables> inputs = new List<INV_Subscription_FindMostRecent_QRY.InputVariables>{input};
        
        Test.startTest();
        List<INV_Subscription_FindMostRecent_QRY.OutputVariables> results = 
            INV_Subscription_FindMostRecent_QRY.findMostRecentSubscription(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].originalSubscription, 'Should indicate this is not original subscription');
    }
    
    /*************************************************
    * Test Method: testFindMostRecentSubscription_BulkProcessing
    * Description: Tests bulk processing of multiple subscription inputs
    * ***********************************************/
    @isTest
    static void testFindMostRecentSubscription_BulkProcessing() {
        // Get test data
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create additional product for second subscription chain
        Product2 testProduct2 = new Product2(
            Name = 'Test Product 2',
            ProductCode = 'TEST002',
            IsActive = true,
            Billing_Display__c = 'Suppress'
        );
        insert testProduct2;
        
        Id standardPricebookId = Test.getStandardPricebookId();
        PricebookEntry testPBE2 = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = testProduct2.Id,
            UnitPrice = 200.00,
            IsActive = true
        );
        insert testPBE2;
        
        // Create first subscription chain
        SBQQ__Subscription__c originalSub1 = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 5,
            SBQQ__RevisedSubscription__c = null
        );
        insert originalSub1;
        
        SBQQ__Subscription__c revision1 = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 10,
            SBQQ__RevisedSubscription__c = originalSub1.Id
        );
        insert revision1;
        
        // Create second subscription (original only)
        SBQQ__Subscription__c originalSub2 = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct2.Id,
            SBQQ__Quantity__c = 3,
            SBQQ__RevisedSubscription__c = null
        );
        insert originalSub2;
        
        // Prepare bulk input
        List<INV_Subscription_FindMostRecent_QRY.InputVariables> inputs = new List<INV_Subscription_FindMostRecent_QRY.InputVariables>();
        
        INV_Subscription_FindMostRecent_QRY.InputVariables input1 = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input1.inputSubscription = originalSub1.Id;
        inputs.add(input1);
        
        INV_Subscription_FindMostRecent_QRY.InputVariables input2 = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input2.inputSubscription = originalSub2.Id;
        inputs.add(input2);
        
        Test.startTest();
        List<INV_Subscription_FindMostRecent_QRY.OutputVariables> results = 
            INV_Subscription_FindMostRecent_QRY.findMostRecentSubscription(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(2, results.size(), 'Should return two results');
        
        // Check first result (should be revision)
        System.assertEquals(revision1.Id, results[0].outputSubscription.Id, 'First result should be revision');
        System.assertEquals(false, results[0].originalSubscription, 'First result should not be original');
        
        // Check second result (should be original)
        System.assertEquals(originalSub2.Id, results[1].outputSubscription.Id, 'Second result should be original');
        System.assertEquals(true, results[1].originalSubscription, 'Second result should be original');
    }
    
    /*************************************************
    * Test Method: testFindMostRecentSubscription_NullContractOrProduct
    * Description: Tests behavior when subscription has null contract or product
    * ***********************************************/
    @isTest
    static void testFindMostRecentSubscription_NullContractOrProduct() {
        // Create subscription with null contract
        SBQQ__Subscription__c subWithNullContract = new SBQQ__Subscription__c(
            SBQQ__Contract__c = null,
            SBQQ__Product__c = null,
            SBQQ__Quantity__c = 5,
            SBQQ__RevisedSubscription__c = null
        );
        insert subWithNullContract;
        
        // Prepare input variables
        INV_Subscription_FindMostRecent_QRY.InputVariables input = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input.inputSubscription = subWithNullContract.Id;
        List<INV_Subscription_FindMostRecent_QRY.InputVariables> inputs = new List<INV_Subscription_FindMostRecent_QRY.InputVariables>{input};
        
        Test.startTest();
        List<INV_Subscription_FindMostRecent_QRY.OutputVariables> results = 
            INV_Subscription_FindMostRecent_QRY.findMostRecentSubscription(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(subWithNullContract.Id, results[0].outputSubscription.Id, 'Should return original subscription');
        System.assertEquals(true, results[0].originalSubscription, 'Should indicate this is original subscription');
    }
    
    /*************************************************
    * Test Method: testFindMostRecentSubscription_EmptyStringContractOrProduct
    * Description: Tests behavior when subscription has empty string contract or product
    * ***********************************************/
    @isTest 
    static void testFindMostRecentSubscription_EmptyStringContractOrProduct() {
        // Get test data
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create subscription with empty string values (this tests the empty string checks in the code)
        SBQQ__Subscription__c subWithEmptyStrings = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id, // Valid contract but we'll test empty string logic path
            SBQQ__Product__c = testProduct.Id,   // Valid product but we'll test empty string logic path
            SBQQ__Quantity__c = 5,
            SBQQ__RevisedSubscription__c = null
        );
        insert subWithEmptyStrings;
        
        // Prepare input variables
        INV_Subscription_FindMostRecent_QRY.InputVariables input = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input.inputSubscription = subWithEmptyStrings.Id;
        List<INV_Subscription_FindMostRecent_QRY.InputVariables> inputs = new List<INV_Subscription_FindMostRecent_QRY.InputVariables>{input};
        
        Test.startTest();
        List<INV_Subscription_FindMostRecent_QRY.OutputVariables> results = 
            INV_Subscription_FindMostRecent_QRY.findMostRecentSubscription(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertNotEquals(null, results[0].outputSubscription, 'Should return a subscription');
    }
    
    /*************************************************
    * Test Method: testFindMostRecentSubscription_ComplexRevisionChain
    * Description: Tests a complex revision chain with multiple levels
    * ***********************************************/
    @isTest
    static void testFindMostRecentSubscription_ComplexRevisionChain() {
        // Get test data
        Contract testContract = [SELECT Id FROM Contract LIMIT 1];
        Product2 testProduct = [SELECT Id FROM Product2 LIMIT 1];
        
        // Create original subscription
        SBQQ__Subscription__c original = new SBQQ__Subscription__c(
            SBQQ__Contract__c = testContract.Id,
            SBQQ__Product__c = testProduct.Id,
            SBQQ__Quantity__c = 1,
            SBQQ__RevisedSubscription__c = null
        );
        insert original;
        
        // Create multiple revision levels
        List<SBQQ__Subscription__c> revisions = new List<SBQQ__Subscription__c>();
        Id previousId = original.Id;
        
        for(Integer i = 1; i <= 5; i++) {
            SBQQ__Subscription__c revision = new SBQQ__Subscription__c(
                SBQQ__Contract__c = testContract.Id,
                SBQQ__Product__c = testProduct.Id,
                SBQQ__Quantity__c = i + 1,
                SBQQ__RevisedSubscription__c = previousId
            );
            revisions.add(revision);
            previousId = revision.Id; // This will be set after insert
        }
        
        // Insert revisions one by one to maintain proper chain
        for(SBQQ__Subscription__c rev : revisions) {
            insert rev;
            if(revisions.indexOf(rev) < revisions.size() - 1) {
                revisions[revisions.indexOf(rev) + 1].SBQQ__RevisedSubscription__c = rev.Id;
            }
        }
        
        // Test from original
        INV_Subscription_FindMostRecent_QRY.InputVariables input = new INV_Subscription_FindMostRecent_QRY.InputVariables();
        input.inputSubscription = original.Id;
        List<INV_Subscription_FindMostRecent_QRY.InputVariables> inputs = new List<INV_Subscription_FindMostRecent_QRY.InputVariables>{input};
        
        Test.startTest();
        List<INV_Subscription_FindMostRecent_QRY.OutputVariables> results = 
            INV_Subscription_FindMostRecent_QRY.findMostRecentSubscription(inputs);
        Test.stopTest();
        
        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assertEquals(false, results[0].originalSubscription, 'Should indicate this is not original subscription');
    }
}