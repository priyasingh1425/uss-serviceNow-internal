/**
 * Created by Ladd Partners on 4/17/2025.
 */
trigger lp_AsyncJobStaging on Async_Job_Staging__c (after insert, after update) {
    if (lp_BillingSettings.customTriggersAreEnabled()) {
        lp_TriggerHandlerDispatcher.dispatch(lp_AsyncJobStagingTriggerHandler.Factory.class);
    }
}