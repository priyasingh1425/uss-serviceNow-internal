/*************************************************
* Name: API_OPSramp_CaseEndpoint_END
* Description: Custom Endpoint used to re-point code to Salesforce that was previously pointed at Cherwell
* Test class: 
* System Changes: 
*     - SC-0000343
* ***********************************************/
@RestResource(urlMapping='/OPSramp/*')
global without sharing class API_OPSramp_CaseEndpoint_END {
    
    private static List<ApiResponseWrapper> apiResponses = new List<ApiResponseWrapper>();
    private static List<SalesforceSupportCaseWrapper> supportCases = new List<SalesforceSupportCaseWrapper>();
    
    /*************************************************
* Method Name: createOpsRampCase
* Description: handler for incoming requests to this endpoint
* ***********************************************/
    
    @HttpPost
    global static void createOpsRampCase(){
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String result;
        
        switch on RestContext.request.requestURI.substringAfterLast('/') {
            when 'create' { 
                result = doOpsRampCaseCreatePost(req, res); }
            when 'update' { 
                result = doOpsRampCaseUpdatePost(req, res); }
            when else { 
                result = doOpsRampCaseInvalidCall(req, res, RestContext.request.requestURI.substringAfterLast('/')); }
        }
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(result);
        
        List<API_Response__c> apiResponseObjects = new List<API_Response__c>();
        if(!apiResponses.isEmpty()){
            for(ApiResponseWrapper arw : apiResponses){
                API_Response__c ar = new API_Response__c();
                ar.Endpoint__c = arw.endpoint;
                ar.Http_Request__c = String.valueOf(req) + ' || Params: ' + arw.httprequest;
                ar.Http_Response__c = String.valueOf(res);
                ar.Incoming_from_External_System__c = arw.incoming;
                ar.Method__c = arw.method;
                ar.Message__c = arw.message;
                ar.Success__c = arw.success;
                ar.Status_Code__c = arw.statusCode;
                ar.Code__c = arw.code;
                ar.Internal_Record_Identifier__c = arw.internalRecordIdentifier;
                apiResponseObjects.add(ar);
            }
        }
        List<Database.SaveResult> srList = new List<Database.SaveResult>();
        if(!apiResponseObjects.isEmpty()){
            srList = Database.insert(apiResponseObjects, false);
        }
        
        for(Database.SaveResult sr : srList){
            if(!sr.isSuccess()){
                for (Database.Error err : sr.getErrors()) {
                    SalesforceSupportCaseWrapper supCase = new SalesforceSupportCaseWrapper();
                    supCase.description = 'The following error occurred for record ID: ' + sr.getId() + ' With the status code: ' + err.getStatusCode() + ' Error Message: ' + err.getMessage();
                    supCase.subject = supCase.subject + ' Error saving API Response.';
                    supportCases.add(supCase);
                }
            }
        }
        
        if(!supportCases.isEmpty()){
            if(supportCases.size() > 1){
                String subj = 'API_OPSramp_CaseEndpoint_END || Multiple issues';
                String descr = '';
                for(SalesforceSupportCaseWrapper cw : supportCases){
                    descr = descr + cw.subject + '  ' + cw.description + '\n'; 
                }
                HLP_Case_SFQueue_Ins.createSFQueueCase(subj, descr?.abbreviate(32000), supportCases.get(0).priority); 
            } else {
                HLP_Case_SFQueue_Ins.createSFQueueCase('API_OPSramp_CaseEndpoint_END ' + supportCases.get(0).subject, supportCases.get(0).description, supportCases.get(0).priority);
            }
        }
        
        Automation_Analytics__c aa = new Automation_Analytics__c();
        aa.Automation_Name__c = 'API_OPSramp_CaseEndpoint_END';
        aa.Automation_Type__c = 'Apex Class';
        aa.Calculation_Explanation__c = 'Case creation: estimate based off of other alert monitoring processes: NMD Alarm';
        aa.Description__c = 'TOC';
        aa.Time_Saved__c = 1;
        insert aa;
        
    }
        
    /*************************************************
* Method Name: doOpsRampCaseCreatePost
* Description: processing for call to the create post 
* ***********************************************/
    global static String doOpsRampCaseCreatePost(RestRequest req, RestResponse res){    
        System.JSONGenerator js = JSON.createGenerator(false);
        
        CreateOpsRampTicketWrapper opsRampData = new CreateOpsRampTicketWrapper();
        js.writeStartObject();
        
        try{
            opsRampData = (CreateOpsRampTicketWrapper)System.JSON.deserialize(req.requestBody.toString(), CreateOpsRampTicketWrapper.class);
        } catch(JSONException e) {
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', e.getMessage());
            
            SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
            s.subject = s.subject + ' deserialization error';
            s.description = 'Cause: ' + e.getCause() + ' Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage();
            supportCases.add(s);
            
            ApiResponseWrapper arw = new ApiResponseWrapper();
            arw.endpoint = arw.endpoint + 'create';
            arw.message = 'Case NOT CREATED' + e.getMessage();
            arw.success = 'Error';
            arw.code = arw.code + '_ERROR';
            arw.statusCode = '500';
            arw.httprequest = 'deserialization error';
            arw.internalRecordIdentifier = 'Case not created';
            apiResponses.add(arw);
        }
        
        //initiate case and assign general fields
        Case c = new Case();
        try{
            c.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Case' AND Name = 'External Customer Support'].get(0).Id;
            c.OwnerId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue'].get(0).Queue.Id;
        } catch(Exception e){
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', e.getMessage());
            
            SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
            s.subject = s.subject + ' query error: integration review required!';
            s.description = 'Cause: ' + e.getCause() + ' Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage();
            supportCases.add(s);
        }
        

        c.System_Origin__c = 'OpsRamp';
        c.Support_Queue__c = 'TOC Support';
        c.Origin = 'Event';
        c.Subject = opsRampData.ShortDescription?.abbreviate(255);
        c.Description = opsRampData.Description?.abbreviate(32000);
        c.MA_External_Rec_Id__c = 'OPR-'+ opsRampData.SourceID;
        c.Priority = priorityParser(opsRampData.Priority);
        
                
        //create list for holding any Case_Config_Item_Junction__c that will need to be associated with the created case
        List<Case_Config_Item_Junction__c> cis = new List<Case_Config_Item_Junction__c>();   
        
        if(opsRampData.MonitoringHostName != null && String.isNotEmpty(opsRampData.MonitoringHostName) && String.isNotBlank(opsRampData.MonitoringHostName)){
            //create a list off Case_Config_Item_Junction__c objects to link each Configuration Item to the case after creation
            List<String> deviceIds = opsRampData.MonitoringHostName.split(',');
            if(!deviceIds.isEmpty()){
                for(CMDB_Config_Item__c ci : [Select Id, Device_Maintenance_ClientID__c, Device_Maintenance_UniqueID__c, Customer_Account__r.Id From CMDB_Config_Item__c Where Device_Maintenance_UniqueID__c IN :deviceIds]){
                    c.AccountId = ci.Customer_Account__r.Id;
                    
                    Case_Config_Item_Junction__c ciJunction = new Case_Config_Item_Junction__c();
                    ciJunction.CMDB_Config_Item__c = ci.Id;
                    cis.add(ciJunction);
                }                         
                
            } else {
                SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
                s.subject = s.subject + ' no devices received from OpsRamp.  Integration review required!';
                s.description = 'Cause: no devices received from OpsRamp. This should not happen, coordinate debug efforts with OpsRamp SME';
                supportCases.add(s);
            }
        }
        
        String caseId;
        
        try{
            c.setOptions(bypassAssignmentRule());
            insert c;
            Case reCase = [Select Id, CaseNumber From Case Where Id = :c.Id]?.get(0);
            caseId = c.Id.toString();
            
            if(!cis.isEmpty()){
                for(Case_Config_Item_Junction__c j : cis){
                    j.Case__c = c.Id;
                }
                insert cis;
            }
            
            js.writeStringField('Status', 'Success');
            js.writeStringField('Id', c.Id.toString());
            js.writeStringField('CaseNumber', reCase.CaseNumber);
            
            ApiResponseWrapper arw = new ApiResponseWrapper();
            arw.endpoint = arw.endpoint + 'create';
            arw.message = 'New Case Created';
            arw.success = 'Success';
            arw.code = arw.code + '_CREATED';
            arw.statusCode = '201';
            arw.httprequest = opsRampData.toString();
            arw.internalRecordIdentifier = c.Id.toString();
            apiResponses.add(arw);
            
        } catch (Exception e){
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', e.getMessage());
            
            SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
            s.subject = s.subject + ' Case not Created!';
            s.description = 'Cause: ' + e.getCause() + ' Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage();
            supportCases.add(s);
            
            ApiResponseWrapper arw = new ApiResponseWrapper();
            arw.endpoint = arw.endpoint + 'create';
            arw.message = 'Case NOT CREATED';
            arw.success = 'Error';
            arw.code = arw.code + '_ERROR';
            arw.statusCode = '500';
            arw.internalRecordIdentifier = 'Case not created';
            arw.httprequest = opsRampData.toString();
            apiResponses.add(arw);
        }
        
        js.writeEndObject();
        String result = js.getAsString();
        
        chatterPoster('OpsRamp Case Initiated.', 'New', c.Priority, c.Subject, c.Description, caseId);

        return result;
    }
    /*************************************************
* Method Name: doOpsRampCaseUpdatePost
* Description: processing for call to the update post 
* ***********************************************/
    global static String doOpsRampCaseUpdatePost(RestRequest req, RestResponse res){
        System.JSONGenerator js = JSON.createGenerator(false);
        UpdateOpsRampCaseWrapper opsRampData = new UpdateOpsRampCaseWrapper();
        js.writeStartObject();
        
        try{
            opsRampData = (UpdateOpsRampCaseWrapper)System.JSON.deserialize(req.requestBody.toString(), UpdateOpsRampCaseWrapper.class);
        } catch(JSONException e) {
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', e.getMessage());
            
            SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
            s.subject = s.subject + ' deserialization error';
            s.description = 'Cause: ' + e.getCause() + ' Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage();
            supportCases.add(s);
            
            ApiResponseWrapper arw = new ApiResponseWrapper();
            arw.endpoint = arw.endpoint + 'update';
            arw.message = 'Case NOT Updated';
            arw.success = 'Error';
            arw.code = arw.code + '_ERROR';
            arw.statusCode = '500';
            arw.internalRecordIdentifier = 'Case not updated';
            arw.httprequest = opsRampData.toString();
            apiResponses.add(arw);
        }
        Case priorCase = new Case();
        
        try{
            priorCase = [SELECT Id, Subject, Description, Priority, Status FROM Case WHERE Id =: opsRampData.fieldId]?.get(0);
           } catch (Exception e){
                js.writeStringField('Status', 'Error');
                js.writeStringField('Error', 'No case found for provided Id (fieldId)');
                
                SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
                s.subject = s.subject + ' Case not Updated!';
                s.description = 'Cause: No case found for provided Id: ' + opsRampData.fieldId + e.getCause() + ' Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage();
                supportCases.add(s);
                
                ApiResponseWrapper arw = new ApiResponseWrapper();
                arw.endpoint = arw.endpoint + 'update';
                arw.message = 'Case NOT Updated';
                arw.success = 'Error';
                arw.code = arw.code + '_ERROR';
                arw.statusCode = '500';
                arw.internalRecordIdentifier = opsRampData.fieldId;
               arw.httprequest = opsRampData.toString();
                apiResponses.add(arw);
            }
        Boolean doClearChatterPost = false;
        if(priorCase != null) {
            Case updateCase = new Case(Id = priorCase.Id);
            try{
                if(opsRampData.status == 'New' || opsRampData.status == ''){
                    //do not change case status
                } else if(opsRampData.status == 'Cleared'|| opsRampData.status == 'Closed' || opsRampData.status == 'Resolved'){
                    updateCase.Status = 'Parked';
                    doClearChatterPost = true;
                } else {
                    js.writeStringField('Status', 'Error');
                    js.writeStringField('Error', 'Invalid Status received from OpsRamp: ' + opsRampData.status);
                    
                    SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
                    s.subject = s.subject + ' Case status not updated.';
                    s.description = 'Case Id: ' + priorCase.Id + ' Invalid Status received from OpsRamp: ' + opsRampData.status;
                    supportCases.add(s);
                }
                
                String newPriority = priorityParser(opsRampData.priority);
                if(newPriority != null || String.isNotEmpty(newPriority) || String.isNotBlank(newPriority)){
                    updateCase.Priority = newPriority;
                }
                updateCase.Description = (opsRampData.description + '\n\n' + priorCase.Description)?.abbreviate(32000);
                updateCase.Subject = opsRampData.subject?.abbreviate(255);
                updateCase.setOptions(bypassAssignmentRule());
                
                update updateCase;
                
                js.writeStringField('Status', 'Success');
                js.writeStringField('Id', updateCase.Id.toString());
                
                ApiResponseWrapper arw = new ApiResponseWrapper();
                arw.endpoint = arw.endpoint + 'update';
                arw.message = 'Case Updated';
                arw.success = 'Success';
                arw.code = arw.code + '_UPDATED';
                arw.statusCode = '200';
                arw.httprequest = opsRampData.toString();
                arw.internalRecordIdentifier = updateCase.Id.toString();
                apiResponses.add(arw);

                if(doClearChatterPost){
                    chatterPoster('OpsRamp Alert CLEARED.', opsRampData.status, newPriority, opsRampData.subject, opsRampData.description, updateCase.id.toString());
                } else {
                    chatterPoster('OpsRamp Alert Update received.', opsRampData.status, newPriority, opsRampData.subject, opsRampData.description, updateCase.id.toString());
                }
                
            } catch (Exception e){
                js.writeStringField('Status', 'Error');
                js.writeStringField('Error', e.getMessage());
                
                SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
                s.subject = s.subject + ' Case not Updated!';
                s.description = 'Cause: ' + e.getCause() + ' Line: ' + e.getLineNumber() + ' Message: ' + e.getMessage();
                supportCases.add(s);
                
                ApiResponseWrapper arw = new ApiResponseWrapper();
                arw.endpoint = arw.endpoint + 'update';
                arw.message = 'Case NOT Updated';
                arw.success = 'Error';
                arw.code = arw.code + '_ERROR';
                arw.statusCode = '500';
                arw.internalRecordIdentifier = opsRampData.fieldId;
                arw.httprequest = opsRampData.toString();
                apiResponses.add(arw);
            }
            
        } else {
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', 'No case found for Id: ' + opsRampData.fieldId + ' This record may have been deleted in Salesforce.  A case has also been created in Salesforce with this information.');
            
            SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
            s.subject = s.subject + '  No Case found for Id: ' + opsRampData.fieldId;
            s.description = 'The case record for Id: ' + opsRampData.fieldId + ' may have been deleted.  An update to this case was sent from OpsRamp';
            supportCases.add(s);
            
            ApiResponseWrapper arw = new ApiResponseWrapper();
            arw.endpoint = arw.endpoint + 'update';
            arw.message = 'Case Not Found';
            arw.success = 'Error';
            arw.code = arw.code + '_ERROR';
            arw.statusCode = '500';
            arw.internalRecordIdentifier = opsRampData.fieldId;
            arw.httprequest = opsRampData.toString();
            apiResponses.add(arw);
        }
        
        js.writeEndObject();
        String result = js.getAsString();
        
        return result;
    }
    /*************************************************
* Method Name: doOpsRampCaseInvalidCall
* Description: processing for call to any invalid url for this endpoint
* ***********************************************/
    global static String doOpsRampCaseInvalidCall(RestRequest req, RestResponse res, String invalidUrl){
        System.JSONGenerator js = JSON.createGenerator(false);      
        
        SalesforceSupportCaseWrapper c = new SalesforceSupportCaseWrapper();
        c.description = ' ::: Invalid API Call ' + invalidUrl + ' ::: ';
        supportCases.add(c);
        
        ApiResponseWrapper arw = new ApiResponseWrapper();
        arw.endpoint = arw.endpoint + invalidUrl;
        arw.message = arw.message + ' Error in URL ::: ';
        arw.success = 'false';
        arw.code = arw.code + '_InvalidURL';
        arw.statusCode = '400';
        arw.internalRecordIdentifier = 'API call was invalid';
        arw.httprequest = 'invalid call';
        apiResponses.add(arw);
        
        js.writeStartObject();
        js.writeStringField('Status', 'Error');
        js.writeStringField('Error', 'Invalid API Call to OPSramp, ' + invalidUrl + ' is invalid');  
        
        js.writeEndObject();
        String result = js.getAsString();
        
        return result;
    }
        /*************************************************
* Name: priorityParser
* Description: maps the received priority values from OpsRamp to their equivalents in Salesforce
* ***********************************************/    
    private static void chatterPoster(String message, String status, String priority, String subject, String description, String caseId){
        

        String chatterText = message + '\n\n' +
                     'Status: ' + (status != null ? status : 'N/A') + '\n' +
                     'Priority: ' + (priority != null ? priority : 'N/A') + '\n' +
                     'Subject: ' + (subject != null ? subject : 'N/A') + '\n' +
                     'Description: ' + (description != null ? description : 'N/A');
        
        Decimal chatterIterations = ((Decimal)chatterText.length()/4900).round(System.RoundingMode.CEILING);
        
        List<Invocable.Action.Result> actionResults = new List<Invocable.Action.Result>();
        
        if(chatterIterations == 1){
            Invocable.Action action = Invocable.Action.createStandardAction('chatterPost');
            
            action.setInvocationParameter('text', chatterText);
            action.setInvocationParameter('subjectNameOrId', caseId);
            actionResults.addAll(action.invoke());
        } else {
            
            if(chatterIterations > 10){
                chatterIterations = 10;
            }
            
            for(Integer i = 0; i < chatterIterations; i++){
                Invocable.Action action = Invocable.Action.createStandardAction('chatterPost');
                String tempChatterText = 'Post ' + (i+1) + ' of ' + chatterIterations + '\n' + chatterText.left(4900);
                chatterText = chatterText.right((chatterText.length() - tempChatterText.length()));
                action.setInvocationParameter('text', tempChatterText);
                action.setInvocationParameter('subjectNameOrId', caseId);
                
                actionResults.addAll(action.invoke());
            }
            
        }
        
        if (actionResults.size() > 0 && actionResults[0].isSuccess()) {
            //success
        } else {           
            SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
            s.subject = s.subject + 'Case Chatter post not created';
            s.description = ' chatter post was not created for case ::: ' + caseId + ' ::: OpsRamp has sent an update ::: ';
            supportCases.add(s);
        }
        
    }
    
        /*************************************************
* Name: priorityParser
* Description: maps the received priority values from OpsRamp to their equivalents in Salesforce
* ***********************************************/
    private static String priorityParser(String priorityValue){
        
        String result = '';
        
        switch on priorityValue{
            when '2' {
                result = 'Low';
            }
            when '3' {
                result = 'Medium';
            }
            when '4' {
                result = 'High';
            }
            when '5' {
                result = 'Urgent';
            }
            when else {
                SalesforceSupportCaseWrapper s = new SalesforceSupportCaseWrapper();
                s.subject = s.subject + ' invalid value, integration evaluation required!';
                s.description = 'Cause: received invalid value for Priority.  Value recieved: ' + priorityValue;
                supportCases.add(s);
            }
        }
        
        return result;
    }
    
            /*************************************************
* Name: bypassAssignmentRule
* Description: method used to obtain the custom (non-standard) assignment rule used specifically for this process -- should not run outside of this process or interfere with other updates made to these types of cases.
* ***********************************************/
    
    private static Database.DMLOptions bypassAssignmentRule(){
        AssignmentRule ar = [
            SELECT Id 
            FROM AssignmentRule 
            WHERE SobjectType = 'Case' AND Name = 'OpsRamp Alarm Rule - Used by APEX'
            LIMIT 1
        ];
        String assignmentRuleId = ar.Id.toString();
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule=false;
        dmo.assignmentRuleHeader.assignmentRuleId= assignmentRuleId;
        
        return dmo;
    }
    
        /*************************************************
* Name: CreateOpsRampTicketWrapper
* Description: Wrapper class for receiving case create calls from OpsRamp
* ***********************************************/   
    
    global class CreateOpsRampTicketWrapper{
        global String Priority; //priority
        global String SourceID; //MA_External_Rec_Id__c
        global String ShortDescription; //subject
        global String Description; //description
        global String MonitoringHostName; //Case_Config_Item_Junction__c
    }
    
    /*************************************************
* Name: UpdateOpsRampCaseWrapper
* Description: Wrapper class for receiving case update calls from OpsRamp
* ***********************************************/  
    
    global class UpdateOpsRampCaseWrapper{
        global String fieldId;
        global String status;
        global String priority;
        global String subject;
        global String description;
    }    
    
    /*************************************************
* Name: SalesforceSupportCaseWrapper
* Description: Wrapper class case creation for Salesforce Support
* ***********************************************/  
    global class SalesforceSupportCaseWrapper{
        global String subject = '';
        global String description;
        global String priority = 'Medium';
    }
    
    /*************************************************
* Name: ApiResponseWrapper
* Description: Wrapper class for creating API response objects
* ***********************************************/      
    global class ApiResponseWrapper{
        global String endpoint ='\\OPSramp\\';
        global String httprequest;
        global String httpresponse;
        global Boolean incoming = true;
        global String success;
        global String method = 'POST';
        global String message;
        global String statusCode;
        global String code = 'API_OPSramp_CaseEndpoint_END';
        global String internalRecordIdentifier;
    }
}