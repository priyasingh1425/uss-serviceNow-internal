// SC-0000100
// 	Calls a queueable method to create a Connectbase account and save that on the Salesforce account, and then start deal creation
public class API_CB_AccountQueueable_INS implements Queueable, Database.AllowsCallouts {
    private String accountName;
    private String sfQuoteId;
    private String sfGroupId;

    // Constructor to pass parameters to the class
    public API_CB_AccountQueueable_INS(String accountName, String sfQuoteId, String sfGroupId) {
        this.accountName = accountName;
        this.sfQuoteId = sfQuoteId;
        this.sfGroupId = sfGroupId;
    }

    // Execute method for the queueable interface
    public void execute(QueueableContext context) {
        try {
            String accId = API_CB_AccountModel_INS.createAccount(accountName, sfQuoteId);
            SBQQ__Quote__c quote = [SELECT Name FROM SBQQ__Quote__c WHERE Id =: sfQuoteId LIMIT 1];
            if (accId != null) {
                System.enqueueJob(new API_CB_DealQueueable_INS(accId, quote.name, sfQuoteId, sfGroupId));
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AccountQueueable_INS.execute at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
}