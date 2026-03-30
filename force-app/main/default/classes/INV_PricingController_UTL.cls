// SC-0000100
// Class to run once the costs have to be fetched, whether in bulk from the quote, or from the quote line group
// Creates account, deal, quote in order in Connectbase
public class INV_PricingController_UTL {
    public static Boolean isProceedClick{get;set;}
    public static String recordId{get;set;}
    
    public static void priceQuote() {
        try {
            isProceedClick = true;
            recordId = ApexPages.currentPage().getParameters().get('id');
            String sfQuoteId = ApexPages.currentPage().getParameters().get('id');
            System.debug('queryString: '+ sfQuoteId);
            SBQQ__Quote__c sfQuote = [SELECT Id, SBQQ__Account__c, SBQQ__Account__r.External_Connectbase_Id__c, SBQQ__Account__r.Name, Name, External_Connectbase_Id__c, Is_Errored__c, Error_Status__c
                                      FROM SBQQ__Quote__c 
                                      WHERE Id =: sfQuoteId 
                                      LIMIT 1];
            String errorMsg = sfQuote.Error_Status__c;
            List<String> errorMsgBreakdown;
            if (sfQuote.Is_Errored__c == false && errorMsg == null) {}
            else {
                errorMsgBreakdown = errorMsg.split(';');
            }
            String sfAccName = sfQuote.SBQQ__Account__r.Name;
            String sfQuoteName = sfQuote.Name;
            String accId;
            if (sfQuote.SBQQ__Account__r.External_Connectbase_Id__c == null || (errorMsgBreakdown!= null && errorMsgBreakdown[1] == 'CreateAccount')) {
                System.enqueueJob(new API_CB_AccountQueueable_INS(sfAccName, sfQuote.Id, null));
                return;
            }
            else {
                accId = sfQuote.SBQQ__Account__r.External_Connectbase_Id__c;
            }
            String dealId;
            if (sfQuote.External_Connectbase_Id__c == null || (errorMsgBreakdown!= null && errorMsgBreakdown[1] == 'CreateDeal')) {
                System.enqueueJob(new API_CB_DealQueueable_INS(accId, sfQuote.Name, sfQuote.Id, null));
                return;
            }
            else {
                dealId = sfQuote.External_Connectbase_Id__c;
            }
            
            masterCreatePricing(accId, dealId, sfQuoteId);
            
            return; 
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in INV_PricingController_UTL.priceQuote at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
    
    public static void masterCreatePricing(String accId, String dealId, String sfQuoteId) {
        try {
            System.debug('inside method start');
            SBQQ__Quote__c sfQuote = [SELECT Id, SBQQ__SubscriptionTerm__c,SBQQ__Type__c,SBQQ__RenewalTerm__c FROM SBQQ__Quote__c WHERE Id =: sfQuoteId LIMIT 1];
            List<SBQQ__QuoteLine__c> bundleQLs = [
                SELECT Id, Name, SBQQ__Product__c, Network_Status__c, SBQQ__RequiredBy__c, SBQQ__Product__r.Connectbase_Product__c, Site_Bandwidth_Mbps__c, Street__c, City__c, State__c, Zip__c, Country__c, External_Connectbase_Id__c, Is_Errored__c, Error_Status__c, Send_To_Connectbase__c, Receive_From_Connectbase__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c = :sfQuoteId
                AND SBQQ__Bundle__c = true
                AND SBQQ__Product__r.Connectbase_Product__c != null
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
                WHERE SBQQ__Quote__c = :sfQuoteId
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
            Database.executeBatch(new BAT_CB_Pricing_INS(accId, dealId, cbProductToQLMap, sfQuote, 'Bulk', null), 1);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in INV_PricingController_UTL.masterCreatePricing at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
    
    @AuraEnabled
    public static void masterCreatePricingSingle(List<Map<String,String>> sfQuoteLineLst) {
        try {
            System.debug('Received Ids' + sfQuoteLineLst);
            List<String> allBundleQLs = new List<String>();
            List<String> allSenderReceiverIds = new List<String>();
            for (Map<String,String> m : sfQuoteLineLst) {
                allBundleQLs.add(m.get('bundle'));
                allSenderReceiverIds.add(m.get('sender'));
                allSenderReceiverIds.add(m.get('receiver'));
            }
            List<SBQQ__QuoteLine__c> bundleQLs = [
                SELECT Id, Name, SBQQ__Quote__c, SBQQ__Product__c, SBQQ__RequiredBy__c, SBQQ__Product__r.Connectbase_Product__c, Site_Bandwidth_Mbps__c, Network_Status__c, Street__c, City__c, State__c, Zip__c, Country__c, External_Connectbase_Id__c, Is_Errored__c, Error_Status__c, Send_To_Connectbase__c, Receive_From_Connectbase__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN : allBundleQLs
            ];
            SBQQ__Quote__c sfQuote = [SELECT SBQQ__SubscriptionTerm__c, SBQQ__Account__r.External_Connectbase_Id__c, External_Connectbase_Id__c FROM SBQQ__Quote__c WHERE Id =: bundleQLs[0].SBQQ__Quote__c LIMIT 1];
            String accId = sfQuote.SBQQ__Account__r.External_Connectbase_Id__c;
            String dealId = sfQuote.External_Connectbase_Id__c;
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
                SELECT Id, Name, SBQQ__Product__c, SBQQ__RequiredBy__r.SBQQ__Product__r.Connectbase_Product__c, SBQQ__RequiredBy__c, Site_Bandwidth_Mbps__c, Network_Status__c, Street__c, City__c, State__c, Zip__c, Country__c, External_Connectbase_Id__c, Is_Errored__c, Error_Status__c, Send_To_Connectbase__c, Receive_From_Connectbase__c
                FROM SBQQ__QuoteLine__c
                WHERE Id IN : allSenderReceiverIds
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
            Database.executeBatch(new BAT_CB_Pricing_INS(accId, dealId, cbProductToQLMap, sfQuote, 'Single', null), 1);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in INV_PricingController_UTL.masterCreatePricingSingle at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
}