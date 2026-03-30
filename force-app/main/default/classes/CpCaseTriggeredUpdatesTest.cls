/**
 * Created by RyanO'Keefe on 11/12/2024.
 */
@IsTest
public with sharing class CpCaseTriggeredUpdatesTest {

    @isTest
    public static void attachAssetTest(){
        //upddated to accommodate Service Summary objects rather than Assets

        //recordTypeId from Account Account record Type
        Id AccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Id CustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
//        Account acct = new Account(Name = 'Test Account', Type = 'Account', RecordTypeId = AccountRecordTypeId);
        Account acct = TestDataFactory.createAccounts(1,'Test Account', 'Account', AccountRecordTypeId)[0];

        //recordTypeId from filter criteria on Asset Customer__c
        Account cust = TestDataFactory.createAccounts(1,'Test Account', 'Account', CustomerRecordTypeId)[0];

        //Asset a = new Asset(AccountID=acct.Id, Name='Test Parent', Base_Order_ID__c= 12345, Customer__c=cust.Id);
        //insert a;
        Service_Summary__c s = new Service_Summary__c(Name = 'Test Service', Billing_Account_Account__c = acct.Id, Customer_Account__c = cust.Id, Base_Order_ID__c = 12345);
        insert s;

        Case c = new Case();

        c.Pin_Verified__c = Boolean.valueOf(true);
        c.AssetBaseID__c = String.valueOf(12345);
        Id CaseRecordTypeId = [SELECT Id, SobjectType FROM RecordType WHERE Name LIKE '%External Customer Support%' AND SobjectType = 'Case' LIMIT 1].Id;
        System.debug('Case Record Type ID: ' + CaseRecordTypeId);
        //set default fields here ***update IDs for Production
        //RecordTypeId = External Customer Support
        c.RecordTypeId = CaseRecordTypeId;
        //OwnerId = TOC Queue (Case)
        ID queueId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue' AND SobjectType = 'Case'].Queue.Id;
        System.debug('Queue ID: ' + queueId);
//        c.OwnerId = queueId; TODO: figure out why this is throwing a invalid cross reference id
        c.Priority = 'Medium';
        c.Origin = 'Customer Portal';
        c.Status = 'New';
//        c.Support_Queue__c = 'TOC Support'; TODO: figure out why this is throwing a invalid cross reference id

        Test.startTest();
        insert c;
        Test.stopTest();

        List<Case> testC = [SELECT Id, AssetBaseID__c, Account_Account_Name__c, AccountId, Service_ID__c FROM Case WHERE AssetBaseID__c = :String.valueOf(s.Base_Order_ID__c)];

        System.assertEquals(acct.Id, testC.get(0).Account_Account_Name__c);
        System.assertEquals(s.Id, testC.get(0).Service_ID__c);
        System.assertEquals(cust.Id, testC.get(0).AccountId);
    }

}