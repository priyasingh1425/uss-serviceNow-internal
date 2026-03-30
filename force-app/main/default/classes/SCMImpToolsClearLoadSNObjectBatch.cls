public with sharing class SCMImpToolsClearLoadSNObjectBatch implements Database.Batchable<sObject>, Database.Stateful {
	
	public Database.QueryLocator start(Database.BatchableContext ctx){
		String query = 'SELECT Id';
		query += ' FROM SCMImpToolsLoad_Serial_Numbers__c';
		query += ' WHERE Has_Error__c = false';
		query += ' AND Serial_Number_Loaded__c = true';
		return Database.getQueryLocator(query);
	}
	
	public void execute(Database.BatchableContext ctx, List<SObject> records) {
		try {
			delete records;
		} catch (Exception ex) {
			SCMC.ErrorLog.log('SCMImpToolsClearLoadSNObjectBatch.execute', 'Error with deleting records: ', ex);
			SCMC.ErrorLog.flush();
		}
	}
	
	public void finish(Database.BatchableContext ctx) {
	}
	
}