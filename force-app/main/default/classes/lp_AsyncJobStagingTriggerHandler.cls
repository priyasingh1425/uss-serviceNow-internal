/**
 * Created by Ladd Partners on 11/13/2024.
 */

public with sharing class lp_AsyncJobStagingTriggerHandler extends lp_AbstractTriggerHandler {

    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById){
            return new lp_AsyncJobStagingTriggerHandler(objects, oldObjectsById);
        }
    }

    private final List<Async_Job_Staging__c> asyncJobs;
    private final Map<Id, Async_Job_Staging__c> oldAsyncJobById;

    private lp_AsyncJobStagingTriggerHandler(List<SObject> asyncJobs, Map<Id, SObject> oldAsyncJobById){
        this.asyncJobs = asyncJobs;
        this.oldAsyncJobById = (Map<Id, Async_Job_Staging__c>) oldAsyncJobById;
    }

    public override void afterInsert(){
        if(!lp_Utility.jobIsRunning(lp_AsyncJobStagingBatch.CLASS_NAME, null)){
            lp_AsyncJobStaging.processJob(asyncJobs);
        }
    }

    public override void afterUpdate(){
        List<Async_Job_Staging__c> processJobs = new List<Async_Job_Staging__c>();
        for(Async_Job_Staging__c asyncJob : asyncJobs){
            Async_Job_Staging__c oldAsyncJob = oldAsyncJobById.get(asyncJob.Id);
            if(asyncJob.Status__c != oldAsyncJob.Status__c &&
               lp_AsyncJobStaging.PROCESS_STATUSES.contains(asyncJob.Status__c)){
                processJobs.add(asyncJob);
            }
        }
        
        Boolean isRunning = lp_Utility.jobIsRunning(lp_AsyncJobStagingBatch.CLASS_NAME, null);
        System.debug(LoggingLevel.DEBUG, 'ProcessJobs: ' + processJobs.size());
        System.debug(LoggingLevel.DEBUG, 'Job Running: ' + isRunning);
        if(!processJobs.isEmpty() && !isRunning){
            lp_AsyncJobStaging.processJob(processJobs);
        }
    }
}