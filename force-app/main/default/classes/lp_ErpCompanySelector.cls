/**
 * Created by Ladd Partners on 4/23/2025.
 */

public with sharing class lp_ErpCompanySelector extends lp_Selector {

    public lp_ErpCompanySelector() {
        setSObjectType(fferpcore__Company__c.getSObjectType());
        addField(fferpcore__Company__c.Id);
        addField(fferpcore__Company__c.Name);
    }

    public List<fferpcore__Company__c> getByNames(Set<String> names) {
        String query = getSelectStatement();
        query += ' WHERE Name IN :names';
        return Database.query(query);
    }
    
    public fferpcore__Company__c getByName(String name) {
        return getByName(name, true);
    }

    public fferpcore__Company__c getByName(String name, Boolean errorOnNull) {
        List<fferpcore__Company__c> companies = getByNames(new Set<String>{ name });
        fferpcore__Company__c company = companies.isEmpty() ? null : companies[0];
        if(company == null && errorOnNull){
            throw new lp_Exception(String.format(lp_ErpCompany.ERROR_COMPANY_NOT_FOUND, new List<String>{ name }));
        }
        return company;
    }

    public fferpcore__Company__c getUsSignal() {
        return getByName(lp_ErpCompany.NAME_US_SIGNAL);
    }
}