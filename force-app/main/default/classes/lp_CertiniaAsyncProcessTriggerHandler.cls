/**
 * Created by Ladd Partners on 4/17/2025.
 */

public with sharing class lp_CertiniaAsyncProcessTriggerHandler extends lp_AbstractTriggerHandler {
    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById){
            return new lp_CertiniaAsyncProcessTriggerHandler(objects, oldObjectsById);
        }
    }

    private final List<Certinia_Async_Process__e> certiniaAsyncProcesses;
    private final Map<Id, Certinia_Async_Process__e> oldCertiniaAsyncProcessById;

    private lp_CertiniaAsyncProcessTriggerHandler(List<SObject> certiniaAsyncProcesses, Map<Id, SObject> oldCertiniaAsyncProcessById){
        this.certiniaAsyncProcesses = certiniaAsyncProcesses;
        this.oldCertiniaAsyncProcessById = (Map<Id, Certinia_Async_Process__e>)oldCertiniaAsyncProcessById;
    }

    public override void afterInsert(){

        Set<Id> asyncJobIds = new Set<Id>();
        Set<Id> salesOrderIds = new Set<Id>();
        for(Certinia_Async_Process__e certiniaAsyncProcess : certiniaAsyncProcesses){
            asyncJobIds.add(certiniaAsyncProcess.RecordId__c);
        }

        if(!asyncJobIds.isEmpty()){
            Boolean isRunning = lp_Utility.jobIsRunning(lp_AsyncJobStagingBatch.CLASS_NAME, null);
            if(isRunning){
                System.debug(LoggingLevel.DEBUG, 'lp_AsyncJobStagingBatch is running - not currently processing Certinia Async Process events');
            } else {
                lp_AsyncJobStagingBatch.runJob(asyncJobIds, null);
            }
        }

    }
}