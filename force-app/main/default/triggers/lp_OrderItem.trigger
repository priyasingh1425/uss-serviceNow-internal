/**
 * Created by Ladd Partners on 4/11/2025.
 */

trigger lp_OrderItem on OrderItem (after insert,after update) {
    if (lp_BillingSettings.customTriggersAreEnabled()) {
        lp_TriggerHandlerDispatcher.dispatch(lp_OrderItemTriggerHandler.Factory.class);
    }
}