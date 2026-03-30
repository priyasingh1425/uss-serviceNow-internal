/**
 * Created by Ladd Partners on 6/1/2025.
 */

@isTest
private class lp_UssRevCostGlaSettingsTest {
    static final String testReportingCode = '0000';

    @TestSetup
    static void setupTestData() {
        // Create custom setting record
        USS_Rev_Cost_GLA_Settings__c settings = USS_Rev_Cost_GLA_Settings__c.getInstance();
        settings.Name = 'Default';
        settings.Revenue_Retail_MRC__c = testReportingCode;
        settings.Revenue_Retail_NRC__c = testReportingCode;
        settings.Revenue_Retail_Usage__c = testReportingCode;
        settings.Revenue_Wholesale_MRC__c = testReportingCode;
        settings.Revenue_Wholesale_NRC__c = testReportingCode;
        settings.Revenue_Wholesale_Usage__c = testReportingCode;
        upsert settings;
    }

    @isTest
    static void test() {
        Test.startTest();
        String retailMrc = lp_UssRevCostGlaSettings.getRevenueRetailMRC();
        String retailNrc = lp_UssRevCostGlaSettings.getRevenueRetailNRC();
        String retailUsage = lp_UssRevCostGlaSettings.getRevenueRetailUsage();
        String wholesaleMrc = lp_UssRevCostGlaSettings.getRevenueWholesaleMRC();
        String wholesaleNrc = lp_UssRevCostGlaSettings.getRevenueWholesaleNRC();
        String wholesaleUsage = lp_UssRevCostGlaSettings.getRevenueWholesaleUsage();
        Test.stopTest();

        System.assertEquals(testReportingCode, retailMrc, 'Retail MRC should match');
        System.assertEquals(testReportingCode, retailNrc, 'Retail NRC should match');
        System.assertEquals(testReportingCode, retailUsage, 'Retail Usage should match');
        System.assertEquals(testReportingCode, wholesaleMrc, 'Wholesale MRC should match');
        System.assertEquals(testReportingCode, wholesaleNrc, 'Wholesale NRC should match');
        System.assertEquals(testReportingCode, wholesaleUsage, 'Wholesale Usage should match'); 
    }
}