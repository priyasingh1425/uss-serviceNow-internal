/*************************************************
* Name: API_APIResponse_INS
* Description: Creates or Returns API Response objects for use in classes that do API callouts and need to generate API Response objects
* Test class: API_APIResponse_INS_TEST (100%)
* ***********************************************/ 

public class API_APIResponse_INS {
    
/************************************************
* Method Name: createAPIResponse 
* Description: Creates API Response objects for use in classes that do API callouts and need to generate API Response objects
* Parameters : multiple strings representing API response parameters and messages, and a boolean to indicate integration direction
* Return Values:  void (success/fail)
* ***********************************************/  
    public static void createAPIResponse(String endpoint, String request, String response, Boolean incoming, String method, String message, String success, String statusCode, String code, String externalId, String internalId, String wrapper){
           API_Response__c ar = new API_Response__c();
                ar.Endpoint__c = endpoint;
                ar.Http_Request__c = request;
                ar.Http_Response__c = response;
                ar.Incoming_from_External_System__c = incoming;
                ar.Method__c = method;
                ar.Message__c = message;
        		ar.Wrapper__c = wrapper;
                ar.Success__c = success;
                ar.Status_Code__c = statusCode;
                ar.Code__c = code;
                ar.External_Record_Identifier__c = externalId;
                ar.Internal_Record_Identifier__c = internalId;
        insert ar;
    }
    
    /************************************************
* Method Name: returnAPIResponse 
* Description: Returns API Response objects for use in classes that do API callouts and need to generate API Response objects
* Parameters : multiple strings representing API response parameters and messages, and a boolean to indicate integration direction
* Return Values:  API_Response__c
* ***********************************************/  
        public static API_Response__c returnAPIResponse(String endpoint, String request, String response, Boolean incoming, String method, String message, String success, String statusCode, String code, String externalId, String internalId, String wrapper){
           API_Response__c ar = new API_Response__c();
                ar.Endpoint__c = endpoint;
                ar.Http_Request__c = request;
                ar.Http_Response__c = response;
                ar.Incoming_from_External_System__c = incoming;
                ar.Method__c = method;
                ar.Message__c = message;
        		ar.Wrapper__c = wrapper;
                ar.Success__c = success;
                ar.Status_Code__c = statusCode;
                ar.Code__c = code;
                ar.External_Record_Identifier__c = externalId;
                ar.Internal_Record_Identifier__c = internalId;
        return ar;
    }
}