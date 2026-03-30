/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_EcmsCertificateSelector extends lp_Selector {

    public lp_EcmsCertificateSelector() {
        setSObjectType(ECMS_Certificate__c.getSObjectType());
        addField(ECMS_Certificate__c.Id);
        addField(ECMS_Certificate__c.Name);
        addField(ECMS_Certificate__c.Account__c);
        addField(ECMS_Certificate__c.Account_Number__c);
        addField(ECMS_Certificate__c.Certificate_Id__c);
        addField(ECMS_Certificate__c.City__c);
        addField(ECMS_Certificate__c.Country__c);
        addField(ECMS_Certificate__c.County__c);
        addField(ECMS_Certificate__c.Designator_Id__c);
        addField(ECMS_Certificate__c.Designator_Name__c);
        addField(ECMS_Certificate__c.Designator_Type__c);
        addField(ECMS_Certificate__c.Domain__c);
        addField(ECMS_Certificate__c.ECMS_Account_Id__c);
        addField(ECMS_Certificate__c.Effective_Date__c);
        addField(ECMS_Certificate__c.Effective_Date_Raw__c);
        addField(ECMS_Certificate__c.Exemption__c);
        addField(ECMS_Certificate__c.Expiration_Date__c);
        addField(ECMS_Certificate__c.Expiration_Date_Raw__c);
        addField(ECMS_Certificate__c.Processing_Message__c);
        addField(ECMS_Certificate__c.Processing_Status__c);
        addField(ECMS_Certificate__c.Scope__c);
        addField(ECMS_Certificate__c.State__c);
        addField(ECMS_Certificate__c.Tax_Type__c);
    }

    public List<ECMS_Certificate__c> getOpenByECMSAccountNumber(Set<String> ecmsAccountNumbers) {
        String statusNew = lp_EcmsCertificate.PROCESSING_STATUS_NEW;
        String statusError = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;

        String query = getSelectStatement();
        query += ' WHERE Account_Number__c IN :ecmsAccountNumbers';
        query += ' AND (Processing_Status__c = :statusNew';
        query += ' OR Processing_Status__c = :statusError)';
        query += ' AND Exemption__c = NULL';

        return Database.query(query);
    }

    public List<ECMS_Certificate__c> getOpenByECMSAccountId(Set<String> ecmsAccountIds) {
        String statusNew = lp_EcmsCertificate.PROCESSING_STATUS_NEW;
        String statusError = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;

        String query = getSelectStatement();
        query += ' WHERE ECMS_Account_Id__c IN :ecmsAccountIds';
        query += ' AND (Processing_Status__c = :statusNew';
        query += ' OR Processing_Status__c = :statusError)';
        query += ' AND Exemption__c = NULL';

        return Database.query(query);
    }

}