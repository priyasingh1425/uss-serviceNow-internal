@RestResource(urlMapping='/ticketOrder/*')
global with sharing class CpTicketOrder {
    
        @HttpPost
    global static void createTicketOrder(){
        //create a ticket with an order
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        TicketOrderWrapper wrapData = new TicketOrderWrapper();
        
        CustomException ce = new CustomException();
        ce.message = '';
        System.JSONGenerator js = JSON.createGenerator(false);
        
        try{
          wrapData = (TicketOrderWrapper)System.JSON.deserialize(req.requestBody.toString(), TicketOrderWrapper.class);
        } catch(Exception e) {
            System.debug('wrapData deserialize Error ' + e);
            ce.message = 'CpTicketOrder ' + e.getLineNumber() + ' ::: wrapData deserialize Error ::: ' + e.getMessage();
			CustomException.sendErrorNotification(ce);
        }
        js.writeStartObject();
        
        try{
            Case c = new Case();
            c.SuppliedEmail = wrapData.email;
            c.Subject = wrapData.subject.abbreviate(254);
            c.Description = 'Name: ' + wrapData.first_name + ' ' + wrapData.last_name + '\n Phone: ' + wrapData.phone + '\n Contact Method: ' + wrapData.contact_method + '\n Description: ' + wrapData.description.abbreviate(31000);
            
            
            //List<Asset> relatedAssetAsList = [SELECT Id FROM Asset WHERE Base_Order_Id__c =: Double.valueOf(wrapData.base_order_id)];
            
            //c.AssetId = relatedAssetAsList.get(0).Id;
            c.Pin_Verified__c = Boolean.valueOf(wrapData.pin_authorization);
            
            //set AssetBaseID__c to link a related Service Summary to the case, after insert begins (has to hit Trigger which is after the Response)
            c.AssetBaseID__c = wrapData.base_order_id;
           
            //set default fields here ***update IDs for Production
            //RecordTypeId = External Customer Support
            c.RecordTypeId = '0126Q000000YNDTQA4';
            //Production: 0126Q000000YNDTQA4  Sandbox: 0128M0000008WHZQA2

            c.Priority = 'Medium';
            c.Origin = 'Customer Portal';
            c.Status = 'New';
            c.Support_Queue__c = 'TOC Support';

            ID queueId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue' AND SobjectType = 'Case'].Queue.Id;
            c.OwnerId = queueId;
            
            insert c;

            CpEmailAutoResponse.tocEmailAutoResponse(c.Id, c.SuppliedEmail, wrapData.first_name);
            
            List<Case> caseQueryResults = new List<Case>();
            //on DML operations, Salesforce only autogenerates the ID, other 'auto-generated' fields must be queried for 
            try{
                caseQueryResults = [SELECT Id, CaseNumber FROM Case Where Id =: c.Id];
            }catch(Exception e){
                js.writeStringField('Status', 'Error');
                js.writeStringField('Error', e.getMessage());
            }
            
            String caseNumberAsString = String.valueOf(caseQueryResults.get(0).CaseNumber);

            js.writeStringField('Status', 'Success');
            js.writeIdField('Id', c.Id);
            js.writeStringField('CaseNumber', caseNumberAsString);
            
            //API Response object creation for monitoring
        	try{            
            	API_Response__c ar = new API_Response__c();
            	ar.Endpoint__c = 'CpTicketOrder ::: \\ticketOrder\\';
            	ar.Http_Request__c = String.valueOf(req);
            	ar.Http_Response__c = String.valueOf(res);
            	ar.Incoming_from_External_System__c = true;
            	ar.Method__c = 'POST';
                ar.Message__c = 'New Case Created';
                ar.Wrapper__c = String.valueOf(wrapdata).abbreviate(131071);
                ar.Success__c = 'true';
                ar.Status_Code__c = '200';
                ar.Code__c = 'API_CPTICKETORDER_CREATED';
                ar.Internal_Record_Identifier__c = caseNumberAsString;
                insert ar;
                
        	}catch(Exception e){
           		ce.message = 'CpTicketOrder ' + e.getLineNumber() + ' ::: API Response object creation error ::: ' + e + ' ::: ' + String.valueOf(wrapdata);
           		CustomException.sendErrorNotification(ce); 
        	}
            
        } catch(Exception e){
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', e.getMessage());   
            ce.message = 'CpTicketOrder general error ::: ' + e + ' ::: ' + String.valueOf(wrapdata);
            
            API_Response__c ar = new API_Response__c();
            ar.Endpoint__c = 'CpTicketOrder ::: \\ticketOrder\\';
            ar.Http_Request__c = String.valueOf(req);
            ar.Http_Response__c = String.valueOf(res);
            ar.Incoming_from_External_System__c = true;
            ar.Method__c = 'POST';
            ar.Message__c = 'CpTicketOrder general error ::: ' + e ;
            ar.Wrapper__c = String.valueOf(wrapdata).abbreviate(131071);
            ar.Success__c = 'true';
            ar.Status_Code__c = '500';
            ar.Code__c = 'API_CPTICKETORDER_ERROR';
            ar.Internal_Record_Identifier__c = 'no case created';
            insert ar;
            CustomException.sendErrorNotification(ce);
        }
        
        js.writeEndObject();
        String result = js.getAsString();

        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(result);

    }
    
    global class TicketOrderWrapper{
        global ticketOrderWrapper(){}
        global String first_name;
        global String last_name;
        global String email;
        global String phone;
        global String contact_method;
        global String description;
        global String base_order_id;
        global String pin_authorization;
        global String subject;
    }


}