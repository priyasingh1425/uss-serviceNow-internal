/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

trigger lp_EcmsExemption on ECMS_Certificate__c (before insert, before update) {
    lp_TriggerHandlerDispatcher.dispatch(lp_EcmsCertificationTriggerHandler.Factory.class);
}