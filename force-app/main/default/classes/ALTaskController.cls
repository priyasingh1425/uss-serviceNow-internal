public with sharing class ALTaskController {
    //Works with LWC ALTaskControllerComponentController
    //Test with ALTaskControllerTest
    //Custom Tasks related list with a checkbox that updates status to Completed on click (and refreshes list)
    
    @AuraEnabled
    public static List<Task> getTasks(String recordId){
        system.debug('getTasks recordId ' + recordId);
        //List<Task> taskList = [SELECT Id,Subject,Owner.Name,Task_Sequence__c,ActivityDate,WhoId,WhatId,Status FROM Task WHERE RecordType.Name IN('External Customer Support') AND Status != 'Completed' AND WhatId =: recordId ORDER BY Task_Sequence__c ASC];
        //Commented out for 00248858, new code bracketed by empty comment
        //List<Task> taskList = [SELECT Id,Subject,Owner.Name,Task_Sequence__c,ActivityDate,WhoId,WhatId,Status,RecordType.Name, Procedure_URL__c FROM Task WHERE WhatId =: recordId ORDER BY Task_Sequence__c ASC];
        List<Task> taskList = [
    SELECT Id, Subject, Owner.Name, Task_Sequence__c, ActivityDate, WhoId, WhatId,
           Status, RecordType.Name, Procedure_URL__c
    FROM Task
    WHERE WhatId = :recordId
    ORDER BY
        IsClosed ASC,            // open first
        Task_Sequence__c ASC,
        ActivityDate ASC
];
        //                
        //from CR 8/15/22 do not use IDs in queries because they will need to be switched before deploying to production
        system.debug(taskList);
        return taskList;
    }
    
    @AuraEnabled
    public static void updateDetails(List<String> lstRecordId) {
        List<Task> lstUpdate = new List<Task>();
        for(Task t : [SELECT Id, Status FROM Task WHERE Id IN : lstRecordId]){
            system.debug('Status before update ' + t.Status + ' Id verification ' + t.Id);
            t.Status = 'Completed'; // Add fields which you want to update
            system.debug('Status after update ' + t.Status);

            t.OwnerId = System.UserInfo.getUserId();
            
            lstUpdate.add(t);
        }
        system.debug('lstUpdate.size() ' + lstUpdate.size());
        if(lstUpdate.size() > 0){
            update lstUpdate;
        }
        
    }
    
    @AuraEnabled
    public static void updateTaskOwnerFromCaseId(String recordId){
        system.debug('recordId ' + recordId);
        
        Id userId = UserInfo.getUserId();
        //List<Task> taskList = ALTaskController.getTasks(recordId);
        //Commented out for 00248858, new code bracketed by empty comment
        List<Task> taskList = [SELECT Id,Subject,Owner.Name,Task_Sequence__c,ActivityDate,WhoId,WhatId,Status, Procedure_URL__c FROM Task WHERE RecordType.Name IN('External Customer Support') AND Status != 'Completed' AND WhatId =: recordId ORDER BY Task_Sequence__c ASC];
        //
        for(Task t : taskList){
            t.OwnerId = userId;
            update t;
        }
        
    }
       
}