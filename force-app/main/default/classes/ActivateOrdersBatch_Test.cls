@isTest
private class ActivateOrdersBatch_Test {

    @testSetup
    static void setup() {
        Account a = new Account(Name = 'Test Account');
        insert a;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp',
            AccountId = a.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c(
            SBQQ__Account__c = a.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert quote;

        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;

        Id stdPricebookId = Test.getStandardPricebookId();

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = stdPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;

        Order o = new Order(
            AccountId = a.Id,
            SBQQ__Quote__c = quote.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            SBQQ__Contracted__c = false,
            Pricebook2Id = stdPricebookId
        );
        insert o;

        insert new OrderItem(
            OrderId = o.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
    }

    @isTest
    static void testBatch_activatesOrder() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
            Database.executeBatch(new ActivateOrdersBatch(quote.Id, 0), 200);
        Test.stopTest();

        Order o = [SELECT Id, Status FROM Order WHERE SBQQ__Quote__c = :quote.Id LIMIT 1];
        Assert.areEqual('Activated', o.Status, 'Order should be Activated');
    }

    @isTest
    static void testBatch_nullRetryDefaultsToZero() {
        ActivateOrdersBatch batch = new ActivateOrdersBatch('fakeId', null);
        Assert.areEqual(0, batch.retryCount, 'Null retry should default to 0');
    }

    @isTest
    static void testBatch_noMatchingOrders() {
        // Create a second quote with no orders linked to it
        Account a = [SELECT Id FROM Account LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        SBQQ__Quote__c emptyQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = a.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = false
        );
        insert emptyQuote;

        Test.startTest();
            Database.executeBatch(new ActivateOrdersBatch(emptyQuote.Id, 0), 200);
        Test.stopTest();

        // No orders exist for this quote — batch completes without errors
        Assert.areEqual(0, [SELECT COUNT() FROM Order WHERE SBQQ__Quote__c = :emptyQuote.Id], 'No orders should exist for the empty quote');
    }
}