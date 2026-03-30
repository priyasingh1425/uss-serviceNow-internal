/**
 * @author Ladd Partners
 * @date 4/30/2025
 */

public with sharing class lp_BillingContractLineSearchController {
    public static final String ERROR_NO_LINES_FOUND = 'No contract lines were found by this search term';
    
    @AuraEnabled(cacheable=false)
    public static ResultWrapper createITSPayableInvoiceline(Map<String, String> lineFromLwc) {
        ResultWrapper result = new ResultWrapper();
        
        try {
            Master_ITS_Payable_Invoice_Line__c newLine = lp_ITSPayableLine.createNewLineFromLwc(lineFromLwc);
            insert newLine;
            result.message = newLine.Id;
        } catch(Exception ex) {
            lp_Utility.logException(ex);
            result.error = true;
            result.message = buildLwcResultErrorMessageFromException(ex);
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static ResultWrapper getVendorFromInvoice(Id itsInvoiceId) {
        ResultWrapper result = new ResultWrapper();

        try {
            Master_ITS_Payable_Invoice__c itsInvoice = new lp_ITSPayableSelector().getWithLinesById(itsInvoiceId);
            result.vendorId = itsInvoice?.Vendor__c;
        } catch(Exception ex) {
            lp_Utility.logException(ex);
            result.error = true;
            result.message = buildLwcResultErrorMessageFromException(ex);
        }
        return result;
    }

    @AuraEnabled(cacheable=false)
    public static ResultWrapper searchContractLineItems(String searchTerm, Boolean useLecCircuitId, Id vendorId) {
        ResultWrapper result = new ResultWrapper();

        try {
            searchTerm = '%' + searchTerm + '%';
            List<ffbc__ContractLineItem__c> lines = new lp_BillingContractLineSelector().getLikeCircuitId(searchTerm, useLecCircuitId, vendorId);

            if (lines.isEmpty()) {
                result.message = ERROR_NO_LINES_FOUND;
                result.warning = true;
                return result;
            }

            for (ffbc__ContractLineItem__c line : lines) {
                result.contractLines.add(new lp_BillingContractLineWrapper(line));
            }
        } catch(Exception ex) {
            lp_Utility.logException(ex);
            result.error = true;
            result.message = buildLwcResultErrorMessageFromException(ex);
        }
        return result;
    }

    private static String buildLwcResultErrorMessageFromException(Exception ex) {
        return 'Apex Error Message: ' + ex.getMessage()
                + ' Apex Line number: ' + ex.getLineNumber()
                + ' Apex Stack trace: ' + ex.getStackTraceString();
    }

    public class ResultWrapper {
        @AuraEnabled public Boolean error { get; set; }
        @AuraEnabled public Boolean warning { get; set; }
        @AuraEnabled public String message { get; set; }
        @AuraEnabled public List<lp_BillingContractLineWrapper> contractLines { get; set; }
        @AuraEnabled public Map<String, String> fieldApiNameByLabel { get; set; }
        @AuraEnabled public Id vendorId { get; set; }

        public ResultWrapper() {
            this.error = false;
            this.warning = false;
            this.message = 'Success';
            this.contractLines = new List<lp_BillingContractLineWrapper>();
            this.fieldApiNameByLabel = new Map<String, String>();
            this.vendorId = null;
        }
    }
}