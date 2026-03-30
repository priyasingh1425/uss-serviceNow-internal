// SC-0000100
// Trigger to notify of ICB products 
// and create addresses on products
// and null update costing fields
trigger QuoteLineTrigger on SBQQ__QuoteLine__c (after insert, before update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__QuoteLine__c quoteLine : Trigger.new) {
            if (quoteLine.SBQQ__Quote__c != null) {
                quoteIds.add(quoteLine.SBQQ__Quote__c);
            }
        }
        List<Id> qIds = new List<Id>(quoteIds);
        String newQuoteId = qIds[0];
        
        // Add groups to amended/renewed quotes
        SBQQ__Quote__c quote = [SELECT SBQQ__Type__c, Is_Costed__c, Carry_Address_From_Group__c FROM SBQQ__Quote__c WHERE Id = : newQuoteId LIMIT 1];
        String quoteType = quote.SBQQ__Type__c;
        Set<String> validTypes = new Set<String>{'Amendment', 'Renewal'};
            
        if (validTypes.contains(quoteType) && quote.Is_Costed__c == false) {
            HLP_QuoteLineTrigger_UTL.createAmendGroups(newQuoteId);
        }
        
        // Notify users of ICB products
        HLP_QuoteLineTrigger_UTL.notifyICBProducts(Trigger.newMap);
        
        // Update A-Z addresses for products
        if (quote.Carry_Address_From_Group__c == true) {
            HLP_QuoteLineTrigger_UTL.updateAddresses(newQuoteId);
        }
        
        HLP_QuoteLineTrigger_UTL.allowCarryoverAddressData(newQuoteId);
        
    }
    else if (Trigger.isBefore && Trigger.isUpdate) {
        // null update costing fields if a critical field is updated
        HLP_QuoteLineTrigger_UTL.nullCostingFields(Trigger.new, Trigger.oldMap);
        
        Set<Id> quoteIds = new Set<Id>();
        for (SBQQ__QuoteLine__c quoteLine : Trigger.new) {
            if (quoteLine.SBQQ__Quote__c != null) {
                quoteIds.add(quoteLine.SBQQ__Quote__c);
            }
        }
        List<Id> qIds = new List<Id>(quoteIds);
        String newQuoteId = qIds[0];
        
        // Add groups to amended/renewed quotes
        String quoteType = [SELECT SBQQ__Type__c FROM SBQQ__Quote__c WHERE Id = : newQuoteId LIMIT 1].SBQQ__Type__c;
        Set<String> validTypes = new Set<String>{'Amendment'};
            
        if (validTypes.contains(quoteType)) {
            HLP_QuoteLineTrigger_UTL.markAsChanged(Trigger.new, Trigger.oldMap);
        }
    }
    
}