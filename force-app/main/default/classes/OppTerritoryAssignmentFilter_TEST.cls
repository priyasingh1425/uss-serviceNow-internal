/**
 * @description  Test class for OppTerritoryAssignmentFilter.
 *
 *               ETM objects (Territory2, ObjectTerritory2Association) cannot be
 *               created in unit tests without an already-active Territory2Model,
 *               which cannot be activated programmatically. To work around this,
 *               a MockFilter subclass overrides getAssociations() to return
 *               in-memory stub records, isolating all logic tests from live
 *               ETM configuration in the org.
 *
 *               buildAccountTerritoryMap() is tested directly as a public static
 *               method since it owns the core bucketing and override logic.
 *
 * @author       Seth Sheppard
 * @since        2026-02-18
 */
@isTest
private class OppTerritoryAssignmentFilter_TEST {

    // ---------------------------------------------------------------------------
    // Fake Territory2 Ids (0M6 key prefix) -- used only in map comparisons;
    // no DML is performed against Territory2.
    // ---------------------------------------------------------------------------
    private static final Id TERRITORY_A = '0M6000000000001AAA';
    private static final Id TERRITORY_B = '0M6000000000002AAA';
    private static final Id TERRITORY_C = '0M6000000000003AAA';

    // ---------------------------------------------------------------------------
    // Inner stub -- overrides the ETM query with caller-supplied mock records
    // ---------------------------------------------------------------------------
    private class MockFilter extends OppTerritoryAssignmentFilter {
        private List<ObjectTerritory2Association> mockData;

        MockFilter(List<ObjectTerritory2Association> mockData) {
            this.mockData = mockData;
        }

        protected override List<ObjectTerritory2Association> getAssociations(Set<Id> accountIds) {
            return mockData;
        }
    }

    // ---------------------------------------------------------------------------
    // Helper: first active Opportunity stage -- avoids hardcoded stage names
    // ---------------------------------------------------------------------------
    private static String getActiveStage() {
        return [
            SELECT MasterLabel FROM OpportunityStage
            WHERE IsActive = true
            ORDER BY SortOrder ASC
            LIMIT 1
        ].MasterLabel;
    }

    // ---------------------------------------------------------------------------
    // Helper: build a minimal ObjectTerritory2Association in memory (no DML)
    // ---------------------------------------------------------------------------
    private static ObjectTerritory2Association makeAssoc(
        Id accountId,
        Id territory2Id,
        String cause
    ) {
        return new ObjectTerritory2Association(
            ObjectId         = accountId,
            Territory2Id     = territory2Id,
            AssociationCause = cause
        );
    }

    // ---------------------------------------------------------------------------
    // Test data setup
    // ---------------------------------------------------------------------------
    @testSetup
    static void setup() {
        Id customerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeId();

        Account acc = new Account(
            Name         = 'Test Account',
            Type         = 'Customer',
            RecordTypeId = customerRtId
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name                           = 'Test Opportunity',
            AccountId                      = acc.Id,
            StageName                      = getActiveStage(),
            CloseDate                      = Date.today().addDays(30),
            Validation_Bypass_Date_Time__c = Datetime.now()
        );
        insert opp;
    }

    // ---------------------------------------------------------------------------
    // getOpportunityTerritory2Assignments -- guard clauses
    // ---------------------------------------------------------------------------

    @isTest
    static void testNullInput_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Id> result = new OppTerritoryAssignmentFilter()
            .getOpportunityTerritory2Assignments(null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Null input should return empty map');
    }

    @isTest
    static void testEmptyInput_returnsEmptyMap() {
        Test.startTest();
        Map<Id, Id> result = new OppTerritoryAssignmentFilter()
            .getOpportunityTerritory2Assignments(new List<Id>());
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Empty input should return empty map');
    }

    @isTest
    static void testNoTerritoryAssociations_oppExcludedFromResult() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        MockFilter filter = new MockFilter(new List<ObjectTerritory2Association>());

        Test.startTest();
        Map<Id, Id> result = filter.getOpportunityTerritory2Assignments(
            new List<Id>{ opp.Id }
        );
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Opp with no territory assignments should be excluded');
    }

    // ---------------------------------------------------------------------------
    // getOpportunityTerritory2Assignments -- happy path
    // ---------------------------------------------------------------------------

    @isTest
    static void testRuleAssignment_mapsCorrectly() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        List<ObjectTerritory2Association> mock = new List<ObjectTerritory2Association>{
            makeAssoc(opp.AccountId, TERRITORY_A, 'Territory2')
        };

        Test.startTest();
        Map<Id, Id> result = new MockFilter(mock)
            .getOpportunityTerritory2Assignments(new List<Id>{ opp.Id });
        Test.stopTest();

        Assert.areEqual(TERRITORY_A, result.get(opp.Id), 'Rule-assigned territory should be returned');
    }

    @isTest
    static void testManualOverridesRule() {
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        // Both associations for same account -- manual should win
        List<ObjectTerritory2Association> mock = new List<ObjectTerritory2Association>{
            makeAssoc(opp.AccountId, TERRITORY_A, 'Territory2'),
            makeAssoc(opp.AccountId, TERRITORY_B, 'Manual')
        };

        Test.startTest();
        Map<Id, Id> result = new MockFilter(mock)
            .getOpportunityTerritory2Assignments(new List<Id>{ opp.Id });
        Test.stopTest();

        Assert.areEqual(TERRITORY_B, result.get(opp.Id), 'Manual override should win over rule-assigned');
    }

    @isTest
    static void testMultipleOpportunitiesSameAccount_allGetSameTerritory() {
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Opportunity opp2 = new Opportunity(
            Name                           = 'Second Opp',
            AccountId                      = acc.Id,
            StageName                      = getActiveStage(),
            CloseDate                      = Date.today().addDays(30),
            Validation_Bypass_Date_Time__c = Datetime.now()
        );
        insert opp2;

        List<Opportunity> opps = [SELECT Id FROM Opportunity];
        List<ObjectTerritory2Association> mock = new List<ObjectTerritory2Association>{
            makeAssoc(acc.Id, TERRITORY_A, 'Territory2')
        };

        Test.startTest();
        Map<Id, Id> result = new MockFilter(mock)
            .getOpportunityTerritory2Assignments(new List<Id>{ opps[0].Id, opps[1].Id });
        Test.stopTest();

        for (Opportunity opp : opps) {
            Assert.areEqual(TERRITORY_A, result.get(opp.Id),
                'All opps on same account should receive the same territory');
        }
    }

    // ---------------------------------------------------------------------------
    // buildAccountTerritoryMap -- core bucketing logic, tested directly
    // ---------------------------------------------------------------------------

    @isTest
    static void testBuildMap_singleRule() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<ObjectTerritory2Association> assocs = new List<ObjectTerritory2Association>{
            makeAssoc(accountId, TERRITORY_A, 'Territory2')
        };

        Map<Id, Id> result = OppTerritoryAssignmentFilter.buildAccountTerritoryMap(assocs);

        Assert.areEqual(TERRITORY_A, result.get(accountId));
    }

    @isTest
    static void testBuildMap_manualWinsOverRule() {
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<ObjectTerritory2Association> assocs = new List<ObjectTerritory2Association>{
            makeAssoc(accountId, TERRITORY_A, 'Territory2'),
            makeAssoc(accountId, TERRITORY_B, 'Manual')
        };

        Map<Id, Id> result = OppTerritoryAssignmentFilter.buildAccountTerritoryMap(assocs);

        Assert.areEqual(TERRITORY_B, result.get(accountId), 'Manual should override rule');
    }

    @isTest
    static void testBuildMap_priorityOrdering_firstRuleWins() {
        // Mock returns records in priority order (as real ORDER BY would).
        // First rule-assigned association per account should win.
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        List<ObjectTerritory2Association> assocs = new List<ObjectTerritory2Association>{
            makeAssoc(accountId, TERRITORY_A, 'Territory2'), // higher priority (first)
            makeAssoc(accountId, TERRITORY_B, 'Territory2')  // lower priority (second)
        };

        Map<Id, Id> result = OppTerritoryAssignmentFilter.buildAccountTerritoryMap(assocs);

        Assert.areEqual(TERRITORY_A, result.get(accountId),
            'First (highest-priority) rule association should win');
    }

    @isTest
    static void testBuildMap_multipleAccounts_independentResults() {
        Id customerRtId = Schema.SObjectType.Account
            .getRecordTypeInfosByDeveloperName()
            .get('Customer')
            .getRecordTypeId();

        List<Account> accounts = new List<Account>{
            new Account(Name = 'Acct Alpha', Type = 'Customer', RecordTypeId = customerRtId),
            new Account(Name = 'Acct Beta',  Type = 'Customer', RecordTypeId = customerRtId)
        };
        insert accounts;

        List<ObjectTerritory2Association> assocs = new List<ObjectTerritory2Association>{
            makeAssoc(accounts[0].Id, TERRITORY_A, 'Territory2'),
            makeAssoc(accounts[1].Id, TERRITORY_B, 'Manual')
        };

        Map<Id, Id> result = OppTerritoryAssignmentFilter.buildAccountTerritoryMap(assocs);

        Assert.areEqual(TERRITORY_A, result.get(accounts[0].Id));
        Assert.areEqual(TERRITORY_B, result.get(accounts[1].Id));
    }

    @isTest
    static void testBuildMap_empty_returnsEmptyMap() {
        Map<Id, Id> result = OppTerritoryAssignmentFilter.buildAccountTerritoryMap(
            new List<ObjectTerritory2Association>()
        );

        Assert.isTrue(result.isEmpty(), 'Empty associations should yield empty map');
    }
}