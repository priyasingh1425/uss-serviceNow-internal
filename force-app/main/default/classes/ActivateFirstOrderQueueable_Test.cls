@isTest
private class ActivateFirstOrderQueueable_Test {

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
            Pricebook2Id = stdPricebookId
        );
        insert o;

        OrderItem oi = new OrderItem(
            OrderId = o.Id,
            PricebookEntryId = pbe.Id,
            Quantity = 1,
            UnitPrice = 100
        );
        insert oi;
    }

    @isTest
    static void testExecute_activatesDraftOrder() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];

        Test.startTest();
            System.enqueueJob(new ActivateFirstOrderQueueable(quote.Id));
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Status FROM Order WHERE SBQQ__Quote__c = :quote.Id LIMIT 1];
        Assert.areEqual('Activated', updatedOrder.Status, 'Order status should be Activated');
    }

    @isTest
    static void testExecute_alreadyActivatedOrder() {
        SBQQ__Quote__c quote = [SELECT Id FROM SBQQ__Quote__c LIMIT 1];
        Order o = [SELECT Id FROM Order WHERE SBQQ__Quote__c = :quote.Id LIMIT 1];
        o.Status = 'Activated';
        update o;

        Test.startTest();
            System.enqueueJob(new ActivateFirstOrderQueueable(quote.Id));
        Test.stopTest();

        Order updatedOrder = [SELECT Id, Status FROM Order WHERE SBQQ__Quote__c = :quote.Id LIMIT 1];
        Assert.areEqual('Activated', updatedOrder.Status, 'Order should remain Activated with no errors');
    }
}