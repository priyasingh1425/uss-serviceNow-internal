@RestResource(urlMapping='/dlr/*')
global with sharing class OM_DLR {
    
    @HttpPut
    global static void upsertDLR(){
        
        //upsert DLR record from Omni to Salesforce
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        dlrWrapper wrapData = new dlrWrapper();
        CustomException ce = new CustomException();            
                        
        System.JSONGenerator js = JSON.createGenerator(false);
                
        try{
          wrapData = (dlrWrapper)System.JSON.deserialize(req.requestBody.toString(), dlrWrapper.class);
        } catch(Exception e) {
            OM_DLR.createAPIResponseDlr('OM_DLR ::: \\dlr\\',String.valueOf(req),String.valueOf(res),true,'PUT','DLR UPSERT ERROR','false','500','API_DLR_UPSERT_ERROR','could not deserialize','record not created', String.valueOf(wrapdata).abbreviate(131071));
            System.debug('wrapData deserialize Error ' + e);
        }
       
        js.writeStartObject();

        List<Service_Summary__c> potentialServiceIDs = new List<Service_Summary__c>();
            
        try{
            
            potentialServiceIDs = [Select Id, Name, Base_Order_ID__c From Service_Summary__c Where Base_Order_ID__c =: Double.valueOf(wrapData.base_order_id)];
            
            if(potentialServiceIDs.size() <1){
                ce.message = ce.message + ' \n OM_DLR error ::: no Service Summary with matching Base Order ID found for base order Id: ' + wrapData.base_order_id;
                    } else if(potentialServiceIDs.size()>1){
                        ce.message = ce.message + ' OM_DLR error ::: multiple Service Summary with matching Base Order IDs (base order ID: ' + wrapData.base_order_id + ') found ::: ' + potentialServiceIDs;
                    }            
        } catch(Exception e){
            OM_DLR.createAPIResponseDlr('OM_DLR ::: \\dlr\\',String.valueOf(req) + '\n\n OM Data ::: ' + String.valueOf(wrapData).abbreviate(131071),String.valueOf(res),true,'PUT','DLR UPSERT ERROR - NO SERVICE ID ::: \n base_order_id: ' + wrapData.base_order_id,'false','500','API_DLR_UPSERT_ERROR',String.valueOf(wrapdata.dlr_id),'record not created for base order: ' + wrapData.base_order_id, String.valueOf(wrapdata).abbreviate(131071));
            js.writeStringField('Status', 'Success');
        }
        
        try{
            DLR_s__c d = new DLR_s__c();
            if(potentialServiceIDs.size()<2){
            } else {
                ce.message = ce.message + ' \n OM_DLR error ::: duplicate service summaries found ' + potentialServiceIDs +  ' \n base_order_id: ' + wrapData.base_order_id;
                throw ce;
            }            
            
            d.Service_ID__c = potentialServiceIDs.get(0).Id;
            d.Base_Order_Id__c = Double.valueOf(wrapData.base_order_id);
            d.DLR_Id__c = Double.valueOf(wrapData.dlr_id);
            d.DLR_Text__c = wrapData.dlr;
            d.Legacy_Timestamp_Created__c = DateTime.valueOf(wrapData.created);
            if(String.isEmpty(wrapData.modified) || String.isBlank(wrapData.modified) || wrapData.modified == null){
               d.Legacy_Timestamp_Modified__c = DateTime.valueOf(wrapData.created);
            } else {
               d.Legacy_Timestamp_Modified__c = DateTime.valueOf(wrapData.modified); 
            }
            js.writeStringField('Status', 'Success');
            
                upsert d Base_Order_ID__c;
            
                    
        //API Response object creation for monitoring
            try{
                OM_DLR.createAPIResponseDlr('OM_DLR ::: \\dlr\\',String.valueOf(req) + '\n\n OM Data ::: ' + String.valueOf(wrapData).abbreviate(131071),String.valueOf(res),true,'PUT','DLR UPSERT ::: \n base_order_id: ' + wrapData.base_order_id + '\n Service Summary Name ::: ' + potentialServiceIDs.get(0).Name,'true','200','API_DLR_UPSERT',String.valueOf(wrapdata.dlr_id),String.valueOf(d.Id), String.valueOf(wrapdata).abbreviate(131071));
            }catch(Exception e){
                ce.message = ' \n OM_DLR ' + e.getLineNumber() + ' ::: for base order Id: ' + wrapData.base_order_id + ' API Response object creation error ::: ' + e;
                throw ce;
            }
            
        } catch(Exception e){
            js.writeStringField('Status', 'Success');
            ce.message = ce.message + ' \n OM_DLR ' + e.getLineNumber() + ' ::: general error for base order Id: ' + wrapData.base_order_id + ' ::: ' + e.getMessage();
            if(ce.message.contains('no Service Summary with matching Base Order ID found')){
                OM_DLR.createAPIResponseDlr('OM_DLR ::: \\dlr\\',String.valueOf(req) + '\n\n OM Data ::: ' + String.valueOf(wrapData).abbreviate(131071),String.valueOf(res),true,'PUT','DLR UPSERT ERROR - NO SERVICE ID ::: \n base_order_id: ' + wrapData.base_order_id,'false','500','API_DLR_NO_SERVICE_ID',String.valueOf(wrapdata.dlr_id),'record not created for base order id: ' +  wrapData.base_order_id, String.valueOf(wrapdata).abbreviate(131071));
                //do not send error for no Service Summary (only create API Response object)
            } else {
                OM_DLR.createAPIResponseDlr('OM_DLR ::: \\dlr\\',String.valueOf(req) + '\n\n OM Data ::: ' + String.valueOf(wrapData).abbreviate(131071),String.valueOf(res),true,'PUT','DLR UPSERT ERROR ::: \n base_order_id: ' + wrapData.base_order_id + '\n service summary Id: ' + potentialServiceIDs.get(0).Name,'false','500','API_DLR_UPSERT_ERROR',String.valueOf(wrapdata.dlr_id),'record not created for base order id: ' +  wrapData.base_order_id, String.valueOf(wrapdata).abbreviate(131071));
                CustomException.sendErrorNotification(ce);
            }
        }        

        js.writeEndObject();
        String result = js.getAsString();

        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(result);

    }
 
    global class dlrWrapper{
        global dlrWrapper(){}
        global String base_order_id;
        global String dlr_id;
        global String dlr;
        global String created;
        global String modified;
    }
    
    public static void createAPIResponseDlr(String endpoint, String request, String response, Boolean incoming, String method, String message, String success, String statusCode, String code, String externalId, String internalId, String wrapper){
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
}