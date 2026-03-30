/**
 * Created by Ladd Partners on 4/18/2025.
 */

public with sharing class lp_OrderComponentSelector extends lp_Selector {

    public lp_OrderComponentSelector() {
        setSObjectType(Order_Component__c.sObjectType);
        addField(Order_Component__c.Id);
        addField(Order_Component__c.LEC_Bill_Start_Date__c);
        addField(Order_Component__c.LEC_Circuit_ID__c);
        addField(Order_Component__c.LEC_Due_Date__c);
        addField(Order_Component__c.LEC_Order_Number__c);
        addField(Order_Component__c.LEC_Term__c);
        addField(Order_Component__c.Name);
        addField(Order_Component__c.Ordered_Type__c);
        addField(Order_Component__c.Vendor__c);
    }
}