/**
 * @author Ladd Partners
 * @date 4/25/2025
*/

public with sharing class lp_EcmsCertificateController {

    @AuraEnabled
    public static lp_MessageWrapper rerunAFCExemptionCreation() {
        lp_MessageWrapper response = new lp_MessageWrapper();
        response.isSuccessful = false;

        try {
            lp_ExemptionCreateBatch.runJob();

            response.message = 'AFC Exemption Create job started';
            response.isSuccessful = true;
        } catch (Exception ex) {
            System.debug('Exception: ' + ex.getMessage());
            System.debug('Stack: ' + ex.getStackTraceString());
            response.message = ex.getMessage();
        }

        return response;
    }

}