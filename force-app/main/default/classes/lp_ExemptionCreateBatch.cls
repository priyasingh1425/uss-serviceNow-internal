/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_ExemptionCreateBatch implements Database.Batchable<String>, Database.Stateful {

    lp_BatchNotify batchNotify = new lp_BatchNotify();
    public static final String JOB_NAME = 'Create AFC Exemptions';

    private lp_ExemptionCreateBatch() {
    }

    public Iterable<String> start(Database.BatchableContext context) {
        List<AggregateResult> certificateAccounts = [SELECT
                Account_Number__c accountNumber
            FROM ECMS_Certificate__c
        WHERE (Processing_Status__c = :lp_EcmsCertificate.PROCESSING_STATUS_NEW
                OR Processing_Status__c = :lp_EcmsCertificate.PROCESSING_STATUS_ERROR)
                AND Exemption__c = NULL
            GROUP BY Account_Number__c];

        List<String> ecmsAccountIds = new List<String>();
        for (AggregateResult certificateAccount : certificateAccounts) {
            ecmsAccountIds.add((String)certificateAccount.get('accountNumber'));
        }

        return ecmsAccountIds;
    }

    public void execute(Database.BatchableContext context, List<String> records) {
        Map<Id, ECMS_Certificate__c> ecmsCertificatesByIds = new Map<Id, ECMS_Certificate__c>(
                new lp_EcmsCertificateSelector().getOpenByECMSAccountNumber(new Set<String>(records)));
        List<laddafc__Exemption__c> afcExemptions = new List<laddafc__Exemption__c>();

        Savepoint sp = Database.setSavepoint();

        try {
            lp_Exemption.deleteExemptions(records);

            for (ECMS_Certificate__c ecmsCertificate : ecmsCertificatesByIds.values()) {
                ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_NEW;
                ecmsCertificate.Processing_Message__c = null;

                if (ecmsCertificate.Account__c == null) {
                    ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;
                    ecmsCertificate.Processing_Message__c = 'No account found.';
                    continue;
                }

                if (ecmsCertificate.Designator_Type__c == lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE &&
                        ecmsCertificate.Tax_Type__c == null) {
                    ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;
                    ecmsCertificate.Processing_Message__c = 'No tax type found.';
                    continue;
                }

                if (ecmsCertificate.Effective_Date_Raw__c != null && ecmsCertificate.Effective_Date__c == null) {
                    ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;
                    ecmsCertificate.Processing_Message__c = 'Invalid effective date.';
                    continue;
                }

                if (ecmsCertificate.Expiration_Date_Raw__c != null && ecmsCertificate.Expiration_Date__c == null) {
                    ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;
                    ecmsCertificate.Processing_Message__c = 'Invalid expiration date.';
                    continue;
                }

                List<laddafc__Exemption__c> afcExemptionsCreated = lp_Exemption.create(ecmsCertificate);

                if (lp_CollectionUtil.isNotEmpty(afcExemptionsCreated)) {
                    afcExemptions.addAll(afcExemptionsCreated);
                }
            }

            System.debug(LoggingLevel.DEBUG, 'afc exemptions to insert: ' + afcExemptions.size());

            List<Database.SaveResult> results = Database.insert(afcExemptions, false);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results.get(i);
                laddafc__Exemption__c afcExemption = afcExemptions.get(i);
                ECMS_Certificate__c ecmsCertificate = ecmsCertificatesByIds.get(afcExemption.ECMS_Certificate__c);

                if (result.success) {
                    ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_PROCESSED;
                    ecmsCertificate.Exemption__c = afcExemption.Id;
                } else {
                    ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;
                    ecmsCertificate.Processing_Message__c = result.errors[0].getMessage();
                }
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Exception: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack: ' + ex.getStackTraceString());

            Database.rollback(sp);

            for (ECMS_Certificate__c ecmsCertificate : ecmsCertificatesByIds.values()) {
                if (ecmsCertificate.Processing_Status__c != lp_EcmsCertificate.PROCESSING_STATUS_ERROR) {
                    ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;
                    ecmsCertificate.Processing_Message__c = ex.getMessage();
                }
            }

            batchNotify.addNotification('Issue creating AFC certificates', ex);
        } finally {
            update ecmsCertificatesByIds.values();
        }
    }

    public void finish(Database.BatchableContext context) {
        if (batchNotify.errorRecordCount > 0) {
            List<String> emailAddresses = lp_EmailNotification.getAFCExemptionCreation();
            batchNotify.sendEmailNotification(emailAddresses, JOB_NAME + ' completed', ECMS_Certificate__c.SObjectType);
        }
    }

    public static void runJob() {
        Integer batchSize = lp_EcmsSettings.getAFCExemptionBatchSize();
        Database.executeBatch(new lp_ExemptionCreateBatch(), batchSize);
    }

}