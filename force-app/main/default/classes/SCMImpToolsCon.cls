public with sharing class SCMImpToolsCon {

	private class Link {
		public string fullurl {get; set;}
		public string description {get; set;}
		
		public Link(string url, string description) {
			this.fullUrl = url;
			this.description = description;
		}
	}

	public Link[] displayLinks {get; private set;}

	public SCMImpToolsCon() {
		init();
	}
	
	private void init() {		
		displayLinks = new Link[]{};
		
		string baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
		
		// Load Inv
		Schema.DescribeSObjectResult r = SCMImpToolsLoad_Inventory__c.sObjectType.getDescribe();
		displayLinks.add(new Link(baseUrl + '/' + r.getKeyPrefix(), 'Load Inventory'));
		
		// Load Serial Numbers
		r = SCMImpToolsLoad_Serial_Numbers__c.sObjectType.getDescribe();
		displayLinks.add(new Link(baseUrl + '/' + r.getKeyPrefix(), 'Load Serial Numbers'));
		
		// PO Stage
		r = SCMImpToolsPO_Stage__c.sObjectType.getDescribe();
		displayLinks.add(new Link(baseUrl + '/' + r.getKeyPrefix(), 'Purchase Order Stage'));
		
		// SO Stage
		r = SCMImpToolsSO_Stage__c.sObjectType.getDescribe();
		displayLinks.add(new Link(baseUrl + '/' + r.getKeyPrefix(), 'Sales Order Stage'));
	}

}