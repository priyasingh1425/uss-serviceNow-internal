public class QuoteTermsHandler {
    // Test-only flags to force exception paths for code coverage
    @TestVisible private static Boolean forceUpdateLineItemsException = false;
    @TestVisible private static Boolean forceCarryoverException = false;
    @TestVisible private static Boolean forceCreateLineGroupException = false;
    @TestVisible private static Boolean forceUpdateAddressException = false;

    public static Map < Id, List < Quote_Legal_Term__c >> UpdateQuoteTerms(List < SBQQ__Quote__c > quotes, Boolean doDML) {
        Map < Id, List < Quote_Legal_Term__c >> results = new Map < Id, List < Quote_Legal_Term__c >> ();
        
        Set < Id > quoteIds = QuoteTermsHelper.getQuoteIds(quotes);
        
        //Delete existing Quote Terms for target quotes.
        QuoteTermsHelper.deleteExistingQuoteTerms(quoteIds);
        
        //Get Static Terms to add on all quotes
        List < Term__c > staticTerms = QuoteTermsHelper.getStaticTerms();
        
        //Get Applicable Quote Terms for target quotes.
        Map < Id, Set < Term__c >> termsByQuoteId = QuoteTermsHelper.getApplicableTermsByQuote(quoteIds);
        
        //Create Quote Terms records.
        List < Quote_Legal_Term__c > quoteTermsToInsert = new List < Quote_Legal_Term__c > ();
        
        for (Id quoteId: termsByQuoteId.keySet()) {
            List < Quote_Legal_Term__c > quoteTermsForQuote = QuoteTermsHelper.createQuoteTerms(quoteId, termsByQuoteId.get(quoteId), staticTerms);
            results.put(quoteId, quoteTermsForQuote);
            quoteTermsToInsert.addAll(quoteTermsForQuote);
        }
        
        //Perform DML if requested.
        if (doDML && !quoteTermsToInsert.isEmpty()) {
            insert quoteTermsToInsert;
        }
        
        return results;
    }
    
    /***********************************************Changes by (start) - Priya Singh***********************************************************************
*
* Description - SC-0000100 : Hander class to create quote line groups
* 
* *******************************************************************************************************************/
    public static void updateLineItemsGrouped(List < SBQQ__Quote__c > quoteList) {
        try {
            if (forceUpdateLineItemsException) { throw new CustomException('Test exception'); }
            For(SBQQ__Quote__c quote: quoteList) {
                quote.SBQQ__LineItemsGrouped__c = True;
            } 
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in QuoteTermsHandler.updateLineItemsGrouped at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }        
    }
    
    public static void allowCarryoverAddressData(List < SBQQ__Quote__c > quoteList) {
        try {
            if (forceCarryoverException) { throw new CustomException('Test exception'); }
            For(SBQQ__Quote__c quote: quoteList) {
                quote.Carry_Address_From_Group__c = true;
            } 
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in QuoteTermsHandler.allowCarryoverAddressData at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }        
    }
    
    @InvocableMethod(label='Create Quote Line Group' description='Create Quote Line Group from Quote Addresses on Opportunity')
    public static void createQuoteLineGroup(List < SBQQ__Quote__c > quoteList) {
        try {
            if (forceCreateLineGroupException) { throw new CustomException('Test exception'); }
            // Get Opportunity IDs from Quotes
            Map < Id, string > oppIds = new Map < Id, string > ();
            for (SBQQ__Quote__c quote: quoteList) {
                if (quote.SBQQ__Opportunity2__c != null) {
                    oppIds.put(quote.SBQQ__Opportunity2__c, quote.Id);
                }
            }
            
            // Retrieve Quote_Address__c records for these Opportunities
            List < Quote_Address__c > addressList = [
                SELECT Id, City__c, Country__c, Facility__c, Network_Status__c, Opportunity__c,
                State__c, Street__c, Zip__c, Z_Address__c, A_address__c, 
                z_Quote_Address__r.Street__c, z_Quote_Address__r.City__c,
                z_Quote_Address__r.State__c, z_Quote_Address__r.Country__c,
                z_Quote_Address__r.Zip__c
                FROM Quote_Address__c
                WHERE Opportunity__c IN: oppIds.KeySet()
            ];
            
            // Group Quote_Address__c records by Opportunity Id
            Map < Id, List < Quote_Address__c >> addressMap = new Map < Id, List < Quote_Address__c >> ();
            for (Quote_Address__c address: addressList) {
                if (!addressMap.containsKey(address.Opportunity__c)) {
                    addressMap.put(address.Opportunity__c, new List < Quote_Address__c > ());
                }
                addressMap.get(address.Opportunity__c).add(address);
            }
            
            // Create Quote Line Groups for each Quote Address
            List < SBQQ__QuoteLineGroup__c > quoteLineGroups = new List < SBQQ__QuoteLineGroup__c > ();
            for (Id oppId: addressMap.keySet()) {
                for (Quote_Address__c address: addressMap.get(oppId)) {
                    string groupName = '';
                    if (address.Network_Status__c == 'Off Net') {
                        /***********************************************Update by (start) - Aayam Ayan***********************************************************************
*
* Description - SC-0000100 : Hander class to create quote line groups
* 
* *******************************************************************************************************************/
                        groupName = address.Street__c + ', ' + address.City__c ;
                        if (address.A_address__c == true) {
                            System.debug('inside a-z');
                            groupName += ' | ';
                            groupName += address.z_Quote_Address__r.Street__c + ', ' + address.z_Quote_Address__r.City__c ;
                            
                            if(groupName.length() > 80){
                                groupName = address.Street__c + ' | '+address.z_Quote_Address__r.Street__c;
                            }
                            
                            
                        }
                        /***********************************************Update by (End) - Aayam Ayan***********************************************************************/
                    } else {
                        groupName = address.Facility__c;
                    }
                    System.debug('groupName@@@@' + groupName);
                    /*********Changes by (Start) - Priya Singh***************/
                    if (address.Z_Address__c == false) {
                        /************Changes by (End) - Priya Singh************/
                        
                        SBQQ__QuoteLineGroup__c lineGroup = new SBQQ__QuoteLineGroup__c();
                        lineGroup.Name = groupName;
                        lineGroup.Street__c = address.Street__c;
                        lineGroup.City__c = address.City__c;
                        lineGroup.State__c = address.State__c;
                        lineGroup.Country__c = address.Country__c;
                        lineGroup.Zip__c = address.Zip__c;
                        lineGroup.Network_Status__c = address.Network_Status__c;
                        lineGroup.Facility__c = address.Facility__c;
                        lineGroup.SBQQ__Quote__c = oppIds.get(oppId);
                        lineGroup.Quote_Address__c = address.Id;
                        quoteLineGroups.add(lineGroup);
                    }
                }
            }
            
            System.debug('quoteLineGroups@@@' + quoteLineGroups);
            // Insert the Quote Line Groups
            try {
                if (!quoteLineGroups.isEmpty()) {
                    insert quoteLineGroups;
                }
            } catch (DmlException e) {
                System.debug('Error inserting Quote Line Groups: ' + e.getMessage());
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in QuoteTermsHandler.createQuoteLineGroup at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
    
    /***********************************************Changes by (End) - Priya Singh***********************************************************************/
    
    public static void updateQuoteAddress(List<SBQQ__Quote__c> quoteList){
        try {
            if (forceUpdateAddressException) { throw new CustomException('Test exception'); }
            Set<Id> opportunityIds = new Set<Id>();
            for (SBQQ__Quote__c quote : quoteList) {
                opportunityIds.add(quote.SBQQ__Opportunity2__c);
            }
            
            List<SBQQ__Quote__c> relatedQuotes = [
                SELECT Id, SBQQ__Status__c
                FROM SBQQ__Quote__c
                WHERE SBQQ__Opportunity2__c IN :opportunityIds
                AND SBQQ__Status__c = 'In Review'
            ];
            
            Set<Id> inReviewQuoteIds = new Set<Id>();
            for (SBQQ__Quote__c quote : relatedQuotes) {
                inReviewQuoteIds.add(quote.Id);
            }
            
            Map<Id, Set<Id>> addressIdToQuoteIds = new Map<Id, Set<Id>>();
            List<SBQQ__QuoteLineGroup__c> qlgs = [
                SELECT SBQQ__Quote__c, Quote_Address__c, Quote_Address__r.z_Quote_Address__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE SBQQ__Quote__c IN :inReviewQuoteIds
            ];
            Set<String> qaIdsReview = new Set<String>();
            for (SBQQ__QuoteLineGroup__c qlg : qlgs) {
                if (qlg.Quote_Address__c != null) {
                    qaIdsReview.add(qlg.Quote_Address__c);
                    if (qlg.Quote_Address__r.z_Quote_Address__c != null) {
                        qaIdsReview.add(qlg.Quote_Address__r.z_Quote_Address__c);
                    }  
                }
                
            }
            List<Quote_Address__c> addressesToUpdate = new List<Quote_Address__c>();
            for (String qaId : qaIdsReview) {
                addressesToUpdate.add(new Quote_Address__c(Id = qaId, Quote_Status__c = true));
            }
            List<Quote_Address__c> qasNotReview = [
                SELECT Id, Quote_Status__c
                FROM Quote_Address__c
                WHERE Opportunity__c IN :opportunityIds
                AND Id NOT IN :qaIdsReview
            ];
            for (Quote_Address__c qa : qasNotReview) {
                addressesToUpdate.add(new Quote_Address__c(Id = qa.Id, Quote_Status__c = false));
            }
            
            if (!addressesToUpdate.isEmpty()) {
                update addressesToUpdate;
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in QuoteTermsHandler.updateQuoteAddress at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
}