/**
 * Created by Ladd Partners on 6/13/2025.
 */

@IsTest
private class lp_UpdateBillingContractLineTest {

    @IsTest
    static void cancelContractLine() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        ffbc__ContractLineItem__c contractLine = createContractLine();
        test.startTest();
            lp_UpdateBillingContractLineBatch.runJob(new Set<Id>{ contractLine.Id }, lp_UpdateBillingContractLineBatch.TRANSACTION_TYPE_CANCELED);
        test.stopTest();
        validate(contractLine.id, true);
    }

    @IsTest
    static void updateContractLinePricing() {
        lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled = false;
        ffbc__ContractLineItem__c contractLine = createContractLine();
        test.startTest();
            lp_UpdateBillingContractLineBatch.runJob(new Set<Id>{ contractLine.Id }, lp_UpdateBillingContractLineBatch.TRANSACTION_TYPE_UPDATE_PRICING_NOT_BILLED);
        test.stopTest();
        validate(contractLine.id, true);
    }

    @IsTest
    static void errorCancelingContractLine() {
        ffbc__ContractLineItem__c contractLine = createContractLine();
        test.startTest();
            lp_UpdateBillingContractLineBatch batch = new lp_UpdateBillingContractLineBatch();
            batch.contractLineIds = new Set<Id>{ contractLine.Id };
            batch.transactionType = lp_UpdateBillingContractLineBatch.TRANSACTION_TYPE_CANCELED;
            batch.contractIds = new Set<Id>();
            batch.throwError = true;
            Database.executeBatch(batch, 1);
        test.stopTest();
        validate(contractLine.id, false);
    }

    private static void validate(Id contractId, Boolean hasBeenProcessed){
        List<ffbc__ContractLineItem__c> contractLines = [Select Id,
                                                                Processed_from_Script__c
                                                           from ffbc__ContractLineItem__c
                                                          where Id = :contractId];

        Assert.areNotEqual(0, contractLines.size(), 'Could not locate the Billing Contract Line');
        ffbc__ContractLineItem__c contractLine = contractLines[0];

        Assert.areEqual(hasBeenProcessed, contractLine.Processed_from_Script__c, 'The Processed From Script is not correctly set');
    }

    private static ffbc__ContractLineItem__c createContractLine(){
        ffbc__ContractLineItem__c contractLine = null;
        lp_BillingSetupTest setupTest = new lp_BillingSetupTest();
        lp_BillingSettings.customTriggersAreEnabled = false;

            OrderItem orderProduct = setupTest.setupOrderProductForBillingContract();
            Async_Job_Staging__c job = lp_BillingSetupTest.createAsyncJob(orderProduct.Id, lp_AsyncJobStaging.JOB_BILL_ORDER_ITEMS, true);
            Id contractId = lp_BillingContractLine.billOrderItem(job);

            job = new lp_AsyncJobStagingSelector().getById(job.Id);
            Assert.areEqual(lp_AsyncJobStaging.STATUS_COMPLETED, job.Status__c, 'Error creating the Billing Contract, error: ' + job.Error_Message__c);

            List<ffbc__ContractLineItem__c> contractLines = new lp_BillingContractLineSelector().getByContractIds(new Set<Id> { contractId });
            Assert.areNotEqual(0, contractLines.size(), 'Could not locate any Billing Contract Lines');

            contractLine = contractLines[0];
            contractLine.Date_for_Closing__c = System.today();
            update contractLine;

        lp_BillingSettings.customTriggersAreEnabled = true;

        return contractLine;
    }
}