/*************************************************
* Name: INV_Case_AutoCloseResolved_BTC
* Description: Batchable class for bulk processing cases that need to be closed 
* Called by flow: Auto Close Resolved Cases
* Related Classes: INV_Case_AutoCloseResolved_BTC
* Test class: INV_Case_AutoCloseResolved_TEST
* ***********************************************/

global class INV_Case_AutoCloseResolved_BTC implements Database.Batchable<sObject>,Database.Stateful {
    
    global final String query;
    
    global INV_Case_AutoCloseResolved_BTC(){
        
        this.query = 'SELECT Id, Status FROM Case WHERE Status = \'Resolved\' AND Auto_Close_Date__c != null AND Auto_Close_Date__c <= TODAY';
        
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Case> cases = new List<Case>();
        for (sObject s : scope) {
            Case c = (Case)s;
            c.Status = 'Closed';
            cases.add(c);
        }
        Database.SaveResult[] SaveResultList = Database.update(cases, false);
        for(Database.SaveResult s : SaveResultList){
            String msg='';
                If(!s.isSuccess()){     
                    for(Database.Error err: s.getErrors()){  
                        msg += err.getmessage()+'"\n\n';
                    } 
                } 
            System.debug('msg');
        } 
        }

    global void finish(Database.BatchableContext BC) {
    }
}