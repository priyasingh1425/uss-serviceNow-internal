/* 
 * Created by Ladd Partners on 5/19/2025.
 */

public with sharing class lp_GeneralLedgerAccountSelector extends lp_Selector {
    public lp_GeneralLedgerAccountSelector() {
        setSObjectType(c2g__codaGeneralLedgerAccount__c.getSObjectType());
        addField(c2g__codaGeneralLedgerAccount__c.c2g__ReportingCode__c);    
        addField(c2g__codaGeneralLedgerAccount__c.Id);
        addField(c2g__codaGeneralLedgerAccount__c.Name);    
    }

    public List<c2g__codaGeneralLedgerAccount__c> getByReportingCodes(Set<String> reportingCodes) {
        String query  = getSelectStatement();
        query += ' WHERE c2g__ReportingCode__c IN :reportingCodes';
        return Database.query(query);
    }

    public c2g__codaGeneralLedgerAccount__c getByReportingCode(String reportingCode) {
        c2g__codaGeneralLedgerAccount__c gla = null;
        List<c2g__codaGeneralLedgerAccount__c> glas = getByReportingCodes(new Set<String>{ reportingCode });
        if (!glas.isEmpty()) {
            gla = glas[0];
        }
        return gla;
    }
}