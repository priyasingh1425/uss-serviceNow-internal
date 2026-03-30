global class DeleteRecordsBatchable implements Database.Batchable<sObject> { 
    
    // created to bulk delete records - use with care!
    // 
    //DeleteRecordsBatchable batchable = new DeleteRecordsBatchable('Select Id From Case Where CaseNumber = \'00237682\' limit 1');
	//System.debug('batchable ' + batchable);
	//Database.executeBatch(batchable);
    
    // Fields
    global final String Query;
    
    // Constructor
    global DeleteRecordsBatchable(String q) {
        Query = q;
    }
    
    // Start
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
 
    // Execute
    global void execute( Database.BatchableContext bc, List<sObject> scope) {
        Database.delete(scope,false);
        Database.emptyRecycleBin(scope);
    }
    
    // Finish
    global void finish(Database.BatchableContext bc) {}
}