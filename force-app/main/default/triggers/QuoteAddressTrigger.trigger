// SC-0000100
// Trigger on Quote Addresses to insert groups after quote has been created
trigger QuoteAddressTrigger on Quote_Address__c (after insert) {
    if (Trigger.isAfter && Trigger.isInsert) {
        HLP_QuoteAddressTrigger_UTL.createQuoteLineGroup(trigger.new);
        
        List<Quote_Address__c> qaList = new List<Quote_Address__c>();
        for (Quote_Address__c qa : trigger.new) {
            if (qa.A_Address__c == true) {
                qaList.add(qa);
            }
        }
        HLP_QuoteAddressTrigger_UTL.createAAddressLookup(qaList);
    }   
}