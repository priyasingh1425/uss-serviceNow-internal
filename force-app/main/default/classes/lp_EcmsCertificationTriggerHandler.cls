/**
 * @author Ladd Partners
 * @date 4/16/2025
*/

public with sharing class lp_EcmsCertificationTriggerHandler extends lp_AbstractTriggerHandler {

    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new lp_EcmsCertificationTriggerHandler(objects, oldObjectsById);
        }
    }

    private final List<ECMS_Certificate__c> ecmsCertificates;
    private final Map<Id, ECMS_Certificate__c> oldEcmsCertificatesById;

    private lp_EcmsCertificationTriggerHandler(List<ECMS_Certificate__c> ecmsCertificates, Map<Id, SObject> oldEcmsCertificatesById) {
        this.ecmsCertificates = ecmsCertificates;
        this.oldEcmsCertificatesById = (Map<Id, ECMS_Certificate__c>) oldEcmsCertificatesById;
    }

    public override void beforeInsert() {
        lp_EcmsCertificate.populateLookups(ecmsCertificates, null);
    }

    public override void beforeUpdate() {
        lp_EcmsCertificate.populateLookups(ecmsCertificates, oldEcmsCertificatesById);
    }

}