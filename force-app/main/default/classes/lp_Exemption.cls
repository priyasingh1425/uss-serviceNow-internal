/**
 * Created by Ladd Partners on 3/15/2025.
 */

public with sharing class lp_Exemption {

    public static final String SCOPE_ALL = 'All';
    public static final String SCOPE_FEDERAL = 'Federal';
    public static final String SCOPE_STATE = 'State';
    public static final String SCOPE_COUNTY = 'County';
    public static final String SCOPE_LOCAL = 'Local';

    public static final String DOMAIN_FEDERAL = 'Federal';
    public static final String DOMAIN_STATE = 'State';

    public static final String SCOPE_ALL_EXTENDED = String.format('{0};{1};{2};{3}', new List<String>{
            SCOPE_FEDERAL,
            SCOPE_STATE,
            SCOPE_COUNTY,
            SCOPE_LOCAL
    });

    public static List<laddafc__Exemption__c> create(ECMS_Certificate__c ecmsCertificate) {
        List<laddafc__Exemption__c> afcExemptions = new List<laddafc__Exemption__c>();

        laddafc__Exemption__c afcExemption = new laddafc__Exemption__c();

        afcExemption.Name = ecmsCertificate.Name;
        afcExemption.laddafc__Account__c = ecmsCertificate.Account__c;
        // 'All' is handled differently in Avalara so we need to replace it.
        afcExemption.laddafc__Scope__c = ecmsCertificate.Scope__c == lp_Exemption.SCOPE_ALL ? lp_Exemption.SCOPE_ALL_EXTENDED : ecmsCertificate.Scope__c;
        System.debug(LoggingLevel.DEBUG, 'ecms cert scope: ' + ecmsCertificate.Scope__c);
        System.debug(LoggingLevel.DEBUG, 'new afc exemption scope: ' + afcExemption.laddafc__Scope__c);
        afcExemption.laddafc__Domain__c = ecmsCertificate.Domain__c;

        if (ecmsCertificate.Tax_Type__c != null) {
            afcExemption.laddafc__Tax_Type__c = ecmsCertificate.Tax_Type__c;
        } else if (ecmsCertificate.Designator_Type__c == lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_CATEGORY) {
            afcExemption.laddafc__Category__c = ecmsCertificate.Designator_Name__c;
        }

        afcExemption.laddafc__City__c = ecmsCertificate.City__c;
        afcExemption.laddafc__County__c = ecmsCertificate.County__c;
        afcExemption.laddafc__Country__c = ecmsCertificate.Country__c;
        afcExemption.laddafc__Region__c = ecmsCertificate.State__c;

        afcExemption.ECMS_Certificate__c = ecmsCertificate.Id;
        afcExemption.ECMS_Certificate_Id__c = ecmsCertificate.Certificate_Id__c;

        afcExemptions.add(afcExemption);

        // ad-hoc exemptions only apply to federal or state certificates
//        if (ecmsCertificate.Domain__c == DOMAIN_FEDERAL || ecmsCertificate.Domain__c == DOMAIN_STATE) {
            List<Integer> taxTypeCodes = lp_AdhocExemption.getTaxTypeCodes(ecmsCertificate.Country__c, ecmsCertificate.State__c, ecmsCertificate.Designator_Id__c);

            // add predefined ad-hoc exemptions
            if (lp_CollectionUtil.isNotEmpty(taxTypeCodes)) {
                Map<Integer, laddafc__Tax_Type__c> taxTypeByCode = lp_TaxType.getByCodes(new Set<Integer>(taxTypeCodes));

                for (Integer taxTypeCode : taxTypeCodes) {
                    laddafc__Tax_Type__c taxType = taxTypeByCode.get(taxTypeCode);

                    if (taxType == null) {
                        ecmsCertificate.Processing_Status__c = lp_EcmsCertificate.PROCESSING_STATUS_ERROR;
                        ecmsCertificate.Processing_Message__c = 'Tax Type (' + taxTypeCode + ') not found for adhoc exemption';
                        return null;
                    }

                    laddafc__Exemption__c afcAdhocExemption = new laddafc__Exemption__c();

                    afcAdhocExemption.Name = taxType.Name;
                    if (ecmsCertificate.Domain__c == DOMAIN_STATE) {
                        afcAdhocExemption.Name += ' State ' + ecmsCertificate.State__c;
                    }
                    afcAdhocExemption.laddafc__Account__c = ecmsCertificate.Account__c;

                    afcAdhocExemption.laddafc__Scope__c = SCOPE_ALL_EXTENDED;
                    if (ecmsCertificate.Domain__c == DOMAIN_STATE) {
                        afcAdhocExemption.laddafc__Scope__c = afcAdhocExemption.laddafc__Scope__c.replace(SCOPE_FEDERAL + ';', '');
                    }

                    afcAdhocExemption.laddafc__Domain__c = ecmsCertificate.Domain__c;

                    afcAdhocExemption.laddafc__Tax_Type__c = taxType.Id;
                    afcAdhocExemption.laddafc__Country__c = 'US';

                    if (ecmsCertificate.Domain__c == DOMAIN_STATE) {
                        afcAdhocExemption.laddafc__Region__c = ecmsCertificate.State__c;
                    }

                    afcAdhocExemption.ECMS_Certificate__c = ecmsCertificate.Id;
                    afcAdhocExemption.ECMS_Certificate_Id__c = ecmsCertificate.Certificate_Id__c;

                    afcExemptions.add(afcAdhocExemption);
                }
            }
//        }

        return afcExemptions;
    }

    public static void deleteExemptions(List<String> customerNumbers) {
        List<laddafc__Exemption__c> exemptions = new lp_ExemptionSelector().getByCustomerNumber(customerNumbers, true);
        System.debug(LoggingLevel.DEBUG, 'number of exemptions to delete: ' + exemptions.size());
        delete exemptions;
    }
}