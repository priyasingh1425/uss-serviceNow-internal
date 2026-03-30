/**
 * @description  Test class for TerritoryPrimaryScheduler.
 *               Verifies that the scheduler can be registered and that it
 *               enqueues TerritoryPrimaryBatch when executed.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
@isTest
private class TerritoryPrimaryScheduler_TEST {

    private static final String CRON_EXPR = '0 0 2 * * ?';
    private static final String JOB_NAME  = 'Territory Primary Nightly Test';

    @isTest
    static void testScheduler_registersSuccessfully() {
        Test.startTest();
        String jobId = System.schedule(JOB_NAME, CRON_EXPR, new TerritoryPrimaryScheduler());
        Test.stopTest();

        CronTrigger ct = [
            SELECT Id, CronExpression, State
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        Assert.areEqual(CRON_EXPR, ct.CronExpression,
            'Scheduled job should have the correct cron expression');
        Assert.areEqual('WAITING', ct.State,
            'Newly scheduled job should be in WAITING state');
    }

    @isTest
    static void testScheduler_executesWithoutError() {
        // Register and immediately fire the scheduler within the test context.
        // TerritoryPrimaryBatch is enqueued inside Test.startTest/stopTest,
        // which processes async jobs synchronously.
        TerritoryPrimaryService.instance = new NoOpService();

        Test.startTest();
        TerritoryPrimaryScheduler scheduler = new TerritoryPrimaryScheduler();
        scheduler.execute(null);
        Test.stopTest();
        // No exception thrown -- batch was enqueued successfully
    }

    // -------------------------------------------------------------------------
    // No-op service to suppress ETM SOQL during batch execution
    // -------------------------------------------------------------------------
    private class NoOpService extends TerritoryPrimaryService {
        protected override Map<Id, String> getQualifyingAccountIds(Set<Id> accountIds) {
            return new Map<Id, String>();
        }

        protected override List<ObjectTerritory2Association> getAssociations(Set<Id> accountIds) {
            return new List<ObjectTerritory2Association>();
        }
    }
}