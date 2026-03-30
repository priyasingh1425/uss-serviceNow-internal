@isTest
public class OFSController_Test {
	static testMethod void validateGetChildAccounts() {
        Test.startTest();
            String ownerId = UserInfo.getuserId();
        
        String recType = [SELECT Id FROM RecordType WHERE sobjecttype = 'Account' AND Name = 'Customer'].get(0).Id;
        String accRecType = [SELECT Id FROM RecordType WHERE sobjecttype = 'Account' AND Name = 'Account'].get(0).Id;
        
            Account customer = new Account(Name='Test Account', OwnerId=ownerId, RecordTypeId=recType, Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail');
        	insert customer;    
        	List<Account> children = new List<Account>();
                children.add(new Account(Name='Child 1', RecordTypeId=accRecType, Type='Account', ParentId=customer.Id));	
			insert children;
            Opportunity opp = new Opportunity(Name='New Opp', AccountId=customer.Id, OwnerId=ownerId, StageName='Qualification', CloseDate=Date.today(), Chk_Introductory__c=true, Current_MRC__c=1, Primary_Contact_Added__c=true);
			insert opp;
    	    List<Account> childAccounts = new List<Account>();
	        childAccounts = OFSController.getChildAccounts(opp.Id);
            System.assert(childAccounts != null); 
        Test.stopTest();
    }
    
    static testMethod void validateProcessWrapper() {
        String recType = [SELECT Id FROM RecordType WHERE sobjecttype = 'Account' AND Name = 'Customer'].get(0).Id;
        String accRecType = [SELECT Id FROM RecordType WHERE sobjecttype = 'Account' AND Name = 'Account'].get(0).Id;
        Test.startTest();
            String ownerId = UserInfo.getuserId();
            Account customer = new Account(Name='Test Account', OwnerId=ownerId, RecordTypeId=recType, Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail');
			insert customer;             
			List<Account> children = new List<Account>();
                children.add(new Account(Name='Child 1', RecordTypeId=accRecType, Type='Account', ParentId=customer.Id));        
            insert children;
        	Opportunity opp = new Opportunity(Name='New Opp', AccountId=customer.Id, OwnerId=ownerId, StageName='Qualification', CloseDate=Date.today(), Chk_Introductory__c=true, Current_MRC__c=1, Primary_Contact_Added__c=true);
            insert opp;
        	String account_id = children[0].Id;
        	Map<String,String> results = new Map<String,String>();
            results = OFSController.processWrapper(opp.Id, account_id, 'new', UserInfo.getUserId(),'Just a description');
        	System.assert(results != null);
        Test.stopTest();
    }
    
    static testMethod void validateProcessWrapper_Negative() {
        String recType = [SELECT Id FROM RecordType WHERE sobjecttype = 'Account' AND Name = 'Customer'].get(0).Id;
        String accRecType = [SELECT Id FROM RecordType WHERE sobjecttype = 'Account' AND Name = 'Account'].get(0).Id;
        Test.startTest();
            String ownerId = UserInfo.getuserId();
            Account customer = new Account(Name='Test Account', OwnerId=ownerId, RecordTypeId=recType, Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail');
            insert customer; 
        	List<Account> children = new List<Account>();
                children.add(new Account(Name='Child 1', RecordTypeId=accRecType, Type='Account', ParentId=customer.Id));
            insert children;
        	Opportunity opp = new Opportunity(Name='New Opp', AccountId=customer.Id, OwnerId=ownerId, StageName='Qualification', CloseDate=Date.today(), Chk_Introductory__c=true, Current_MRC__c=1, Primary_Contact_Added__c=true);
            insert opp;
        	String account_id = children[0].Id;
        	Map<String,String> results = new Map<String,String>();
            results = OFSController.processWrapper(opp.Id, account_id, 'old', '123','Just a description');
        	System.assert(results != null); 
        Test.stopTest();
    }
    
    @isTest public static void testingTheCallout() {
        Test.setMock(HttpCalloutMock.class, new HttpMockCallout());
        HttpResponse res = HttpCalloutClass.getInfoFromExternalService();
        String actualValue = res.getBody();
        String expectedValue = '{"success":"true","message":"The Order for Service has been created.","code":"API_OFS_CREATED","data":{"token":"OFS!","order_for_service_id":12345,"description":"Just a description"}}';
        System.assertEquals(actualValue, expectedValue);
        System.assertEquals(200, res.getStatusCode());
    }
}