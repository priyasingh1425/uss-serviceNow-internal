/**
 * @author Ladd Partners
 * @date 4/21/2025
*/

public with sharing class lp_MonthlyPayableInvoiceSelector extends lp_Selector {
    public lp_MonthlyPayableInvoiceSelector() {
        setSObjectType(c2g__codaPurchaseInvoice__c.getSObjectType());
        addField(c2g__codaPurchaseInvoice__c.Id);
        addField(c2g__codaPurchaseInvoice__c.Name);
        addField(c2g__codaPurchaseInvoice__c.c2g__Account__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__AccountInvoiceNumber__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__DeriveCurrency__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__DerivePeriod__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__DueDate__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__InvoiceCurrency__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__InvoiceDate__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__InvoiceStatus__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__OwnerCompany__c);
        addField(c2g__codaPurchaseInvoice__c.c2g__Period__c);
        addField(c2g__codaPurchaseInvoice__c.Master_ITS_Payable_Invoice__c);
    }

    public List<c2g__codaPurchaseInvoice__c> getWithLinesById(Set<Id> payableIds) {
        lp_MonthlyPayableInvoiceLineItemSelector lineSelector = new lp_MonthlyPayableInvoiceLineItemSelector();
        lineSelector.setSObjectType('c2g__PurchaseInvoiceExpenseLineItems__r');
    
        String query = getSelectStatement(lineSelector.getSelectStatement());
        query += ' WHERE Id = :payableIds';
    
        return Database.query(query);
    }

    public c2g__codaPurchaseInvoice__c getWithLinesById(Id payableId) {
        List<c2g__codaPurchaseInvoice__c> results = getWithLinesById(new Set<Id>{payableId});
        c2g__codaPurchaseInvoice__c result = !results.isEmpty()? results[0] : null;
        return result;
    }
}