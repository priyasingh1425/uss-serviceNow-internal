/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_ITSPayableSelector extends lp_Selector {
    public lp_ITSPayableSelector() {
        setSObjectType(Master_ITS_Payable_Invoice__c.getSObjectType());
        addField(Master_ITS_Payable_Invoice__c.Id);
        addField(Master_ITS_Payable_Invoice__c.Name);
        addField(Master_ITS_Payable_Invoice__c.Name__c);
        addField(Master_ITS_Payable_Invoice__c.Calculated_Total__c);
        addField(Master_ITS_Payable_Invoice__c.Due_Date__c);
        addField(Master_ITS_Payable_Invoice__c.Invoice_Amount__c);
        addField(Master_ITS_Payable_Invoice__c.Invoice_Date__c);
        addField(Master_ITS_Payable_Invoice__c.Invoice_Number__c);
        addField(Master_ITS_Payable_Invoice__c.Net_Term__c);
        addField(Master_ITS_Payable_Invoice__c.Vendor__c);
    }
    
    public List<Master_ITS_Payable_Invoice__c> getWithLinesById(Set<Id> payableIds) {
        lp_ITSPayableLineItemSelector lineSelector = new lp_ITSPayableLineItemSelector();
        lineSelector.setSObjectType('Master_ITS_Payable_Invoice_Lines__r');
    
        String query = getSelectStatement(lineSelector.getSelectStatement());
        query += ' WHERE Id = :payableIds';

        return Database.query(query);
    }

    public Master_ITS_Payable_Invoice__c getWithLinesById(Id payableId) {
        List<Master_ITS_Payable_Invoice__c> results = getWithLinesById(new Set<Id>{payableId});
        Master_ITS_Payable_Invoice__c result = !results.isEmpty()? results[0] : null;
        return result;
    }
}