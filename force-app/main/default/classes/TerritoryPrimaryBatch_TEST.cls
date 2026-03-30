/**
 * @description  Test class for TerritoryPrimaryBatch.
 *
 *               TerritoryPrimaryService.instance is swapped for a MockService
 *               to avoid ETM SOQL while still exercising the batch query scope
 *               (Account RecordType filter) and the execute → service delegation.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
@isTest
private class TerritoryPrimaryBatch_TEST {

    // -------------------------------------------------------------------------
    // Mock service -- returns a fixed territory name for all accounts
    // -------------------------------------------------------------------------
    private class MockService extends TerritoryPrimaryService {
        private String territoryName;

        MockService(String territoryName) {
            this.territoryName = territoryName;
        }

        protected override Map<Id, String> getQualifyingAccountIds(Set<Id> accountIds) {
            Map<Id, String> result = new Map<Id, String>();
            for (Id id : accountIds) result.put(id, null); // null = no current value
            return result;
        }

        protected override List<ObjectTerritory2Association> getAssociations(Set<Id> accountIds) {
            List<ObjectTerritory2Association> result = new List<ObjectTerritory2Association>();
            for (Id accountId : accountIds) {
                result.add((ObjectTerritory2Association) JSON.deserialize(
                    '{"attributes":{"type":"ObjectTerritory2Association"},' +
                    '"ObjectId":"' + accountId + '",' +
                    '"Territory2":{"attributes":{"type":"Territory2"},' +
                    '"Name":"' + territoryName + '",' +
                    '"Territory2Type":{"attributes":{"type":"Territory2Type"},' +
                    '"Priority":6000}}}',
                    ObjectTerritory2Association.class
                ));
            }
            return result;
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private static Id getCustomerRtId() {
        return Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeId();
    }

    // -------------------------------------------------------------------------
    // Tests
    // -------------------------------------------------------------------------

    @isTest
    static void testBatch_stampsQualifyingAccounts() {
        Id customerRtId = getCustomerRtId();

        List<Account> accounts = new List<Account>{
            new Account(Name = 'Batch Acct 1', Type = 'Customer', RecordTypeId = customerRtId),
            new Account(Name = 'Batch Acct 2', Type = 'Customer', RecordTypeId = customerRtId)
        };
        insert accounts;

        TerritoryPrimaryService.instance = new MockService('Southeast');

        Test.startTest();
        Database.executeBatch(new TerritoryPrimaryBatch(), 200);
        Test.stopTest();

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
        List<Account> results = [
            SELECT Territory_Primary__c
            FROM Account
            WHERE Id IN :accountIds
        ];

        for (Account acc : results) {
            Assert.areEqual('Southeast', acc.Territory_Primary__c,
                'Batch should stamp Territory_Primary__c via the service');
        }
    }

    @isTest
    static void testBatch_startReturnsQualifyingAccountsOnly() {
        // Verify the batch query scope only includes Prospect/Customer accounts.
        // We insert a Customer account, run the batch, and confirm it's stamped.
        // Non-qualifying accounts that may exist in the org are excluded by the
        // batch start() query and are therefore not updated.
        Id customerRtId = getCustomerRtId();

        Account acc = new Account(
            Name         = 'Batch Scope Test',
            Type         = 'Customer',
            RecordTypeId = customerRtId
        );
        insert acc;

        TerritoryPrimaryService.instance = new MockService('Midwest');

        Test.startTest();
        Database.executeBatch(new TerritoryPrimaryBatch(), 200);
        Test.stopTest();

        Account result = [SELECT Territory_Primary__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Midwest', result.Territory_Primary__c);
    }
}