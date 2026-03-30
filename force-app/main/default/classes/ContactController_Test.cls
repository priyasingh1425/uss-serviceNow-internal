@isTest
private class ContactController_Test {
    static testMethod void validateGetParentContacts() {
        Test.startTest();
        Account customer = new Account(Name='Test Account', Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail',
                                       RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert customer;
        
        List<Contact> contacts = new List<Contact>();
        contacts.add(new Contact(LastName='Contact 1', FirstName='Test', AccountId=customer.Id));
        contacts.add(new Contact(LastName='Contact 2', FirstName='Test', AccountId=customer.Id));
        insert contacts; 
        
        Account account = new Account(Name='Test Account', Type='Account', ParentId=customer.Id, Type_Custom__c='Account', Sub_Type__c='Retail',
                                      RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId());            
        insert account; 
        
        List<Contact> parentContacts = new List<Contact>();     
        parentContacts = ContactController.getParentContacts(account.Id); 
        
        System.assert(parentContacts != null); 
        Test.stopTest();
    }
    
    static testMethod void validateGetContact() {
        Account customer = new Account(Name='Test Account', Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail',
                                       RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert customer; 
        
        Contact con = new Contact(LastName='Contact 1', FirstName='Test',AccountId=customer.Id);
        
        Test.startTest();
        insert con;
        Contact con2 = ContactController.getContact(con.Id);
        System.assert(con2 != null);
        Test.stopTest();
    } 
    
    static testMethod void validateGetContactChangeEmail(){
        Account customer = new Account(Name='Test Account', Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail',
                                       RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId());
        insert customer; 
        
        Contact con = new Contact(LastName='Contact 1', FirstName='Test',AccountId=customer.Id);
        con.Roles__c = 'Accounts Payable, CMC Contact';
        con.Restricted_Roles__c = 2;
        Test.startTest();
        insert con;
        List<BNR_DisabledContact_WRP> wraps = ContactController.getContactChangeEmail(con.Id);
        System.assertEquals('collections@ussignal.com', wraps.get(0).email);
        System.assertEquals('CMC@ussignal.com', wraps.get(1).email);
        Test.stopTest();
    }
}