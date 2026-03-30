/**
 * Created by Ladd Partners on 5/7/2025.
 */

 public with sharing class lp_BillingUnitOfMeasureSelector extends lp_Selector {

    public lp_BillingUnitOfMeasureSelector() {
        setSObjectType(ffbc__UnitOfMeasure__c.sObjectType);
        addField(ffbc__UnitOfMeasure__c.Id);
        addField(ffbc__UnitOfMeasure__c.Name);
    }

    public List<ffbc__UnitOfMeasure__c> getByNames(Set<String> unitOfMeasureNames) {
        String query = getSelectStatement();
        query += ' WHERE Name IN :unitOfMeasureNames';
        return Database.query(query);
    }
    
    public ffbc__UnitOfMeasure__c getByName(String unitOfMeasureName) {
        ffbc__UnitOfMeasure__c unitOfMeasure = null;
        List<ffbc__UnitOfMeasure__c> unitOfMeasures = getByNames(new Set<String>{ unitOfMeasureName });
        if(!unitOfMeasures.isEmpty()){
            unitOfMeasure = unitOfMeasures[0];
        }
        return unitOfMeasure;
    }

}