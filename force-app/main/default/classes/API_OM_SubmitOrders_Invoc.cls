public with sharing class API_OM_SubmitOrders_Invoc {
    @InvocableMethod(label='Submit Orders to OM' callout=true category='OM Integration')
    public static List<OMSubmitResult> submitOrdersInvoc(List<OMSubmitRequest> requests){
        List<OMSubmitResult> results = new List<OMSubmitResult>();

        for(OMSubmitRequest request:requests){
            results.add(submitOrder(
                request.quoteId,
                request.contacts,
                request.fileIds));
        }

        return results;
    }

    private static OMSubmitResult submitOrder(Id quoteId, List<API_OM_SubmitOrdersContact_Model> contacts, List<Id> fileIds){
        OMSubmitResult result = new OMSubmitResult();
        try{
            API_Order_OmniIntegration_Util service = API_Order_OmniIntegration_Util.getService();
            service.submitOrders(quoteId, contacts, fileIds);

            result.success = true;
            result.messages = 'The orders are now in a \'review\' state'.split(';');
        }catch(API_OM_Connection_Util.OMException ex){
            result.success = false;
            result.messages = ex.getMessage().split(';');
        }catch(Exception ex){
            result.success = false;
            result.messages = new List<String>();
            result.messages.add('Unexpected Exception: ' + ex.getMessage());
            result.messages.add('Please verify the submission status of your order manually.');
            System.debug(ex.getStackTraceString());
        }

        return result;
    }

    public class OMSubmitRequest{
        @InvocableVariable(label='Quote Id')
        public Id quoteId;
        @InvocableVariable(label='Order Contacts')
        public List<API_OM_SubmitOrdersContact_Model> contacts;
        @InvocableVariable(label='Content Document Ids')
        public List<Id> fileIds;
    }

    public class OMSubmitResult{
        @InvocableVariable
        public Boolean success;
        @InvocableVariable
        public List<String> messages;
    }
}