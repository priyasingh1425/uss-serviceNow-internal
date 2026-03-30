public class QuoteTermsQueryHelper 
{
    public static List<Static_Quote_Term__mdt> getStaticQuoteTerms()
    {
    	List<Static_Quote_Term__mdt> results = [SELECT ID, Term_Record_Name__c FROM Static_Quote_Term__mdt WHERE Active__c = TRUE];
        return results;
    }
    
    public static List<Term__c> getTermsByName(List<String> termNames)
    {
        List<Term__c> results = [SELECT ID, Sort_Order__c, Text2__c FROM Term__c WHERE Name IN :termNames];
        return results;
    }
    
    public static List<Quote_Legal_Term__c> getQuoteTerms(Set<Id> quoteIds)
    {
        List<Quote_Legal_Term__c> results = [SELECT ID FROM Quote_Legal_Term__c WHERE Quote__c IN :quoteIds];
        return results;
    }
    
    public static Map<Id, List<SBQQ__QuoteLine__c>> getQuoteLines(Set<Id> quoteIds)
    {
        Map<Id, List<SBQQ__QuoteLine__c>> results = new Map<Id, List<SBQQ__QuoteLine__c>>();
        
        List<SBQQ__QuoteLine__c> qls = [SELECT ID, SBQQ__Quote__c, SBQQ__Product__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c IN :quoteIds];
        for(Id quoteId : quoteIds) {
            results.put(quoteId, new List<SBQQ__QuoteLine__c>());
            
            for(SBQQ__QuoteLine__c ql : qls) {
                if (ql.SBQQ__Quote__c == quoteId) {
                    results.get(quoteId).add(ql);
                }
            }
        }
        
        return results;
    }
    
    public static Map<Id, List<Term__c>> getTermsByProductId(Set<Id> productIds)
    {
        Map<Id, List<Term__c>> results = new Map<Id, List<Term__c>>();
        
        List<Product_Term__c> pts = [SELECT ID, Product__c, Term__c, Term__r.Text2__c, Term__r.Sort_Order__c FROM Product_Term__c WHERE Product__c IN :productIds];
        for(Id productId : productIds) {
            results.put(productId, new List<Term__c>());
            
            for(Product_Term__c pt : pts) {
                if (pt.Product__c == productId) {                    
                    results.get(productId).add(pt.Term__r);
                }
            }
        }
        
        return results;        
    }
}