// SC-0000100
// Helper class to create quote line groups on quotes not in review
// and create a circular lookup on A addresses
public class HLP_QuoteAddressTrigger_UTL {
    
    public static void createQuoteLineGroup(List<Quote_Address__c> qaList){
        try {
            Map<Quote_Address__c, List<SBQQ__Quote__c>> qaToQuoteMap = new Map<Quote_Address__c, List<SBQQ__Quote__c>>();
            List <SBQQ__QuoteLineGroup__c> quoteLineGroups = new List <SBQQ__QuoteLineGroup__c>();
            
            Set<Id> oppIds = new Set<Id>();
            for (Quote_Address__c qa : qaList) {
                oppIds.add(qa.Opportunity__c);
                qaToQuoteMap.put(qa, new List<SBQQ__Quote__c>());
            }
            
            List<Quote_Address__c> qaDetails = [
                SELECT Id, z_Quote_Address__r.Street__c, z_Quote_Address__r.City__c,
                A_address__c, Z_Address__c, Street__c, City__c, State__c, Country__c,
                Zip__c, Network_Status__c, Facility__c, Opportunity__c, Bypass_Trigger__c
                FROM Quote_Address__c
                WHERE Id IN :qaToQuoteMap.keySet()
            ];
            
            
            List<SBQQ__Quote__c> qList = [
                SELECT Id, SBQQ__Opportunity2__c
                FROM SBQQ__Quote__c 
                WHERE SBQQ__Opportunity2__c IN :oppIds
                AND SBQQ__Status__c != 'In Review'
            ];
            
            for (SBQQ__Quote__c q : qList) {
                for (Quote_Address__c qa : qaDetails) {
                    if (qa.Opportunity__c == q.SBQQ__Opportunity2__c) {
                        if (!qaToQuoteMap.containsKey(qa)) {
                            qaToQuoteMap.put(qa, new List<SBQQ__Quote__c>());
                        }
                        qaToQuoteMap.get(qa).add(q);
                    }
                }
            }
            for (Quote_Address__c address : qaToQuoteMap.keySet()) {
                String groupName = '';
                if (address.Network_Status__c == 'Off Net') {
                    groupName = address.Street__c + ', ' + address.City__c ;
                    if (address.A_address__c == true) {
                        groupName += ' | ';
                        groupName += address.z_Quote_Address__r.Street__c + ', ' + address.z_Quote_Address__r.City__c ;
                        
                        if(groupName.length() > 80){
                            groupName = address.Street__c + ' | '+address.z_Quote_Address__r.Street__c;
                        }
                    }
                } else {
                    groupName = address.Facility__c;
                }
                if (address.Z_Address__c == false && address.Bypass_Trigger__c == false) {
                    for (SBQQ__Quote__c q : qaToQuoteMap.get(address)) {
                        SBQQ__QuoteLineGroup__c lineGroup = new SBQQ__QuoteLineGroup__c();
                        lineGroup.Name = groupName;
                        lineGroup.Street__c = address.Street__c;
                        lineGroup.City__c = address.City__c;
                        lineGroup.State__c = address.State__c;
                        lineGroup.Country__c = address.Country__c;
                        lineGroup.Zip__c = address.Zip__c;
                        lineGroup.Network_Status__c = address.Network_Status__c;
                        lineGroup.Facility__c = address.Facility__c;
                        lineGroup.SBQQ__Quote__c = q.Id;
                        lineGroup.Quote_Address__c = address.Id;
                        quoteLineGroups.add(lineGroup); 
                    }
                }
                
            }
            insert quoteLineGroups;
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteAddressTrigger_UTL.createQuoteLineGroup at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
    
    public static void createAAddressLookup(List<Quote_Address__c> qaList){
        try {
            List<Quote_Address__c> ZqaListUpdate = new List<Quote_Address__c>();
            Set<String> ZqaIds = new Set<String>();
            Map<String, String> zToAQAMap = new Map<String, String>();
            for (Quote_Address__c qa : qaList) {
                if (qa.A_Address__c == true) {
                    ZqaIds.add(qa.z_Quote_Address__c);
                    zToAQAMap.put(qa.z_Quote_Address__c, qa.Id);
                }
            }
            
            List<Quote_Address__c> zQAs = [SELECT Id FROM Quote_Address__c
                                          WHERE Id IN : ZqaIds];
            
            for (Quote_Address__c zQA : zQAs) {
                zQA.A_Quote_Address__c = zToAQAMap.get(zQA.Id);
                ZqaListUpdate.add(zQA);
            }
            
            if (!ZqaListUpdate.isEmpty()) {
                update ZqaListUpdate;
            }
            
          
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteAddressTrigger_UTL.createAAddressLookup at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
}