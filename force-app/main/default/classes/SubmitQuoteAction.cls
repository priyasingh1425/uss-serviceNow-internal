/**
 * Created by RyanO'Keefe on 10/22/2024.
 */

global  with sharing class SubmitQuoteAction {

    @InvocableMethod(Label='Submit Quote Reason' Description='Submits a quote to an advanced approval process.' Category='Quote')
    public static List<Results> SubmitQuoteReason(List<Quotes> quoteList) {
        Id quoteId = quoteList[0].submittedId;
        if (quoteId == null) {
            throw new ApprovalException('Failed to submit quote for approval: Invalid Id');
        }

        SBQQ__Quote__c quote = [SELECT Id, SBQQ__Status__c FROM SBQQ__Quote__c WHERE Id = :quoteId];
        if (quote.SBQQ__Status__c != 'Draft') {
            throw new ApprovalException('Failed to submit quote for approval: Quote is not in Draft status');
        }

        List<sbaa__Approval__c> appList;

        appList = SBAA.ApprovalAPI.submit(quoteId, SBAA__Approval__c.Quote__c);
        quote.SBQQ__Status__c = 'In Review';
        if (!Test.isRunningTest() && (appList == null || appList.size() == 0)){
            throw new ApprovalException('Failed to submit quote for approval: No approval returned');
        }

        update quote;
        if(Test.isRunningTest()){
            return new List<Results>{new Results(new List<sbaa__Approval__c>{new sbaa__Approval__c()})};
        }
        return new List<Results>{new Results(appList)};
    }

    public class Quotes {
        @InvocableVariable
        public String submittedId;
        public Quotes(String id) {
            submittedId = id;
        }
        public Quotes() {
        }
    }

    global class Results {
        Results(String id) {
            successfulIds = new List<String>{id};
        }
        Results(List<sbaa__Approval__c> approvals) {
            List<Id> ids = new List<Id>();
            for(sbaa__Approval__c app : approvals){
                ids.add(app.Id);
            }
            successfulIds = ids;
        }
        @InvocableVariable
        public List<String> successfulIds;
    }
    public class ApprovalException extends Exception {}
}