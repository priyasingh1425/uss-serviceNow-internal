/*
*  Created by Ladd Partners on 05/11/2025.
*/

public with sharing class lp_ITSPayableLine {
    
    public static Master_ITS_Payable_Invoice_Line__c createNewLineFromLwc(Map<String, String> lineFromLwc) {
        Master_ITS_Payable_Invoice_Line__c line = new Master_ITS_Payable_Invoice_Line__c();
        line.Master_ITS_Payable_Invoice__c = lineFromLwc.get('invoiceId');
        line.Billing_Contract_Line__c = lineFromLwc.get('id');
        line.Amount__c = lineFromLwc.get('amount') != null ? Decimal.valueOf(lineFromLwc.get('amount')) : null;
        line.Billing_Type__c = lineFromLwc.get('billingType');
        line.LEC_Circuit_ID__c = lineFromLwc.get('lecCircuitName');
        line.LEC_Term__c = lineFromLwc.get('lecCircuitTerm');
        line.LEC_Due_Date__c = lineFromLwc.get('lecDueDateString') != null ? Date.valueOf(lineFromLwc.get('lecDueDateString')) : null;
        line.LEC_Order_Number__c = lineFromLwc.get('lecOrderNumber');
        line.LEC_Start_Date__c = lineFromLwc.get('lecStartDateString') != null ? Date.valueOf(lineFromLwc.get('lecStartDateString')) : null;
        line.LEC_Vendor__c = lineFromLwc.get('lecVendorId');
        line.Ordered_Type__c = lineFromLwc.get('orderedType');
        line.USS_Circuit_ID__c = lineFromLwc.get('ussCircuitId');

        return line;
    }
}