/**
 * @author Ladd Partners
 * @date 11/17/17
 * @group
 * @description
 */

trigger lp_SalesOrderTrigger on SCMC__Sales_Order__c (before insert) {
    lp_TriggerHandlerDispatcher.dispatch(lp_SalesOrderTriggerHandler.Factory.class);


}