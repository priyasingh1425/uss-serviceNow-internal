/**
 * Created by Ladd Partners on 11/18/2024.
 */

public with sharing class lp_BillingContractSelector extends lp_Selector {

    public lp_BillingContractSelector(){
        setSObjectType(ffbc__Contract__c.sObjectType);
        addField(ffbc__Contract__c.ffbc__ActiveContract__c);
        addField(ffbc__Contract__c.ffbc__StartDate__c);
        addField(ffbc__Contract__c.ffbc__Status__c);
        addField(ffbc__Contract__c.ffbc__Type__c);
        addField(ffbc__Contract__c.Id);
        addField(ffbc__Contract__c.LPC_Order__c);
        addField(ffbc__Contract__c.Name);
    }

    
    public List<ffbc__Contract__c> getByIds(Set<Id> contractIds){
        String query = getSelectStatement();
        query += ' WHERE Id IN :contractIds';
        return Database.query(query);
    }
    
    public ffbc__Contract__c getActiveChangeRequestByActiveContractId(Id activeContractId){
        ffbc__Contract__c contract = null;
        
        String query = getSelectStatement();
        query += ' WHERE ffbc__Type__c = {0}{1}{0}'; // Change Request
        query += ' AND ffbc__ActiveContract__c = {0}{2}{0}'; // activeContractId
        query += ' AND ffbc__Status__c = {0}{3}{0}'; // Active
        query = String.format(query, new List<String>{ '\'', lp_BillingContract.TYPE_CHANGE_REQUEST, activeContractId, lp_BillingContract.STATUS_ACTIVE });
        List<ffbc__Contract__c> contracts = Database.query(query);
        
        if(!contracts.isEmpty()){
            contract = contracts[0];
        }
        return contract;
    }
}