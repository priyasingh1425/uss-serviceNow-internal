/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_EcmsImportQueueable implements System.Queueable, Database.AllowsCallouts {

    lp_BatchNotify batchNotify;
    ProcessingAccountInfo processingAccount;
    List<String> changedAccountIds;
    Datetime startDatetime;
    Datetime endDatetime;

    public static final String JOB_NAME = 'Import ECMS Certificates';

    @TestVisible
    private class ProcessingAccountInfo {
        public String ecmsAccountId { get; set; }
        public Integer nextOffset { get; set; }
        // previously created certs. we want to save them all together for a particular account.
        public List<ECMS_Certificate__c> ecmsCertificates { get; set; }

        public ProcessingAccountInfo(String ecmsAccountId, Integer nextOffset, List<ECMS_Certificate__c> ecmsCertificates) {
            this.ecmsAccountId = ecmsAccountId;
            this.nextOffset = nextOffset;
            this.ecmsCertificates = ecmsCertificates;
        }
    }

    public lp_EcmsImportQueueable() {
        this.batchNotify = new lp_BatchNotify();
        this.processingAccount = null;
        this.startDatetime = lp_EcmsSettings.getPreviousECMSImportRunTime();
        this.endDatetime = Datetime.now();
    }

    @TestVisible
    private lp_EcmsImportQueueable(lp_BatchNotify batchNotify, ProcessingAccountInfo processingAccount, List<String> changedAccountIds, Datetime startDate, Datetime endDate) {
        this.batchNotify = batchNotify;
        this.processingAccount = processingAccount;
        this.changedAccountIds = changedAccountIds;
        this.startDatetime = startDate;
        this.endDatetime = endDate;
    }

    public void execute(QueueableContext context) {
        Savepoint sp = null;

        // NOTE: this is a loose max. it will stop once we go over this number, but will still attempt to save everything already created.
        Integer maxNumberOfCertsToCreate = Integer.valueOf(lp_EcmsSettings.getMaxEcmsCertsToImportInTransaction());

        Set<String> processedEcmsAccountIds = new Set<String>();

        try {
            // if we're not continuing to process more from the previous account, go get the changes
            if (this.processingAccount == null && this.changedAccountIds == null) {
                System.debug(LoggingLevel.DEBUG, 'changes start: ' + this.startDatetime);
                System.debug(LoggingLevel.DEBUG, 'changes end: ' + this.endDatetime);

                lp_EcmsTypes.GetSummaryResponse summaryResponse = lp_EcmsService.getChangesSummary(this.startDatetime, this.endDatetime);

                Set<String> ecmsAccountIds = new Set<String>();

                for (String accountId : summaryResponse.updated) {
                    ecmsAccountIds.add(accountId);
                }

                // NOTE: deleted seems to indicate the accounts were deleted. so, skipping these. APi calls using these accounts returns a bad URL
                // summaryResponse.deleted

                changedAccountIds = new List<String>();
                changedAccountIds.addAll(ecmsAccountIds);
            }
            System.debug(LoggingLevel.DEBUG, '# of changed accounts: ' + changedAccountIds.size());

            Integer numberOfCallOuts;
            if (!Test.isRunningTest()) {
                // -1 for the potential summary call above
                numberOfCallOuts = Limits.getLimitCallouts() - 1;
            } else {
                numberOfCallOuts = 50;
            }

            // changeAccountsIds could be empty if the previous run stopped in the middle of processing the last account in the list
            if (this.processingAccount != null || !changedAccountIds.isEmpty()) {
                List<ECMS_Certificate__c> allEcmsCertificates = new List<ECMS_Certificate__c>();
                List<ECMS_Certificate__c> currentAccountEcmsCertificates = new List<ECMS_Certificate__c>();

                for (Integer i = 0; i < numberOfCallOuts; i++) {
                    String accountId;
                    Integer offset;

                    if (this.processingAccount == null) {
                        accountId = changedAccountIds.remove(0);
                        offset = 0;
                    } else {
                        accountId = this.processingAccount.ecmsAccountId;
                        offset = this.processingAccount.nextOffset;
                        if (currentAccountEcmsCertificates.isEmpty()) {
                            currentAccountEcmsCertificates.addAll(this.processingAccount.ecmsCertificates);
                        }
                    }

                    System.debug(LoggingLevel.DEBUG, 'ecms account id: ' + accountId);

                    lp_EcmsTypes.GetByAccountIdResponse response = lp_EcmsService.importByAccountId(accountId, offset);

                    System.debug(LoggingLevel.DEBUG, 'recordSetCount: ' + response.recordSetCount);

                    // not sure why, but some account Ids bring back multiple account numbers. don't know how to handle it, so just report it as an error.
                    if (response.customerRef.accountNumber == null) {
                        this.batchNotify.addNotification('No Account Number found for Account Id ' + accountId, null);
                        this.processingAccount = null;
                        continue;
                    }
                    if (response.customerRef.accountNumber.contains(',')) {
                        System.debug(LoggingLevel.DEBUG, 'customer account numbers: ' + response.customerRef.accountNumber);
                        this.batchNotify.addNotification('Multiple Account Numbers found for Account Id ' + accountId, null);
                        this.processingAccount = null;
                        continue;
                    }

                    List<ECMS_Certificate__c> newEcmsCertificates = lp_EcmsCertificate.create(response, endDatetime);
                    System.debug(LoggingLevel.DEBUG, '# of ecms certs created: ' + newEcmsCertificates.size());
                    currentAccountEcmsCertificates.addAll(newEcmsCertificates);

                    if (response.nextSkip != null) {
                        // there are more records for this account
                        this.processingAccount = new ProcessingAccountInfo(accountId, response.nextSkip, currentAccountEcmsCertificates);
                        offset = response.nextSkip;
                    } else if (!changedAccountIds.isEmpty()) {
                        allEcmsCertificates.addAll(currentAccountEcmsCertificates);
                        currentAccountEcmsCertificates = new List<ECMS_Certificate__c>();
                        processedEcmsAccountIds.add(accountId);
                        this.processingAccount = null;

                        // if we've reached our limit of certs to create in a transaction OR this is the final callout, queue up another one
                        if (allEcmsCertificates.size() >= maxNumberOfCertsToCreate || i == numberOfCallOuts - 1) {
                            System.enqueueJob(new lp_EcmsImportQueueable(this.batchNotify, null, this.changedAccountIds, this.startDatetime, this.endDatetime));
                            break;
                        }
                    } else {
                        // no more accounts to pull
                        allEcmsCertificates.addAll(currentAccountEcmsCertificates);
                        processedEcmsAccountIds.add(accountId);
                        this.processingAccount = null;
                        break;
                    }
                }

                sp = Database.setSavepoint();

                // if we're reprocessing these accounts, delete any old open certs so we start fresh
                lp_EcmsCertificate.deleteOpenByEcmsAccountId(processedEcmsAccountIds);

                System.debug(LoggingLevel.DEBUG, 'total ecms certs created: ' + allEcmsCertificates.size());

                insert allEcmsCertificates;

                this.batchNotify.processedRecordCount += allEcmsCertificates.size();
            } else {
                this.batchNotify.addNotification('No account updates found.', null);
            }
        } catch (Exception ex) {
            if (sp != null) {
                Database.rollback(sp);
            }

            this.batchNotify.errorRecordCount++;
            System.debug(LoggingLevel.ERROR, 'error message: ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'stack: ' + ex.getStackTraceString());
            batchNotify.addNotification('Error ' + ' [' + ex.getMessage() + '] ', ex);
        }

        // in the middle of processing an account. need to continue
        if (this.processingAccount != null) {
            System.enqueueJob(new lp_EcmsImportQueueable(this.batchNotify, this.processingAccount, this.changedAccountIds, this.startDatetime, this.endDatetime));
        } else if (changedAccountIds != null && changedAccountIds.isEmpty()) {
            // when we are done processing all changes...
            List<String> emailAddresses = lp_EmailNotification.getECMSCertificateImport();
            this.batchNotify.sendEmailNotification(emailAddresses, JOB_NAME + ' completed', null);

            if (this.batchNotify.errorRecordCount == 0) {
                lp_EcmsSettings.setPreviousECMSImportRunTime(this.endDatetime);
            }

            // certs have been pulled. go create AFC Exemptions (unless someone shut it off).
            if (lp_EcmsSettings.getAutoCreationOfAFCExemptionsEnabled()) {
                if (this.batchNotify.processedRecordCount > 0 && !Test.isRunningTest()) {
                    lp_ExemptionCreateBatch.runJob();
                }
            }
        }
    }

}