/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

public with sharing class lp_ITSPayableController {
    @AuraEnabled(Cacheable=false)
    public static lp_MessageWrapper createMonthlyPayableInvoice(Id itsPayableInvoiceId) {
        lp_MessageWrapper wrapper = new lp_MessageWrapper();
        wrapper.isSuccessful = false;

        try {
            c2g__codaPurchaseInvoice__c monthlyPayableInvoice = lp_MonthlyPayableInvoice.createFromITSPayable(itsPayableInvoiceId);
            wrapper.newRecordId = monthlyPayableInvoice.Id;
            wrapper.message = String.format('Monthly Payable Invoice {0} has been created', new List<String>{monthlyPayableInvoice.Id});
            wrapper.isSuccessful = true;
        }
        catch(Exception e) {
            wrapper.message = e.getMessage();
        }

        return wrapper;
    }
}