public class INV_API_SellCPQ_GetQuotes_QRY {
    public class inputVariables{
        @InvocableVariable
        public Id opportunityId;
        
        @InvocableVariable
        public Id originalUser;
    }
    
    @InvocableMethod(label='Product Refresh: Get QuoteLines from SellCPQ' description='performs a callout to get quotelines from SellCPQ and writes them to an Opportunity as Opportunity Products')
    public static void getProductsFromSellCPQ(List<InputVariables> inputVariables){
        API_SellCPQ_GetQuotes_QRY.getQuoteLines(inputVariables.get(0).opportunityId, inputVariables.get(0).originalUser);
    }
    
    
}