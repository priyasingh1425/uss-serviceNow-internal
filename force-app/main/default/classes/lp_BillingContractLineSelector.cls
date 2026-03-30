/**
 * Created by Ladd Partners on 4/18/2025.
 */

public with sharing class lp_BillingContractLineSelector extends lp_Selector {

    public lp_BillingContractLineSelector(){
        setupQuery(false);
    }

    public lp_BillingContractLineSelector(Boolean doDeepClone) {
        setupQuery(doDeepClone);
    }

    private void setupQuery(Boolean forDeepClone){
        setSObjectType(ffbc__ContractLineItem__c.sObjectType);
        addField(ffbc__ContractLineItem__c.Id);
        addField(ffbc__ContractLineItem__c.Name);
        addField('LPC_Order_Item__r.Usage_Product__c');

        if(forDeepClone) {
            Map<string, Schema.SObjectField> contractLineFields = Schema.SObjectType.ffbc__ContractLineItem__c.fields.getMap();
            for (SObjectField field : contractLineFields.values()) {
                Schema.DescribeFieldResult f = field.getDescribe();
                if(!f.isAutoNumber() &&
                   !f.isCalculated() &&
                   f.getName() != 'Id' &&
                   f.getName() != 'ffbc__TotalBilled__c') {
                    addField(f.getName());
                }
            }
        } else {
            addField(ffbc__ContractLineItem__c.CurrencyIsoCode);
            addField(ffbc__ContractLineItem__c.ffbc__ActiveContractLineItem__c);
            addField('ffbc__ActiveContractLineItem__r.ffbc__Contract__c');
            addField(ffbc__ContractLineItem__c.ffbc__AnalysisItem1__c);
            addField(ffbc__ContractLineItem__c.ffbc__AnalysisItem2__c);
            addField(ffbc__ContractLineItem__c.ffbc__AnalysisItem3__c);
            addField(ffbc__ContractLineItem__c.ffbc__AnalysisItem4__c);
            addField('ffbc__AnalysisItem1__r.Name');
            addField('ffbc__AnalysisItem2__r.Name');
            addField('ffbc__AnalysisItem3__r.Name');
            addField('ffbc__AnalysisItem4__r.Name');
            addField(ffbc__ContractLineItem__c.ffbc__BilledTo__c);
            addField(ffbc__ContractLineItem__c.ffbc__BillingTerm__c);
            addField('ffbc__BillingTerm__r.Name');
            addField(ffbc__ContractLineItem__c.ffbc__BillingType__c);
            addField(ffbc__ContractLineItem__c.ffbc__Canceled__c);
            addField(ffbc__ContractLineItem__c.ffbc__Contract__c);
            addField('ffbc__Contract__r.ffbc__StartDate__c');
            addField('ffbc__Contract__r.ffbc__Status__c');
            addField(ffbc__ContractLineItem__c.ffbc__Description__c);
            addField(ffbc__ContractLineItem__c.ffbc__EndDate__c);
            addField(ffbc__ContractLineItem__c.ffbc__FirstBillDate__c);
            addField(ffbc__ContractLineItem__c.ffbc__OnHold__c);
            addField(ffbc__ContractLineItem__c.ffbc__ProductService__c);
            addField('ffbc__ProductService__r.Usage_Product__c');
            addField(ffbc__ContractLineItem__c.ffbc__Quantity__c);
            addField(ffbc__ContractLineItem__c.ffbc__SalesPrice__c);
            addField(ffbc__ContractLineItem__c.ffbc__StartDate__c);
            addField(ffbc__ContractLineItem__c.ffbc__TotalBilled__c);
            addField(ffbc__ContractLineItem__c.ffbc__TotalContractLineValue__c);
            addField(ffbc__ContractLineItem__c.ffbc__UnitOfMeasure__c);
            addField(ffbc__ContractLineItem__c.ffbc__UnitPrice__c);
            addField(ffbc__ContractLineItem__c.LPC_Circuit_Id__c);
            addField('LPC_Circuit_Id__r.Name');
            addField(ffbc__ContractLineItem__c.LPC_Customer_Notes__c);
            addField(ffbc__ContractLineItem__c.LPC_Customer_Reference__c);
            addField(ffbc__ContractLineItem__c.LPC_General_Ledger_Account__c);
            addField(ffbc__ContractLineItem__c.LPC_LEC_Circuit_Id__c);
            addField(ffbc__ContractLineItem__c.LPC_LEC_Due_Date__c);
            addField(ffbc__ContractLineItem__c.LPC_LEC_Order_Number__c);
            addField(ffbc__ContractLineItem__c.LPC_LEC_Start_Date__c);
            addField(ffbc__ContractLineItem__c.LPC_LEC_Term__c);
            addField(ffbc__ContractLineItem__c.LPC_LEC_Vendor__c);
            addField('LPC_LEC_Vendor__r.Name');
            addField(ffbc__ContractLineItem__c.LPC_Order_Item__c);
            addField(ffbc__ContractLineItem__c.LPC_Sale_Type__c);
            addField(ffbc__ContractLineItem__c.LPC_Service_Type__c);
            addField(ffbc__ContractLineItem__c.LPC_Ship_City_Z__c);
            addField(ffbc__ContractLineItem__c.LPC_Ship_Country_Z__c);
            addField(ffbc__ContractLineItem__c.LPC_Ship_State_Z__c);
            addField(ffbc__ContractLineItem__c.LPC_Ship_Street_Z__c);
            addField(ffbc__ContractLineItem__c.LPC_Ship_Zip_Z__c);
            addField(ffbc__ContractLineItem__c.LPC_Shipping_City__c);
            addField(ffbc__ContractLineItem__c.LPC_Shipping_Country__c);
            addField(ffbc__ContractLineItem__c.LPC_Shipping_State__c);
            addField(ffbc__ContractLineItem__c.LPC_Shipping_Street__c);
            addField(ffbc__ContractLineItem__c.LPC_Shipping_Zip__c);
            addField(ffbc__ContractLineItem__c.LPC_Transaction_Type__c);
            addField(ffbc__ContractLineItem__c.Ordered_Type__c);
        }
    }

    public List<ffbc__ContractLineItem__c> getByContractIds(Set<Id> contractIds){
        String query = getSelectStatement();
        query += ' WHERE ffbc__Contract__c IN :contractIds';
        return Database.query(query);
    }
    
    public List<ffbc__ContractLineItem__c> getByContractId(Id contractId){
        return getByContractIds(new Set<Id>{ contractId });
    }

    public List<ffbc__ContractLineItem__c> getLikeCircuitId(String searchTerm, Boolean useLecCircuitId, Id vendorId){
        List<String> goodStatuses = new List<String>{'Active', 'Draft'};
        String query = getSelectStatement();
        query += ' WHERE ffbc__ContractStatus__c IN :goodStatuses';
        query += useLecCircuitId ? ' AND LPC_LEC_Circuit_ID__c LIKE :searchTerm' : ' AND LPC_Circuit_Id__r.Name LIKE :searchTerm';
        query += ' AND Id NOT IN (SELECT Billing_Contract_Line__c FROM Master_ITS_Payable_Invoice_Line__c WHERE Billing_Contract_Line__c != null)';
        if (vendorId != null) {
            query += ' AND LPC_LEC_Vendor__c = :vendorId';
        }
        query += ' LIMIT 1000'; // for LWC safety
        return Database.query(query);
    }

    public Map<Id, ffbc__ContractLineItem__c> getMapByIdFromContractIds(Set<Id> contractIds){
        return new Map<Id, ffbc__ContractLineItem__c>(getByContractIds(contractIds));
    }
    
    public Map<Id, ffbc__ContractLineItem__c> getMapByActiveContractLineIdFromContractIds(Set<Id> contractIds){
        Map<Id, ffbc__ContractLineItem__c> lineByActiveContractLineId = new Map<Id, ffbc__ContractLineItem__c>();
        List<ffbc__ContractLineItem__c> lines = getByContractIds(contractIds);
        for(ffbc__ContractLineItem__c line : lines){
            if(line.ffbc__ActiveContractLineItem__c != null){
                lineByActiveContractLineId.put(line.ffbc__ActiveContractLineItem__c, line);
            }
        }
        return lineByActiveContractLineId;
    }

    public List<ffbc__ContractLineItem__c> getByIds(Set<Id> ids) {
        String query = getSelectStatement();
        query += ' WHERE Id IN :ids';

        return Database.query(query);
    }

    public ffbc__ContractLineItem__c getById(Id id) {
        ffbc__ContractLineItem__c contractLine = null;
        List<ffbc__ContractLineItem__c> contractLines = getByIds(new Set<Id> { id });
        if (!contractLines.isEmpty()) {
            contractLine = contractLines[0];
        }
        return contractLine;
    }

    public Map<Id, ffbc__ContractLineItem__c> getMapById(Set<Id> ids) {
        return new Map<Id, ffbc__ContractLineItem__c>((getByIds(ids)));
    }

    public List<ffbc__ContractLineItem__c> getRequiresCreditByContractIds(Set<Id> contractIds){
        String query = getSelectStatement();
        query += ' WHERE ffbc__Contract__c IN :contractIds';
        query += ' AND ffbc__EndDate__c < ffbc__BilledTo__c';
        return Database.query(query);
    }
    
    public List<ffbc__ContractLineItem__c> getRequiresCreditByContractId(Id contractId){
        return getRequiresCreditByContractIds(new Set<Id>{ contractId });
    }
}