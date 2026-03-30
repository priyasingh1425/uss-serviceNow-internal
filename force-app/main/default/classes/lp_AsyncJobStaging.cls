/**
 * Created by Ladd Partners on 4/17/2025.
 */

public with sharing class lp_AsyncJobStaging {
    
    public static final String ERROR_MISSING_JOB = 'Could not locate the Job Type';
    public static final String ERROR_MISSING_ORDER = 'Could not locate the Order for Async Job';
    public static final String ERROR_MISSING_ORDER_PRODUCT = 'Could not locate the Order Product for Async Job';
    public static final String ERROR_MISSING_CONTRACT_LINE = 'Could not locate the Billing Contract Line for Async Job';
    public static final String JOB_AMEND_ORDER_ITEMS = 'Amend Order Items';
    public static final String JOB_BILL_ORDER_ITEMS = 'Bill Order Items';
    public static final String JOB_CREATE_CREDIT_LINE = 'Create Credit Contract Line';
    public static final String JOB_DISCONNECT_ORDER_ITEMS = 'Disconnect Order Items';
    public static final String JOB_RENEW_ORDER_ITEMS = 'Renew Order Items';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_COMPLETED_WITH_ERROR = 'Completed with Error';
    public static final String STATUS_ERROR = 'Error';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_REPROCESS = 'Reprocess';
    public static final String TRANSACTION_TYPE_ASYNC_JOB_STAGING = 'Async Job Staging';
    public static final String TYPE_ORDER_ITEM = 'Order Item';
    public static final String TYPE_CONTRACT = 'Contract';

    public static final Set<String> PROCESS_STATUSES = new Set<String> { STATUS_NEW, STATUS_REPROCESS };

    public static void processJob(List<Async_Job_Staging__c> asyncJobs){
        List<Certinia_Async_Process__e> processAsyncJobEvents = new List<Certinia_Async_Process__e>();
        for(Async_Job_Staging__c asyncJob : asyncJobs){
            Certinia_Async_Process__e processAsyncJobEvent = new Certinia_Async_Process__e();
            processAsyncJobEvent.RecordId__c = asyncJob.Id;
            processAsyncJobEvent.Transaction_Type__c = TRANSACTION_TYPE_ASYNC_JOB_STAGING;
            processAsyncJobEvents.add(processAsyncJobEvent);
        }

        if(!processAsyncJobEvents.isEmpty()){
            // This will be run as an integration user
            Database.SaveResult[] saveResults = EventBus.publish(processAsyncJobEvents);
        }
    }
    
    public static void createOrderItemJobs(Map<String, Set<Id>> orderItemIdsByJob) {
        List<Async_Job_Staging__c> jobs = new List<Async_Job_Staging__c>();
        
        for(String jobType : orderItemIdsByJob.keySet()) {
            for(Id orderItemId : orderItemIdsByJob.get(jobType)) { 
                Async_Job_Staging__c job = new Async_Job_Staging__c();
                job.Order_Product__c = orderItemId;
                job.Job__c = jobType;
                job.Status__c = STATUS_NEW;
                jobs.add(job);
            }
        } 
        
        if(!jobs.isEmpty()) {
            insert jobs;
        }
    }
    
    public static void reportError(Id stagingRecordId, String errorMessage, Savepoint sp, Exception e) {
        if(sp != null){
            Database.rollback(sp); 
        }
        
        if(e != null){ 
            lp_Utility.logException(e);
        }

        Async_Job_Staging__c updatedStagingRecord = new Async_Job_Staging__c(Id = stagingRecordId);
        updatedStagingRecord.Status__c = STATUS_ERROR;
        updatedStagingRecord.Error_Message__c = errorMessage;
        update updatedStagingRecord;
    }
    
    public static void completeOrderItemJob(Id stagingRecordId, Id contractId) {
        Async_Job_Staging__c updatedStagingRecord = complete(stagingRecordId, false);
        updatedStagingRecord.Billing_Contract__c = contractId;
        update updatedStagingRecord;
    }
    
    public static Async_Job_Staging__c complete(Id stagingRecordId, Boolean doUpdate) {
        Async_Job_Staging__c updatedStagingRecord = new Async_Job_Staging__c(Id = stagingRecordId);
        updatedStagingRecord.Status__c = STATUS_COMPLETED;
        updatedStagingRecord.Error_Message__c = null;
        if(doUpdate){
            update updatedStagingRecord;
        }
        return updatedStagingRecord;
    }
    
    public static Async_Job_Staging__c createCreditLineJob(Id contractLineId) {
        return createCreditLineJob(contractLineId, null, true);
    }
    
    public static Async_Job_Staging__c createCreditLineJob(Id contractLineId, Date processDate) {
        return createCreditLineJob(contractLineId, processDate, true);
    }

    public static Async_Job_Staging__c createCreditLineJob(Id contractLineId, Date processDate, Boolean doInsert) {
        Async_Job_Staging__c job = new Async_Job_Staging__c();
        job.Job__c = JOB_CREATE_CREDIT_LINE;
        job.Process_Date__c = processDate;
        job.Source_Billing_Contract_Line__c = contractLineId;
        job.Status__c = STATUS_NEW;
        if(doInsert){
            insert job;
        }
        return job;
    }
    
    public static List<Async_Job_Staging__c> createCreditLineJobs(Map<Id, Date> processDateByContractLineNeedingCreditId) {
        List<Async_Job_Staging__c> newJobs = new List<Async_Job_Staging__c>();
        if (processDateByContractLineNeedingCreditId != null && !processDateByContractLineNeedingCreditId.isEmpty()) {
            Map<Id, Async_Job_Staging__c> asyncJobByContractLine = new lp_AsyncJobStagingSelector().getCreateCreditLineMapBySourceContractLineId(processDateByContractLineNeedingCreditId.keySet());
            for(Id contractLineId : processDateByContractLineNeedingCreditId.keySet()){
                Async_Job_Staging__c existingJob = asyncJobByContractLine.get(contractLineId);
                if(existingJob == null){
                    Async_Job_Staging__c newJob = lp_AsyncJobStaging.createCreditLineJob(contractLineId, processDateByContractLineNeedingCreditId.get(contractLineId), false);
                    newJobs.add(newJob);
                }
            }
        }
        insert newJobs;
        return newJobs;
    }
    
    public static void completeCreditLineJob(Id stagingRecordId, Id contractLineId, String message) {
        Async_Job_Staging__c updatedStagingRecord = complete(stagingRecordId, false);
        updatedStagingRecord.Billing_Contract_Line__c = contractLineId;
        updatedStagingRecord.Error_Message__c = message;
        update updatedStagingRecord;
    }
}