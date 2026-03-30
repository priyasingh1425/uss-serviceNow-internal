/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_ITSPayableLineItemSelector extends lp_Selector {
    public lp_ITSPayableLineItemSelector() {
        setSObjectType(Master_ITS_Payable_Invoice_Line__c.getSObjectType());
        addField(Master_ITS_Payable_Invoice_Line__c.Id);
        addField(Master_ITS_Payable_Invoice_Line__c.Name);
        addField(Master_ITS_Payable_Invoice_Line__c.Amount__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Amt_Paid__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Billing_Contract_Line__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Billing_Contract_Status__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Billing_Type__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Charge_Type__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Department__c);
        addField(Master_ITS_Payable_Invoice_Line__c.General_Ledger_Account_Number__c);
        addField(Master_ITS_Payable_Invoice_Line__c.LEC_Circuit_ID__c);
        addField(Master_ITS_Payable_Invoice_Line__c.LEC_Due_Date__c);
        addField(Master_ITS_Payable_Invoice_Line__c.LEC_Start_Date__c);
        addField(Master_ITS_Payable_Invoice_Line__c.LEC_Term__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Location__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Ordered_Type__c);
        addField(Master_ITS_Payable_Invoice_Line__c.Product__c);
        addField(Master_ITS_Payable_Invoice_Line__c.State__c);
        addField(Master_ITS_Payable_Invoice_Line__c.USS_Circuit_ID__c);
    }
}