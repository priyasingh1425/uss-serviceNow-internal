/**
 * @description  Service class for stamping Territory_Primary__c on Account.
 *               Territory_Primary__c stores the Territory2.Name of the
 *               highest-priority active ETM assignment for each account.
 *
 *               Priority resolution:
 *                 1. Territory2Type.Priority ASC  — lowest integer wins
 *                    Company (2000) > Division (4000) > Region (6000)
 *                 2. Territory2.Name ASC as tiebreaker — alphabetical
 *                    Duplicate top-priority assignments should be rare.
 *
 *               Only Prospect and Customer RecordType accounts are processed.
 *               All other record types are silently skipped.
 *               Accounts with no territory assignments have the field cleared.
 *               Accounts whose Territory_Primary__c is already correct are
 *               skipped entirely -- no DML is issued for unchanged records.
 *
 *               Architecture note: production SOQL is isolated in two virtual
 *               methods (getQualifyingAccountIds, getAssociations) so that test
 *               subclasses can stub ETM data without needing an active
 *               Territory2Model in the org.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
public virtual class TerritoryPrimaryService {

    // Swappable instance -- tests replace this with a MockService subclass
    @TestVisible
    private static TerritoryPrimaryService instance = new TerritoryPrimaryService();

    /**
     * @description  Entry point. Stamps Territory_Primary__c for the supplied
     *               Account IDs. Filters to qualifying record types, compares
     *               new vs current values, and only DMLs records that changed.
     *
     * @param        accountIds  Account IDs to evaluate. Safe to call with any
     *                           set -- non-qualifying IDs are filtered before DML.
     */
    public static void stampTerritoryPrimary(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) return;
        instance.execute(accountIds);
    }

    // -------------------------------------------------------------------------
    // Private execution pipeline
    // -------------------------------------------------------------------------

    private void execute(Set<Id> accountIds) {
        // Returns qualifying IDs mapped to their current Territory_Primary__c value
        Map<Id, String> qualifyingAccounts = getQualifyingAccountIds(accountIds);
        if (qualifyingAccounts.isEmpty()) return;

        List<ObjectTerritory2Association> assocs = getAssociations(qualifyingAccounts.keySet());

        // First record per account wins -- ORDER BY guarantees correct ranking
        Map<Id, String> newValues = new Map<Id, String>();
        for (ObjectTerritory2Association assoc : assocs) {
            if (!newValues.containsKey(assoc.ObjectId)) {
                newValues.put(assoc.ObjectId, assoc.Territory2.Name);
            }
        }

        // Only update accounts where Territory_Primary__c is actually changing.
        // newValues.get() returns null for unassigned accounts → clears the field.
        List<Account> toUpdate = new List<Account>();
        for (Id accountId : qualifyingAccounts.keySet()) {
            String newValue     = newValues.get(accountId);
            String currentValue = qualifyingAccounts.get(accountId);
            if (newValue != currentValue) {
                toUpdate.add(new Account(
                    Id                   = accountId,
                    Territory_Primary__c = newValue
                ));
            }
        }

        Integer updated = 0;
        Integer failed  = 0;
        if (!toUpdate.isEmpty()) {
            List<Database.SaveResult> results = Database.update(toUpdate, false);
            for (Database.SaveResult sr : results) {
                if (sr.isSuccess()) {
                    updated++;
                } else {
                    failed++;
                    for (Database.Error err : sr.getErrors()) {
                        System.debug(LoggingLevel.ERROR,
                            'TerritoryPrimaryService: failed to update Account ' +
                            sr.getId() + ' — ' + err.getStatusCode() + ': ' + err.getMessage()
                        );
                    }
                }
            }
        }
        System.debug(LoggingLevel.INFO,
            'TerritoryPrimaryService: chunk=' + qualifyingAccounts.size() +
            ' evaluated, ' + toUpdate.size() + ' needed update, ' +
            updated + ' succeeded, ' + failed + ' failed'
        );
    }

    // -------------------------------------------------------------------------
    // Virtual query methods -- overridden by test stubs
    // -------------------------------------------------------------------------

    /**
     * @description  Returns qualifying accounts mapped to their current
     *               Territory_Primary__c value (null if blank). Filters to
     *               Prospect and Customer RecordTypes. The current value is
     *               used in execute() for a dirty check to avoid unnecessary DML.
     */
    @TestVisible
    protected virtual Map<Id, String> getQualifyingAccountIds(Set<Id> accountIds) {
        Map<Id, String> result = new Map<Id, String>();
        for (Account acc : [
            SELECT Id, Territory_Primary__c
            FROM Account
            WHERE Id IN :accountIds
              AND RecordType.DeveloperName IN ('Prospect', 'Customer')
        ]) {
            result.put(acc.Id, acc.Territory_Primary__c);
        }
        return result;
    }

    /**
     * @description  Queries ObjectTerritory2Association for the supplied
     *               accounts, ordered by Territory2Type priority then
     *               Territory2.Name ascending. First record per account wins.
     */
    @TestVisible
    protected virtual List<ObjectTerritory2Association> getAssociations(Set<Id> accountIds) {
        return [
            SELECT ObjectId,
                   Territory2.Name,
                   Territory2.Territory2Type.Priority
            FROM ObjectTerritory2Association
            WHERE ObjectId IN :accountIds
            ORDER BY Territory2.Territory2Type.Priority ASC NULLS LAST,
                     Territory2.Name ASC
        ];
    }
}