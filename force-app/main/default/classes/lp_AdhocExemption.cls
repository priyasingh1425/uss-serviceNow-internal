/**
 * @author Ladd Partners
 * @date 8/25/2025
*/

public with sharing class lp_AdhocExemption {

    public class ExemptionDefinition {
        public String country { get; set; }
        public String region { get; set; }
        public String triggeringType { get; set; }
        public List<Integer> taxTypeCodes { get; set; }
    }

    @TestVisible
    private static Map<String, ExemptionDefinition> definitionsByKey { get; set; }

    static {
        definitionsByKey = new Map<String, ExemptionDefinition>();

        List<Adhoc_Exemption__mdt> adhocExemptions = Adhoc_Exemption__mdt.getAll().values();

        for (Adhoc_Exemption__mdt adhocExemption : adhocExemptions) {
            String adhocKey = new Key().getKey(adhocExemption);

            ExemptionDefinition exDef = new ExemptionDefinition();
            exDef.country = adhocExemption.Country__c ?? '';
            exDef.region = adhocExemption.Region__c ?? '';
            exDef.triggeringType = adhocExemption.Triggering_Type__c;

            List<String> taxTypeCodeStrings = adhocExemption.Type_to_Add__c?.split(',');
            exDef.taxTypeCodes = new List<Integer>();
            for (String taxTypeCodeString : taxTypeCodeStrings) {
                exDef.taxTypeCodes.add((Integer)Decimal.valueOf(taxTypeCodeString));
            }
            definitionsByKey.put(adhocKey, exDef);
        }
    }

    public class Key {
        private final String KEY_FORMAT = '{0}.{1}.{2}';

        public String getKey(Adhoc_Exemption__mdt adhocExemption) {
            return getKey(adhocExemption.Country__c, adhocExemption.Region__c, adhocExemption.Triggering_Type__c);
        }

        public String getKey(String country, String region, String triggeringType) {
            if (country == 'USA') {
                country = 'US';
            }

            String tempKey = String.format(KEY_FORMAT, new List<String>{country?.toLowerCase(), region?.toLowerCase(), triggeringType});
            return tempKey.replace('null', '');
        }
    }

    public static List<Integer> getTaxTypeCodes(String country, String region, String triggeringType) {
        if (country == 'USA') {
            country = 'US';
        }

        String key = new Key().getKey(country, region, triggeringType);

        return definitionsByKey.get(key)?.taxTypeCodes;
    }

}