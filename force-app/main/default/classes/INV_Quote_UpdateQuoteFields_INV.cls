public class INV_Quote_UpdateQuoteFields_INV {
    
    public class InputVariables{
        @InvocableVariable(label='QuoteID Text ID' description='Quote ID' required=true)
        public String inputQuote;
        
        @InvocableVariable(label='Opportunity Type' description='SBQQ__Quote__r.SBQQ__Opportunity2__r.Type' required=true)
        public String inputType;
        
        @InvocableVariable(label='Opportunity Renewal' description='SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Renewal__c' required=true)
        public Boolean inputRenewal;
    }
    
    
    @InvocableMethod(label='Update Quote Fields' description='A re-write specifically for the flow Quote - Update Quote Fields')
    public static void updateQuoteFields(List<InputVariables> ivs){
        Set<SBQQ__Quote__c> updateQuotes = new Set<SBQQ__Quote__c>();
        
        
        Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.SBQQ__Subscription__c.fields.getMap();
        String allfields = '';
        for(Schema.SObjectField f : mapFields.values()){
            
            if(String.valueOf(allfields) == ''){
                allfields = String.valueOf(f);
            } else {
                allfields = String.valueOf(f) + ', ' + allfields; 
            }
        }
       
        for(InputVariables i : ivs){
  
            String quoteLineOrderType = '';
            SBQQ__Subscription__c outputSubscription = new SBQQ__Subscription__c();
            Boolean originalSubscription;

            if(i.inputType == 'Change' || i.inputType == 'CHANGE'){
                quoteLineOrderType = 'Change';
            } else if(i.inputType == 'Disconnect' || i.inputType == 'Disco'){
                quoteLineOrderType = 'Disco';
            } else if(i.inputRenewal){
                quoteLineOrderType = 'Renew';
            }
            
            INV_Quote_UPdateQuoteFields_BTC batchJob = new INV_Quote_UPdateQuoteFields_BTC(i.inputQuote, quoteLineOrderType);
            
            Id batchJobId = Database.executeBatch(batchJob, 10);
            
        }
 
    }
    
}