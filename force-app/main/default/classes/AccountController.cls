public class AccountController {
	@AuraEnabled 
    public static List<Account> getChildAccounts(String recordId) {
        List<Account> children = new List<Account>();
        children = [SELECT Id, Name, CRM_ID__c, Disabled__c, Status__c, Customer_Number__c FROM Account WHERE ParentId=:recordId];        
        return children;
    }
    @AuraEnabled
    public static Account getAccount(String recordId) {
        Account acc = [SELECT Id, Disabled__c, Type FROM Account WHERE Id=:recordId];        
        return acc;
    }
    @AuraEnabled
    public static Account getNewOwnerAccount(String recordId) {
        Account acc = [SELECT Id, New_Owner__c, New_Owner_Text__c FROM Account WHERE Id=:recordId];        
        return acc;
    }

}