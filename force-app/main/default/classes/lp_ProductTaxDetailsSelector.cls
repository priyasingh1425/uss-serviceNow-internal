/**
 * Created by Ladd Partners on 4/18/2025.
 */

public with sharing class lp_ProductTaxDetailsSelector extends lp_Selector {

    public lp_ProductTaxDetailsSelector() {
        setSObjectType(LPC_Product_Tax_Details__c.sObjectType);
        addField(LPC_Product_Tax_Details__c.Contract_Billing_Type__c);
        addField(LPC_Product_Tax_Details__c.Id);
        addField(LPC_Product_Tax_Details__c.Interstate__c);
        addField(LPC_Product_Tax_Details__c.Product__c);
        addField(LPC_Product_Tax_Details__c.Service_Type__c);
        addField(LPC_Product_Tax_Details__c.Transaction_Type__c);
    }

    public List<LPC_Product_Tax_Details__c> getByProductBillingTypeInterstateKey(Set<Id> productIds, Set<String> billingTypes) {
        String query = getSelectStatement();
        query += ' WHERE Product__c IN :productIds';
        query += ' AND Contract_Billing_Type__c IN :billingTypes';
        return Database.query(query);
    }

    public Map<String, LPC_Product_Tax_Details__c> getMapByProductBillingTypeInterstateKey(Set<Id> productIds, Set<String> billingTypes) {
        Map<String, LPC_Product_Tax_Details__c> taxDetailByProductBillingTypeInterstateKey = new Map<String, LPC_Product_Tax_Details__c>();
        List<LPC_Product_Tax_Details__c> taxDetails = getByProductBillingTypeInterstateKey(productIds, billingTypes);
        for(LPC_Product_Tax_Details__c taxDetail : taxDetails) {
            String key = lp_ProductTaxDetails.getProductIdAndBillingTypeKey(taxDetail.Product__c, taxDetail.Contract_Billing_Type__c, taxDetail.Interstate__c);
            taxDetailByProductBillingTypeInterstateKey.put(key, taxDetail);
        }
        return taxDetailByProductBillingTypeInterstateKey;
    }
}