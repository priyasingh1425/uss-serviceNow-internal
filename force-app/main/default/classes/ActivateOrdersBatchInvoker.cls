public class ActivateOrdersBatchInvoker {

    @InvocableMethod(label='Activate Orders Batch'
                     description='Calls ActivateOrdersBatch for given Quote Id')
    public static void runBatch(List<String> quoteId) {



                Database.executeBatch(
                    new ActivateOrdersBatch(quoteId[0], 0),
                    1   // scope size
                );
            
        
    }
}