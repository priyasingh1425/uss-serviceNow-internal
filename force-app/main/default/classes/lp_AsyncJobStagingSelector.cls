/**
 * Created by Ladd Partners on 4/17/2025.
 */

public with sharing class lp_AsyncJobStagingSelector extends lp_Selector {

    public lp_AsyncJobStagingSelector () {
        setSObjectType(Async_Job_Staging__c.getSObjectType());
        addField(Async_Job_Staging__c.Billing_Contract__c);
        addField(Async_Job_Staging__c.Billing_Contract_Line__c);
        addField('Billing_Contract_Line__r.ffbc__ActiveContractLineItem__c');
        addField('Billing_Contract_Line__r.ffbc__BilledTo__c');
        addField('Billing_Contract_Line__r.ffbc__Contract__c');
        addField('Billing_Contract_Line__r.ffbc__Contract__r.ffbc__Status__c');
        addField('Billing_Contract_Line__r.ffbc__EndDate__c');
        addField(Async_Job_Staging__c.CreatedById);
        addField(Async_Job_Staging__c.Error_Message__c);
        addField(Async_Job_Staging__c.Id);
        addField(Async_Job_Staging__c.Job__c);
        addField(Async_Job_Staging__c.Name);
        addField(Async_Job_Staging__c.Order_Product__c);
        addField(Async_Job_Staging__c.Process_Date__c);
        addField(Async_Job_Staging__c.Source_Billing_Contract_Line__c);
        addField('Source_Billing_Contract_Line__r.ffbc__ActiveContractLineItem__c');
        addField('Source_Billing_Contract_Line__r.ffbc__BilledTo__c');
        addField('Source_Billing_Contract_Line__r.ffbc__Contract__c');
        addField('Source_Billing_Contract_Line__r.ffbc__Contract__r.ffbc__Status__c');
        addField('Source_Billing_Contract_Line__r.ffbc__EndDate__c');
        addField(Async_Job_Staging__c.Status__c); 
    }

    public Async_Job_Staging__c getById(Id asyncJobId){
        Async_Job_Staging__c job = null;
        List<Async_Job_Staging__c> jobs = getByIds(new Set<Id> { asyncJobId });
        if(!jobs.isEmpty()){
            job = jobs[0];
        }
        return job;
    }

    public List<Async_Job_Staging__c> getByIds(Set<Id> asyncJobIds){
        String query = getSelectStatement();
        query += ' Where Id In :asyncJobIds';
        return Database.query(query);
    }

    public Set<Id> getNewAsyncJobStagingIds(){
        Set<String> validateStatuses = lp_AsyncJobStaging.PROCESS_STATUSES;
        Set<Id> newAsyncJobStagingIds = new Set<Id>();
        String query = getSelectStatement();
        query += ' where Status__c In :validateStatuses';
        query += '   and Billing_Contract__c = null';
        List<Async_Job_Staging__c> asyncJobStagingRecords = (List<Async_Job_Staging__c>)Database.query(query);
        for(Async_Job_Staging__c asyncJobStagingRecord : asyncJobStagingRecords){
            newAsyncJobStagingIds.add(asyncJobStagingRecord.Id);
        }
        return newAsyncJobStagingIds;
    }

    public String getQueryStringById(){
        String query = getSelectStatement();
        query += ' Where Id In :asyncJobStagingIdsString';
        query += '   and Status__c In :validateStatuses';
        return query;
    }

    public List<Async_Job_Staging__c> getCreateCreditLineBySourceContractLineId(Set<Id> sourceContractLineIds){
        String createCreditLineJob = lp_AsyncJobStaging.JOB_CREATE_CREDIT_LINE;
        String query = getSelectStatement();
        query += ' WHERE Source_Billing_Contract_Line__c IN :sourceContractLineIds';
        query += ' AND Job__c = :createCreditLineJob';
        return Database.query(query);
    }
    
    public Map<Id, Async_Job_Staging__c> getCreateCreditLineMapBySourceContractLineId(Set<Id> sourceContractLineIds){
        List<Async_Job_Staging__c> jobs = getCreateCreditLineBySourceContractLineId(sourceContractLineIds);

        Map<Id, Async_Job_Staging__c> asyncJobBySourceContractLine = new Map<Id, Async_Job_Staging__c>();
        for(Async_Job_Staging__c job : jobs){
            asyncJobBySourceContractLine.put(job.Source_Billing_Contract_Line__c, job);
        }
        return asyncJobBySourceContractLine;
    }
}