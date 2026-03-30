@isTest
public with sharing class Quote_ExpirationSchedulableHandlerTest 
{
    @TestSetup
    static void testSetup()
    {
        Account a = new Account();
        a.Name = 'Test';
        insert a;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = a.id;
        q.SBQQ__Opportunity2__c = opp.Id;
        q.SBQQ__Primary__c = true;
        q.SBQQ__ExpirationDate__c = Date.today().addDays(1);
        insert q;

    }

    @isTest
    public static void TestHandler()
    {
        SBQQ__Quote__c q = [SELECT ID, Reminder_Sent__c FROM SBQQ__Quote__c LIMIT 1];
        System.assertEquals(false, q.Reminder_Sent__c, 'Reminder sent flag should not be set.');
        Quote_ExpirationSchedulableHandler qesh = new Quote_ExpirationSchedulableHandler();
        qesh.execute(null);

        q = [SELECT ID, Reminder_Sent__c FROM SBQQ__Quote__c WHERE ID = :q.id LIMIT 1];
        System.assertEquals(true, q.Reminder_Sent__c, 'Reminder sent flag should be set.');
    }
    
}