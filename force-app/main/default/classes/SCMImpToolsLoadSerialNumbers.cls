public with sharing class SCMImpToolsLoadSerialNumbers {

	private ApexPages.StandardSetController setController	{get; set;}

	public list<SCMImpToolsLoad_Serial_Numbers__c> snList { get; set; }
	public string splitSerialNumber { get; set; }
	
	public SCMImpToolsLoadSerialNumbers(ApexPages.StandardSetController controller){
		this.setController = controller;
	}

	public void clearLoadObject(){
		SCMImpToolsClearLoadSNObjectBatch clearBatch = new SCMImpToolsClearLoadSNObjectBatch();
		Database.executeBatch(clearBatch, 200);
	}

	public void loadSNControlNumbers(){
		SCMImpToolsLoadInventorySNBatch loadSNBatch = new SCMImpToolsLoadInventorySNBatch();
		Database.executeBatch(loadSNBatch, 500);
	}
	
	public void loadIOSerialNumbers(){
		SCMImpToolsLoadIOSNBatch loadSNBatch = new SCMImpToolsLoadIOSNBatch();
		Database.executeBatch(loadSNBatch, 200);
	}
	
	public PageReference goBackList(){
		return this.setController.cancel();
	}

}