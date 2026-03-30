/**
 * Created by Ladd Partners on 6/1/2025.
 */

@isTest
private class lp_BillingContractSelectorTest {

    @isTest
    static void testGetByIds() {
        Test.startTest();
        List<ffbc__Contract__c> result = new lp_BillingContractSelector().getByIds(new Set<Id>());
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Should return empty list');
    }

    @isTest
    static void testGetActiveChangeRequestByActiveContractIdWithNoResult() {
        Id contractId = '001000000000000';
        Test.startTest();
        ffbc__Contract__c result = new lp_BillingContractSelector().getActiveChangeRequestByActiveContractId(contractId);
        Test.stopTest();

        // Verify results
        Assert.isNull(result, 'Should return null when no change request exists');
    }
}