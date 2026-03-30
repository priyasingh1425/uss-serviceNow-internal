/**
 * @author Ladd Partners
 * @date 4/23/2025
*/

public with sharing class lp_ExemptionSelector extends lp_Selector {

    public lp_ExemptionSelector() {
        setSObjectType(laddafc__Exemption__c.getSObjectType());
        addField(laddafc__Exemption__c.Id);
    }

    public List<laddafc__Exemption__c> getByCustomerNumber(List<String> customerNumbers, Boolean ignoreDoNotDeleteExemptions) {
        String query = getSelectStatement();
        query += ' WHERE laddafc__Account__r.Customer_Number_Truncated__c IN :customerNumbers';
        if (ignoreDoNotDeleteExemptions) {
            query += ' AND Do_Not_Delete__c = FALSE';
        }

        return Database.query(query);
    }

}