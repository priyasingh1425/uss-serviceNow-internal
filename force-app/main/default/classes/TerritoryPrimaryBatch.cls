/**
 * @description  Batchable class to re-stamp Territory_Primary__c across all
 *               Prospect and Customer accounts.
 *
 *               Use after any bulk territory operation that does not fire
 *               triggers -- model activation, large territory rule runs,
 *               or bulk account imports.
 *
 *               Execute via Apex:
 *                   Database.executeBatch(new TerritoryPrimaryBatch(), 2000);
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
public class TerritoryPrimaryBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            WHERE RecordType.DeveloperName IN ('Prospect', 'Customer')
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        TerritoryPrimaryService.stampTerritoryPrimary(
            new Map<Id, Account>(scope).keySet()
        );
    }

    public void finish(Database.BatchableContext bc) {
        // Reserved for notifications or chained jobs
    }
}