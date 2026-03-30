/**
 * Created by Ladd Partners on 3/25/2025.
 */

public with sharing class lp_EcmsCertificate {

    public static final String PROCESSING_STATUS_NEW = 'New';
    public static final String PROCESSING_STATUS_ERROR = 'Error';
    public static final String PROCESSING_STATUS_PROCESSED = 'Processed';

    public static final String DESIGNATOR_TYPE_TAX_TYPE = 'Tax type';
    public static final String DESIGNATOR_TYPE_TAX_CATEGORY = 'Tax category';

    public static void populateLookups(List<ECMS_Certificate__c> ecmsCertificates, Map<Id, ECMS_Certificate__c> oldEcmsCertificatesById) {
        Set<String> accountNumbers = new Set<String>();
        Set<Integer> taxTypeCodes = new Set<Integer>();

        for (ECMS_Certificate__c ecmsCertificate : ecmsCertificates) {
            ECMS_Certificate__c oldCertificate = oldEcmsCertificatesById?.get(ecmsCertificate.Id);

            if (oldCertificate == null || ecmsCertificate.Account_Number__c != oldCertificate.Account_Number__c) {
                if (ecmsCertificate.Account_Number__c != null) {
                    accountNumbers.add(ecmsCertificate.Account_Number__c);
                }
            }

            if (oldCertificate == null || ecmsCertificate.Designator_Id__c != oldCertificate.Designator_Id__c ||
                    ecmsCertificate.Designator_Type__c != oldCertificate.Designator_Type__c) {
                if (ecmsCertificate.Designator_Type__c == lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE &&
                        ecmsCertificate.Designator_Id__c != null) {
                    taxTypeCodes.add(Integer.valueOf(ecmsCertificate.Designator_Id__c));
                }
            }

            if (oldCertificate == null || ecmsCertificate.Effective_Date_Raw__c != oldCertificate.Effective_Date_Raw__c) {
                try {
                    ecmsCertificate.Effective_Date__c = ecmsCertificate.Effective_Date_Raw__c == null ? null : Date.valueOf(ecmsCertificate.Effective_Date_Raw__c);
                } catch (Exception ex) {
                    // if conversion fails, it will error when it tries to create an AFC exemption
                }
            }

            if (oldCertificate == null || ecmsCertificate.Expiration_Date_Raw__c != oldCertificate.Expiration_Date_Raw__c) {
                try {
                    ecmsCertificate.Expiration_Date__c = ecmsCertificate.Expiration_Date_Raw__c == null ? null : Date.valueOf(ecmsCertificate.Expiration_Date_Raw__c);
                } catch (Exception ex) {
                    // if conversion fails, it will error when it tries to create an AFC exemption
                }
            }
        }

        Map<String, Account> accountsByCustomerNumber = new Map<String, Account>();
        if (!accountNumbers.isEmpty()) {
            accountsByCustomerNumber = new lp_AccountSelector().getByCustomerNumberMap(accountNumbers);
        }

        Map<Integer, laddafc__Tax_Type__c> taxTypesByTaxTypeCode = new Map<Integer, laddafc__Tax_Type__c>();
        if (!taxTypeCodes.isEmpty()) {
            taxTypesByTaxTypeCode = new lp_TaxTypeSelector().getByTaxTypeCodeMap(taxTypeCodes);
        }

        for (ECMS_Certificate__c ecmsCertificate : ecmsCertificates) {
            ECMS_Certificate__c oldCertificate = oldEcmsCertificatesById?.get(ecmsCertificate.Id);

            if (oldCertificate == null || ecmsCertificate.Account_Number__c != oldCertificate.Account_Number__c) {
                if (ecmsCertificate.Account_Number__c != null) {
                    Account a = accountsByCustomerNumber.get(ecmsCertificate.Account_Number__c?.toLowerCase());
                    ecmsCertificate.Account__c = a?.Id;
                } else {
                    ecmsCertificate.Account__c = null;
                }
            }

            if (oldCertificate == null || ecmsCertificate.Designator_Id__c != oldCertificate.Designator_Id__c ||
                    ecmsCertificate.Designator_Type__c != oldCertificate.Designator_Type__c) {
                if (ecmsCertificate.Designator_Type__c == lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE &&
                        ecmsCertificate.Designator_Id__c != null) {
                    laddafc__Tax_Type__c taxType = taxTypesByTaxTypeCode.get(Integer.valueOf(ecmsCertificate.Designator_Id__c));
                    ecmsCertificate.Tax_Type__c = taxType?.Id;
                } else {
                    ecmsCertificate.Tax_Type__c = null;
                }
            }
        }
    }

    public static List<ECMS_Certificate__c> create(lp_EcmsTypes.GetByAccountIdResponse exemptionResponseWrapper, Datetime runTime) {
        List<ECMS_Certificate__c> stagingRecords = new List<ECMS_Certificate__c>();

        lp_EcmsTypes.Customer customer = exemptionResponseWrapper.customerRef;
        System.debug(LoggingLevel.DEBUG, 'customer: ' + customer);
        System.debug(LoggingLevel.DEBUG, '# of exemptions: ' + exemptionResponseWrapper.value.size());

        for (lp_EcmsTypes.Value ecmsValue : exemptionResponseWrapper.value) {
            // don't even create a record if cert is expired
            System.debug(LoggingLevel.FINEST, 'expiration date: ' + ecmsValue.expirationDate);
            if (ecmsValue.expirationDate == null || Datetime.valueOf(ecmsValue.expirationDate).dateGmt() >= Date.today()) {
                ECMS_Certificate__c staging = create(ecmsValue, customer, runTime);
                stagingRecords.add(staging);
            }
        }

        System.debug(LoggingLevel.FINEST, 'stagingRecords: ' + stagingRecords);
        return stagingRecords;
    }

    public static ECMS_Certificate__c create(lp_EcmsTypes.Value exemption, lp_EcmsTypes.Customer customer, Datetime runTime) {
        ECMS_Certificate__c staging = new ECMS_Certificate__c();

        staging.Name = String.format('{0} {1} {2}', new List<String>{
                exemption.exemptionDesignator.name,
                exemption.location.state != null ? exemption.location.state : '',
                exemption.domain != null ? exemption.domain : ''
        });
        staging.ECMS_Account_Id__c = customer.accountId;
        staging.Account_Number__c = customer.accountNumber;
        staging.Certificate_Id__c = exemption.certificateId;
        staging.Effective_Date_Raw__c = exemption.effectiveDate;
        staging.Expiration_Date_Raw__c = exemption.expirationDate;
        staging.Scope__c = exemption.scope != null ? String.join(exemption.scope, ';') : '';
        staging.Domain__c = exemption.domain;
        staging.Designator_Id__c = exemption.exemptionDesignator.id;
        staging.Designator_Name__c = exemption.exemptionDesignator.name;
        staging.Designator_Type__c = exemption.exemptionDesignator.type;
        staging.City__c = exemption.location.city;
        staging.County__c = exemption.location.county;
        staging.Country__c = exemption.location.country;
        staging.State__c = exemption.location.state;
        staging.Run_Time__c = runTime;

        return staging;
    }

    public static void deleteOpenByEcmsAccountId(Set<String> ecmsAccountIds) {
        List<ECMS_Certificate__c> ecmsCertificates = new lp_EcmsCertificateSelector().getOpenByECMSAccountId(ecmsAccountIds);
        System.debug(LoggingLevel.DEBUG, 'number of certs to delete: ' + ecmsCertificates.size());
        delete ecmsCertificates;
    }

}