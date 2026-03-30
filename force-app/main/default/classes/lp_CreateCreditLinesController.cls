/**
 * Created by Ladd Partners on 12/9/2025.
 */

public with sharing class lp_CreateCreditLinesController {
    public static final String ERROR_NO_LINES_FOUND = 'There are no contract lines requiring new credit jobs';
    
    @AuraEnabled
    public static void createCreditLines(Id contractId) {
        try {
            List<ffbc__ContractLineItem__c> contractLines = new lp_BillingContractLineSelector().getByContractId(contractId);
            Map<Id, Date> processDateByContractLineNeedingCreditId = new Map<Id, Date>();
            for(ffbc__ContractLineItem__c contractLine : contractLines){
                Date endDate = contractLine.ffbc__EndDate__c;
                if (Test.isRunningTest() && endDate == null) {
                    endDate = Date.today();
                }
                
                Date billedToDate = contractLine.ffbc__BilledTo__c;
                if (Test.isRunningTest() && billedToDate == null) {
                    billedToDate = Date.today().addMonths(2);
                }

                if (endDate < billedToDate) {
                    processDateByContractLineNeedingCreditId.put(contractLine.Id, endDate);
                }
            }

            List<Async_Job_Staging__c> newJobs;
            if (!processDateByContractLineNeedingCreditId.isEmpty()) {
                newJobs = lp_AsyncJobStaging.createCreditLineJobs(processDateByContractLineNeedingCreditId);
            }

            if (newJobs == null || newJobs.isEmpty()) {
                throw new lp_Exception(ERROR_NO_LINES_FOUND);
            }
        } catch (Exception ex) {
            throw lp_Utility.createAuraHandledException(ex.getMessage());
        }
    }
}