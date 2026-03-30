global class INV_Quote_UPdateQuoteFields_BTC implements Database.Batchable<sObject>,Database.Stateful {
    
    global final String query;
    global final String allFields;
    global final String quoteLineOrderType;
    global final String inputQuote;
    global List<String> exception_List = new List<String>();
    
    global INV_Quote_UPdateQuoteFields_BTC(String inputQuote, String quoteLineOrderType) {
        
        this.query = 'Select Id, Facility__c, Street__c, City__c, State__c, Zip__c, Country__c, Customer_Reference__c, Order_Type__c, Street_Z__c, City_Z__c, State_Z__c, Zip_Z__c, Country_Z__c, Site_Bandwidth_Mbps__c,Prior_Subscription__c, Prior_Order_Product__c, SBQQ__Quote__r.Update_Processing__c,SBQQ__Quote__r.SBQQ__Opportunity2__r.Type,SBQQ__Quote__r.SBQQ__Opportunity2__r.SBQQ__Renewal__c,SBQQ__RenewedSubscription__c,SBQQ__UpgradedSubscription__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__c = \'' + inputQuote + '\'';
        this.allFields = 'SBQQ__RevisedSubscription__c, SBQQ__Contract__c, SBQQ__Product__c, SBQQ__OrderProduct__r.Facility__c, SBQQ__OrderProduct__r.Street__c, SBQQ__OrderProduct__r.City__c, SBQQ__OrderProduct__r.State__c, SBQQ__OrderProduct__r.Zip__c, SBQQ__OrderProduct__r.Country__c, SBQQ__OrderProduct__r.Customer_Reference__c, SBQQ__OrderProduct__r.Street_Z__c, SBQQ__OrderProduct__r.City_Z__c, SBQQ__OrderProduct__r.State_Z__c, SBQQ__OrderProduct__r.Zip_Z__c, SBQQ__OrderProduct__r.Country_Z__c, SBQQ__OrderProduct__r.Site_Bandwidth_Mbps__c, SBQQ__OrderProduct__r.Id, Id ';
        this.quoteLineOrderType = quoteLineOrderType;
        this.inputQuote = inputQuote;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<SBQQ__QuoteLine__c> quoteLinesToUpdate = new List<SBQQ__QuoteLine__c>();
        for (sObject s : scope) {
            SBQQ__Subscription__c outputSubscription = new SBQQ__Subscription__c();
            Boolean originalSubscription;
            
            SBQQ__QuoteLine__c ql = (SBQQ__QuoteLine__c)s;
            
            String inputSubscription;
            
            if(quoteLineOrderType == 'Renew'){
                inputSubscription = ql.SBQQ__RenewedSubscription__c;
            } else {
                inputSubscription = ql.SBQQ__UpgradedSubscription__c;
            }           
            
            String currentSubQuery = 'SELECT ' + allfields + ' FROM SBQQ__Subscription__C WHERE Id = \'' + inputSubscription + '\'';
            SBQQ__Subscription__c currentSub = (SBQQ__Subscription__c)Database.query(currentSubQuery).get(0);
            
            String query;
            List<SBQQ__Subscription__c> allRelevantSubs = new List<SBQQ__Subscription__c>();
            
            if((String)currentSub.SBQQ__Contract__c!=null && (String)currentSub.SBQQ__Contract__c != '' && (String)currentSub.SBQQ__Product__c != null && (String)currentSub.SBQQ__Product__c != ''){
                query = 'SELECT ' + allfields + ' FROM SBQQ__Subscription__C WHERE SBQQ__Contract__c = \'' + (String)currentSub.SBQQ__Contract__c + '\' AND SBQQ__Product__c = \'' + (String)currentSub.SBQQ__Product__c + '\' AND SBQQ__RevisedSubscription__c != null ORDER BY CreatedDate DESC';
                
                //get all subscriptions that have the same order product as the original subscription and are on the same contract.  We are looking for the most recent in the series of Revised subscriptions, so we only want subscriptions that have revised another.  If revised subscription is blank, that should indicate that it is the original, and subscriptions that are originals are covered in teh else statement of the list processing.
                allRelevantSubs = Database.query(query);
            }
            
            SBQQ__Subscription__c currentIteration = currentSub;
            Boolean continueWhileLoop = true;
            
            //list processing.  We will iterate through the list until we find the most recent subscription.  If the current iteration is not the most recent, we will set the current iteration to the most recent and continue the loop.  If the current iteration is the most recent (not revised by any additional subscriptions), that will be the subscription returned.
            if(allRelevantSubs.size() > 0){
                originalSubscription = false;
                while(continueWhileLoop){
                    for(SBQQ__Subscription__c sub : allRelevantSubs){
                        if(sub.SBQQ__RevisedSubscription__c == currentIteration.Id){
                            currentIteration = sub;
                        } else {
                            outputSubscription = currentIteration;
                            continueWhileLoop = false;
                        }
                    }
                } 
            } else {
                //no subscriptions were found on the contract with the same product.  This means that the original subscription is the most recent.  We will return the original subscription.
                outputSubscription = currentSub;
                originalSubscription = true;
            }
            
            ql.Facility__c = outputSubscription.SBQQ__OrderProduct__r.Facility__c;
            ql.Street__c = outputSubscription.SBQQ__OrderProduct__r.Street__c;
            ql.City__c = outputSubscription.SBQQ__OrderProduct__r.City__c;
            ql.State__c = outputSubscription.SBQQ__OrderProduct__r.State__c;
            ql.Zip__c = outputSubscription.SBQQ__OrderProduct__r.Zip__c;
            ql.Country__c = outputSubscription.SBQQ__OrderProduct__r.Country__c;
            ql.Customer_Reference__c = outputSubscription.SBQQ__OrderProduct__r.Customer_Reference__c;
            ql.Order_Type__c = quoteLineOrderType;
            ql.Street_Z__c = outputSubscription.SBQQ__OrderProduct__r.Street_Z__c;
            ql.City_Z__c = outputSubscription.SBQQ__OrderProduct__r.City_Z__c;
            ql.State_Z__c = outputSubscription.SBQQ__OrderProduct__r.State_Z__c;
            ql.Zip_Z__c = outputSubscription.SBQQ__OrderProduct__r.Zip_Z__c;
            ql.Country_Z__c = outputSubscription.SBQQ__OrderProduct__r.Country_Z__c;
            ql.Site_Bandwidth_Mbps__c = outputSubscription.SBQQ__OrderProduct__r.Site_Bandwidth_Mbps__c;
            ql.Prior_Subscription__c = outputSubscription.Id;
            ql.Prior_Order_Product__c = outputSubscription.SBQQ__OrderProduct__r.Id;

            quoteLinesToUpdate.add(ql);
        }
        if (!quoteLinesToUpdate.isEmpty()) {
            Database.SaveResult[] SaveResultList = Database.update(quoteLinesToUpdate, false);
            
            for(integer i =0; i<quoteLinesToUpdate.size();i++){
                String msg='';
                If(!SaveResultList[i].isSuccess()){
                    msg += quoteLinesToUpdate.get(i).id + '\n'+'Error: "';        
                    for(Database.Error err: SaveResultList[i].getErrors()){  
                        msg += err.getmessage()+'"\n\n';
                    } 
                }                
                if(msg!='')
                    exception_List.add(msg);
            } 
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        if(exception_List != null && !exception_List.IsEmpty()){
            try{
                HLP_Case_SFQueue_Ins.createSFQueueCase('INV_Quote_UPdateQuoteFields_BTC failed for quote: ' + inputQuote, String.join(exception_List, ' || '), 'High');
            } catch(Exception e){
                System.debug('Error sending email');
            }
            
        }
        System.debug('Batch job finished. Quote lines updated: ' + BC.getJobId());
    }
    
    
}