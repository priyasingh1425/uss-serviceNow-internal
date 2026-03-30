/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_MonthlyLateFeesBatch implements Database.Batchable<Account>, Database.Stateful {
    private lp_BatchNotify batchNotify { get; set; }

    private Set<Id> accountIds = new Set<Id>();

    public static final String JOB_NAME = 'Billing Documents - Monthly Late Fees';

    private laddafc__AFC_Configuration__c configuration = laddafc__AFC_Configuration__c.getInstance();
    private Boolean disabledAutoBillingDocTaxCalculation = false;

    public Iterable<Account> start(Database.BatchableContext context) {
        batchNotify.errorRecordCount = 0;
        batchNotify.processedRecordCount = 0;
        return (List<Account>)Database.query(new lp_AccountSelector().getQueryStringForMonthlyLateFeesAccounts(accountIds));
    }

    public void execute(Database.BatchableContext context, List<Account> accounts) {
        batchNotify.processedRecordCount += accounts.size();
        Map<Id, String[]> monthlyLateBatchErrors = lp_BillingDocument.createFinanceCharge(accounts);

        for(Id accountId : monthlyLateBatchErrors.keySet()) {
            for(String error : monthlyLateBatchErrors.get(accountId)) {
                batchNotify.addNotification(error, null);
                batchNotify.errorRecordCount++;
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        if(disabledAutoBillingDocTaxCalculation) {
            Savepoint sp = Database.setSavepoint();
            try {
                laddafc__AFC_Configuration__c config = laddafc__AFC_Configuration__c.getOrgDefaults();

                System.debug(config.laddafc__Disable_Auto_Billing_Doc_Tax_Calculation__c);
                config.laddafc__Disable_Auto_Billing_Doc_Tax_Calculation__c = false;
                update config;

                disabledAutoBillingDocTaxCalculation = false;
            }
            catch(Exception e) {
                lp_Utility.logException(e);
                Database.rollback(sp);
            }
        }

        if(!batchNotify.notifications.isEmpty() && batchNotify.errorRecordCount > 0) {
            batchNotify.sendUserEmailNotification(UserInfo.getUserEmail(), JOB_NAME, null);
        }
    }

    public static void runJob() {
        Set<Id> accountIds = new lp_BillingDocumentSelector().getAccountIds(new lp_BillingDocumentSelector().getMonthlyLateFeesBillDocs());
        if (!accountIds.isEmpty()) {
            runJob(accountIds);
        }
    }

    public static void runJob(Set<Id> lateAccountsIds) {
        lp_MonthlyLateFeesBatch batch = new lp_MonthlyLateFeesBatch(); 
        batch.batchNotify = new lp_BatchNotify();
        batch.accountIds = lateAccountsIds;

        laddafc__AFC_Configuration__c config = laddafc__AFC_Configuration__c.getOrgDefaults();
            
        if(!config.laddafc__Disable_Auto_Billing_Doc_Tax_Calculation__c) {
            Savepoint sp = Database.setSavepoint();
            try {
                batch.disabledAutoBillingDocTaxCalculation = true;
                config.laddafc__Disable_Auto_Billing_Doc_Tax_Calculation__c = true;

                if(config.Id == null) {
                    insert config;
                } else {
                    update config;
                }
            }
            catch(Exception e) {
                lp_Utility.logException(e);
                Database.rollback(sp);
                batch.disabledAutoBillingDocTaxCalculation = false;
            }
        }

        Database.executeBatch(batch, lp_BillingSettings.getLateFeesBatchSize());
    }
}