public with sharing class API_OM_RequestLogger implements EBTLS.RequestLoggingInterface {
    private static List<API_Response__c> logs = new List<API_Response__c>();
    private static Boolean isBulk = false;

    public void log(HttpRequest req, HttpResponse resp) {

        new EBTLS.DefaultRequestLogger().log(req, resp);

        API_Response__c ar = new API_Response__c();
        ar.Incoming_from_External_System__c = false;

        ar.Method__c = req.getMethod();
        ar.Endpoint__c = req.getEndpoint();
        String requestBody = String.valueOf(req) + '\n\n' + req.getBody();
        if(requestBody.length() > 32000){
            ar.Http_Request__c = requestBody.substring(0, 32000);
        } else {
            ar.Http_Request__c = requestBody;
        }
        

        ar.Status_Code__c = String.valueOf(resp.getStatusCode());
        String responseBody = String.valueOf(resp) + '\n\n' + resp.getBody();
        if(responseBody.length() > 32000){
            ar.Http_Response__c = responseBody.substring(0,32000);
        }else{
            ar.Http_Response__c = responseBody;
        }
        

        ar.Internal_Record_Identifier__c = extractQuoteId(req.getBody());

        try{
            API_OM_Connection_Util.APIResponse respBody = (API_OM_Connection_Util.APIResponse) JSON.deserialize(resp.getBody(), API_OM_Connection_Util.APIResponse.class);

            ar.Success__c = String.valueOf(respBody.success);
            ar.Code__c = respBody.code;
            if(respBody.message != null){
                if(respBody.message.length() > 32000){
                    ar.Message__c = respBody.message.substring(0, 32000);
                } else {
                    ar.Message__c = respBody.message;
                }
                
            }else{
                ar.Message__c = JSON.serialize(respBody.messages)?.left(255);
            }
            // ar.External_Record_Identifier__c = externalId;
        }catch(Exception ex){
            System.debug('Unable to parse response. Reverting to basic logging.');
        }

        if(isBulk){
            logs.add(ar);
        }else{
            insert ar;
        }
    }

    @testVisible
    private String extractQuoteId(String requestBody){
        try{
            return requestBody.substringBetween('payload_reference_id":"', '"');
        }catch(Exception ex){
            System.debug('Unable to parse request identifier.');
            return null;
        }
    }

    public static void setBulkMode(Boolean isBulkMode){
        isBulk = isBulkMode;
    }

    public static void saveLogs(){
        insert logs;
    }
}