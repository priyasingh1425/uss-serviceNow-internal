public class CpCaseTriggeredUpdates {
    
    public static void attachAsset(Case c){
        //changed to accommodate Service Summary object rather than Asset
        //unit tests located on the test class: TestCpTicketOrder
        CustomException ce = new CustomException();
           try{   
        List<Service_Summary__c> relatedServiceAsList = [SELECT Id, Billing_Account_Account__c, Customer_Account__c FROM Service_Summary__c WHERE Base_Order_ID__c =: Decimal.valueOf(c.AssetBaseID__c)];
		system.debug('relatedServiceAsList ::: ' + relatedServiceAsList);
        
        try{List<Case> queriedTrigger = [SELECT Id, Account_Account_Name__c, AssetId FROM Case WHERE Id =: c.Id];
           } finally {}


            List<Account> relatedAccountAsList = [SELECT Id FROM Account WHERE Id =: relatedServiceAsList.get(0).Billing_Account_Account__c];
            System.debug('realtedAccountAsList ::: ' + relatedAccountAsList);
        c.Account_Account_Name__c = relatedAccountAsList.get(0).Id;
        c.Service_ID__c = relatedServiceAsList.get(0).Id;
        c.AccountId = relatedServiceAsList.get(0).Customer_Account__c;     
        
       System.debug('Account Account Name ' + c.Account_Account_Name__c);   
               } catch(Exception e){
        System.debug('CpCaseTriggeredUpdates general error ::: ' + e);           
        }
    }
}