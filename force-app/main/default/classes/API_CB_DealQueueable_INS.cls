// SC-0000100
// Calls a queueable method to create a Connectbase deal and save that on the Salesforce quote, and then start costing creation
public class API_CB_DealQueueable_INS implements Queueable, Database.AllowsCallouts {
    private String accId;
    private String dealName;
    private String sfQuoteId;
    private String sfGroupId;

    // Constructor to pass parameters to the class
    public API_CB_DealQueueable_INS(String accId, String dealName, String sfQuoteId, String sfGroupId) {
        this.accId = accId;
        this.dealName = dealName;
        this.sfQuoteId = sfQuoteId;
        this.sfGroupId = sfGroupId;
    }
    
    public void execute(QueueableContext context) {
        try {
            String dealId = API_CB_DealModel_INS.createDeal(accId, dealName, sfQuoteId);
            if (dealId != null) {
                if (sfGroupId == null) {
                    INV_PricingController_UTL.masterCreatePricing(accId, dealId, sfQuoteId);
                }
                else {
                    CTL_CB_ReConfiguration_UTL.masterCreatePricingSingle(accId, dealId, sfQuoteId, sfGroupId);
                }
                if(Test.isRunningTest()){
                    throw new CustomException();
                }  
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_DealQueueable_INS.execute at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
}