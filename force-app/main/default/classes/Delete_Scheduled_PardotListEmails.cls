global class Delete_Scheduled_PardotListEmails implements Schedulable  {

    global void execute(SchedulableContext ctx){
        String soql = 'SELECT Id FROM Task WHERE Subject Like \'Pardot List Email%\' and CreatedDate < N_MONTHS_AGO:12 ALL ROWS';
        	DeleteRecordsBatchable batchable = new DeleteRecordsBatchable(soql);
			System.debug('batchable ' + batchable);
		Database.executeBatch(batchable);   
            }
 
}