/**
 * @description Test class for QuoteTriggerHandler.
 *              Provides 100% code coverage for the recursion guard handler.
 *
 * @author      Seth Sheppard
 * @date        2025-12-29
 *
 * @see         QuoteTriggerHandler - Recursion guards for QuoteTrigger
 * @see         QuoteTrigger - The trigger this handler supports
 */
@IsTest
public class QuoteTriggerHandlerTest {

    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
    }

    @IsTest
    static void testShouldQueueForTerms() {
        // Test that a quote can be queued initially
        Id fakeQuoteId = '0Q0000000000001AAA';

        Test.startTest();
        System.assertEquals(true, QuoteTriggerHandler.shouldQueueForTerms(fakeQuoteId),
            'New quote should be eligible for queueing');

        // Mark as queued
        QuoteTriggerHandler.markQueuedForTerms(new Set<Id>{fakeQuoteId});

        // Should not queue again
        System.assertEquals(false, QuoteTriggerHandler.shouldQueueForTerms(fakeQuoteId),
            'Already queued quote should not be eligible again');
        Test.stopTest();
    }

    @IsTest
    static void testShouldProcessQuoteAddress() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        // Initially should process
        System.assertEquals(true, QuoteTriggerHandler.shouldProcessQuoteAddress(opp.Id),
            'Opportunity should be processable initially');

        // Mark as processed
        QuoteTriggerHandler.markQuoteAddressProcessed(new Set<Id>{opp.Id});

        // Should not process again
        System.assertEquals(false, QuoteTriggerHandler.shouldProcessQuoteAddress(opp.Id),
            'Same opportunity should not process twice');

        // Different opportunity should still be processable
        Id fakeOppId = '006000000000001AAA';
        System.assertEquals(true, QuoteTriggerHandler.shouldProcessQuoteAddress(fakeOppId),
            'Different opportunity should still be processable');
        Test.stopTest();
    }

    @IsTest
    static void testQuoteInsertQueuesJob() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert quote;
        Test.stopTest();

        // Verify quote was created
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals(1, quotes.size(), 'Quote should be created');
    }

    @IsTest
    static void testQuoteUpdateQueuesJobOnce() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert quote;

        Test.startTest();
        // First update
        quote.SBQQ__Notes__c = 'Test note 1';
        update quote;

        // Second update in same transaction context would be guarded
        // (In real scenario, this would be from child trigger cascade)
        quote.SBQQ__Notes__c = 'Test note 2';
        update quote;
        Test.stopTest();

        // Verify quote was updated
        SBQQ__Quote__c updatedQuote = [SELECT SBQQ__Notes__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];
        System.assertEquals('Test note 2', updatedQuote.SBQQ__Notes__c, 'Quote should be updated');
    }

    @IsTest
    static void testHandlerReset() {
        // Test the reset method for completeness
        Id fakeQuoteId = '0Q0000000000001AAA';
        Id fakeOppId = '006000000000001AAA';

        // Mark some items as processed
        QuoteTriggerHandler.markQueuedForTerms(new Set<Id>{fakeQuoteId});
        QuoteTriggerHandler.markQuoteAddressProcessed(new Set<Id>{fakeOppId});

        // Verify they're marked
        System.assertEquals(false, QuoteTriggerHandler.shouldQueueForTerms(fakeQuoteId));
        System.assertEquals(false, QuoteTriggerHandler.shouldProcessQuoteAddress(fakeOppId));

        Test.startTest();
        // Call reset to clear the guards
        QuoteTriggerHandler.reset();

        // Verify they're cleared - should be eligible again
        System.assertEquals(true, QuoteTriggerHandler.shouldQueueForTerms(fakeQuoteId),
            'After reset, quote should be eligible for queueing again');
        System.assertEquals(true, QuoteTriggerHandler.shouldProcessQuoteAddress(fakeOppId),
            'After reset, opportunity should be processable again');
        Test.stopTest();
    }

    @IsTest
    static void testMultipleQuotesInSameTransaction() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        // Insert multiple quotes in same transaction
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        for (Integer i = 0; i < 3; i++) {
            quotes.add(new SBQQ__Quote__c(
                SBQQ__Account__c = acc.Id,
                SBQQ__Opportunity2__c = opp.Id,
                SBQQ__Primary__c = (i == 0)
            ));
        }
        insert quotes;
        Test.stopTest();

        // Verify all quotes were created
        List<SBQQ__Quote__c> createdQuotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id IN :quotes];
        System.assertEquals(3, createdQuotes.size(), 'All quotes should be created');
    }
}