public with sharing class lp_MonthlyPayableInvoiceLineItemSelector extends lp_Selector {
    public lp_MonthlyPayableInvoiceLineItemSelector() {
        setSObjectType(c2g__codaPurchaseInvoiceExpenseLineItem__c.getSObjectType());
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.Id);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.Name);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__DeriveLineNumber__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__Dimension1__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__Dimension2__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__Dimension3__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__Dimension4__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__GeneralLedgerAccount__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__LineDescription__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__NetValue__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.c2g__OwnerCompany__c);
        addField(c2g__codaPurchaseInvoiceExpenseLineItem__c.Master_ITS_Payable_Invoice_Line__c);
    }
}