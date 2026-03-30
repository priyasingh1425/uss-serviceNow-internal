/**
 * Created by Ladd Partners on 2/15/2023.
 */

@IsTest
private class lp_UtilityTest {
    @IsTest
    static void recordTypeTest() {
        Product2 product = new Product2();
        product.Name = 'Test Product';
        product.ProductCode = 'TP001';
        product.IsActive = true;
        product.Family = 'HVAC';
        lp_Utility.getRecordType(Product2.getSObjectType(), 'Master');
        lp_Utility.getRecordType('Master', product);
    }

    @IsTest
    static void testGetOrderProcessQueueId () {
        Id processQueue = lp_Utility.getOrderProcessQueueId();

        //System.assertNotEquals(null, processQueue);
    }

    @IsTest
    private static void notRunningBatch() {
        System.assert(!lp_Utility.isRunningBatch(), 'expecting not running batch');
    }

    @IsTest
    private static void ApprovalProcess() {
        Approval.ProcessResult result = lp_Utility.submitForApproval(null, null, null);
    }

    @IsTest
    static void testLogException() {
        Boolean errorThrown = false;
        try {
            System.debug('Testing log exception');
            throw new lp_Exception('This is a test Exception');
        } catch (Exception ex) {
            lp_Utility.logException(ex);
            errorThrown = true;
        }
        Assert.isTrue(errorThrown, 'Exception was not thrown');
    }
    
    @IsTest
    static void testCreateAuraHandledException() {
        String errorMessage = 'This is a test Exception';
        AuraHandledException ahEx = lp_Utility.createAuraHandledException(errorMessage);
        Assert.areEqual(errorMessage, ahEx.getMessage(), 'Exception message was not set');
    }
    
    @IsTest
    static void testConvertSetIdsToString() {
        Set<Id> mockIds = new Set<Id>{'0011x0000000000AAA', '0011x0000000000BBB'};
        String result = lp_Utility.convertSetIdsToString(mockIds);
        Assert.areEqual('\'0011x0000000000AAA\',\'0011x0000000000BBB\'', result, 'Set ids were not converted to string correctly');
    }
    
    @IsTest
    static void testJobIsRunning() {
        Boolean jobIsRunning = lp_Utility.jobIsRunning('lp_MonthlyLateFeesBatch', null);
        Assert.isFalse(jobIsRunning, 'Job should not be running');
    }
}