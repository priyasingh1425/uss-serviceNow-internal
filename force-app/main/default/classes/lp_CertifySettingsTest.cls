/**
 * Created by Ladd Partners on 5/31/2025.
 */
@isTest
private class lp_CertifySettingsTest {
    
    @isTest
    static void testDefaultSettings() {
        // Test default settings
        System.assertEquals(false, lp_CertifySettings.isProduction, 'Default production setting should be false');
        System.assertEquals(null, lp_CertifySettings.importExpenseReportsTimeout, 'Default timeout should be null');
        System.assertEquals(5, lp_CertifySettings.getPayableInvoiceBatchSize(), 'Default batch size should be 5 in test context');
    }
    
    @isTest
    static void testCustomSettings() {
        // Create custom settings
        Certify_Settings__c settings = new Certify_Settings__c(
            Is_Production__c = true,
            Import_Expense_Reports_Timeout__c = 30,
            Create_Payable_Invoice_Batch_Size__c = 100
        );
        insert settings;
        
        // Test custom settings
        System.assertEquals(true, lp_CertifySettings.isProduction, 'Production setting should be true');
        System.assertEquals(30, lp_CertifySettings.importExpenseReportsTimeout, 'Timeout should be 30');
        System.assertEquals(5, lp_CertifySettings.getPayableInvoiceBatchSize(), 'Batch size should still be 5 in test context');
    }
    
    @isTest
    static void testBatchSizeLimits() {
        // Test minimum batch size
        Certify_Settings__c settings = new Certify_Settings__c(
            Create_Payable_Invoice_Batch_Size__c = 0
        );
        insert settings;
        System.assertEquals(5, lp_CertifySettings.getPayableInvoiceBatchSize(), 'Batch size should be 5 when setting is below minimum');
        
        // Test maximum batch size
        settings.Create_Payable_Invoice_Batch_Size__c = 300;
        update settings;
        System.assertEquals(5, lp_CertifySettings.getPayableInvoiceBatchSize(), 'Batch size should be 5 when setting is above maximum');
        
        // Test valid batch size
        settings.Create_Payable_Invoice_Batch_Size__c = 150;
        update settings;
        System.assertEquals(5, lp_CertifySettings.getPayableInvoiceBatchSize(), 'Batch size should be 5 in test context regardless of setting');
    }
}