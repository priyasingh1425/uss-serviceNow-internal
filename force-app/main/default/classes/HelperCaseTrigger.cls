public class HelperCaseTrigger {

    public void checkForAssetBaseID(List<Case> triggerNew, Map<Id, Case> triggerNewMap) {
        for (Case c : triggerNew) {
            if (!((c.AssetBaseID__c == null || String.isBlank(c.AssetBaseID__c) || String.isEmpty(c.AssetBaseID__c)))) {
                CpCaseTriggeredUpdates.attachAsset(c);
            }
        }
    }

    public void emailToCaseChanges(List<Case> triggerNew, Map<Id, Case> triggerNewMap) {
        Id rt = [
            SELECT Id
            FROM RecordType
            WHERE SObjectType = 'Case'
            AND Name = 'External Customer Support'
            LIMIT 1
        ].Id;

        Set<Case> uniques = new Set<Case>(triggerNew);
        List<Case> uniqueTrigger = new List<Case>(uniques);

        for (Case c : triggerNew) {
            if (
                (c.Triggering_Flow__c != 'Incoming Email Flow') &&
                String.isNotBlank(c.SuppliedEmail) &&
                (
                    (c.Origin == 'Email - CMC') ||
                    ((c.Origin == 'Email - TOC') && c.RecordTypeId == rt)
                )
            ) {
                CaseChangesForEmailToCase.silentlyFailIfSameSubject(c);
            }
        }
    }

    public void entitlementFlows(List<Case> triggerNew, Map<Id, Case> triggerNewMap) {
        for (Case c : triggerNew) {
            // intentionally blank for now
        }
    }

    /**
     * Stamps the source Case Id on cloned Cases.
     * Requires Case.Cloned_From_Case__c (Lookup to Case).
     *
     * IMPORTANT:
     * - Call this from Trigger BEFORE INSERT (recommended).
     * - This avoids needing an extra DML update and avoids getCloneSourceId() being null in after insert.
     *
     * Example trigger usage:
     * if (Trigger.isBefore && Trigger.isInsert) {
     *     new HelperCaseTrigger().stampCloneSource(Trigger.new);
     * }
     */
    public void stampCloneSource(List<Case> triggerNew) {
        for (Case c : triggerNew) {
            // Do not overwrite if already stamped
            if (c.Cloned_From_Case__c != null) continue;

            // Only stamp when created via Clone
            if (!c.isClone()) continue;

            Id sourceId = c.getCloneSourceId();
            if (sourceId == null) continue;

            c.Cloned_From_Case__c = sourceId;
        }
    }

    public void validateRequiredFields(List<Case> triggerNew, Map<Id, Case> triggerNewMap) {
        Id integrationAccountId = CityIntegrationConstants.ACCOUNT_ID;
        if (integrationAccountId == null) {
            return;
        }

        for (Case c : triggerNew) {
            if (c.RecordTypeId == externalCustomerSupportRtId && c.AccountId == integrationAccountId) {
                if (String.isBlank(c.Subject)) {
                    c.addError('Subject is required for City of Minneapolis cases.');
                }
                if (String.isBlank(c.Description)) {
                    c.addError('Description is required for City of Minneapolis cases.');
                }
            }
        }
    }

     private static Id externalCustomerSupportRtId {
        get {
            if (externalCustomerSupportRtId == null) {
                externalCustomerSupportRtId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CityIntegrationConstants.RT_EXTERNAL_CUSTOMER_SUPPORT).getRecordTypeId();
            }
            return externalCustomerSupportRtId;
        }
        set;
    }
}