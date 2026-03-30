/**
 * Created by Ladd Partners on 5/21/2025.
 */

trigger lp_BillingContractLine on ffbc__ContractLineItem__c (after Insert) {
    if (lp_BillingSettings.customTriggersAreEnabled()) {
        lp_TriggerHandlerDispatcher.dispatch(lp_BillingContractLineTriggerHandler.Factory.class);
    }
}