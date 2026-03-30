/*************************************************
* Name: INV_Subscription_FindMostRecent_QRY
* Description: Invocable action class that is used by a flow to find the most recent subscription for a given subscription ID.
* Called by flow(s): 
    * Quote - Update Quote Fields
* Related Classes: n/a
* Test class: INV_Subscription_FindRecent_TEST
* ***********************************************/


public with sharing class INV_Subscription_FindMostRecent_QRY {

    public class InputVariables{
        @InvocableVariable(label='SBQQ__Subscription__c Text ID' description='Subscription ID for a Subscription record with at least the fields SBQQ__Contract__c and SBQQ__Product__c filled in' required=true)
        public String inputSubscription;
    }

    public class OutputVariables{
        @InvocableVariable(label='Most Recent Subscription' description='Most recent subscription for the given input subscription')
        public SBQQ__Subscription__c outputSubscription;
        
        @InvocableVariable(label='Is Original Subscription?' description='True if this has returned the Original Subscription, False if this has returned a Subscription that has revised another Subscription.')
        public Boolean originalSubscription;
    }

    /*************************************************
* Method Name: findMostRecentSubscription
* Description: Invocable action method that is used by a flow to find the most recent subscription for a given subscription ID.
* ***********************************************/   

    @InvocableMethod(label='Find Most Recent Subscription' description='Finds the most recent subscription for a given subscription ID')
    public static List<OutputVariables> findMostRecentSubscription(List<InputVariables> ivs){
        List<OutputVariables> outputVariables = new List<OutputVariables>();

        Map<String, Schema.SObjectField> mapFields = Schema.SObjectType.SBQQ__Subscription__c.fields.getMap();
        String allfields = '';
        for(Schema.SObjectField f : mapFields.values()){

                if(String.valueOf(allfields) == ''){
                    allfields = String.valueOf(f);
                } else {
                    allfields = String.valueOf(f) + ', ' + allfields; 
                }
        }
        
        //process each InputVariable: this allows for bulkification
        for (InputVariables v : ivs) {
            String currentSubQuery = 'SELECT ' + allfields + ' FROM SBQQ__Subscription__C WHERE Id = \'' + v.inputSubscription + '\'';
            SBQQ__Subscription__c currentSub = (SBQQ__Subscription__c)Database.query(currentSubQuery).get(0);
            
            OutputVariables ov = new OutputVariables();
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
                ov.originalSubscription = false;
                while(continueWhileLoop){
                    for(SBQQ__Subscription__c s : allRelevantSubs){
                        if(s.SBQQ__RevisedSubscription__c == currentIteration.Id){
                            currentIteration = s;
                        } else {
                            ov.outputSubscription = currentIteration;
                            continueWhileLoop = false;
                        }
                    }
                } 
            } else {
                //no subscriptions were found on the contract with the same product.  This means that the original subscription is the most recent.  We will return the original subscription.
                ov.outputSubscription = currentSub;
                ov.originalSubscription = true;
            }
            
            outputVariables.add(ov);
        } 

        return outputVariables;

    }
}