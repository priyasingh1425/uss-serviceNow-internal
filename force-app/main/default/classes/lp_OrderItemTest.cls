/**
 * Created by Ladd Partners on 6/1/2025.
 */

@isTest
private class lp_OrderItemTest {

    @isTest
    static void testProcessBilling() {
        lp_BillingSetupTest setupTest = new lp_BillingSetupTest();
        OrderItem orderItem = setupTest.setupOrderProduct(false);
        Set<Id> orderItemIds = new Set<Id>{ orderItem.Id };

        Test.startTest();
        lp_OrderItem.processBilling(orderItemIds);
        Test.stopTest();

        // Verify async jobs were created
        List<Async_Job_Staging__c> jobs = [SELECT Id FROM Async_Job_Staging__c];
        Assert.isFalse(jobs.isEmpty(), 'Async jobs should be created');
    }

    @isTest
    static void testGetSoftDateName() {
        Test.startTest();
        // Test Monthly billing frequency
        String monthlySoftDate = lp_OrderItem.getSoftDateName(lp_OrderItem.BILLING_FREQUENCY_MONTHLY);
        Assert.areEqual(lp_SoftDate.NAME_MONTH_BEGINNING, monthlySoftDate, 'Monthly soft date should match');

        // Test Annual billing frequency
        String annualSoftDate = lp_OrderItem.getSoftDateName(lp_OrderItem.BILLING_FREQUENCY_ANNUAL);
        Assert.areEqual(lp_SoftDate.NAME_YEAR_BEGINNING, annualSoftDate, 'Annual soft date should match');

        // Test Quarterly billing frequency
        String quarterlySoftDate = lp_OrderItem.getSoftDateName(lp_OrderItem.BILLING_FREQUENCY_QUARTERLY);
        Assert.areEqual(lp_SoftDate.NAME_QUARTER_BEGINNING, quarterlySoftDate, 'Quarterly soft date should match');

        // Test Semiannual billing frequency
        String semiannualSoftDate = lp_OrderItem.getSoftDateName(lp_OrderItem.BILLING_FREQUENCY_SEMIANNUAL);
        Assert.areEqual(lp_SoftDate.NAME_HALF_YEAR_BEGINNING, semiannualSoftDate, 'Semiannual soft date should match');

        // Test null billing frequency
        String nullSoftDate = lp_OrderItem.getSoftDateName(null);
        Assert.isNull(nullSoftDate, 'Null billing frequency should return null');
        Test.stopTest();
    }

    @isTest
    static void testUpdateBillingContractReference() {
        lp_BillingSetupTest setupTest = new lp_BillingSetupTest();
        OrderItem orderItem = setupTest.setupOrderProductForBillingContract();
        
        // Create test billing contract lines
        List<ffbc__ContractLineItem__c> contractLines = new List<ffbc__ContractLineItem__c>();
        
        ffbc__ContractLineItem__c mrcLine = new ffbc__ContractLineItem__c();
        mrcLine.ffbc__BillingType__c = lp_BillingContractLine.BILLING_TYPE_RECURRING_FIXED;
        contractLines.add(mrcLine);
        
        ffbc__ContractLineItem__c nrcLine = new ffbc__ContractLineItem__c();
        nrcLine.ffbc__BillingType__c = lp_BillingContractLine.BILLING_TYPE_ONE_OFF;
        contractLines.add(nrcLine);

        Map<Id, List<ffbc__ContractLineItem__c>> billingContractLinesByOrderItemId = new Map<Id, List<ffbc__ContractLineItem__c>>();
        Test.startTest();
        billingContractLinesByOrderItemId.put(orderItem.Id, new List<ffbc__ContractLineItem__c>{ mrcLine });
        lp_OrderItem.updateBillingContractReference(billingContractLinesByOrderItemId);

        billingContractLinesByOrderItemId.put(orderItem.Id, new List<ffbc__ContractLineItem__c>{ nrcLine });
        lp_OrderItem.updateBillingContractReference(billingContractLinesByOrderItemId);
        Test.stopTest();

        // Verify order items were updated
        List<OrderItem> updatedOrderItems = [SELECT Id, LPC_BillingContractLine__c FROM OrderItem WHERE Id IN :billingContractLinesByOrderItemId.keySet()];
        for(OrderItem orderProduct : updatedOrderItems) {
            Assert.isNull(orderProduct.LPC_BillingContractLine__c, 'Billing contract line should be set to null');
        }
    }

    @isTest
    static void testUpdateBillingContractReferenceWithNullMap() {
        Test.startTest();
        lp_OrderItem.updateBillingContractReference(null);
        Test.stopTest();
        // No assertions needed as we're just testing the null case doesn't throw an error
    }
}