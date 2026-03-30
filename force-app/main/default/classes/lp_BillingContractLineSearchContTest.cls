/*
*  Created by Ladd Partners on 05/09/2025.
*/

@IsTest
public with sharing class lp_BillingContractLineSearchContTest {
    private static final String LEC_CIRCUIT_ID = '121212';

    @IsTest
    private static void testController() {
        runTest(new TestSettings());
    }

    @IsTest
    private static void testErrors() {
        TestSettings ts = new TestSettings();
        ts.testError = true;
        runTest(ts);
    }
    
    private static void runTest(TestSettings settings) {
        if (settings.testError) {
            lp_BillingContractLineSearchController.ResultWrapper errorWrapper = lp_BillingContractLineSearchController.createITSPayableInvoiceline(null);
            Assert.isTrue(errorWrapper.error, 'Expected an error from incorrect create ITS line item method call');
            errorWrapper = lp_BillingContractLineSearchController.searchContractLineItems('', false, null);
            Assert.isTrue(errorWrapper.warning, 'Expected a warning from controller that no billing lines were found');
            Assert.areEqual(lp_BillingContractLineSearchController.ERROR_NO_LINES_FOUND, errorWrapper.message, 'Unexpected warning message returned from controller');
            errorWrapper = lp_BillingContractLineSearchController.searchContractLineItems(null, null, null);
            Assert.isTrue(errorWrapper.error, 'Expected an error from controller due to incorrect search contract lines method call');
            return;
        }
        
        lp_SetupTestFFA.createBaseFFAData('US Signal Company, LLC', 'US Checking');
        lp_SetupTestFFA.TestData testData = lp_SetupTestFFA.testData;

        System.runAs(testData.TestUser) {
            Service_Summary__c summary = new Service_Summary__c();
            summary.Name = 'Summary - Test';
            summary.Customer_Account__c = testData.Account.Id;
            insert summary;

            ffbc__SoftDate__c softDate = new ffbc__SoftDate__c();
            softDate.Name = 'Monthly';
            softDate.ffbc__Definition__c = '+1M';
            softDate.ffbc__EstimatedDaysPerTerm__c = 30;
            softDate.ffbc__MrrMultiplier__c = 1.0;
            insert softDate;

            ffbc__Contract__c billingContract = new ffbc__Contract__c();
            billingContract.ffbc__StartDate__c = Date.today();
            billingContract.ffbc__EndDate__c = Date.today().addYears(1);
            billingContract.ffbc__Account__c = testData.Account.Id;
            billingContract.ffbc__ContractName__c = 'TestContract';
            insert billingContract;

            ffbc__ContractLineItem__c bcLine = new ffbc__ContractLineItem__c();
            bcLine.ffbc__ProductService__c = testData.Product.Id;
            bcLine.ffbc__Contract__c = billingContract.Id;
            bcLine.ffbc__FirstBillDate__c = Date.today().addDays(1);
            bcLine.ffbc__EndDate__c = Date.today().addDays(90);
            bcLine.ffbc__BillingTerm__c = softDate.Id;
            bcLine.LPC_LEC_Circuit_ID__c = LEC_CIRCUIT_ID;
            bcLine.LPC_Circuit_Id__c = summary.Id;
            bcLine.LPC_LEC_Term__c = '12';
            bcLine.Ordered_Type__c = 'Cellular';
            bcLine.LPC_LEC_Start_Date__c = Date.today();
            bcLine.LPC_LEC_Due_Date__c = Date.today().addDays(10);
            bcLine.ffbc__BillingType__c = 'Recurring Fixed';
            bcLine.ffbc__Quantity__c = 1;
            bcLine.ffbc__Canceled__c = true;
            insert bcLine;

            Master_ITS_Payable_Invoice__c itsInvoice = new Master_ITS_Payable_Invoice__c();
            itsInvoice.Invoice_Number__c = '123456';
            itsInvoice.Invoice_Date__c = Date.today();
            itsInvoice.Due_Date__c = Date.today().addMonths(1);
            itsInvoice.Invoice_Amount__c = 100.00;
            insert itsInvoice;

            Test.startTest();
            lp_BillingContractLineSearchController.ResultWrapper controllerResult = lp_BillingContractLineSearchController.searchContractLineItems(LEC_CIRCUIT_ID, true, null);
            Assert.isFalse(controllerResult.error, 'Unexpected error returned by the controller while searching for billing contract lines'+controllerResult.message);
            Assert.areEqual(1, controllerResult.contractLines.size(), 'Incorrect number of contract lines found');

            lp_BillingContractLineWrapper wrapper = controllerResult.contractLines[0];
            Assert.areEqual(bcLine.Id, wrapper.id, 'Unexpected billing contract line Id returned from the controller');
            
            Map<String, String> mockLwcContractLine = new Map<String, String>();
            mockLwcContractLine.put('id', wrapper.id);
            mockLwcContractLine.put('name', wrapper.name);
            mockLwcContractLine.put('invoiceId', itsInvoice.Id);
            mockLwcContractLine.put('amount', String.valueOf(wrapper.amount));
            mockLwcContractLine.put('billingType', wrapper.billingType);
            mockLwcContractLine.put('lecCircuitName', wrapper.lecCircuitName);
            mockLwcContractLine.put('lecCircuitTerm', wrapper.lecCircuitTerm);
            mockLwcContractLine.put('lecDueDate', String.valueOf(wrapper.lecDueDate));
            mockLwcContractLine.put('lecStartDate', String.valueOf(wrapper.lecStartDate));
            mockLwcContractLine.put('orderedType', wrapper.orderedType);
            mockLwcContractLine.put('ussCircuitId', wrapper.ussCircuitId);
            mockLwcContractLine.put('ussCircuitName', wrapper.ussCircuitName);

            controllerResult = lp_BillingContractLineSearchController.createITSPayableInvoiceline(mockLwcContractLine);
            Assert.isFalse(controllerResult.error, 'Unexpected error returned by the controller while creating ITS line item'+controllerResult.message);

            String lineId = controllerResult.message;
            Master_ITS_Payable_Invoice_Line__c itsLine = [SELECT Id, Billing_Contract_Line__c FROM Master_ITS_Payable_Invoice_Line__c WHERE Id=:lineId];
            Assert.isNotNull(itsLine, 'Unable to find created ITS line item');
            Assert.areEqual(bcLine.Id, itsLine.Billing_Contract_Line__c, 'Unable to resolve billing contract line from ITS line item');
            Test.stopTest();
        }
    }
    
    private class TestSettings {
        Boolean testError = false;
    }
}