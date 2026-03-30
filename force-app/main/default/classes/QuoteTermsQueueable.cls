/**
 * @description Queueable class to calculate quote legal terms asynchronously.
 *              Runs after the main transaction completes, ensuring all quote lines
 *              exist before terms are calculated. This moves ~5 SOQL queries out
 *              of the synchronous transaction context.
 *
 * @author      Seth Sheppard
 * @date        2025-12-29
 *
 * @bug-fix     Governor Limit Issue - Too many SOQL queries: 101
 *              During CPQ Quote Clone operations, UpdateQuoteTerms was running
 *              synchronously on insert before quote lines existed, then re-running
 *              on cascading updates. Moving to Queueable ensures:
 *              1. Terms calculate once, after all DML completes
 *              2. Quote lines exist when terms are calculated (better data accuracy)
 *              3. ~5 SOQL queries removed from synchronous transaction
 *
 * @see         QuoteTriggerHandler - Guards that prevent duplicate queueing
 * @see         QuoteTermsHandler.UpdateQuoteTerms - The method executed by this Queueable
 */
public class QuoteTermsQueueable implements Queueable {

    private Set<Id> quoteIds;

    // Test-only flag to force exception for code coverage
    @TestVisible
    private static Boolean forceException = false;

    /**
     * @description Constructor - stores the quote IDs to process
     * @param quoteIds Set of Quote Ids to calculate terms for
     */
    public QuoteTermsQueueable(Set<Id> quoteIds) {
        this.quoteIds = quoteIds;
    }

    /**
     * @description Execute method called by the Queueable framework.
     *              Retrieves quotes and calculates their legal terms.
     * @param context QueueableContext provided by the platform
     */
    public void execute(QueueableContext context) {
        try {
            // Test-only: force exception for code coverage
            if (forceException) {
                throw new CustomException('Test exception for coverage');
            }
            List<SBQQ__Quote__c> quotes = [
                SELECT Id FROM SBQQ__Quote__c WHERE Id IN :quoteIds
            ];
            if (!quotes.isEmpty()) {
                QuoteTermsHandler.UpdateQuoteTerms(quotes, true);
            }
        } catch (Exception e) {
            if(!e.getMessage().startsWith('Delete failed.')){
                CustomException ce = new CustomException();
                ce.message = 'An error occurred in QuoteTermsQueueable.execute at line ' +
                    e.getLineNumber() + ': ' + e.getMessage();
                CustomException.sendErrorNotification(ce);
            }
        }
    }
}