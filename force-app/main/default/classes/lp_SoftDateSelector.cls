/**
 * Created by Ladd Partners on 4/29/2025.
 */

 public with sharing class lp_SoftDateSelector extends lp_Selector {

    public lp_SoftDateSelector() {
        setSObjectType(ffbc__SoftDate__c.sObjectType);
        addField(ffbc__SoftDate__c.Id);
        addField(ffbc__SoftDate__c.Name);
    }

    public List<ffbc__SoftDate__c> getByNames(Set<String> softDateNames) {
        String query = getSelectStatement();
        query += ' WHERE Name IN :softDateNames';
        return Database.query(query);
    }
    
    public ffbc__SoftDate__c getByName(String softDateName) {
        ffbc__SoftDate__c softDate = null;
        List<ffbc__SoftDate__c> softDates = getByNames(new Set<String>{ softDateName });
        if(!softDates.isEmpty()){
            softDate = softDates[0];
        }
        return softDate;
    }

}