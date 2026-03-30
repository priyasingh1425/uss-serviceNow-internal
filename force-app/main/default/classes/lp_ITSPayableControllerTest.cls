/**
 * @author Ladd Partners
 * @date 4/18/2025
*/

@isTest
private class lp_ITSPayableControllerTest {
    private static final String LEC_CIRCUIT_ID = '11111';
    private static final String LPC_LEC_TERM = '12';
    private static final String ORDERED_TYPE_1 = 'Cellular';
    private static final String ORDERED_TYPE_2 = 'Failover';
    private static final String BILLING_TYPE_1 = 'Recurring Fixed';
    private static final String BILLING_TYPE_2 = 'Recurring Variable';
    private static final String CHARGE_TYPE_1 = 'Annual Recurring Charge';
    private static final String CHARGE_TYPE_2 = 'Monthly Recurring Charge';
    private static final String ITS_STATUS_CANCELLED = 'Cancelled';
    private static final String ITS_STATUS_ACTIVE = 'Active';
    private static final Decimal AMT_PAID_1 = 50.00;
    private static final Decimal AMT_PAID_2 = 25.25;
    private static final Decimal AMT_PAID_TOTAL = 75.25;
    private static final Date ITS_INVOICE_DATE = Date.today();
    private static final Date ITS_DUE_DATE = Date.today().addDays(15);
    private static final Integer ITS_NET_TERM = 15;
    private static final String PAYABLE_STATUS = 'In Progress';
    private static final Boolean PAYABLE_DERIVE_CURRENCY = true;
    private static final Boolean PAYABLE_DERIVE_PERIOD = true;
    private static final Boolean PAYABLE_LINE_DERIVE_LINE = true;

    private static final String ITS_ROLLUP_WRONG = 'Sum of Amt Paid from Lines was wrong!';
    private static final String ITS_NET_TERM_WRONG = 'Net Term calculated from Date Difference was wrong!';
    private static final String ITS_STATUS_WRONG = 'Status was calculated incorrect from Billing Contract Status Formula Field!';
    private static final String PAYABLE_NOT_FOUND = 'Monthly Payable was not generated and could not be queried!';
    private static final String PAYABLE_LINE_DESCRIPTION_WRONG = 'Incorrect LEC Circuit ID or Charge Type concatenation!';
    private static final String PAYABLE_INCORRECT_MAPPING = 'Incorrect mapping!';

    @isTest
    private static void createMonthlyPayableInvoiceFromITSPayable() {
        lp_SetupTestFFA.createBaseFFAData('US Signal Company, LLC', 'US Checking');
        lp_SetupTestFFA.TestData testData = lp_SetupTestFFA.testData;

        System.runAs(testData.TestUser) {
            Product2 testProduct = lp_SetupTestFFA.createProduct(testData.GLAMap.get('grossRevenue').Id, testData.GLAMap.get('cogs').Id, true);
            testProduct.Name = '2 x 1 Gbps CDC Connection';
            update testProduct;

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

            Account testAccount = testData.Account;
            Id vendorRecordType = lp_Utility.getRecordType(Account.getSObjectType(), 'Vendor');
            testAccount.RecordTypeId = vendorRecordType;
            update testAccount;

            //Creating Billing Contract
            ffbc__Contract__c billContract = new ffbc__Contract__c();
            billContract.ffbc__StartDate__c = Date.today();
            billContract.ffbc__EndDate__c = Date.today().addYears(1);
            billContract.ffbc__Account__c = testData.Account.Id;
            billContract.ffbc__ContractName__c = 'TestContract';
            insert billContract;

            ffbc__ContractLineItem__c bcLine1 = new ffbc__ContractLineItem__c();
            bcLine1.ffbc__ProductService__c = testProduct.Id;
            bcLine1.ffbc__Contract__c = billContract.Id;
            bcLine1.ffbc__FirstBillDate__c = Date.today().addDays(1);
            bcLine1.ffbc__EndDate__c = Date.today().addDays(90);
            bcLine1.ffbc__BillingTerm__c = softDate.Id;
            bcLine1.LPC_LEC_Circuit_ID__c = LEC_CIRCUIT_ID;
            bcLine1.LPC_Circuit_Id__c = summary.Id;
            bcLine1.LPC_LEC_Term__c = LPC_LEC_TERM;
            bcLine1.Ordered_Type__c = ORDERED_TYPE_1;
            bcLine1.LPC_LEC_Start_Date__c = Date.today();
            bcLine1.LPC_LEC_Due_Date__c = Date.today().addDays(10);
            bcLine1.ffbc__BillingType__c = BILLING_TYPE_1;
            bcLine1.ffbc__Quantity__c = 1;
            bcLine1.ffbc__Canceled__c = true;
            insert bcLine1;

            ffbc__ContractLineItem__c bcLine2 = new ffbc__ContractLineItem__c();
            bcLine2.ffbc__ProductService__c = testProduct.Id;
            bcLine2.ffbc__Contract__c = billContract.Id;
            bcLine2.ffbc__FirstBillDate__c = Date.today().addDays(1);
            bcLine2.ffbc__EndDate__c = Date.today().addDays(150);
            bcLine2.ffbc__BillingTerm__c = softDate.Id;
            bcLine2.LPC_LEC_Circuit_ID__c = LEC_CIRCUIT_ID;
            bcLine2.LPC_Circuit_Id__c = summary.Id;
            bcLine2.LPC_LEC_Term__c = LPC_LEC_TERM;
            bcLine2.Ordered_Type__c = ORDERED_TYPE_2;
            bcLine2.LPC_LEC_Start_Date__c = Date.today();
            bcLine2.LPC_LEC_Due_Date__c = Date.today().addDays(10);
            bcLine2.ffbc__BillingType__c = BILLING_TYPE_2;
            bcLine2.ffbc__Quantity__c = 1;
            bcLine2.ffbc__Canceled__c = false;
            insert bcLine2;

            //Call FF API to update Billing Contract Status
            ffbc.ContractsService.ActivationRequest activationRequest = new ffbc.ContractsService.ActivationRequest();
            activationRequest.ContractIds = new Set<Id>{ billContract.Id };
            activationRequest.MonthsToGenerate = 0;

            ffbc.ContractsService.ActivationResponse resp = ffbc.ContractsService.activation(activationRequest);
            //Check FF API Response for errors
            if (resp.hasErrors()) {
                String errorMessage = '';
                for (Id errorId : resp.getErrors().keySet()) {
                    errorMessage = 'Activation Failed Error ' + errorId + ': ';

                    for (String error : resp.getErrors().get(errorId)) {
                        errorMessage += error + '\n';
                    }

                    System.debug(LoggingLevel.ERROR, errorMessage);
                }
            }

            //Verify Billing Contract is Active
            billContract = [SELECT Id, ffbc__Status__c FROM ffbc__Contract__c WHERE Id = :billContract.Id];
            Assert.areEqual('Active', billContract.ffbc__Status__c, 'Incorrect Status!');

            //Creating ITS Payable Invoice from Billing Contract
            Master_ITS_Payable_Invoice__c itsInvoice = new Master_ITS_Payable_Invoice__c();
            itsInvoice.Vendor__c = testData.Account.Id;
            itsInvoice.Invoice_Number__c = '123456';
            itsInvoice.Invoice_Date__c = ITS_INVOICE_DATE;
            itsInvoice.Due_Date__c = ITS_DUE_DATE;
            itsInvoice.Invoice_Amount__c = 1000.50;
            insert itsInvoice;

            Master_ITS_Payable_Invoice_Line__c itsInvoiceLine1 = new Master_ITS_Payable_Invoice_Line__c();
            itsInvoiceLine1.Master_ITS_Payable_Invoice__c = itsInvoice.Id;
            itsInvoiceLine1.Billing_Contract_Line__c = bcLine1.Id;
            itsInvoiceLine1.LEC_CIRCUIT_ID__c = LEC_CIRCUIT_ID;
            itsInvoiceLine1.Charge_Type__c = CHARGE_TYPE_1;
            itsInvoiceLine1.Amt_Paid__c = AMT_PAID_1;
            itsInvoiceLine1.General_Ledger_Account_Number__c = testData.GLAMap.get('accountsPayableControl').Id;
            itsInvoiceLine1.Department__c = testData.Dimension1.Id;
            itsInvoiceLine1.State__c = testData.Dimension2.Id;
            itsInvoiceLine1.Location__c = testData.Dimension3.Id;
            itsInvoiceLine1.Product__c = testData.Dimension4.Id;
            insert itsInvoiceLine1;

            Master_ITS_Payable_Invoice_Line__c itsInvoiceLine2 = new Master_ITS_Payable_Invoice_Line__c();
            itsInvoiceLine2.Master_ITS_Payable_Invoice__c = itsInvoice.Id;
            itsInvoiceLine2.Billing_Contract_Line__c = bcLine2.Id;
            itsInvoiceLine2.LEC_CIRCUIT_ID__c = LEC_CIRCUIT_ID;
            itsInvoiceLine2.Charge_Type__c = CHARGE_TYPE_2;
            itsInvoiceLine2.Amt_Paid__c = AMT_PAID_2;
            itsInvoiceLine2.General_Ledger_Account_Number__c = testData.GLAMap.get('accountsPayableControl').Id;
            itsInvoiceLine2.Department__c = testData.Dimension1.Id;
            itsInvoiceLine2.State__c = testData.Dimension2.Id;
            itsInvoiceLine2.Location__c = testData.Dimension3.Id;
            itsInvoiceLine2.Product__c = testData.Dimension4.Id;
            insert itsInvoiceLine2;

            //Verify Formula Fields on ITS Header and Line are populated proper
            itsInvoice = new lp_ITSPayableSelector().getWithLinesById(itsInvoice.Id);
            Assert.areEqual(AMT_PAID_TOTAL, itsInvoice.Calculated_Total__c, ITS_ROLLUP_WRONG);
            Assert.areEqual(ITS_NET_TERM, itsInvoice.Net_Term__c, ITS_NET_TERM_WRONG);

            for(Master_ITS_Payable_Invoice_Line__c line : itsInvoice.Master_ITS_Payable_Invoice_Lines__r) {
                if(line.Billing_Contract_Line__c == bcLine1.Id) {
                    Assert.areEqual(ITS_STATUS_CANCELLED, line.Billing_Contract_Status__c, ITS_STATUS_WRONG);
                }
                else if(line.Billing_Contract_Line__c == bcLine2.Id) {
                    Assert.areEqual(ITS_STATUS_ACTIVE, line.Billing_Contract_Status__c, ITS_STATUS_ACTIVE);
                }
            }

            Test.startTest();

            //Create Monthly Payable Invoice from ITS Payable Invoice
            lp_MessageWrapper result = lp_ITSPayableController.createMonthlyPayableInvoice(itsInvoice.Id);

            Test.stopTest();

            //Verify Monthly Payable Invoice exists and check complex fields
            Assert.areEqual(true, result.newRecordId != null, PAYABLE_NOT_FOUND);

            c2g__codaPurchaseInvoice__c resultMonthly = new lp_MonthlyPayableInvoiceSelector().getWithLinesById(result.newRecordId);
            Assert.areEqual(itsInvoice.Id, resultMonthly.Master_ITS_Payable_Invoice__c, PAYABLE_INCORRECT_MAPPING);
            Assert.areEqual(testData.Account.Id, resultMonthly.c2g__Account__c, PAYABLE_INCORRECT_MAPPING);
            Assert.areEqual(testData.CurrentCompany.Id, resultMonthly.c2g__OwnerCompany__c, PAYABLE_INCORRECT_MAPPING);
            Assert.areEqual(PAYABLE_STATUS, resultMonthly.c2g__InvoiceStatus__c, PAYABLE_INCORRECT_MAPPING);
            Assert.isNotNull(resultMonthly.c2g__Period__c, PAYABLE_INCORRECT_MAPPING);
            Assert.isNotNull(resultMonthly.c2g__InvoiceCurrency__c, PAYABLE_INCORRECT_MAPPING);

            for(c2g__codaPurchaseInvoiceExpenseLineItem__c line : resultMonthly.c2g__PurchaseInvoiceExpenseLineItems__r) {
                Assert.areEqual(testData.CurrentCompany.Id, line.c2g__OwnerCompany__c, PAYABLE_INCORRECT_MAPPING);

                if(line.Master_ITS_Payable_Invoice_Line__c == itsInvoiceLine1.Id) {
                    Assert.areEqual(LEC_CIRCUIT_ID + ' ' + CHARGE_TYPE_1, line.c2g__lineDescription__c, PAYABLE_INCORRECT_MAPPING);
                }
                else if(line.Master_ITS_Payable_Invoice_Line__c == itsInvoiceLine2.Id) {
                    Assert.areEqual(LEC_CIRCUIT_ID + ' ' + CHARGE_TYPE_2, line.c2g__lineDescription__c, PAYABLE_INCORRECT_MAPPING);
                }
            }
        }
    }
}