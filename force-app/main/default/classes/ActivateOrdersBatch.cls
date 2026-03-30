global class ActivateOrdersBatch implements Database.Batchable<SObject>, Database.Stateful {

    global String quoteId;
    global Integer retryCount;
    global static final Integer MAX_RETRY = 3;

    // Constructor
    global ActivateOrdersBatch(String qId, Integer retry) {
        this.quoteId = qId;
        this.retryCount = (retry == null) ? 0 : retry;
    }

    // Start Method
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Status, SBQQ__Contracted__c
            FROM Order
            WHERE SBQQ__Quote__c = :quoteId
            AND SBQQ__Contracted__c = false
        ]);
    }

    // Execute Method (scope = 1)
    global void execute(Database.BatchableContext bc, List<Order> scope) {

        for (Order o : scope) {
            if (o.Status != 'Activated') {
                o.Status = 'Activated';
            }
        }

        if (!scope.isEmpty()) {
            update scope;
        }
    }

    // ✅ Updated Finish Method
    global void finish(Database.BatchableContext bc) {

     
    }
}