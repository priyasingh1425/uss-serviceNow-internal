/*
    Copyright (c) 2013 LessSoftware.com, inc.
    All rights reserved.
    
  Class to start batch process to load inventory
*/
public with sharing class SCMImpToolsLoadInventoryExtension {
    
	private ApexPages.StandardSetController setController;

    //this  constructor is invoked from the multi select on the requisition tab
    public SCMImpToolsLoadInventoryExtension(ApexPages.StandardSetController controller) {
    	this.setcontroller = controller;
	}
    
	public PageReference process() {
	    Database.executeBatch(new SCMImpToolsLoadInventory(),3);        
		// Get the sObject describe result for the Account object
		Schema.DescribeSObjectResult r = SCMImpToolsLoad_Inventory__c.sObjectType.getDescribe(); 
		String keyPrefix = r.getKeyPrefix();
		PageReference retPage = new PageReference('/' + keyPrefix + '/o');
	    return retPage;  
	}
	
	public PageReference goback() {
		PageReference retPage = setController.cancel();
		return retPage;
	}
}