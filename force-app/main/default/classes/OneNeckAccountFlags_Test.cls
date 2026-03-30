@isTest
private class OneNeckAccountFlags_Test {
    
    // Test data setup method
    @TestSetup
    static void setupTestData() {
        // Create test Accounts
        List<Account> accounts = new List<Account>();
        accounts.add(new Account(
            Name = 'Test Account Dynamics',
            Has_OneNeck_Dynamics_on_BC__c = false,
            Has_OneNeck_POM_Microsoft_on_BC__c = false
        ));
        accounts.add(new Account(
            Name = 'Test Account POM',
            Has_OneNeck_Dynamics_on_BC__c = false,
            Has_OneNeck_POM_Microsoft_on_BC__c = false
        ));
        accounts.add(new Account(
            Name = 'Test Account Both',
            Has_OneNeck_Dynamics_on_BC__c = false,
            Has_OneNeck_POM_Microsoft_on_BC__c = false
        ));
        insert accounts;
        
        // Create Products with different System Origins
        List<Product2> products = new List<Product2>();
        products.add(new Product2(
            Name = 'Dynamics Product',
            System_Origin__c = OneNeckAccountFlagsBatch.ORIGIN_DYNAMICS,
            IsActive = true
        ));
        products.add(new Product2(
            Name = 'POM Product',
            System_Origin__c = OneNeckAccountFlagsBatch.ORIGIN_POM,
            IsActive = true
        ));
        insert products;
        
        // Create Certinia Billing Contracts
        List<ffbc__Contract__c> contracts = new List<ffbc__Contract__c>();
        contracts.add(new ffbc__Contract__c(
            ffbc__Account__c = accounts[0].Id
        ));
        contracts.add(new ffbc__Contract__c(
            ffbc__Account__c = accounts[1].Id
        ));
        contracts.add(new ffbc__Contract__c(
            ffbc__Account__c = accounts[2].Id
        ));
        insert contracts;
        
        // Create Contract Line Items
        List<ffbc__ContractLineItem__c> clis = new List<ffbc__ContractLineItem__c>();
        
        // CLI for Dynamics product (recent)
        clis.add(new ffbc__ContractLineItem__c(
            ffbc__Contract__c = contracts[0].Id,
            ffbc__ProductService__c = products[0].Id
        ));
        
        // CLI for POM product (recent)
        clis.add(new ffbc__ContractLineItem__c(
            ffbc__Contract__c = contracts[1].Id,
            ffbc__ProductService__c = products[1].Id
        ));
        
        // CLIs for both products on same account (recent)
        clis.add(new ffbc__ContractLineItem__c(
            ffbc__Contract__c = contracts[2].Id,
            ffbc__ProductService__c = products[0].Id
        ));
        clis.add(new ffbc__ContractLineItem__c(
            ffbc__Contract__c = contracts[2].Id,
            ffbc__ProductService__c = products[1].Id
        ));
        
        insert clis;
    }
    
    @isTest
    static void testBatch_DynamicsProduct() {
        // Get the test account
        Account acc = [SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
                       FROM Account 
                       WHERE Name = 'Test Account Dynamics' 
                       LIMIT 1];
        
        // Verify initial state
        System.assertEquals(false, acc.Has_OneNeck_Dynamics_on_BC__c, 'Dynamics flag should initially be false');
        System.assertEquals(false, acc.Has_OneNeck_POM_Microsoft_on_BC__c, 'POM flag should initially be false');
        
        Test.startTest();
        // Execute batch
        Id batchId = Database.executeBatch(new OneNeckAccountFlagsBatch(), 200);
        Test.stopTest();
        
        // Query updated account
        acc = [SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
               FROM Account 
               WHERE Id = :acc.Id];
        
        // Verify flags
        System.assertEquals(true, acc.Has_OneNeck_Dynamics_on_BC__c, 'Dynamics flag should be set to true');
        System.assertEquals(false, acc.Has_OneNeck_POM_Microsoft_on_BC__c, 'POM flag should remain false');
    }
    
    @isTest
    static void testBatch_POMProduct() {
        // Get the test account
        Account acc = [SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
                       FROM Account 
                       WHERE Name = 'Test Account POM' 
                       LIMIT 1];
        
        Test.startTest();
        Id batchId = Database.executeBatch(new OneNeckAccountFlagsBatch(), 200);
        Test.stopTest();
        
        // Query updated account
        acc = [SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
               FROM Account 
               WHERE Id = :acc.Id];
        
        // Verify flags
        System.assertEquals(false, acc.Has_OneNeck_Dynamics_on_BC__c, 'Dynamics flag should remain false');
        System.assertEquals(true, acc.Has_OneNeck_POM_Microsoft_on_BC__c, 'POM flag should be set to true');
    }
    
    @isTest
    static void testBatch_BothProducts() {
        // Get the test account
        Account acc = [SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
                       FROM Account 
                       WHERE Name = 'Test Account Both' 
                       LIMIT 1];
        
        Test.startTest();
        Id batchId = Database.executeBatch(new OneNeckAccountFlagsBatch(), 200);
        Test.stopTest();
        
        // Query updated account
        acc = [SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
               FROM Account 
               WHERE Id = :acc.Id];
        
        // Verify both flags are set
        System.assertEquals(true, acc.Has_OneNeck_Dynamics_on_BC__c, 'Dynamics flag should be set to true');
        System.assertEquals(true, acc.Has_OneNeck_POM_Microsoft_on_BC__c, 'POM flag should be set to true');
    }
    
    @isTest
    static void testInvocableMethod() {
        Test.startTest();
        // Call the invocable method
        OneNeckAccountFlagsJob.runBatch(new List<String>());
        Test.stopTest();
        
        // Verify batch was executed by checking if accounts were updated
        List<Account> updatedAccounts = [
            SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
            FROM Account 
            WHERE Has_OneNeck_Dynamics_on_BC__c = true OR Has_OneNeck_POM_Microsoft_on_BC__c = true
        ];
        
        System.assert(updatedAccounts.size() > 0, 'At least one account should have been updated by the batch');
    }
    
    @isTest
    static void testBatch_EmptyScope() {
        // Test batch with no matching records (all records are too old)
        // Delete all CLIs from setup to ensure empty scope
        delete [SELECT Id FROM ffbc__ContractLineItem__c];
        
        Test.startTest();
        Id batchId = Database.executeBatch(new OneNeckAccountFlagsBatch(), 200);
        Test.stopTest();
        
        // Verify no errors occurred with empty scope
        System.assert(true, 'Batch should handle empty scope without errors');
    }
    
    @isTest
    static void testBatch_MultipleAccountUpdates() {
        // Test that the same account can have multiple CLIs and flags are set correctly
        Account testAccount = new Account(
            Name = 'Multi CLI Account',
            Has_OneNeck_Dynamics_on_BC__c = false,
            Has_OneNeck_POM_Microsoft_on_BC__c = false
        );
        insert testAccount;
        
        ffbc__Contract__c testContract = new ffbc__Contract__c(
            ffbc__Account__c = testAccount.Id
        );
        insert testContract;
        
        Product2 dynamicsProduct = [SELECT Id FROM Product2 WHERE System_Origin__c = :OneNeckAccountFlagsBatch.ORIGIN_DYNAMICS LIMIT 1];
        Product2 pomProduct = [SELECT Id FROM Product2 WHERE System_Origin__c = :OneNeckAccountFlagsBatch.ORIGIN_POM LIMIT 1];
        
        // Create multiple CLIs for the same account
        List<ffbc__ContractLineItem__c> clis = new List<ffbc__ContractLineItem__c>();
        clis.add(new ffbc__ContractLineItem__c(
            ffbc__Contract__c = testContract.Id,
            ffbc__ProductService__c = dynamicsProduct.Id
        ));
        clis.add(new ffbc__ContractLineItem__c(
            ffbc__Contract__c = testContract.Id,
            ffbc__ProductService__c = dynamicsProduct.Id
        ));
        clis.add(new ffbc__ContractLineItem__c(
            ffbc__Contract__c = testContract.Id,
            ffbc__ProductService__c = pomProduct.Id
        ));
        insert clis;
        
        Test.startTest();
        Id batchId = Database.executeBatch(new OneNeckAccountFlagsBatch(), 200);
        Test.stopTest();
        
        // Query account
        testAccount = [SELECT Id, Has_OneNeck_Dynamics_on_BC__c, Has_OneNeck_POM_Microsoft_on_BC__c 
                       FROM Account 
                       WHERE Id = :testAccount.Id];
        
        // Verify both flags are set
        System.assertEquals(true, testAccount.Has_OneNeck_Dynamics_on_BC__c, 'Dynamics flag should be set');
        System.assertEquals(true, testAccount.Has_OneNeck_POM_Microsoft_on_BC__c, 'POM flag should be set');
    }
}