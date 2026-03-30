/**
 * @author Ladd Partners
 * @date 4/22/2025
*/

public with sharing class lp_EcmsSettings {

    public static Boolean isProduction {
        get;
        private set;
    }

    public static Boolean useProduction() {
        if (isProduction == null) {
            ECMS_Settings__c settings = ECMS_Settings__c.getInstance();
            isProduction = settings.Is_Production__c;
        }

        return isProduction;
    }

    public static Boolean getAutoCreationOfAFCExemptionsEnabled() {
        ECMS_Settings__c settings = ECMS_Settings__c.getInstance();
        Boolean disabledAutoCreateAFC = settings.Disable_Auto_creation_of_AFC_Exemptions__c;

        return !disabledAutoCreateAFC;
    }

    // how many different accounts to create AFC exemptions for at a time
    public static Integer getAFCExemptionBatchSize() {
        Integer batchSize = 10;
        ECMS_Settings__c settings = ECMS_Settings__c.getInstance();

        if (settings.Name != null && settings.AFC_Exemption_Creation_Batch_Size__c != null) {
            batchSize = (Integer) settings.AFC_Exemption_Creation_Batch_Size__c;
        }

        return batchSize;
    }

    // how many exemptions to bring back at a time when importing by ECMS Account Id
    public static Integer getECMSExemptionsBatchSize() {
        Integer batchSize = 100;
        ECMS_Settings__c settings = ECMS_Settings__c.getInstance();

        if (settings.Name != null && settings.ECMS_Get_By_Account_Id_Batch_Size__c != null) {
            batchSize = (Integer) settings.ECMS_Get_By_Account_Id_Batch_Size__c;
        }

        return batchSize;
    }

    // how many ecms certificates to create in a single transaction.
    public static Integer getMaxEcmsCertsToImportInTransaction() {
        Integer batchSize = 2500;
        ECMS_Settings__c settings = ECMS_Settings__c.getInstance();

        if (settings.Name != null && settings.Certificate_Import_Max_Records__c != null) {
            batchSize = (Integer) settings.Certificate_Import_Max_Records__c;
        }

        if (batchSize > 24000) { batchSize = 24000; }

        return batchSize;
    }

    public static Datetime getPreviousECMSImportRunTime() {
        ECMS_Settings__c settings = ECMS_Settings__c.getOrgDefaults();
        Datetime lastRun = settings.Import_Last_Run__c;

        if (lastRun == null) {
            lastRun = Datetime.newInstance(1900, 1, 1, 0, 0, 0);
        }

        return lastRun;
    }

    public static void setPreviousECMSImportRunTime(Datetime lastRunTime) {
        ECMS_Settings__c settings = ECMS_Settings__c.getOrgDefaults();
        settings.Import_Last_Run__c = lastRunTime;
        upsert settings;
    }

}