// SC-0000100
// Visualforce page controller to re-cost bundles by group
public class CTL_CB_ReConfiguration_UTL {
      public static Boolean isProceedClick{get;set;}
    public static Boolean costingStatus{get;set;}
    public static String groupName{get;set;}
    
     // Constructor to assign costingStatus
   /* public CTL_CB_ReConfiguration_UTL() {
         String costingParam = ApexPages.currentPage().getParameters().get('costing');
        
        // Convert the string parameter to a Boolean
        costingStatus = (costingParam != null && costingParam.toLowerCase() == 'true');
          isProceedClick = false;
    }*/

    public static void assignValues(){
        String costingParam = ApexPages.currentPage().getParameters().get('costing');
        System.debug('Costing confirm'+costingParam);
        
        // Convert the string parameter to a Boolean
        costingStatus = (costingParam != null && costingParam.toLowerCase() == 'true');
          isProceedClick = false;
        groupName = ApexPages.currentPage().getParameters().get('name');
    }
    
    
    public static void priceGroup() {
        try{
            isProceedClick = true;
            String qlgId = ApexPages.currentPage().getParameters().get('id');
            String costing = ApexPages.currentPage().getParameters().get('costing');
            System.debug(costing);
            System.debug('queryString: '+ qlgId);
            
            if(costing == 'true'){
                return;
            }
            SBQQ__QuoteLineGroup__c sfQLG = [SELECT Id, SBQQ__Quote__c
                                             FROM SBQQ__QuoteLineGroup__c WHERE Id =: qlgId LIMIT 1];
            SBQQ__Quote__c sfQuote = [SELECT Id, Name, Is_Errored__c, Error_Status__c, 
                                      External_Connectbase_Id__c,
                                      SBQQ__Account__r.Name, 
                                      SBQQ__Account__r.External_Connectbase_Id__c, 
                                      SBQQ__SubscriptionTerm__c,
                                      SBQQ__Type__c,SBQQ__RenewalTerm__c 
                                      FROM SBQQ__Quote__c 
                                      WHERE Id =: sfQLG.SBQQ__Quote__c];
            
            String errorMsg = sfQuote.Error_Status__c;
            List<String> errorMsgBreakdown;
            if (sfQuote.Is_Errored__c == false && errorMsg == null) {}
            else {
                errorMsgBreakdown = errorMsg.split(';');
            }
            String accId;
            if (sfQuote.SBQQ__Account__r.External_Connectbase_Id__c == null || (errorMsgBreakdown!= null && errorMsgBreakdown[1] == 'CreateAccount')) {
                System.enqueueJob(new API_CB_AccountQueueable_INS(sfQuote.SBQQ__Account__r.Name, sfQuote.Id, sfQLG.Id));
                return;
            }
            else {
                accId = sfQuote.SBQQ__Account__r.External_Connectbase_Id__c;
            }
            String dealId;
            if (sfQuote.External_Connectbase_Id__c == null || (errorMsgBreakdown!= null && errorMsgBreakdown[1] == 'CreateDeal')) {
                System.enqueueJob(new API_CB_DealQueueable_INS(accId, sfQuote.Name, sfQuote.Id, sfQLG.Id));
                return;
            }
            else {
                dealId = sfQuote.External_Connectbase_Id__c;
            }
            
            masterCreatePricingSingle(accId, dealId, sfQuote.Id, sfQLG.Id);
            return;
            
        } catch(Exception e){
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in CTL_CB_ReConfiguration_UTL.priceGroup at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            System.debug(ce.message);
            CustomException.sendErrorNotification(ce);
            
        }
        
    }
    
    public static void masterCreatePricingSingle(String accId, String dealId, String sfQuoteId, String qlgId) {
        try {
            SBQQ__QuoteLineGroup__c sfQLG = [SELECT Id, SBQQ__Quote__c
                                             FROM SBQQ__QuoteLineGroup__c WHERE Id =: qlgId LIMIT 1];
            SBQQ__Quote__c sfQuote = [SELECT Id, Name, Is_Errored__c, Error_Status__c, 
                                      External_Connectbase_Id__c,
                                      SBQQ__Account__r.Name, 
                                      SBQQ__Account__r.External_Connectbase_Id__c, 
                                      SBQQ__SubscriptionTerm__c,
                                      SBQQ__Type__c,SBQQ__RenewalTerm__c 
                                      FROM SBQQ__Quote__c 
                                      WHERE Id =: sfQLG.SBQQ__Quote__c];
            List<SBQQ__QuoteLine__c> qls = [SELECT Id
                                            FROM SBQQ__QuoteLine__c
                                            WHERE Send_To_Connectbase__c = true
                                            AND SBQQ__Group__c = :qlgId];
            List<SBQQ__QuoteLine__c> qlsRecosted = [SELECT Id, Recosted__c
                                                    FROM SBQQ__QuoteLine__c
                                                    WHERE Receive_From_Connectbase__c = true
                                                    AND SBQQ__Group__c = :qlgId];
            for (SBQQ__QuoteLine__c ql : qlsRecosted) {
                ql.Recosted__c = true;
            }
            update qlsRecosted;
            
            if (!qls.isEmpty()) {
                sfQLG.Costing_in_Progress__c = true;
                update sfQLG;
            }
            List<SBQQ__QuoteLine__c> bundleQLs = [
                SELECT Id, Name, SBQQ__Product__c, Network_Status__c, SBQQ__RequiredBy__c, SBQQ__Product__r.Connectbase_Product__c, Site_Bandwidth_Mbps__c, Street__c, City__c, State__c, Zip__c, Country__c, External_Connectbase_Id__c, Is_Errored__c, Error_Status__c, Send_To_Connectbase__c, Receive_From_Connectbase__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Group__c = :qlgId
                AND SBQQ__Bundle__c = true
            ];
            Map<String, SBQQ__QuoteLine__c> bundleIdToBundleMap = new Map<String, SBQQ__QuoteLine__c>();
            Map<SBQQ__QuoteLine__c, List<SBQQ__QuoteLine__c>> bundleToChildrenMap = new Map<SBQQ__QuoteLine__c, List<SBQQ__QuoteLine__c>>();
            Map<String, List<Map<String, SBQQ__QuoteLine__c>>> cbProductToQLMap = new Map<String, List<Map<String, SBQQ__QuoteLine__c>>>();
            for (SBQQ__QuoteLine__c bundleQL : bundleQLs) {
                bundleToChildrenMap.put(bundleQL, new List<SBQQ__QuoteLine__c>{bundleQL});
                bundleIdToBundleMap.put(bundleQL.Id, bundleQL);
                if (!cbProductToQLMap.containsKey(bundleQL.SBQQ__Product__r.Connectbase_Product__c)) {
                    cbProductToQLMap.put(bundleQL.SBQQ__Product__r.Connectbase_Product__c, new List<Map<String, SBQQ__QuoteLine__c>>());
                }    
            }
            List<SBQQ__QuoteLine__c> childQLs = [
                SELECT Id, Name, SBQQ__Product__c, Network_Status__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Connectbase_Product__c, SBQQ__RequiredBy__c, Site_Bandwidth_Mbps__c, Street__c, City__c, State__c, Zip__c, Country__c, External_Connectbase_Id__c, Is_Errored__c, Error_Status__c, Send_To_Connectbase__c, Receive_From_Connectbase__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Group__c = :qlgId
                AND (Send_To_Connectbase__c = true
                     OR Receive_From_Connectbase__c = true)
                AND SBQQ__RequiredBy__c IN : bundleQLs
            ];
            
            for (SBQQ__QuoteLine__c childQL :  childQLs) {
                bundleToChildrenMap.get(bundleIdToBundleMap.get(childQL.SBQQ__RequiredBy__c)).add(childQL);
            }
            
            for (SBQQ__QuoteLine__c bundleQL : bundleToChildrenMap.keySet()) {
                String cbProduct = bundleQL.SBQQ__Product__r.Connectbase_Product__c;
                List<SBQQ__QuoteLine__c> allQLs = bundleToChildrenMap.get(bundleQL);
                
                SBQQ__QuoteLine__c senderQL = null;
                SBQQ__QuoteLine__c receiverQL = null;
                
                for (SBQQ__QuoteLine__c allQL : allQLs) {
                    if (allQL.Send_To_Connectbase__c == true && allQL.Receive_From_Connectbase__c == true) {
                        cbProductToQLMap.get(cbProduct).add(new Map<String, SBQQ__QuoteLine__c>{'sender' => allQL, 'receiver' => allQL});
                    }
                    else if (allQL.Send_To_Connectbase__c == true && senderQL == null) {
                        senderQL = allQL;
                    }
                    else if (allQL.Receive_From_Connectbase__c == true && receiverQL == null) {
                        receiverQL = allQL;
                    }
                }
                
                if (senderQL != null && receiverQL != null) {
                    cbProductToQLMap.get(cbProduct).add(new Map<String, SBQQ__QuoteLine__c>{'sender' => senderQL, 'receiver' => receiverQL});
                }
            }
            
            /*for (String cbProduct : cbProductToQLMap.keySet()) {
				for (Map<String, SBQQ__QuoteLine__c> m : cbProductToQLMap.get(cbProduct)) {
					System.debug(cbProduct + ' ' + m.get('sender').Name + ' ' + m.get('receiver').Name);
				}
			}*/
            // System.debug('cbProductToQLMap@@@' + cbProductToQLMap);
            System.debug('inside method finish');
            Database.executeBatch(new BAT_CB_Pricing_INS(accId, dealId, cbProductToQLMap, sfQuote, 'Single', qlgId), 1);
            
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in CTL_CB_ReConfiguration_UTL.masterCreatePricingSingle at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            System.debug(ce.message);
            CustomException.sendErrorNotification(ce);
        }
    }
    
    
    @AuraEnabled(cacheable = true)
    public static List<SBQQ__QuoteLine__c> bundlesFromQuote(String sfQuoteId ){
        
        System.debug('sfQuoteId===>'+sfQuoteId);
        try {
            
            return [SELECT Id, Name, Bundle_Parent_Name__c, SBQQ__RequiredBy__c, Site_Bandwidth_Mbps__c, Street__c, City__c, State__c, Zip__c, Country__c, External_Connectbase_Id__c, Is_Errored__c, Error_Status__c,SBQQ__Product__r.Send_To_Connectbase__c,SBQQ__Product__r.Receive_From_Connectbase__c,SBQQ__Product__r.name,Bundle_Parent_ID__c FROM SBQQ__QuoteLine__c
                    WHERE SBQQ__Quote__c = :sfQuoteId AND Network_Status__c = 'Off Net'];
            
            
        } catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in CTL_CB_ReConfiguration_UTL.bundlesFromQuote at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            System.debug(ce.message);
            CustomException.sendErrorNotification(ce);
            return null;
            
            
        }
    }
    
}