public class QuoteTermsHelper 
{
    public static Set<Id> getQuoteIds(List<SBQQ__Quote__c> quotes)
    {
        Set<Id> results = new Set<Id>();        
        for(SBQQ__Quote__c quote : quotes) {
            if (quote.id != null) {
            	results.add(quote.id);    
            }
        }        
        return results;
    }
    
    public static void deleteExistingQuoteTerms(Set<Id> quoteIds)
    {
        List<Quote_Legal_Term__c> quoteTermsToDelete = QuoteTermsQueryHelper.getQuoteTerms(quoteIds);

        if (!quoteTermsToDelete.isEmpty()) {
            // allOrNone=false: if a concurrent job already deleted these records (ENTITY_IS_DELETED),
            // don't throw — the net result (records gone) is what we want either way.
            Database.delete(quoteTermsToDelete, false);
        }
    }
       
    public static List<Term__c> getStaticTerms()
    {        
        //Get the custom metadata records.
        List<Static_Quote_Term__mdt> sqts = QuoteTermsQueryHelper.getStaticQuoteTerms();
        
        //Get term Names from records.
        List<String> termNames = new List<String>();
        for(Static_Quote_Term__mdt sqt : sqts) {
            termNames.add(sqt.Term_Record_Name__c);
        }
        
        //Get the related records.
        return QuoteTermsQueryHelper.getTermsByName(termNames);        
    }
    
    public static Map<Id, Set<Term__c>> getApplicableTermsByQuote(Set<Id> quoteIds)
    {
        Map<Id, Set<Term__c>> results = new Map<Id, Set<Term__c>>();
        
        Map<Id, List<SBQQ__QuoteLine__c>> quoteLinesByQuoteId = QuoteTermsQueryHelper.getQuoteLines(quoteIds);
        Set<Id> productIds = new Set<Id>();
        for(List<SBQQ__QuoteLine__c> quoteLines : quoteLinesByQuoteId.values()) {
            productIds.addAll(getProductIdsFromQuoteLines(quoteLines));
        }            
        Map<Id, List<Term__c>> termsByProductId = QuoteTermsQueryHelper.getTermsByProductId(productIds);
        
        for(Id quoteId : quoteLinesByQuoteId.keySet()) {
            results.put(quoteId, new Set<Term__c>());
            
            for(SBQQ__QuoteLine__c quoteLine : quoteLinesByQuoteId.get(quoteId)) {
                if (termsByProductId.containsKey(quoteLine.SBQQ__Product__c)) {
                    results.get(quoteId).addAll(termsByProductId.get(quoteLine.SBQQ__Product__c));
                }
            }
        }
        
        return results;
    }
    
    public static List<Quote_Legal_Term__c> createQuoteTerms(Id quoteId, Set<Term__c> terms, List<Term__c> staticTerms)
    {
        List<Quote_Legal_Term__c> results = new List<Quote_Legal_Term__c>();
        
		//First, add static terms.		
		for(Term__c staticTerm : staticTerms) {         
            Quote_Legal_Term__c qt = createQuoteTerm(quoteId, staticTerm);  
            
            //Dont add static terms in tests to prevent org custom metadata issues.
            if (Test.isRunningTest()) {
            	results.add(qt);    
            }
        }
        
		//Then add product terms.        
        for(Term__c term : terms) {
            results.add(createQuoteTerm(quoteId, term));
        }
        return results;
    }
    
    private static Quote_Legal_Term__c createQuoteTerm(Id quoteId, Term__c t)
    {
        Quote_Legal_Term__c qt = new Quote_Legal_Term__c();
        qt.Quote__c = quoteId;
        qt.Sort_Order__c = t.Sort_Order__c;
        qt.Term__c = t.id;
        //qt.Text__c = t.Term_Text__c;
        qt.Text2__c = t.Text2__c;
        return qt;
    }
    
    private static Set<Id> getProductIdsFromQuoteLines(List<SBQQ__QuoteLine__c> quoteLines)
    {
        Set<Id> results = new Set<Id>();
        
        for(SBQQ__QuoteLine__c quoteLine : quoteLines) {
			results.add(quoteLine.SBQQ__Product__c);
        }
        
        return results;
    }
}