/**
 * Created by Ladd Partners on 12/9/2025.
 */

@IsTest
private class lp_CreateCreditLinesControllerTest {
    static lp_BillingSetupTest setupTest;
    
    @TestSetup
    static void createData() {
        setupTest = new lp_BillingSetupTest(false);
        setupTest.setupOrderProduct_UsageProduct();
    }

    @IsTest
    static void testCreateCreditLines() {
        List<ffbc__ContractLineItem__c> contractLines = [SELECT Id, Name, ffbc__EndDate__c, ffbc__BilledTo__c, ffbc__Contract__c FROM ffbc__ContractLineItem__c];
        Integer contractLinesSize = contractLines.size();
        ffbc__ContractLineItem__c contractLine = contractLines[0];
        test.startTest();
        lp_CreateCreditLinesController.createCreditLines(contractLine.ffbc__Contract__c);
        Test.getEventBus().deliver();
        test.stopTest();
        List<ffbc__ContractLineItem__c> creditContractLines = [SELECT Id, Name, ffbc__EndDate__c, ffbc__BilledTo__c, ffbc__Contract__c FROM ffbc__ContractLineItem__c WHERE ffbc__BillingType__c = :lp_BillingContractLine.BILLING_TYPE_ONE_OFF];
        Assert.areEqual(1, creditContractLines.size(), 'There should be 1 credit contract line');
    }
    
    @IsTest
    static void testCreateCreditLines_Usage() {
        List<ffbc__ContractLineItem__c> contractLines = [SELECT Id, Name, ffbc__EndDate__c, ffbc__BilledTo__c, ffbc__Contract__c FROM ffbc__ContractLineItem__c];
        Integer contractLinesSize = contractLines.size();
        ffbc__ContractLineItem__c contractLine = contractLines[0];

        test.startTest();
        lp_CreateCreditLinesController.createCreditLines(contractLine.ffbc__Contract__c);
        Test.getEventBus().deliver();
        test.stopTest();
        List<ffbc__ContractLineItem__c> creditContractLines = [SELECT Id, Name, ffbc__EndDate__c, ffbc__BilledTo__c, ffbc__Contract__c FROM ffbc__ContractLineItem__c WHERE ffbc__BillingType__c = :lp_BillingContractLine.BILLING_TYPE_ONE_OFF];
        Assert.areEqual(1, creditContractLines.size(), 'There should be 1 credit contract line');
    }
}