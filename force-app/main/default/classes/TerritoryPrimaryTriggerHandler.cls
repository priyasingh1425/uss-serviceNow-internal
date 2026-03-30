/**
 * @description  Handler class for ObjectTerritory2Association events.
 *               Collects Account IDs from a list of association records and
 *               delegates to TerritoryPrimaryService to re-stamp Territory_Primary__c.
 *
 *               ObjectTerritory2Association.ObjectId can reference any SObject
 *               (Account, Contact, etc.). This handler filters to Accounts only
 *               before passing IDs to the service.
 *
 *               NOTE: Salesforce ETM does not allow Apex triggers on
 *               ObjectTerritory2Association. This class is retained as a reusable
 *               helper (e.g., called from custom Platform Events or future trigger
 *               support). Territory stamping is currently driven entirely by
 *               TerritoryPrimaryBatch via the nightly TerritoryPrimaryScheduler.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
public class TerritoryPrimaryTriggerHandler {

    private static final Schema.SObjectType ACCOUNT_TYPE = Account.SObjectType;

    /**
     * @description  Handles after-insert events. Fires when territory
     *               assignments are added to accounts.
     */
    public static void handleAfterInsert(List<ObjectTerritory2Association> newRecords) {
        TerritoryPrimaryService.stampTerritoryPrimary(collectAccountIds(newRecords));
    }

    /**
     * @description  Handles after-delete events. Fires when territory
     *               assignments are removed from accounts.
     */
    public static void handleAfterDelete(List<ObjectTerritory2Association> oldRecords) {
        TerritoryPrimaryService.stampTerritoryPrimary(collectAccountIds(oldRecords));
    }

    /**
     * @description  Extracts Account IDs from a list of associations,
     *               skipping any records whose ObjectId references a
     *               non-Account SObject type.
     */
    @TestVisible
    private static Set<Id> collectAccountIds(List<ObjectTerritory2Association> records) {
        Set<Id> accountIds = new Set<Id>();
        for (ObjectTerritory2Association assoc : records) {
            if (assoc.ObjectId != null
                    && assoc.ObjectId.getSObjectType() == ACCOUNT_TYPE) {
                accountIds.add(assoc.ObjectId);
            }
        }
        return accountIds;
    }
}