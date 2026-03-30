/**
 * @description Handler class for QuoteTrigger recursion control and async processing.
 *              Prevents duplicate processing when child triggers (QuoteLineTrigger,
 *              QuoteAddressTrigger) update the Quote record, causing QuoteTrigger to
 *              re-fire within the same transaction.
 *
 * @author      Seth Sheppard
 * @date        2025-12-29
 *
 * @bug-fix     Governor Limit Issue - Too many SOQL queries: 101
 *              During CPQ Quote Clone operations, the QuoteTrigger was firing multiple
 *              times due to cascading updates from child triggers. This caused
 *              UpdateQuoteTerms (~5 SOQL) and updateQuoteAddress (~3 SOQL) to run
 *              repeatedly, exceeding the 100 SOQL limit.
 *
 * @solution    - Static Set tracking prevents duplicate queueing/processing per transaction
 *              - Terms calculation moved to Queueable (runs after transaction completes)
 *              - Address updates guarded per-Opportunity to prevent redundant processing
 */
public class QuoteTriggerHandler {

    // Track quotes already queued for terms calculation this transaction
    private static Set<Id> queuedForTerms = new Set<Id>();

    // Track opportunities already processed for address updates this transaction
    private static Set<Id> processedOpportunityIds = new Set<Id>();

    /**
     * @description Check if a quote should be queued for terms calculation.
     *              Returns false if the quote has already been queued in this transaction.
     * @param quoteId The Id of the quote to check
     * @return Boolean - true if quote should be queued, false if already queued
     */
    public static Boolean shouldQueueForTerms(Id quoteId) {
        return !queuedForTerms.contains(quoteId);
    }

    /**
     * @description Mark quotes as queued for terms calculation.
     *              Prevents duplicate queueing within the same transaction.
     * @param quoteIds Set of Quote Ids to mark as queued
     */
    public static void markQueuedForTerms(Set<Id> quoteIds) {
        queuedForTerms.addAll(quoteIds);
    }

    /**
     * @description Check if an opportunity should be processed for quote address updates.
     *              Returns false if the opportunity has already been processed in this transaction.
     * @param opportunityId The Id of the opportunity to check
     * @return Boolean - true if opportunity should be processed, false if already processed
     */
    public static Boolean shouldProcessQuoteAddress(Id opportunityId) {
        return !processedOpportunityIds.contains(opportunityId);
    }

    /**
     * @description Mark opportunities as processed for quote address updates.
     *              Prevents duplicate processing within the same transaction.
     * @param opportunityIds Set of Opportunity Ids to mark as processed
     */
    public static void markQuoteAddressProcessed(Set<Id> opportunityIds) {
        processedOpportunityIds.addAll(opportunityIds);
    }

    /**
     * @description Reset all guards. Used by test classes to reset state between tests.
     */
    @TestVisible
    private static void reset() {
        queuedForTerms.clear();
        processedOpportunityIds.clear();
    }
}