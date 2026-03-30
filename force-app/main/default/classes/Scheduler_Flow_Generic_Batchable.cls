global class Scheduler_Flow_Generic_Batchable implements Database.Batchable<sObject>, Database.Stateful {
    //bulk batchifies flow processing (works with Scheduler_Flow_Generic_Init, Scheduler_Flow_Generic_Helper, Scheduler_Flow_Generic_MDTBuilder and the metadata type Scheduler_Flow_Generic__mdt)
    
    // Fields
    global final String Query;
    global final Scheduler_Flow_Generic__mdt settings;
    Boolean i = true;
    
    // Constructor
    global Scheduler_Flow_Generic_Batchable(String q, Scheduler_Flow_Generic__mdt s) {
        Query = q;
        settings = s;
    }
    
    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    // Execute
    global void execute( Database.BatchableContext bc, List<sObject> scope) {
        try{
        //logic to be executed batch wise
        Set<sObject> uniques = new Set<sObject>(scope);
        Map<String, sObject> params = new Map<String, sObject>();
        
        for(sObject s : uniques){
            
            params.put(settings.Flow_Input_Variable_Name__c, s);
            
            Flow.Interview instanceOfFlow = Flow.Interview.createInterview(settings.Auto_Launch_Flow_to_Execute__c, params);
            instanceOfFlow.start();
            while(instanceOfFlow.getVariableValue('InterviewStatus') == 'InProgress'){
                System.debug('wait');
            }
        }
        }catch(Exception e){
            System.debug('Batch execute issue: ' + e.getMessage());
            i = false;
        }
    }
    
    // Finish
    global void finish(Database.BatchableContext bc) {
        if(settings.Run_Batches_Until_All_Records_Processed__c && i){
            try{//run subsequent batches if more records exist
                System.debug('got to finish');
                System.debug('query ::: ' + query);
                System.debug('i ini ::: ' + i);
                if(Database.query(query).size()>0){
                    Scheduler_Flow_Generic_Batchable genericBatch = new Scheduler_Flow_Generic_Batchable(query, settings);
                    
                    database.executeBatch(genericBatch);
                } else {}
            }catch(Exception e){
                System.debug('Batchable finish error ::: ' + e.getMessage());
            } 
        } else {}
    }
}