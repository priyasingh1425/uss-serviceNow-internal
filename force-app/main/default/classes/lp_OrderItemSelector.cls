/**
 * Created by Ladd Partners on 4/11/2025.
 */

public with sharing class lp_OrderItemSelector extends lp_Selector {
    public lp_OrderItemSelector() {
        setSObjectType(OrderItem.getSObjectType());
        addField(OrderItem.Billing_Display__c);
        addField(OrderItem.Circuit_ID__c);
        addField(OrderItem.City__c);
        addField(OrderItem.City_Z__c);
        addField(OrderItem.Country__c);
        addField(OrderItem.Country_Z__c);
        addField(OrderItem.Customer_Reference__c);
        addField(OrderItem.EndDate);
        addField(OrderItem.Facility__c);
        addField(OrderItem.Id);
        addField(OrderItem.LPC_BillingContractLine__c);
        addField('LPC_BillingContractLine__r.ffbc__Contract__c');
        addField('LPC_BillingContractLine__r.ffbc__Contract__r.ffbc__Status__c');
        addField(OrderItem.MRC_Per_Unit__c);
        addField(OrderItem.NRC_Price__c);
        addField(OrderItem.NRC_List_Unit_Price__c);
        addField(OrderItem.OrderId);
        addField('Order.Account.ffbc__BillingAccount__c');
        addField('Order.Account.Sub_Type__c');
        addField('Order.Bundle_Customer_Reference__c');
        addField('Order.LPC_Billing_Contract__c');
        addField('Order.LPC_Billing_Contract__r.ffbc__Account__r.Sub_Type__c');
        addField('Order.LPC_Billing_Contract__r.ffbc__Status__c');
        addField('Order.Prior_Billing_Contract__c');
        addField('Order.OpportunityId');
        addField('Order.Type');
        addField(OrderItem.Product2Id);
        addField('Product2.Dimension_4__r.Name');
        addField('Product2.Family');
        addField('Product2.SBQQ__BillingFrequency__c');
        addField('Product2.Usage_Product__c');
        addField(OrderItem.Prior_Billing_Contract_Line_Item__c);
        addField(OrderItem.Promotion_Duration__c);
        addField(OrderItem.Quantity);
        addField(OrderItem.SBQQ__BillingFrequency__c);
        addField(OrderItem.Service_ID__c);
        addField(OrderItem.ServiceDate);
        addField(OrderItem.Start_Billing__c);
        addField(OrderItem.State__c);
        addField(OrderItem.State_Z__c);
        addField(OrderItem.Street__c);
        addField(OrderItem.Street_Z__c);
        addField(OrderItem.UnitPrice);
        addField(OrderItem.Unit_of_Measure__c);
        addField(OrderItem.Usage_Product__c);
        addField(OrderItem.Zip__c);
        addField(OrderItem.Zip_Z__c);
    }
    
    public List<OrderItem> getByIds(Set<Id> orderItemIds) {
        String query = getSelectStatement();
        query += ' WHERE Id IN :orderItemIds';
        return Database.query(query);
    }

    public OrderItem getById(Id orderItemId){
        OrderItem orderItem = null;
        List<OrderItem> orderItems = getByIds(new Set<Id> { orderItemId });
        if(!orderItems.isEmpty()){
            orderItem = orderItems[0];
        }
        return orderItem;
    }
    
    public List<OrderItem> getWithOrderComponentsByIds(Set<Id> orderItemIds) {
        lp_OrderComponentSelector orderComponentSelector = new lp_OrderComponentSelector();
        orderComponentSelector.setSObjectType('Order_Components_Product__r');
        String orderComponentQuery = orderComponentSelector.getSelectStatement();

        String query = getSelectStatement(orderComponentQuery);
        query += ' WHERE Id IN :orderItemIds';
        return Database.query(query);
    }
    
    public OrderItem getWithOrderComponentsById(Id orderItemId) {
        OrderItem orderItem = null;
        List<OrderItem> orderItems = getWithOrderComponentsByIds(new Set<Id> { orderItemId });
        if(!orderItems.isEmpty()){
            orderItem = orderItems[0];
        }
        return orderItem;
    }
 
    public Map<Id, List<OrderItem>> getMapByOrderId(Set<Id> orderItemIds) {
        List<OrderItem> orderItems = getByIds(orderItemIds);
        
        Map<Id, List<OrderItem>> orderItemsByOrderId = new Map<Id, List<OrderItem>>();
        for(OrderItem orderItem : orderItems){
            List<OrderItem> currentOrderItems = orderItemsByOrderId.get(orderItem.OrderId);
            if(currentOrderItems == null){
                currentOrderItems = new List<OrderItem>();
                orderItemsByOrderId.put(orderItem.OrderId, currentOrderItems);
            }
            currentOrderItems.add(orderItem);
        }
        return orderItemsByOrderId;
    }
    
    public List<OrderItem> getHasActiveContractLineByOrderId(Set<Id> orderIds) {  
        String activeStatus = lp_BillingContract.STATUS_ACTIVE;
        String query = getSelectStatement();
        query += ' WHERE OrderId IN :orderIds';
        query += ' AND LPC_BillingContractLine__c != null';
        query += ' AND LPC_BillingContractLine__r.ffbc__Contract__r.ffbc__Status__c = :activeStatus';
        return Database.query(query);
    }
}