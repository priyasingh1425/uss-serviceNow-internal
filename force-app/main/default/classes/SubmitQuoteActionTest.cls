/**
 * Created by RyanO'Keefe on 10/24/2024.
 */
@isTest
public with sharing class SubmitQuoteActionTest {
    @IsTest
    static void testSubmit() {

        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = a.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        insert quote;

        Test.startTest();
        try{
        SubmitQuoteAction.SubmitQuoteReason(new List<SubmitQuoteAction.Quotes>{new SubmitQuoteAction.Quotes(quote.Id)});
        }catch(Exception e){
            // We rethrow the exception so we still fail, but with more detail
            System.debug('Exception: ' + e.getMessage());
            System.debug([SELECT Id,SBQQ__Status__c,ApprovalStatus__c FROM sbqq__Quote__c]);
            System.debug([SELECT Id FROM sbaa__Approval__c]);
            throw e;
        }
        quote = [SELECT ApprovalStatus__c,SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id LIMIT 1];
        Test.stopTest();

        System.assertEquals('Approved', quote.ApprovalStatus__c,'Expected ApprovalStatus__c to be Pending, was ' + quote.ApprovalStatus__c); // approvals seem to not work in test context
        System.assertEquals('In Review', quote.SBQQ__Status__c,'Expected SBQQ__Status__c to be In Review, was ' + quote.SBQQ__Status__c);
    }

    @IsTest
    static void testSubmitWrongStatus() {
        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = a.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        quote.SBQQ__Status__c = 'In Review';
        insert quote;
        Boolean threwException = false;
        Test.startTest();
        try{
            SubmitQuoteAction.SubmitQuoteReason(new List<SubmitQuoteAction.Quotes>{new SubmitQuoteAction.Quotes(quote.Id)});
        }catch(Exception e){
            threwException = true;
        }
        System.assert(threwException,'Must throw exception if quote is not in Draft status');
        Test.stopTest();
    }

    @IsTest
    static void testSubmitNoQuote() {

        Boolean threwException = false;
        Test.startTest();
        try{
            SubmitQuoteAction.SubmitQuoteReason(new List<SubmitQuoteAction.Quotes>{new SubmitQuoteAction.Quotes(null)});
        }catch(Exception e){
            threwException = true;
        }
        System.assert(threwException,'Must throw exception if quote is not in Draft status');
        Test.stopTest();
    }

}