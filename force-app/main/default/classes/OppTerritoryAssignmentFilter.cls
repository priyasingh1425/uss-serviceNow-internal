/**
 * @description  ETM Opportunity Territory Assignment Filter
 *               Implements the TerritoryMgmt.OpportunityTerritory2AssignmentFilter
 *               interface required by Salesforce Enterprise Territory Management.
 *               Configured in Setup → Territory Settings → Opportunity Territory
 *               Assignment Filter.
 *
 *               Assignment logic (in priority order):
 *                 1. Manual (override) territory assignments on the Account win
 *                    over rule-assigned territories, regardless of Territory2Type
 *                    priority. This allows ops/admin to pin an account to a
 *                    specific territory without changing the assignment rules.
 *                 2. Within each cause group (Manual or rule-assigned), the
 *                    Territory2Type with the lowest Priority integer wins
 *                    (e.g. Priority 1 beats Priority 2).
 *                 3. If two territories share the same Territory2Type priority,
 *                    the most recently modified ObjectTerritory2Association wins.
 *                    There should not be duplicate highest-priority territories
 *                    on a single account under normal operating conditions.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
global virtual class OppTerritoryAssignmentFilter
    implements TerritoryMgmt.OpportunityTerritory2AssignmentFilter {

    /**
     * @description  Called by Salesforce ETM when opportunities are saved or
     *               when the territory assignment job runs. Returns a map of
     *               Opportunity Id → Territory2 Id. Opportunities omitted from
     *               the returned map will be unassigned from any territory.
     *
     * @param        opportunityIds  List of Opportunity Ids to evaluate
     * @return       Map<Id, Id>     Opportunity Id → Territory2 Id
     */
    global Map<Id, Id> getOpportunityTerritory2Assignments(List<Id> opportunityIds) {
        Map<Id, Id> oppToTerritoryMap = new Map<Id, Id>();

        if (opportunityIds == null || opportunityIds.isEmpty()) {
            return oppToTerritoryMap;
        }

        List<Opportunity> opps = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id IN :opportunityIds
              AND AccountId != null
        ];

        if (opps.isEmpty()) {
            return oppToTerritoryMap;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : opps) {
            accountIds.add(opp.AccountId);
        }

        // Delegate ETM query to virtual method so tests can stub without
        // requiring an active Territory2Model in the org (see _TEST class).
        List<ObjectTerritory2Association> associations = getAssociations(accountIds);
        Map<Id, Id> accountToTerritoryMap = buildAccountTerritoryMap(associations);

        for (Opportunity opp : opps) {
            Id territory2Id = accountToTerritoryMap.get(opp.AccountId);
            if (territory2Id != null) {
                oppToTerritoryMap.put(opp.Id, territory2Id);
            }
        }

        return oppToTerritoryMap;
    }

    /**
     * @description  Buckets territory associations by cause, then merges them
     *               so that manual overrides win over rule-assigned territories.
     *               Within each bucket, the first association per account wins
     *               because the records arrive pre-sorted by Territory2Type
     *               priority then last modified date (see getAssociations).
     *
     * @param        associations  Pre-sorted list of ObjectTerritory2Association
     * @return       Map<Id, Id>   Account Id → winning Territory2 Id
     */
    public static Map<Id, Id> buildAccountTerritoryMap(
        List<ObjectTerritory2Association> associations
    ) {
        Map<Id, Id> manualMap = new Map<Id, Id>();
        Map<Id, Id> ruleMap   = new Map<Id, Id>();

        for (ObjectTerritory2Association assoc : associations) {
            if (assoc.AssociationCause == 'Manual') {
                if (!manualMap.containsKey(assoc.ObjectId)) {
                    manualMap.put(assoc.ObjectId, assoc.Territory2Id);
                }
            } else {
                if (!ruleMap.containsKey(assoc.ObjectId)) {
                    ruleMap.put(assoc.ObjectId, assoc.Territory2Id);
                }
            }
        }

        // Seed with rule assignments, then let manual overrides take precedence
        Map<Id, Id> result = new Map<Id, Id>(ruleMap);
        result.putAll(manualMap);
        return result;
    }

    /**
     * @description  Queries ObjectTerritory2Association for the given accounts,
     *               ordered by Territory2Type priority then last modified date.
     *               Exposed as a virtual method so test subclasses can stub
     *               ETM data without requiring an active Territory2Model.
     *               AssociationCause values: 'Territory2' (rule) | 'Manual' (override)
     *
     * @param        accountIds  Set of Account Ids to query associations for
     * @return       List<ObjectTerritory2Association>
     */
    @TestVisible
    protected virtual List<ObjectTerritory2Association> getAssociations(Set<Id> accountIds) {
        return [
            SELECT ObjectId,
                   Territory2Id,
                   AssociationCause,
                   Territory2.Territory2Type.Priority,
                   LastModifiedDate
            FROM ObjectTerritory2Association
            WHERE ObjectId IN :accountIds
            ORDER BY Territory2.Territory2Type.Priority ASC NULLS LAST,
                     LastModifiedDate DESC
        ];
    }
}