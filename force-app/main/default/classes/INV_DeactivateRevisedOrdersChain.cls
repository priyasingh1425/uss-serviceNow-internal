public with sharing class INV_DeactivateRevisedOrdersChain {

    @InvocableMethod(
        label='Deactivate Revised Orders Chain + Related Amendment Orders'
        description='Deactivates all Orders in the Revised_Order__c chain. For each Order deactivated, also deactivates any Amendment (Type=Change) Orders whose Revised_Order__c points to that deactivated Order.'
    )
    public static void deactivateRevisedOrders(List<Id> activeOrderIds) {
        if (activeOrderIds == null || activeOrderIds.isEmpty()) {
            return;
        }

        final Integer MAX_DEPTH = 50;
        final String STATUS_INACTIVE = 'Inactive';

        Set<Id> initialTriggerIds = new Set<Id>(activeOrderIds);

        Set<Id> frontier = new Set<Id>(activeOrderIds);
        Set<Id> priorOrderIds = new Set<Id>();
        Integer depth = 0;

        while (!frontier.isEmpty() && depth < MAX_DEPTH) {
            List<Order> current = [
                SELECT Id, Revised_Order__c
                FROM Order
                WHERE Id IN :frontier
            ];

            Set<Id> nextFrontier = new Set<Id>();

            for (Order o : current) {
                if (o.Revised_Order__c == null) continue;

                Id priorId = o.Revised_Order__c;

                if (initialTriggerIds.contains(priorId)) continue;

                if (priorOrderIds.add(priorId)) {
                    nextFrontier.add(priorId);
                }
            }

            frontier = nextFrontier;
            depth++;
        }

        if (priorOrderIds.isEmpty()) {
            return;
        }

        Map<Id, Order> ordersToUpdateById = new Map<Id, Order>();

        List<Order> priorOrders = [
            SELECT Id, Status
            FROM Order
            WHERE Id IN :priorOrderIds
        ];

        Set<Id> deactivatedPriorIds = new Set<Id>();

        for (Order o : priorOrders) {
            if (o.Status == STATUS_INACTIVE) continue;

            o.Status = STATUS_INACTIVE;
            ordersToUpdateById.put(o.Id, o);
            deactivatedPriorIds.add(o.Id);
        }

        if (!deactivatedPriorIds.isEmpty()) {
            for (Order childAmend : [
                SELECT Id, Status, Type, Revised_Order__c
                FROM Order
                WHERE Type = 'Change'
                  AND Revised_Order__c IN :deactivatedPriorIds
                  AND Id NOT IN :initialTriggerIds
            ]) {
                if (childAmend.Status == STATUS_INACTIVE) continue;

                childAmend.Status = STATUS_INACTIVE;
                ordersToUpdateById.put(childAmend.Id, childAmend);
            }
        }

        if (!ordersToUpdateById.isEmpty()) {
            update ordersToUpdateById.values();
        }
    }
}