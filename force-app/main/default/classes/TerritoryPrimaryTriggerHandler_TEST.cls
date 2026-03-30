/**
 * @description  Test class for TerritoryPrimaryTriggerHandler.
 *
 *               Salesforce ETM does not allow Apex triggers on
 *               ObjectTerritory2Association, so the handler methods are called
 *               directly. ObjectTerritory2Association records are built
 *               in-memory via JSON deserialization to avoid ETM DML restrictions.
 *
 *               TerritoryPrimaryService.instance is swapped for a MockService
 *               so that ETM SOQL in the service does not execute.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
@isTest
private class TerritoryPrimaryTriggerHandler_TEST {

    // -------------------------------------------------------------------------
    // Mock service -- suppresses ETM SOQL and captures which IDs were stamped
    // -------------------------------------------------------------------------
    private class MockService extends TerritoryPrimaryService {
        public Set<Id> stampedIds = new Set<Id>();

        protected override Map<Id, String> getQualifyingAccountIds(Set<Id> accountIds) {
            stampedIds.addAll(accountIds); // capture for assertion
            return new Map<Id, String>();  // empty → execute() exits before DML on fake IDs
        }

        protected override List<ObjectTerritory2Association> getAssociations(Set<Id> accountIds) {
            return new List<ObjectTerritory2Association>(); // no associations needed
        }
    }

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------

    private static final String ACCOUNT_PREFIX =
        Account.SObjectType.getDescribe().getKeyPrefix();

    private static final String CONTACT_PREFIX =
        Contact.SObjectType.getDescribe().getKeyPrefix();

    private static Id fakeAccountId(Integer n) {
        return (Id)(ACCOUNT_PREFIX + String.valueOf(n).leftPad(12, '0'));
    }

    private static Id fakeContactId(Integer n) {
        return (Id)(CONTACT_PREFIX + String.valueOf(n).leftPad(12, '0'));
    }

    private static ObjectTerritory2Association makeAssoc(Id objectId) {
        return (ObjectTerritory2Association) JSON.deserialize(
            '{"attributes":{"type":"ObjectTerritory2Association"},"ObjectId":"' + objectId + '"}',
            ObjectTerritory2Association.class
        );
    }

    // -------------------------------------------------------------------------
    // collectAccountIds -- tested directly via @TestVisible
    // -------------------------------------------------------------------------

    @isTest
    static void testCollectAccountIds_accountsIncluded() {
        Id accId1 = fakeAccountId(1);
        Id accId2 = fakeAccountId(2);

        List<ObjectTerritory2Association> assocs = new List<ObjectTerritory2Association>{
            makeAssoc(accId1),
            makeAssoc(accId2)
        };

        Set<Id> result = TerritoryPrimaryTriggerHandler.collectAccountIds(assocs);

        Assert.areEqual(2, result.size());
        Assert.isTrue(result.contains(accId1));
        Assert.isTrue(result.contains(accId2));
    }

    @isTest
    static void testCollectAccountIds_nonAccountsExcluded() {
        Id accId     = fakeAccountId(1);
        Id contactId = fakeContactId(1);

        List<ObjectTerritory2Association> assocs = new List<ObjectTerritory2Association>{
            makeAssoc(accId),
            makeAssoc(contactId)
        };

        Set<Id> result = TerritoryPrimaryTriggerHandler.collectAccountIds(assocs);

        Assert.areEqual(1, result.size(), 'Contact ID should be filtered out');
        Assert.isTrue(result.contains(accId));
    }

    @isTest
    static void testCollectAccountIds_emptyList_returnsEmptySet() {
        Set<Id> result = TerritoryPrimaryTriggerHandler.collectAccountIds(
            new List<ObjectTerritory2Association>()
        );
        Assert.isTrue(result.isEmpty());
    }

    // -------------------------------------------------------------------------
    // handleAfterInsert / handleAfterDelete -- verify delegation to service
    // -------------------------------------------------------------------------

    @isTest
    static void testHandleAfterInsert_callsService() {
        Id accId = fakeAccountId(1);
        MockService mock = new MockService();
        TerritoryPrimaryService.instance = mock;

        Test.startTest();
        TerritoryPrimaryTriggerHandler.handleAfterInsert(
            new List<ObjectTerritory2Association>{ makeAssoc(accId) }
        );
        Test.stopTest();

        Assert.isTrue(mock.stampedIds.contains(accId),
            'handleAfterInsert should pass Account ID to the service');
    }

    @isTest
    static void testHandleAfterDelete_callsService() {
        Id accId = fakeAccountId(2);
        MockService mock = new MockService();
        TerritoryPrimaryService.instance = mock;

        Test.startTest();
        TerritoryPrimaryTriggerHandler.handleAfterDelete(
            new List<ObjectTerritory2Association>{ makeAssoc(accId) }
        );
        Test.stopTest();

        Assert.isTrue(mock.stampedIds.contains(accId),
            'handleAfterDelete should pass Account ID to the service');
    }

    @isTest
    static void testHandleAfterInsert_nonAccount_notPassedToService() {
        Id contactId = fakeContactId(1);
        MockService mock = new MockService();
        TerritoryPrimaryService.instance = mock;

        Test.startTest();
        TerritoryPrimaryTriggerHandler.handleAfterInsert(
            new List<ObjectTerritory2Association>{ makeAssoc(contactId) }
        );
        Test.stopTest();

        Assert.isTrue(mock.stampedIds.isEmpty(),
            'Non-Account IDs should not be passed to the service');
    }
}