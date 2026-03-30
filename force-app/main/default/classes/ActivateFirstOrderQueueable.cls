public class ActivateFirstOrderQueueable implements Queueable {

    private String quoteId;

    public ActivateFirstOrderQueueable(String qId) {
        this.quoteId = qId;
    }

    public void execute(QueueableContext context) {

        Order firstOrder = [
            SELECT Id, Status, SBQQ__Contracted__c
            FROM Order
            WHERE SBQQ__Quote__c = :quoteId
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        
        if (firstOrder.Status != 'Activated') {
            firstOrder.Status = 'Activated';
            update firstOrder;
        }

        
        
    }
}