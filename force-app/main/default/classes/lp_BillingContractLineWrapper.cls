/*
*  Created by Ladd Partners on 05/11/2025.
*/

public with sharing class lp_BillingContractLineWrapper {
    @AuraEnabled public Id id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public Decimal amount { get; set; }
    @AuraEnabled public String billingType { get; set; }
    @AuraEnabled public String lecCircuitName { get; set; }
    @AuraEnabled public String lecCircuitTerm { get; set; }
    @AuraEnabled public Date lecDueDate { get; set; }
    @AuraEnabled public String lecDueDateString { get; set; }
    @AuraEnabled public String lecOrderNumber { get; set; }
    @AuraEnabled public Date lecStartDate { get; set; }
    @AuraEnabled public String lecStartDateString { get; set; }
    @AuraEnabled public String lecVendorId { get; set; }
    @AuraEnabled public String lecVendorName { get; set; }
    @AuraEnabled public String orderedType { get; set; }
    @AuraEnabled public String ussCircuitId { get; set; }
    @AuraEnabled public String ussCircuitName { get; set; }


    public lp_BillingContractLineWrapper(ffbc__ContractLineItem__c line) {
        this.id = line.Id;
        this.name = line.Name;
        this.amount = line.ffbc__TotalContractLineValue__c;
        this.billingType = line.ffbc__BillingType__c;
        this.lecCircuitName = line.LPC_LEC_Circuit_Id__c;
        this.lecCircuitTerm = line.LPC_LEC_Term__c;
        this.lecDueDate = line.LPC_LEC_Due_Date__c ?? Date.today();
        this.lecDueDateString = buildDateStringForLWC(this.lecDueDate);
        this.lecOrderNumber = line.LPC_LEC_Order_Number__c;
        this.lecStartDate = line.LPC_LEC_Start_Date__c ?? Date.today();
        this.lecStartDateString = buildDateStringForLWC(this.lecStartDate);
        this.lecVendorId = line.LPC_LEC_Vendor__c;
        this.lecVendorName = line.LPC_LEC_Vendor__r.Name;
        this.orderedType = line.Ordered_Type__c;
        this.ussCircuitId = line.LPC_Circuit_Id__c;
        this.ussCircuitName = line.LPC_Circuit_Id__r.Name;
    }

    private static String buildDateStringForLWC(Date d) {
        return d.year() + '-' + d.month() + '-' + d.day();
    }
}