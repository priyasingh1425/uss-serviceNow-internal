/**
 * @author Ladd Partners
 * @date 5/22/2025
*/

public with sharing class lp_SalesOrderLineSelector extends lp_Selector {

    public lp_SalesOrderLineSelector() {
        setSObjectType(SCMC__Sales_Order_Line_Item__c.SObjectType);
        addField(SCMC__Sales_Order_Line_Item__c.Id);
        addField(SCMC__Sales_Order_Line_Item__c.Name);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Condition_Code__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Customer_Current_Promise_Date__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Item_Cost__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Item_Master__c);
        addField('SCMC__Item_Master__r.Name');
        addField('SCMC__Item_Master__r.SCMC__Product__c');
        addField('SCMC__Item_Master__r.SCMC__Stocking_UOM__c');
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Purchase_Order_Line_Item__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Quantity__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Quantity_Allocated__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Quantity_Backordered__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Quantity_Shipped__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Sales_Order__c);
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Status__c);
        addField('SCMC__Sales_Order__r.SCMC__Currency__c');        
        addField('SCMC__Sales_Order__r.SCMC__Customer_Account__c');
        addField('SCMC__Sales_Order__r.SCMC__Warehouse__c');
        addField('SCMC__Sales_Order__r.SCMC__Warehouse__r.Name');
        addField('SCMC__Sales_Order__r.SCMFFA__Company__c');
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Supplier_Site__c);
        addField('SCMC__Supplier_Site__r.Name');
        addField(SCMC__Sales_Order_Line_Item__c.SCMC__Unit_Cost__c);
    }

    public List<SCMC__Sales_Order_Line_Item__c> getByIds(Set<Id> salesOrderLineIds) {
        String query = getSelectStatement();
        query += ' WHERE Id IN :salesOrderLineIds';
        return Database.query(query);
    }

    public Map<Id, SCMC__Sales_Order_Line_Item__c> getMapByIds(Set<Id> salesOrderLineIds) {
        return new Map<Id, SCMC__Sales_Order_Line_Item__c>(getByIds(salesOrderLineIds));
    }

}