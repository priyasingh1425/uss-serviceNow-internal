/**
 * Created by Ladd Partners on 4/11/2025.
 */

public with sharing class lp_OrderItemTriggerHandler extends lp_AbstractTriggerHandler {
    
    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new lp_OrderItemTriggerHandler(objects, oldObjectsById);
        }
    }

    private final List<OrderItem> orderItems;
    private final Map<Id, OrderItem> oldOrderItemById;

    private lp_OrderItemTriggerHandler(List<SObject> orderItems, Map<Id, SObject> oldObjectsById) {
        this.orderItems = orderItems;
        this.oldOrderItemById = (Map<Id, OrderItem>) oldObjectsById;
    }
    
    public override void afterInsert() {
        Set<Id> orderItemToBillIds = new Set<Id>();
        
        // Find OrderItems that need to be billed
        for(OrderItem orderItem : orderItems) {
            if (orderItem.Start_Billing__c && orderItem.ServiceDate != null && orderItem.Billing_Display__c == lp_OrderItem.BILLING_DISPLAY_DISPLAY) {
                orderItemToBillIds.add(orderItem.Id);
            }
        }
        
        if (!orderItemToBillIds.isEmpty() && lp_BillingSettings.orderProductBillingIsEnabled()) {
            // Bill Order Items
            lp_OrderItem.processBilling(orderItemToBillIds);
        }
    }
    
    public override void afterUpdate() {
        Set<Id> orderItemToBillIds = new Set<Id>();
        
        // Find OrderItems that need to be billed
        for (OrderItem orderItem : orderItems) {
            OrderItem oldOrderItem = oldOrderItemById.get(orderItem.Id);
            if (orderItem.Start_Billing__c && orderItem.ServiceDate != null && orderItem.Billing_Display__c == lp_OrderItem.BILLING_DISPLAY_DISPLAY && (oldOrderItem.Start_Billing__c != orderItem.Start_Billing__c)) {
                orderItemToBillIds.add(orderItem.Id);
            }
        }
        
        if (!orderItemToBillIds.isEmpty() && lp_BillingSettings.orderProductBillingIsEnabled()) {
            // Bill Order Items
            lp_OrderItem.processBilling(orderItemToBillIds);
        }
    }
}