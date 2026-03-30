@RestResource(urlMapping='/tickets/*')
global with sharing class CpTickets {
    
    @HttpPost
    global static void createTicket(){
        //create a ticket without an order
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        TicketWrapper wrapData = new TicketWrapper();
        
        CustomException ce = new CustomException();
        ce.message = '';        
        System.JSONGenerator js = JSON.createGenerator(false);

        try{
          wrapData = (TicketWrapper)System.JSON.deserialize(req.requestBody.toString(), TicketWrapper.class);
        } catch(Exception e) {
            System.debug('wrapData deserialize Error ' + e);
            ce.message = 'CpTickets '+ e.getLineNumber() + ' ::: wrapData deserialize Error ::: ' + e;
            CustomException.sendErrorNotification(ce);
        }
              
        js.writeStartObject();
        
        try{
            Case c = new Case();
            c.SuppliedEmail = wrapData.email;
            c.Subject = wrapData.subject.abbreviate(254);
            c.Description = 'Name: ' + wrapData.first_name + ' ' + wrapData.last_name + '\n Phone: ' + wrapData.phone + '\n Contact Method: ' + wrapData.contact_method + '\n Description: ' + wrapData.description.abbreviate(31000);
            c.RecordTypeId = '0126Q000000YNDTQA4';
            //External Customer Support record type Production: 0126Q000000YNDTQA4, Sandbox: 0128M0000008WHZQA2
            c.Support_Queue__c = 'TOC Support';
            c.Priority = 'Medium';
            c.Origin = 'Customer Portal';
            c.Status = 'New';
            
            ID queueId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue' AND SobjectType = 'Case'].Queue.Id;
            System.debug('queueID ::: ' + queueId);
            c.OwnerId = queueId;          

            insert c;
            System.debug('case ::: ' + String.valueof(c));
      
            CpEmailAutoResponse.tocEmailAutoResponse(c.Id, c.SuppliedEmail, wrapData.first_name);
            
            List<Case> caseQueryResults = new List<Case>();
            //on DML operations, Salesforce only autogenerates the ID, other 'auto-generated' fields must be queried for 
            try{
                caseQueryResults = [SELECT Id, CaseNumber FROM Case Where Id =: c.Id];
                System.debug('caseQueryResults ::: ' + caseQueryResults);
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
                ar.Endpoint__c = 'CpTickets ::: \\tickets\\';
                ar.Http_Request__c = String.valueOf(req);
                ar.Http_Response__c = String.valueOf(res);
                ar.Incoming_from_External_System__c = true;
                ar.Method__c = 'POST';
                ar.Message__c = 'New Case Created';
                ar.Wrapper__c = String.valueOf(wrapdata).abbreviate(131071);
                ar.Success__c = 'true';
                ar.Status_Code__c = '200';
                ar.Code__c = 'API_CPTICKET_CREATED';
                ar.Internal_Record_Identifier__c = caseNumberAsString;
                insert ar;
                
            }catch(Exception e){
                            
                API_Response__c ar = new API_Response__c();
                ar.Endpoint__c = 'CpTickets ::: \\tickets\\';
                ar.Http_Request__c = String.valueOf(req);
                ar.Http_Response__c = String.valueOf(res);
                ar.Incoming_from_External_System__c = true;
                ar.Method__c = 'POST';
                ar.Wrapper__c = String.valueOf(wrapdata).abbreviate(131071);
                ar.Message__c = 'CpTikets error ::: ' + e;
                ar.Success__c = 'true';
                ar.Status_Code__c = '500';
                ar.Code__c = 'API_CPTICKETORDER_ERROR';
                ar.Internal_Record_Identifier__c = 'no case created';
                insert ar;
                ce.message = 'CpTickets ' + e.getLineNumber() + ' ::: API Response object creation error ::: ' + e + ' ::: ' + String.valueOf(wrapdata);
                CustomException.sendErrorNotification(ce); 
            }
            
            
        } catch(Exception e){
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', e.getMessage());
                        
            API_Response__c ar = new API_Response__c();
            ar.Endpoint__c = 'CpTickets ::: \\tickets\\';
            ar.Http_Request__c = String.valueOf(req);
            ar.Http_Response__c = String.valueOf(res);
            ar.Incoming_from_External_System__c = true;
            ar.Method__c = 'POST';
            ar.Message__c = 'CpTicket error ::: ' + e;
            ar.Wrapper__c = String.valueOf(wrapdata).abbreviate(131071);
            ar.Success__c = 'true';
            ar.Status_Code__c = '500';
            ar.Code__c = 'API_CPTICKETORDER_ERROR';
            ar.Internal_Record_Identifier__c = 'no case created';
            insert ar;
            
            ce.message = 'CpTickets general error ::: ' + e + ' ::: ' + String.valueOf(wrapdata);
            CustomException.sendErrorNotification(ce);
        }
        
        js.writeEndObject();
        String result = js.getAsString();
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(result);
    }
    
    
    global class TicketWrapper{
        global ticketWrapper(){}
        global String first_name;
        global String last_name;
        global String email;
        global String phone;
        global String contact_method;
        global String description;
        global String subject;
        
    }
    
}