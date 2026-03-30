/**
 * @author Ladd Partners
 * @date 5/22/2025
*/

trigger lp_SalesOrderLine on SCMC__Sales_Order_Line_Item__c (after update) {
    if (lp_BillingSettings.customTriggersAreEnabled() || Test.isRunningTest()) {
        lp_TriggerHandlerDispatcher.dispatch(lp_SalesOrderLineTriggerHandler.Factory.class);
    }
}