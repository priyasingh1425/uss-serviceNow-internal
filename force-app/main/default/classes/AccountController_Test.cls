@isTest
private class AccountController_Test {
    static testMethod void validateGetChildAccounts() {
        Account customer = new Account(Name='Test Account', Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail');
        List<Account> children = new List<Account>();
        	children.add(new Account(Name='Child 1', Type='Account', ParentId=customer.Id));	
        Test.startTest();
        	insert customer;        	
        	insert children;        
    	    List<Account> childAccounts = new List<Account>();
	        childAccounts = AccountController.getChildAccounts(customer.Id);
            System.assert(childAccounts != null); 
        Test.stopTest();
    }
    
    static testMethod void validateGetAccount() {
        Account customer = new Account(Name='Test Account', Type='Customer', Type_Custom__c='Customer', 
										Sub_Type__c='Retail', Disabled__c=Datetime.now());
        Account customer2 = new Account();
        Test.startTest();
        	insert customer;
        	customer2 = AccountController.getAccount(customer.Id);
        	System.assert(customer2 != null);
        Test.stopTest();
    } 
}