trigger lp_CertiniaAsyncProcess on Certinia_Async_Process__e (after Insert) {
    if (lp_BillingSettings.customTriggersAreEnabled()) {
        lp_TriggerHandlerDispatcher.dispatch(lp_CertiniaAsyncProcessTriggerHandler.Factory.class);
    }
}