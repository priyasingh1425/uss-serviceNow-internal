/**
 * Created by Ladd Partners on 5/19/2025.
 */

public with sharing class lp_UssRevCostGlaSettings {
    private static String reportingCode_RevenueRetailUsage { get; set; }
    private static String reportingCode_RevenueWholesaleUsage { get; set; }
    private static String reportingCode_RevenueRetailMRC { get; set; }
    private static String reportingCode_RevenueWholesaleMRC { get; set; }
    private static String reportingCode_RevenueRetailNRC { get; set; }
    private static String reportingCode_RevenueWholesaleNRC { get; set; }

    public static String getRevenueRetailUsage() {
        if (reportingCode_RevenueRetailUsage == null) {
            USS_Rev_Cost_GLA_Settings__c settings = USS_Rev_Cost_GLA_Settings__c.getInstance();
            reportingCode_RevenueRetailUsage = settings.Revenue_Retail_Usage__c;
        }
        return reportingCode_RevenueRetailUsage;
    }
    
    public static String getRevenueWholesaleUsage() {
        if (reportingCode_RevenueWholesaleUsage == null) {
            USS_Rev_Cost_GLA_Settings__c settings = USS_Rev_Cost_GLA_Settings__c.getInstance();
            reportingCode_RevenueWholesaleUsage = settings.Revenue_Wholesale_Usage__c;
        }
        return reportingCode_RevenueWholesaleUsage;
    }

    public static String getRevenueRetailMRC() {
        if (reportingCode_RevenueRetailMRC == null) {
            USS_Rev_Cost_GLA_Settings__c settings = USS_Rev_Cost_GLA_Settings__c.getInstance();
            reportingCode_RevenueRetailMRC = settings.Revenue_Retail_MRC__c;
        }
        return reportingCode_RevenueRetailMRC;
    }

    public static String getRevenueWholesaleMRC() {
        if (reportingCode_RevenueWholesaleMRC == null) {
            USS_Rev_Cost_GLA_Settings__c settings = USS_Rev_Cost_GLA_Settings__c.getInstance();
            reportingCode_RevenueWholesaleMRC = settings.Revenue_Wholesale_MRC__c;
        }
        return reportingCode_RevenueWholesaleMRC;
    }

    public static String getRevenueRetailNRC() {
        if (reportingCode_RevenueRetailNRC == null) {
            USS_Rev_Cost_GLA_Settings__c settings = USS_Rev_Cost_GLA_Settings__c.getInstance();
            reportingCode_RevenueRetailNRC = settings.Revenue_Retail_NRC__c;
        }
        return reportingCode_RevenueRetailNRC;
    }

    public static String getRevenueWholesaleNRC() {
        if (reportingCode_RevenueWholesaleNRC == null) {
            USS_Rev_Cost_GLA_Settings__c settings = USS_Rev_Cost_GLA_Settings__c.getInstance();
            reportingCode_RevenueWholesaleNRC = settings.Revenue_Wholesale_NRC__c;
        }
        return reportingCode_RevenueWholesaleNRC;
    }

}