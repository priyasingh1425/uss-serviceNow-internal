/**
 * @description Trigger for SBQQ__Quote__c (CPQ Quote) object.
 *              Handles quote terms calculation, line group creation, and address updates.
 *
 * @bug-fix     Governor Limit Issue - Too many SOQL queries: 101
 *              Modified by @Seth Sheppard on 2025-12-29
 *              See QuoteTriggerHandler and QuoteTermsQueueable for details.
 */
trigger QuoteTrigger on SBQQ__Quote__c (after insert, after update, before insert)
{
    // BEFORE INSERT - runs synchronously (no recursion issue here)
    if (Trigger.isBefore && Trigger.isInsert)
    {
        QuoteTermsHandler.updateLineItemsGrouped(trigger.new);

        List<SBQQ__Quote__c> validQuotes = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : Trigger.new) {
            if (quote.SBQQ__Type__c != 'Amendment' && quote.SBQQ__Type__c != 'Renewal') {
                validQuotes.add(quote);
            }
        }
        if (!validQuotes.isEmpty()) {
            QuoteTermsHandler.allowCarryoverAddressData(validQuotes);
        }
    }

    // AFTER INSERT - queue terms calculation, run other logic
    if (Trigger.isAfter && Trigger.isInsert)
    {
        /***********************************************
         * Bug Fix (Start) - @Seth Sheppard - 2025-12-29
         * Governor Limit: Too many SOQL queries: 101
         *
         * Changed: Moved UpdateQuoteTerms from synchronous to Queueable.
         * Reason: During CPQ Clone, cascading child trigger updates caused
         *         QuoteTrigger to re-fire multiple times, running UpdateQuoteTerms
         *         (~5 SOQL) on each fire. Now queued once per quote per transaction.
         ***********************************************/
        Set<Id> toQueue = new Set<Id>();
        for (SBQQ__Quote__c quote : Trigger.new) {
            if (QuoteTriggerHandler.shouldQueueForTerms(quote.Id)) {
                toQueue.add(quote.Id);
            }
        }
        if (!toQueue.isEmpty()) {
            QuoteTriggerHandler.markQueuedForTerms(toQueue);
            System.enqueueJob(new QuoteTermsQueueable(toQueue));
        }
        /***********************************************
         * Bug Fix (End) - @Seth Sheppard
         ***********************************************/

        // Create quote line groups for non-amendment/renewal quotes
        List<SBQQ__Quote__c> validQuotes = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : Trigger.new) {
            if (quote.SBQQ__Type__c != 'Amendment' && quote.SBQQ__Type__c != 'Renewal') {
                validQuotes.add(quote);
            }
        }
        if (!validQuotes.isEmpty()) {
            QuoteTermsHandler.createQuoteLineGroup(validQuotes);
        }
    }

    // AFTER UPDATE - queue terms calculation, update addresses (both guarded)
    if (Trigger.isAfter && Trigger.isUpdate)
    {
        /***********************************************
         * Bug Fix (Start) - @Seth Sheppard - 2025-12-29
         * Governor Limit: Too many SOQL queries: 101
         *
         * Changed: Moved UpdateQuoteTerms from synchronous to Queueable.
         * Added: Per-quote guard to prevent duplicate queueing.
         * Reason: Cascading updates from QuoteLineTrigger caused re-fires.
         ***********************************************/
        Set<Id> toQueue = new Set<Id>();
        for (SBQQ__Quote__c quote : Trigger.new) {
            if (QuoteTriggerHandler.shouldQueueForTerms(quote.Id)) {
                toQueue.add(quote.Id);
            }
        }
        if (!toQueue.isEmpty()) {
            QuoteTriggerHandler.markQueuedForTerms(toQueue);
            System.enqueueJob(new QuoteTermsQueueable(toQueue));
        }
        /***********************************************
         * Bug Fix (End) - @Seth Sheppard
         ***********************************************/

        /***********************************************
         * Bug Fix (Start) - @Seth Sheppard - 2025-12-29
         * Governor Limit: Too many SOQL queries: 101
         *
         * Changed: Added per-Opportunity guard for updateQuoteAddress.
         * Reason: updateQuoteAddress (~3 SOQL) was running on every cascading
         *         update. Now runs once per Opportunity per transaction.
         ***********************************************/
        Set<Id> opportunitiesToProcess = new Set<Id>();
        List<SBQQ__Quote__c> quotesToProcess = new List<SBQQ__Quote__c>();
        for (SBQQ__Quote__c quote : Trigger.new) {
            if (quote.SBQQ__Opportunity2__c != null &&
                QuoteTriggerHandler.shouldProcessQuoteAddress(quote.SBQQ__Opportunity2__c)) {
                opportunitiesToProcess.add(quote.SBQQ__Opportunity2__c);
                quotesToProcess.add(quote);
            }
        }
        if (!opportunitiesToProcess.isEmpty()) {
            QuoteTriggerHandler.markQuoteAddressProcessed(opportunitiesToProcess);
            QuoteTermsHandler.updateQuoteAddress(quotesToProcess);
        }
        /***********************************************
         * Bug Fix (End) - @Seth Sheppard
         ***********************************************/
    }
}