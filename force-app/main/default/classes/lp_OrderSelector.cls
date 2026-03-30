/**
 * Created by Ladd Partners on 4/18/2025.
 */

public with sharing class lp_OrderSelector extends lp_Selector {

    public lp_OrderSelector(){
        setSObjectType(Order.sObjectType);
        addField(Order.Account_Account__c);
        addField(Order.Account_Account_Name__c);
        addField(Order.AccountId);    
        addField('Account.Sub_Type__c');
        addField(Order.Bill_Start_Date__c);
        addField(Order.Bundle_Customer_Reference__c);
        addField(Order.ContractId);
        addField(Order.CurrencyIsoCode);
        addField(Order.EffectiveDate);
        addField(Order.Id);
        addField(Order.LPC_Billing_Contract__c);
        addField(Order.Name);
        addField(Order.OpportunityId);
        addField('Opportunity.Name');
    }

    public Order getById(Id orderId){
        Order orderRecord = null;
        List<Order> orders = getByIds(new Set<Id> { orderId });
        if(!orders.isEmpty()){
            orderRecord = orders[0];
        }
        return orderRecord;
    }

    public List<Order> getByIds(Set<Id> orderIds){
        string query = getSelectStatement();
        query += ' WHERE Id IN :orderIds';
        return Database.query(query);
    }
    
    public Order getWithOrderItemsById(Id orderId){
        Order orderRecord = null;
        List<Order> orders = getWithOrderItemsByIds(new Set<Id> { orderId });
        if(!orders.isEmpty()){
            orderRecord = orders[0];
        }
        return orderRecord;
    }

    public List<Order> getWithOrderItemsByIds(Set<Id> orderIds){
        lp_OrderItemSelector orderItemSelector = new lp_OrderItemSelector();
        orderItemSelector.setSObjectType('OrderItems');
        String orderItemQuery = orderItemSelector.getSelectStatement();
        
        String query = getSelectStatement(orderItemQuery);
        query += ' WHERE Id IN :orderIds';
        return Database.query(query);
    }

}