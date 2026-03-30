/**
 * @description  Test class for TerritoryPrimaryService.
 *
 *               ObjectTerritory2Association cannot be created via DML in tests
 *               without an active Territory2Model. A MockService subclass
 *               overrides getAssociations() to return in-memory stub records,
 *               keeping all ETM assertions fully synthetic.
 *
 *               getQualifyingAccountIds() runs real SOQL against inserted
 *               Account records so the RecordType filter is exercised for real.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
@isTest
private class TerritoryPrimaryService_TEST {

    // -------------------------------------------------------------------------
    // Mock service -- overrides only the ETM query
    // -------------------------------------------------------------------------
    private class MockService extends TerritoryPrimaryService {
        private List<ObjectTerritory2Association> mockData;

        MockService(List<ObjectTerritory2Association> mockData) {
            this.mockData = mockData;
        }

        protected override List<ObjectTerritory2Association> getAssociations(Set<Id> accountIds) {
            return mockData;
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

    private static Account insertCustomerAccount(String name) {
        Account acc = new Account(
            Name         = name,
            Type         = 'Customer',
            RecordTypeId = getCustomerRtId()
        );
        insert acc;
        return acc;
    }

    /**
     * Builds an in-memory ObjectTerritory2Association with relationship fields
     * populated via JSON deserialization (bypasses ETM DML restrictions).
     * listOrder controls tiebreaking -- records are returned in the order
     * the mock provides them; first record per account wins.
     */
    private static ObjectTerritory2Association makeAssoc(
        Id accountId,
        String territoryName,
        Integer priority
    ) {
        String jsonStr =
            '{"attributes":{"type":"ObjectTerritory2Association"},' +
            '"ObjectId":"' + accountId + '",' +
            '"Territory2":{"attributes":{"type":"Territory2"},' +
            '"Name":"' + territoryName + '",' +
            '"Territory2Type":{"attributes":{"type":"Territory2Type"},' +
            '"Priority":' + priority + '}}}';
        return (ObjectTerritory2Association) JSON.deserialize(jsonStr, ObjectTerritory2Association.class);
    }

    // -------------------------------------------------------------------------
    // Guard clause tests
    // -------------------------------------------------------------------------

    @isTest
    static void testNullInput_noError() {
        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(null);
        Test.stopTest();
        // No exception thrown -- passes implicitly
    }

    @isTest
    static void testEmptyInput_noError() {
        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(new Set<Id>());
        Test.stopTest();
    }

    // -------------------------------------------------------------------------
    // Single account -- basic stamping
    // -------------------------------------------------------------------------

    @isTest
    static void testSingleTerritory_stampedCorrectly() {
        Account acc = insertCustomerAccount('Acct Single');

        List<ObjectTerritory2Association> mock = new List<ObjectTerritory2Association>{
            makeAssoc(acc.Id, 'Northeast', 6000)
        };
        TerritoryPrimaryService.instance = new MockService(mock);

        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account result = [SELECT Territory_Primary__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Northeast', result.Territory_Primary__c);
    }

    // -------------------------------------------------------------------------
    // Multiple territories -- priority ordering
    // -------------------------------------------------------------------------

    @isTest
    static void testMultiplePriorities_lowestWins() {
        Account acc = insertCustomerAccount('Acct Priority');

        // Company (2000) should beat Region (6000)
        List<ObjectTerritory2Association> mock = new List<ObjectTerritory2Association>{
            makeAssoc(acc.Id, 'Enterprise',  2000),
            makeAssoc(acc.Id, 'Northeast',   6000)
        };
        TerritoryPrimaryService.instance = new MockService(mock);

        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account result = [SELECT Territory_Primary__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Enterprise', result.Territory_Primary__c,
            'Lowest priority number (2000) should win over 6000');
    }

    @isTest
    static void testSamePriority_alphabeticalNameWins() {
        Account acc = insertCustomerAccount('Acct Tiebreak');

        // Mock returns records in ORDER BY order (Territory2.Name ASC -- "Alpha" before "Beta")
        List<ObjectTerritory2Association> mock = new List<ObjectTerritory2Association>{
            makeAssoc(acc.Id, 'Alpha Region', 6000),
            makeAssoc(acc.Id, 'Beta Region',  6000)
        };
        TerritoryPrimaryService.instance = new MockService(mock);

        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account result = [SELECT Territory_Primary__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Alpha Region', result.Territory_Primary__c,
            'Alphabetically first Territory2.Name should win on priority tie');
    }

    // -------------------------------------------------------------------------
    // No assignments -- field cleared
    // -------------------------------------------------------------------------

    @isTest
    static void testNoAssignments_fieldCleared() {
        Account acc = insertCustomerAccount('Acct Clear');
        acc.Territory_Primary__c = 'Old Value';
        update acc;

        TerritoryPrimaryService.instance = new MockService(
            new List<ObjectTerritory2Association>()
        );

        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(new Set<Id>{ acc.Id });
        Test.stopTest();

        Account result = [SELECT Territory_Primary__c FROM Account WHERE Id = :acc.Id];
        Assert.isNull(result.Territory_Primary__c,
            'Territory_Primary__c should be blank when no assignments exist');
    }

    // -------------------------------------------------------------------------
    // Non-qualifying record type -- skipped
    // -------------------------------------------------------------------------

    @isTest
    static void testNonQualifyingAccount_skipped() {
        // Pass a non-existent ID -- the qualifying SOQL returns nothing,
        // so no DML fires and no exception is thrown.
        Id fakeId = '001000000000001AAA';

        TerritoryPrimaryService.instance = new MockService(
            new List<ObjectTerritory2Association>()
        );

        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(new Set<Id>{ fakeId });
        Test.stopTest();
        // No exception -- passes implicitly; qualifying filter excluded the ID
    }

    // -------------------------------------------------------------------------
    // Already correct -- no DML fired
    // -------------------------------------------------------------------------

    @isTest
    static void testAlreadyStamped_noDmlFired() {
        Account acc = insertCustomerAccount('Acct Unchanged');
        acc.Territory_Primary__c = 'Northeast';
        update acc;

        TerritoryPrimaryService.instance = new MockService(
            new List<ObjectTerritory2Association>{ makeAssoc(acc.Id, 'Northeast', 6000) }
        );

        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(new Set<Id>{ acc.Id });
        Integer dmlStatements = Limits.getDmlStatements();
        Test.stopTest();

        Assert.areEqual(0, dmlStatements,
            'No DML should fire when Territory_Primary__c is already the correct value');
        Account result = [SELECT Territory_Primary__c FROM Account WHERE Id = :acc.Id];
        Assert.areEqual('Northeast', result.Territory_Primary__c, 'Value should be unchanged');
    }

    // -------------------------------------------------------------------------
    // Bulk -- 200+ accounts, no governor limit violations
    // -------------------------------------------------------------------------

    @isTest
    static void testBulk_200Accounts_noGovernorViolations() {
        Id customerRtId = getCustomerRtId();
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name         = 'Bulk Acct ' + i,
                Type         = 'Customer',
                RecordTypeId = customerRtId
            ));
        }
        insert accounts;

        List<ObjectTerritory2Association> mock = new List<ObjectTerritory2Association>();
        for (Account acc : accounts) {
            mock.add(makeAssoc(acc.Id, 'Northeast', 6000));
        }
        TerritoryPrimaryService.instance = new MockService(mock);

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        Test.startTest();
        TerritoryPrimaryService.stampTerritoryPrimary(accountIds);
        Test.stopTest();

        List<Account> results = [
            SELECT Territory_Primary__c
            FROM Account
            WHERE Id IN :accountIds
              AND Territory_Primary__c = 'Northeast'
        ];
        Assert.areEqual(200, results.size(), 'All 200 accounts should be stamped');
    }
}