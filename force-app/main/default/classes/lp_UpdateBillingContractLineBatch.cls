/**
 * Created by Ladd Partners on 6/12/2025.
 */

public with sharing class lp_UpdateBillingContractLineBatch implements Database.Batchable<sObject>, Database.Stateful  {

    private lp_BatchNotify batchNotify = new lp_BatchNotify();
    @TestVisible private boolean throwError {
        get {
            if(throwError == null){
                throwError = false;
            }
            return throwError;
        }
        set;
    }

    public static final String JOB_NAME = 'Update Billing Contract Lines';
    public static final String TRANSACTION_TYPE_CANCELED = 'Canceled';
    public static final String TRANSACTION_TYPE_UPDATE_PRICING_NOT_BILLED = 'Updating Pricing Not Billed';
    public static final String MISSING_CHANGE_REQUEST_LINE_MESSAGE = 'Could not locate the Change Request Line';

    public Set<Id> contractLineIds { get; set; }
    public String transactionType { get; set; }
    public Set<Id> contractIds { get; set; }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'Select Id, Name, ffbc__Contract__c, ffbc__Contract__r.ffbc__Status__c, ffbc__Contract__r.ffbc__Type__c, ffbc__Canceled__c, Processed_from_Script__c, Date_for_Closing__c, LPC_Order_Item__c, LPC_Order_Item__r.MRC_Per_Unit__c';
        query += '        From ffbc__ContractLineItem__c';
        query += '       Where Id In :contractLineIds';
        Map<String, Object> asyncJobStagingMapping = new Map<String, Object>{'contractLineIds' => contractLineIds };
        return Database.getQueryLocatorWithBinds(query, asyncJobStagingMapping, AccessLevel.SYSTEM_MODE);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<ffbc__ContractLineItem__c> contractLines = (List<ffbc__ContractLineItem__c>) scope;

        if (contractLines.size() > 1) {
            throw new lp_Exception('Can only process one Billing Contract Line at a time', true);
        }

        Savepoint sp = Database.setSavepoint();
        ffbc__ContractLineItem__c contractLine = contractLines[0];
        try {
            Boolean applyChangeRequest = true;

            Id openContractId = contractLine.ffbc__Contract__c;
            List<ffbc__ContractLineItem__c> changeRequestLinesByContractLineId = [Select Id, ffbc__Contract__c
                                                                                    from ffbc__ContractLineItem__c
                                                                                   where ffbc__ActiveContractLineItem__c = :contractLine.Id
                                                                                     and ffbc__Contract__r.ffbc__Status__c = :lp_BillingContract.STATUS_ACTIVE
                                                                                     and ffbc__Contract__r.ffbc__Type__c = :lp_BillingContract.TYPE_CHANGE_REQUEST];

            if(!changeRequestLinesByContractLineId.isEmpty()){
                openContractId = changeRequestLinesByContractLineId[0].ffbc__Contract__c;
                applyChangeRequest = false;
            } else if(contractLine.ffbc__Contract__r.ffbc__Type__c == lp_BillingContract.TYPE_CONTRACT &&
               contractLine.ffbc__Contract__r.ffbc__Status__c == lp_BillingContract.STATUS_ACTIVE){
                openContractId = lp_BillingContract.createChangeRequest(openContractId);
            }

            List<ffbc__ContractLineItem__c> changeRequestLines = new lp_BillingContractLineSelector().getByContractIds(new Set<Id>{ openContractId });
            ffbc__ContractLineItem__c openChangeRequestLine = null;
            for(ffbc__ContractLineItem__c changeRequestLine : changeRequestLines){
                if(changeRequestLine.ffbc__ActiveContractLineItem__c == contractLine.Id ||
                   changeRequestLine.Id == contractLine.Id){
                    openChangeRequestLine = new ffbc__ContractLineItem__c(Id = changeRequestLine.Id);
                    break;
                }
            }

            if(openChangeRequestLine == null || throwError){
                throw new lp_Exception(MISSING_CHANGE_REQUEST_LINE_MESSAGE, true);
            }

            if(transactionType == TRANSACTION_TYPE_CANCELED){
                openChangeRequestLine.ffbc__Canceled__c = true;
                openChangeRequestLine.ffbc__EndDate__c = contractLine.Date_for_Closing__c;
                openChangeRequestLine.Processed_from_Script__c = true;
            } else if(transactionType == TRANSACTION_TYPE_UPDATE_PRICING_NOT_BILLED){
                openChangeRequestLine.ffbc__UnitPrice__c = contractLine.LPC_Order_Item__r.MRC_Per_Unit__c;
                openChangeRequestLine.Processed_from_Script__c = true;
            }

            update openChangeRequestLine;
            if(applyChangeRequest){
                contractIds.add(openContractId);
            }

        } catch (Exception e) {
            Database.rollback(sp);
            System.debug('++++++++ Message: ' + e.getMessage());
            System.debug('++++++++ Line number: ' + e.getLineNumber());
            System.debug('++++++++ Stack trace: ' + e.getStackTraceString());

            batchNotify.errorRecordCount += contractLines.size();
            batchNotify.addNotification('Issue with updating the Billing Contract Line: ' + contractLine.Name, e);
        }
    }

    public void finish(Database.BatchableContext bc) {
        if(batchNotify.errorRecordCount > 0){
            List<String> emailTo = new List<String>{ userInfo.getUserEmail() };
            this.batchNotify.sendEmailNotification(emailTo, JOB_NAME + 'batch completed', ffbc__ContractLineItem__c.getSObjectType());
        }

        if(!contractIds.isEmpty() && lp_BillingSettings.autoActivateContactsOrApplyChangeIsEnabled()){
            lp_BillingContract.activateContractsOrApplyChange(contractIds);
        }
    }

    public static void runJob(Set<Id> contractLineIds, String transactionType) {
        lp_UpdateBillingContractLineBatch batch = new lp_UpdateBillingContractLineBatch();
        batch.contractLineIds = contractLineIds;
        batch.transactionType = transactionType;
        batch.contractIds = new Set<Id>();
        Database.executeBatch(batch, 1);
    }
}