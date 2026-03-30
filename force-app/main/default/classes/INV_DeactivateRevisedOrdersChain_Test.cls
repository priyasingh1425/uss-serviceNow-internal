@IsTest
private class INV_DeactivateRevisedOrdersChain_Test {

    @IsTest
    static void testDeactivateRevisedChainAndAmendments() {

        // Account
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        /*
            Chain:
            Order C (trigger)
              -> Order B
                   -> Order A

            Amendment:
            Change Order D -> Revised_Order__c = Order B
        */

        // Oldest order
        Order orderA = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today().addDays(-30),
            Status = 'Draft'
        );
        insert orderA;

        // Middle order
        Order orderB = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today().addDays(-20),
            Status = 'Draft',
            Revised_Order__c = orderA.Id
        );
        insert orderB;

        // Trigger order
        Order orderC = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today().addDays(-10),
            Status = 'Draft',
            Revised_Order__c = orderB.Id
        );
        insert orderC;

        // Amendment (Change) order pointing to Order B
        Order changeOrder = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft',
            Type = 'Change',
            Revised_Order__c = orderB.Id
        );
        insert changeOrder;

        Test.startTest();
        INV_DeactivateRevisedOrdersChain.deactivateRevisedOrders(
            new List<Id>{ orderC.Id }
        );
        Test.stopTest();

        // Re-query results
        Map<Id, Order> results = new Map<Id, Order>([
            SELECT Id, Status
            FROM Order
            WHERE Id IN :new List<Id>{
                orderA.Id,
                orderB.Id,
                orderC.Id,
                changeOrder.Id
            }
        ]);

        // Assertions
        System.assertEquals(
            'Inactive',
            results.get(orderA.Id).Status,
            'Oldest order should be Inactive'
        );

        System.assertEquals(
            'Inactive',
            results.get(orderB.Id).Status,
            'Middle order should be Inactive'
        );

        System.assertEquals(
            'Draft',
            results.get(orderC.Id).Status,
            'Trigger order must NOT be changed'
        );

        System.assertEquals(
            'Inactive',
            results.get(changeOrder.Id).Status,
            'Amendment (Change) order should be Inactive'
        );
    }

    @IsTest
    static void testNoRevisedOrder_NoAction() {

        Account acc = new Account(Name = 'Standalone Account');
        insert acc;

        Order standalone = new Order(
            AccountId = acc.Id,
            EffectiveDate = Date.today(),
            Status = 'Draft'
        );
        insert standalone;

        Test.startTest();
        INV_DeactivateRevisedOrdersChain.deactivateRevisedOrders(
            new List<Id>{ standalone.Id }
        );
        Test.stopTest();

        standalone = [
            SELECT Status
            FROM Order
            WHERE Id = :standalone.Id
        ];

        System.assertEquals(
            'Draft',
            standalone.Status,
            'Standalone order should remain unchanged'
        );
    }
}