global class Delete_Scheduled_SalesloftAdminCalls implements Schedulable {

    global void execute(SchedulableContext ctx){
        String soql = 'Select Id from Task where RecordType.Name = \'Call\' and CreatedBy.Name = \'Salesloft Administrator\' and CreatedDate < N_MONTHS_AGO:12 ALL ROWS';
        	DeleteRecordsBatchable batchable = new DeleteRecordsBatchable(soql);
			System.debug('batchable ' + batchable);
		Database.executeBatch(batchable);   
            }
 
}