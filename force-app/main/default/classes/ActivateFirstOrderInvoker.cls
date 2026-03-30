public class ActivateFirstOrderInvoker {

   
        @InvocableVariable(required=true)
        public Id quoteId;
    

    @InvocableMethod(label='Activate First Order quauable' 
                     description='Calls ActivateFirstOrderQueueable for given Quote Id')
    public static void invokeQueueable(List<String> quoteId) {

       

            
                System.enqueueJob(
                    new ActivateFirstOrderQueueable(quoteId[0])
                );
            
       
    }
}