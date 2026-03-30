global class Scheduler_Flow_Generic_Helper Implements Schedulable{
    global Scheduler_Flow_Generic__mdt settings;
    
    global Scheduler_Flow_Generic_Helper(Scheduler_Flow_Generic__mdt s){
        settings = s;
    }
    
    global void execute(SchedulableContext sc){

        CustomException ce = new CustomException();
        
        try{
            SObjectType templateType = Schema.getGlobalDescribe().get(String.valueOf(settings.Input_Record_Type__c));
            Map<String,Schema.SObjectField> mfields = templateType.getDescribe().fields.getMap();
            String allfields = '';
            for(Schema.SObjectField f : mfields.values()){
                if(String.valueOf(allfields) == ''){
                    allfields = String.valueOf(f);
                } else {
                    allfields = String.valueOf(f) + ', ' + allfields; 
                }
            }
            Integer batch = Integer.valueOf(settings.Batch_Size__c);
            String query = 'SELECT ' + allfields + ' ' + settings.Text_Query__c + ' LIMIT ' + batch;
            Scheduler_Flow_Generic_Batchable genericBatch = new Scheduler_Flow_Generic_Batchable(query, settings);
            
            database.executeBatch(genericBatch);
        }catch(Exception e){
            ce.message = 'Custom APEX Error ::: Scheduler_Flow_Generic_Helper ::: line: ' + e.getLineNumber() + ' ::: ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
}