public class ContactController {
	@AuraEnabled 
    public static List<Contact> getParentContacts(String recordId) {
        Account account = new Account();
        account = [SELECT Id, ParentId FROM Account WHERE Id=:recordId];
        List<Contact> contacts = new List<Contact>();
        if (account != null) {
            contacts = [SELECT Id, Name, CRM_ID__c, Phone, Email, Disabled__c, Roles__c FROM Contact WHERE AccountId=:account.ParentId];        
        }
        return contacts;
    }
    @AuraEnabled
    public static Contact getContact(String recordId) {
        Contact con = [SELECT Id, Disabled__c, Restricted_Roles__c, Roles__c FROM Contact WHERE Id=:recordId];        
        return con;
    }
    
    @AuraEnabled
    public static List<BNR_DisabledContact_WRP> getContactChangeEmail(String recordId) {
        Contact con = [SELECT Id, Roles__c FROM Contact WHERE Id=:recordId];   
        List<String> spl = con.Roles__c.split(', ');
        Set<String> splDistinct = new Set<String>(spl);
        List<String> recordRoles = new List<String>(splDistinct);
        
        StaticResource sr = [SELECT Id, Name, Body FROM StaticResource WHERE Name = 'cmpDisabledContact_ContactChangeEmail'].get(0);
        Map<String, Object> parsedSR = (Map<String, Object>) JSON.deserializeUntyped(sr.Body.toString());
        List<BNR_DisabledContact_WRP> results = new List<BNR_DisabledContact_WRP>();
        for(String key: parsedSR.keySet()){
            if(recordRoles.contains(key)){
               results.add(new BNR_DisabledContact_WRP(key, parsedSR.get(key).toString())); 
            }
        }
        system.debug('results: ' + results);
        return results;
    }

}