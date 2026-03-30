global class Delete_Scheduled_AutoResponse implements Schedulable {

    global void execute(SchedulableContext ctx){
        String soql = 'Select Id FROM Task WHERE (Subject Like \'Email: Case Received (Case: \' or Subject Like \'Email: Case % - We have received your support request\') and CreatedBy.Name = \'System\'';
        	DeleteRecordsBatchable batchable = new DeleteRecordsBatchable(soql);
			System.debug('batchable ' + batchable);
		Database.executeBatch(batchable);   
            }
 
}