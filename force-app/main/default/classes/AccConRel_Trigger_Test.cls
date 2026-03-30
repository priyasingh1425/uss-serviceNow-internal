@isTest
private class AccConRel_Trigger_Test {
    @isTest static void testDeleteACR() {
    	Account customer = new Account(Name='Test Account', Type='Customer', Type_Custom__c='Customer', Sub_Type__c='Retail');
        insert customer;
        Contact contact = new Contact(LastName='Tester', AccountId=customer.Id);
        insert contact; 
        AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountId=:customer.Id AND ContactId=:contact.Id];
        Test.startTest();
        System.debug('ACR is ' + acr);
        Database.DeleteResult result = Database.delete(acr, false);
        System.assert(!result.isSuccess());
        System.Debug('Success is ' + result.isSuccess());
        System.assert(result.getErrors().size() > 0);
        System.Debug('Error Count is ' + result.getErrors().size());
        Test.stopTest();
    }
}