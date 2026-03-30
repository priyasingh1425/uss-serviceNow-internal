/**
 * Created by Ladd Partners on 4/17/2025.
 */

public with sharing class lp_AsyncJobStagingBatch implements Database.Batchable<sObject>, Database.Stateful {

    public static final String CLASS_NAME = 'lp_AsyncJobStagingBatch';
    public static final String JOB_NAME = 'Process Async Job Staging Records';
    
    public Set<Id> asyncJobStagingIds { get; set; }
    public Set<Id> contractIds { get; set; }
    public Id jobId { get; set; }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String queryString = new lp_AsyncJobStagingSelector().getQueryStringById();
        Set<String> validateStatuses = lp_AsyncJobStaging.PROCESS_STATUSES;
        Map<String, Object> asyncJobStagingMapping = new Map<String, Object>{'asyncJobStagingIdsString' => asyncJobStagingIds, 'validateStatuses' => validateStatuses };
        List<Async_Job_Staging__c> stagingRecords = Database.queryWithBinds(queryString, asyncJobStagingMapping, AccessLevel.SYSTEM_MODE);
        return Database.getQueryLocatorWithBinds(queryString, asyncJobStagingMapping, AccessLevel.SYSTEM_MODE);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {

        List<Async_Job_Staging__c> stagingRecords = scope;

        if (stagingRecords.size() > 1) {
            throw new lp_Exception('Can only process one staging record at a time', true);
        }

        Savepoint sp = Database.setSavepoint();
        Async_Job_Staging__c stagingRecord = stagingRecords[0];
        try {
            if(stagingRecord.Job__c == lp_AsyncJobStaging.JOB_AMEND_ORDER_ITEMS){
                Id contractId = lp_BillingContractLine.amendOrderItem(stagingRecord, false);
                contractIds.add(contractId);
            } else if(stagingRecord.Job__c == lp_AsyncJobStaging.JOB_BILL_ORDER_ITEMS){
                Id contractId = lp_BillingContractLine.billOrderItem(stagingRecord);
                contractIds.add(contractId);
            } else if(stagingRecord.Job__c == lp_AsyncJobStaging.JOB_DISCONNECT_ORDER_ITEMS){
                Id contractId = lp_BillingContractLine.disconnectOrderItem(stagingRecord);
                contractIds.add(contractId);
            } else if(stagingRecord.Job__c == lp_AsyncJobStaging.JOB_RENEW_ORDER_ITEMS){
                Set<Id> addContractIds = lp_BillingContractLine.renewOrderItem(stagingRecord);
                contractIds.addAll(addContractIds);
            } else if(stagingRecord.Job__c == lp_AsyncJobStaging.JOB_CREATE_CREDIT_LINE){
                Id contractId = lp_BillingContractLine.createCreditLine(stagingRecord);
                contractIds.add(contractId);
            } else {
                throw new lp_Exception(lp_AsyncJobStaging.ERROR_MISSING_JOB, true);
            }
        } catch (Exception e) {
            lp_AsyncJobStaging.reportError(stagingRecord.Id, e.getMessage(), sp, e);
        }
    }

    public void finish(Database.BatchableContext bc) {
        Set<Id> newAsyncJobStagingIds = new lp_AsyncJobStagingSelector().getNewAsyncJobStagingIds();
        if(!newAsyncJobStagingIds.isEmpty() && !lp_Utility.jobIsRunning(lp_AsyncJobStagingBatch.CLASS_NAME, jobId)){
            runJob(newAsyncJobStagingIds, contractIds);
        } else { 
            if(!contractIds.isEmpty() && lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled()){
                lp_BillingContract.activateContractsOrApplyChange(contractIds);
            }
        }
    }

    public static void runJob(Set<Id> asyncJobStagingIds, Set<Id> contractIds) {
        lp_AsyncJobStagingBatch batch = new lp_AsyncJobStagingBatch();
        batch.asyncJobStagingIds = asyncJobStagingIds;
        batch.contractIds = contractIds ?? new Set<Id>();
        if(Test.isRunningTest()){
            batch.jobId = Database.executeBatch(batch, 1);
        } else {
            // add delay to allow post processing actions to complete before running (again).
            batch.jobId = System.scheduleBatch(batch, JOB_NAME, 2, 1);
        }
    }
}