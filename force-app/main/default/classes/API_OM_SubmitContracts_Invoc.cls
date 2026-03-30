/**
 * SC-0000187 Case 00509459: Created for flow Contract_Daily_Omni_Integration
**/
public class API_OM_SubmitContracts_Invoc {
    
    @InvocableMethod(label='Submit Contracts and Subscriptions to OM' callout=true category='OM Integration')
    public static void submitContractsInvoc(List<OMSubmitRequest> requests) {
        try {
            System.debug('****requests: ' + requests);
            String serializedOmOrderPayload = JSON.serialize(requests[0].omOrderPayload, true);
            System.debug('****serializedOmOrderPayload #1: ' + serializedOmOrderPayload);
            submitOrder(serializedOmOrderPayload);
        } catch(Exception ex) {
            System.debug('***** ex: ' + ex.getMessage());
        }        
    }

    @future(callout=true)
    public static void submitOrder(String serializedOmOrderPayload) {
        System.debug('****serializedOmOrderPayload #2: ' + serializedOmOrderPayload);
        try {
            API_OM_Connection_Util.getService().sendRequestToOmni(serializedOmOrderPayload);
        } catch(API_OM_Connection_Util.OMException ex) {
            System.debug('result.messages: ' + ex.getMessage().split(';'));
        } catch(Exception ex) {
            System.debug('Unexpected Exception: ' + ex.getMessage());
            System.debug(ex.getStackTraceString());
        }
    }

    public class OMSubmitRequest {
        @InvocableVariable(label='OM Order Payload')
        public API_OM_Order_Payload_Model omOrderPayload;
    }
}