/**
 * @author Ladd Partners
 * @date 8/25/2025
*/

public with sharing class lp_TaxType {

    private static Map<Integer, laddafc__Tax_Type__c> taxTypesByTaxTypeCode;

    public static Map<Integer, laddafc__Tax_Type__c> getByCodes(Set<Integer> taxTypeCodes) {
        Map<Integer, laddafc__Tax_Type__c> taxTypesRequestedByCode = new Map<Integer, laddafc__Tax_Type__c>();
        Set<Integer> taxTypeCodesToQuery = new Set<Integer>();

        if (taxTypesByTaxTypeCode == null || taxTypesByTaxTypeCode.isEmpty()) {
            taxTypesByTaxTypeCode = new Map<Integer, laddafc__Tax_Type__c>();
            taxTypeCodesToQuery.addAll(taxTypeCodes);
        } else {
            for (Integer typeCode : taxTypeCodes) {
                laddafc__Tax_Type__c taxType = taxTypesByTaxTypeCode.get(typeCode);

                if (taxType != null) {
                    taxTypesRequestedByCode.put(typeCode, taxType);
                } else {
                    taxTypeCodesToQuery.add(typeCode);
                }
            }
        }

        if (!taxTypeCodesToQuery.isEmpty()) {
            Map<Integer, laddafc__Tax_Type__c> taxTypesByCode = new lp_TaxTypeSelector().getByTaxTypeCodeMap(taxTypeCodesToQuery);
            taxTypesRequestedByCode.putAll(taxTypesByCode);
            taxTypesByTaxTypeCode.putAll(taxTypesByCode);
        }

        return taxTypesRequestedByCode;
    }

}