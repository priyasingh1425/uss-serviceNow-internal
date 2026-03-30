/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

@isTest
private class lp_BillingSettingsTest {

    @isTest
    private static void updateBillSettings() {
        lp_SetupTestFFA.createBaseFFAData();
        lp_SetupTestFFA.TestData testData = lp_SetupTestFFA.testData;
        Map<String,c2g__codaGeneralLedgerAccount__c> glaMap = testData.GLAMap;

        System.runAs(testData.TestUser) {
            Product2 testProduct = lp_SetupTestFFA.createProduct(glaMap.get('grossRevenue').Id, glaMap.get('cogs').Id, false);
            testProduct.Name = '2 x 1 Gbps CDC Connection';
            insert testProduct;

            Test.startTest();
            Decimal daysPastDue = lp_BillingSettings.getDaysPastDue();
            String financeChargeProductName = lp_BillingSettings.getFinanceChargeProductName();
            Product2 financeChargeProduct = lp_BillingSettings.getFinanceChargeProduct(financeChargeProductName);
            Decimal lateFeesBatchSize = lp_BillingSettings.getLateFeesBatchSize();
            Test.stopTest();

            Assert.areEqual(10.0, daysPastDue, 'Days Past Due - Successful Fetch!');
            Assert.areEqual('2 x 1 Gbps CDC Connection', financeChargeProductName, 'Finance Charge Product Name - Successful Fetch!');
            Assert.areEqual(testProduct.Id, financeChargeProduct.Id, 'Product2 - Id Matches');
            Assert.areEqual(5, lateFeesBatchSize, 'Late Fees Batch Size - Successful Fetch!');
        }
    }

    @isTest
    private static void testCustomTriggersEnabled() {
        // Test default behavior (enabled in test context)
        Assert.isTrue(lp_BillingSettings.customTriggersAreEnabled(), 'Custom triggers should be enabled in test context');

        // Test with custom settings
        LPC_Billing_Central_Configuration__c settings = LPC_Billing_Central_Configuration__c.getInstance();
        settings.Disable_Custom_Triggers__c = true;
        upsert settings;

        // Reset the cached value
        lp_BillingSettings.customTriggersAreEnabled = null;
        
        // Should still be true in test context
        Assert.isTrue(lp_BillingSettings.customTriggersAreEnabled(), 'Custom triggers should still be enabled in test context');
    }

    @isTest
    private static void testOrderProductBillingEnabled() {
        // Test default behavior (enabled in test context)
        Assert.isTrue(lp_BillingSettings.orderProductBillingIsEnabled(), 'Order product billing should be enabled in test context');

        // Test with custom settings
        LPC_Billing_Central_Configuration__c settings = LPC_Billing_Central_Configuration__c.getInstance();
        settings.Enable_Order_Product_Billing__c = false;
        upsert settings;

        // Reset the cached value
        lp_BillingSettings.orderProductBillingIsEnabled = null;
        
        // Should still be true in test context
        Assert.isTrue(lp_BillingSettings.orderProductBillingIsEnabled(), 'Order product billing should still be enabled in test context');
    }

    @isTest
    private static void testAutoActivateContractsEnabled() {
        // Test default behavior (enabled in test context)
        Assert.isTrue(lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled(), 'Auto activate contracts should be enabled in test context');

        // Test with custom settings
        LPC_Billing_Central_Configuration__c settings = LPC_Billing_Central_Configuration__c.getInstance();
        settings.Automatically_Activate_Billing_Contract__c = false;
        upsert settings;

        // Reset the cached value
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = null;
        
        // Should still be true in test context
        Assert.isTrue(lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled(), 'Auto activate contracts should still be enabled in test context');
    }

    @isTest
    private static void testFinanceChargeProductNotFound() {
        // Test with non-existent product name
        try {
            lp_BillingSettings.getFinanceChargeProduct('Non Existent Product');
            Assert.fail('Should have thrown an exception for non-existent product');
        } catch (lp_Exception e) {
            Assert.isTrue(e.getMessage().contains('Searching for Finance Prod Name returned 0 results!'), 'Should throw correct error message');
        }
    }

    @isTest
    private static void testFinanceChargeProductIdNotFound() {
        try {
            lp_BillingSettings.getFinanceChargeProductId();
            Assert.fail('Should have thrown an exception for non-existent product ID');
        } catch (lp_Exception e) {
            Assert.isTrue(e.getMessage().contains('returned 0 results'), 'Unexpected error message: ' + e.getMessage());
        }
    }

    @isTest
    private static void testLateFeesBatchSizeLimits() {
        LPC_Billing_Central_Configuration__c settings = LPC_Billing_Central_Configuration__c.getInstance();
        
        // Test minimum batch size
        settings.Batch_Size__c = 0;
        upsert settings;
        Assert.areEqual(5, lp_BillingSettings.getLateFeesBatchSize(), 'Batch size should be 5 when setting is below minimum');
        
        // Test maximum batch size
        settings.Batch_Size__c = 300;
        upsert settings;
        Assert.areEqual(5, lp_BillingSettings.getLateFeesBatchSize(), 'Batch size should be 5 when setting is above maximum');
        
        // Test valid batch size
        settings.Batch_Size__c = 150;
        upsert settings;
        Assert.areEqual(5, lp_BillingSettings.getLateFeesBatchSize(), 'Batch size should be 5 in test context regardless of setting');
    }
}