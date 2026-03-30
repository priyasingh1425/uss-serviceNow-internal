/**
 * Created by Ladd Partners on 3/7/2025.
 */

public with sharing class lp_CompanySelector extends lp_Selector {

    public lp_CompanySelector() {
        setSObjectType(c2g__codaCompany__c.getSObjectType());
        addField(c2g__codaCompany__c.Id);
        addField(c2g__codaCompany__c.Name);
    }

    public List<c2g__codaCompany__c> getByNames(Set<String> names) {
        String query = getSelectStatement();
        query += ' WHERE Name IN :names';
        return Database.query(query);
    }
    
    public c2g__codaCompany__c getByName(String name) {
        return getByName(name, true);
    }

    public c2g__codaCompany__c getByName(String name, Boolean errorOnNull) {
        List<c2g__codaCompany__c> companies = getByNames(new Set<String>{ name });
        c2g__codaCompany__c company = companies.isEmpty() ? null : companies[0];
        if(company == null && errorOnNull){
            throw new lp_Exception(String.format(lp_Company.ERROR_COMPANY_NOT_FOUND, new List<String>{ name }));
        }
        return company;
    }

    public c2g__codaCompany__c getUsSignal() {
        return getByName(lp_Company.NAME_US_SIGNAL);
    }
}