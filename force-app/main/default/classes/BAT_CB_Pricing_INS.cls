// SC-0000100
// Batch class to create quotes in Connectbase for each product in Connectbase one by one,
// and store the returned configuration in a custom Salesforce object for later polling
public class BAT_CB_Pricing_INS implements Database.Batchable<List<Map<String,SBQQ__QuoteLine__c>>>, Database.AllowsCallouts {
    
    private List<String> allQlIds;
    private String accId;
    private String dealId;
    private Map<String, List<Map<String,SBQQ__QuoteLine__c>>> cbProductToQLMap;
    private SBQQ__Quote__c sfQuote;
    private string pricingType;
    private String sfGroup;
    
    public BAT_CB_Pricing_INS(String accId, String dealId, Map<String, List<Map<String,SBQQ__QuoteLine__c>>> cbProductToQLMap, SBQQ__Quote__c sfQuote, String pricingType, String sfGroup) {
        this.accId = accId;
        this.dealId = dealId;
        this.cbProductToQLMap = cbProductToQLMap;
        this.sfQuote = sfQuote;
        this.pricingType = pricingType;
        this.sfGroup = sfGroup;
    }
    
    public Iterable<List<Map<String,SBQQ__QuoteLine__c>>> start(Database.BatchableContext bc) {
        System.debug('inside start');
        return cbProductToQLMap.values();
    }
    
    public void execute(Database.BatchableContext bc, List<List<Map<String,SBQQ__QuoteLine__c>>> scope) {
        System.debug('inside execute');
        try {
            for (List<Map<String,SBQQ__QuoteLine__c>> qlMapList : scope) {
                String quoteName;
                String product;
                String mediaType = '"Fiber", "Coax/HFC"';
                Decimal lowestSpeed = null;
                Decimal highestSpeed = null;
                Set<String> addresses = new Set<String>();
                Map<String,String> senderToReceiverMap = new Map<String,String>();
                for (Map<String,SBQQ__QuoteLine__c> qlMap : qlMapList) {
                    if (qlMap.get('sender').Network_Status__c == 'Off Net') {
                        if (qlMap.get('sender').SBQQ__RequiredBy__c == null) {
                            product = qlMap.get('sender').SBQQ__Product__r.Connectbase_Product__c;
                        }
                        else {
                            product = qlMap.get('sender').SBQQ__RequiredBy__r.SBQQ__Product__r.Connectbase_Product__c;
                        }
                        String street = qlMap.get('sender').Street__c;
                        String city = qlMap.get('sender').City__c;
                        String state = qlMap.get('sender').State__c;
                        String zip = qlMap.get('sender').Zip__c;
                        String country = qlMap.get('sender').Country__c;
                        if (street != null && city != null && state != null && zip != null) {
                            String address = street + ', ' + city + ', ' + state + ' ' + zip + ', ' + country;
                            addresses.add(address);
                        }
                        Decimal targetSpeed = qlMap.get('sender').Site_Bandwidth_Mbps__c;
                        if (lowestSpeed == null || targetSpeed < lowestSpeed) {
                            lowestSpeed = targetSpeed;
                        }
                        if (highestSpeed == null || targetSpeed > highestSpeed) {
                            highestSpeed = targetSpeed;
                        }
                        senderToReceiverMap.put(qlMap.get('sender').Id, qlMap.get('receiver').Id);
                    }
                    
                }
                if (pricingType == 'Bulk')  {
                    quoteName = product + ' ' + String.valueOf(DateTime.now());
                }
                else if (pricingType == 'Single') {
                    quoteName = product + ' ' + String.valueOf(DateTime.now()) + ' Recosting';
                }
                System.debug('product@@@' + product + ' lowestSpeed@@@' + lowestSpeed + ' highestSpeed@@@' + highestSpeed);
                Map<String, Decimal> speedMap = new Map<String, Decimal>{'lowestSpeed' => lowestSpeed, 'highestSpeed' => highestSpeed};
                    String term = (sfQuote.SBQQ__Type__c == 'Amendment' || sfQuote.SBQQ__Type__c == 'Renewal') ? String.valueOf(sfQuote.SBQQ__RenewalTerm__c) : String.valueOf(sfQuote.SBQQ__SubscriptionTerm__c);
                if (!senderToReceiverMap.isEmpty()) {
                    API_CB_PricingModel_INS.createPricing(accId, dealId, quoteName, product, mediaType, term, speedMap, addresses, senderToReceiverMap, this.sfGroup); 
                }
            } 
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in BAT_CB_Pricing_INS.execute at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
    
    public void finish(Database.BatchableContext bc) {
        System.debug('inside finish');
        try {
            List<String> allQLIds = new List<String>();
            for (List<Map<String,SBQQ__QuoteLine__c>> qlList : cbProductToQLMap.values()) {
                for (Map<String,SBQQ__QuoteLine__c> qlMap : qlList) {
                    allQlIds.add(qlMap.get('receiver').Id);
                }
            }
            List<SBQQ__QuoteLine__c> errorQlList = [SELECT Id, Is_Errored__c, Error_Status__c FROM SBQQ__QuoteLine__c WHERE Id IN : allQLIds];
            
            if(errorQlList.size() > 0){
                for (SBQQ__QuoteLine__c ql : errorQlList ) {
                    if (ql.Is_Errored__c == true && ql.Error_Status__c.split(';')[1] == 'CreatePricing') {
                        sfQuote.Is_Errored__c = true;
                        if (pricingType == 'Bulk')  {
                            sfQuote.Error_Status__c = ql.Error_Status__c + ql.Id;
                        }
                        else if (pricingType == 'Single') {
                            sfQuote.Error_Status__c = ql.Error_Status__c + ql.Id + 'Recosting';
                        }
                        update sfQuote;
                        break;
                    }
                }
            }            
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in BAT_CB_Pricing_INS.finish at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
}