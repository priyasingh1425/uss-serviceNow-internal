/**
 * Created by Ladd Partners on 4/11/2025.
 */

public with sharing class lp_BillingContract {

    public static final String STATUS_ACTIVE = 'Active';
    public static final String STATUS_DRAFT = 'Draft';
    public static final String STATUS_EXPIRED = 'Expired';
    public static final String TYPE_CHANGE_REQUEST = 'Change Request';
    public static final String TYPE_CONTRACT = 'Contract';

    public static ffbc__Contract__c createFromOrder(Order order) {
        ffbc__Contract__c contract = new ffbc__Contract__c();
        contract.CurrencyIsoCode = 'USD';
        contract.ffbc__Account__c = order.Account_Account_Name__c;
        contract.ffbc__Company__c = new lp_ErpCompanySelector().getUsSignal()?.Id;
        contract.ffbc__ContractName__c = order.Opportunity.Name;
        contract.ffbc__Description__c = null;
        contract.ffbc__FirstBillDate__c = order.EffectiveDate;
        contract.ffbc__StartDate__c = order.EffectiveDate;
        contract.ffbc__Status__c = STATUS_DRAFT;
        contract.ffbc__Type__c = TYPE_CONTRACT;
        contract.LPC_Order__c = order.Id;
        contract.LPC_Customer_Reference__c = order.Bundle_Customer_Reference__c;
        return contract;
    }

    public static Id createChangeRequest(Id contractId) {
        Id changeRequestContractId = null;
        try {
            changeRequestContractId = ffbc.ContractsService.createChangeRequest(contractId);
        } catch (Exception e) {
            throwError(e);
        }
        return changeRequestContractId;
    }

    public static void activateContractsOrApplyChange(Set<Id> contractIds) {
        Set<Id> activeContractIds = new Set<Id>();
        Set<Id> applyChangeRequestIds = new Set<Id>();
        List<ffbc__Contract__c> contracts = new lp_BillingContractSelector().getByIds(contractIds);
        
        for(ffbc__Contract__c contract : contracts) {
            if(contract.ffbc__Type__c == TYPE_CHANGE_REQUEST) {
                applyChangeRequestIds.add(contract.Id);
            } else {
                activeContractIds.add(contract.Id);
            }
        }

        if(!activeContractIds.isEmpty()) {
            activateContractsAsync(activeContractIds);
        }

        if(!applyChangeRequestIds.isEmpty()) {
            applyChanges(applyChangeRequestIds);
        }
    }
    
    public static void activateContracts(Set<Id> contractIds) {
        try {
            List<ffbc.ContractsServiceActionActivate.Request> requests = new List<ffbc.ContractsServiceActionActivate.Request>();
            for (Id contractId : contractIds) {
                ffbc.ContractsServiceActionActivate.Request request = new ffbc.ContractsServiceActionActivate.Request();
                request.ContractId = contractId;
                requests.add(request);
            }                
            List<ffbc.ContractsServiceActionActivate.Response> response = ffbc.ContractsServiceActionActivate.activate(requests);
            for (ffbc.ContractsServiceActionActivate.Response res : response) {
                System.debug('Activate Response for Contract Id: ' + res.contractId);
                if (res.hasErrors) {
                    System.debug('Activate Errors: ' + res.errorMessages);
                }
            }
        } catch (Exception e) {
            throwError(e);
        }
    }

    public static void activateContractsAsync(Set<Id> contractIds) {
        try {
            ffbc.ContractsService.ActivationRequest activationRequest = new ffbc.ContractsService.ActivationRequest();
            activationRequest.ContractIds = contractIds;
            Id recordId = ffbc.ContractsService.activationAsync(activationRequest);    
        } catch (Exception e) {
            throwError(e);
        }
    }

    public static void applyChanges(Set<Id> contractIds) {
        try {
            ffbc.ContractsService.ApplyChangeRequestsRequest applyChangeRequest = new ffbc.ContractsService.ApplyChangeRequestsRequest();
            applyChangeRequest.ChangeRequestIds = contractIds;

            if(Test.isRunningTest()){ return; }
            ffbc.ContractsService.ApplyChangeRequestsResponse response = ffbc.ContractsService.applyChangeRequests(applyChangeRequest);
            if(response.hasErrors()) {
                Map<Id, List<String>> errorResponsesMap = response.getErrors();
                for(Id contractId : errorResponsesMap.keySet()) {
                    String errorMessage = errorResponsesMap.get(contractId)[0];
                }
            }
        } catch (Exception e) {
            throwError(e);
        }
    }

    public static Id getActiveChangeRequest(Id contractId) {
        ffbc__Contract__c activeChangeRequest = new lp_BillingContractSelector().getActiveChangeRequestByActiveContractId(contractId);
        Id changeRequestContractId = activeChangeRequest?.Id;
        if(changeRequestContractId == null){
            changeRequestContractId = createChangeRequest(contractId);
        }
        return changeRequestContractId;
    }
    
    public static ffbc__Contract__c end(Id contractId, Date endDate) {
        ffbc__Contract__c endedContract = new ffbc__Contract__c( Id = contractId );
        endedContract.ffbc__OriginalEndDate__c = endDate;
        update endedContract;
        return endedContract;
    }

    @TestVisible private static void throwError(Exception e) {
        lp_Utility.logException(e);
        throw new lp_Exception(e.getMessage(), e, false);
    }
}