/**
 * @author Ladd Partners
 * @date 4/16/2025
*/

public with sharing class lp_TaxTypeSelector extends lp_Selector {

    public lp_TaxTypeSelector() {
        setSObjectType(laddafc__Tax_Type__c.getSObjectType());
        addField(laddafc__Tax_Type__c.Id);
        addField(laddafc__Tax_Type__c.Name);
        addField(laddafc__Tax_Type__c.laddafc__Description__c);
        addField(laddafc__Tax_Type__c.laddafc__Tax_Type_Code__c);
    }

    public List<laddafc__Tax_Type__c> getByTaxTypeCode(Set<Integer> taxTypeCodes) {
        String query = getSelectStatement();
        query += ' WHERE laddafc__Tax_Type_Code__c IN :taxTypeCodes';

        return Database.query(query);
    }

    public Map<Integer, laddafc__Tax_Type__c> getByTaxTypeCodeMap(Set<Integer> taxTypeCodes) {
        List<laddafc__Tax_Type__c> taxTypes = getByTaxTypeCode(taxTypeCodes);
        Map<Integer, laddafc__Tax_Type__c> taxTypesByTaxTypeCode = new Map<Integer, laddafc__Tax_Type__c>();

        for (laddafc__Tax_Type__c taxType : taxTypes) {
            taxTypesByTaxTypeCode.put(Integer.valueOf(taxType.laddafc__Tax_Type_Code__c), taxType);
        }

        return taxTypesByTaxTypeCode;
    }

}