/**
 * @author Ladd Partners
 * @date 8/14/2025
*/

public with sharing class lp_FacilitySelector extends lp_Selector {

    public lp_FacilitySelector() {
        setSObjectType(Facility__c.getSObjectType());
        addField(Facility__c.Id);
        addField(Facility__c.Name);
        addField(Facility__c.LPC_Analysis_Item_3__c);
        addField(Facility__c.Facility__c);
    }

    public List<Facility__c> getById(Set<Id> ids) {
        String query = getSelectStatement();
        query += ' WHERE Id IN :ids';

        return Database.query(query);
    }

    public List<Facility__c> getByFacility(Set<String> facilities) {
        String query = getSelectStatement();
        query += ' WHERE Facility__c IN :facilities';

        return Database.query(query);
    }

    public Facility__c getByFacility(String facility) {
        List<Facility__c> facilities = getByFacility(new Set<String>{facility});

        Facility__c facilityRecord = null;
        if (facilities.isEmpty() == false) {
            facilityRecord = facilities[0];
        }

        return facilityRecord;
    }

}