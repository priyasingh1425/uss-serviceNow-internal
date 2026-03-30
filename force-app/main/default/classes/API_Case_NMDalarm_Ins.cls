@RestResource(urlMapping='/NMDalarm/*')
global with sharing class API_Case_NMDalarm_Ins {
    
    
    @HttpPost
    global static void createNMDCase(){
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        system.debug('Request is giving these' +req);
        String result;
        
        switch on RestContext.request.requestURI.substringAfterLast('/') {
            when 'create' { 
                result = doCreatePost(req, res); }
            when 'clear' { 
                result = doClearPost(req, res); }
            when else { 
                result = doInvalidCall(req, res, RestContext.request.requestURI.substringAfterLast('/')); }
        }
        
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(result);
        system.debug('Request is giving these' +req);
        system.debug('Request body: ' +req);
        system.debug('Response is giving these' +RestContext.response);
    }
    
    global class NMDCaseWrapper{
        global NMDCaseWrapper(){}
        //global String alarmid;//external identifier (unique according to Chuck Taylor)
        //global String nodelabel;//specific piece of equipment that is monitored, alarmid will always tie to a specific piece of equipment and circuit
        //global String ipaddr;
        //global String firsteventtime;
        global String logmsg;
        global String serviceid; //full circuit Id from alarm side
        global String alarmtype;
        global String casenumber;
        //global String severity;
        
    }
    
    global class NMDCaseWrapperSubject{
        global NMDCaseWrapperSubject(){}
        global String logmsg;
        global String serviceid; //full circuit Id from alarm side
        global String alarmtype;
        global String casenumber;
        global String subject;
        
    }
    
    global class NMDAlarmClearedWrapper{
        global NMDAlarmClearedWrapper(){}
        global String casenumber;
    }
    
    global static String doCreatePost(RestRequest req, RestResponse res){
        //create a Case from an NMD Alarm
        
        System.JSONGenerator js = JSON.createGenerator(false);
        
        NMDCaseWrapper wrapData = new NMDCaseWrapper();
        NMDCaseWrapperSubject wrapDataSubject = new NMDCaseWrapperSubject();
        
        js.writeStartObject();
        
        if(req.requestBody.toString().contains('subject')){
            //handle a wrapper that includes a Subject
            try{
                wrapDataSubject = (NMDCaseWrapperSubject)System.JSON.deserialize(req.requestBody.toString(), NMDCaseWrapperSubject.class);
            } catch(Exception e) {
                HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: wrapDataSubject deserialize Error ::: ' + e, 'High');                                      
            }
            
            if(String.isBlank(wrapDataSubject.casenumber) || String.isEmpty(wrapDataSubject.casenumber) || wrapDataSubject.casenumber == null){
                
                try{
                    String sid = wrapDataSubject.serviceid;
                    Case c = new Case();
                    c.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Case' AND Name = 'External Customer Support'].get(0).Id;
                    c.Support_Queue__c = 'TOC Support';
                    c.Origin = 'Automated Alert';
                    c.Status = 'New';
                    c.OwnerId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue'].get(0).Queue.Id;
                    c.Description = wrapDataSubject.logmsg;
                    
                    List<Service_Summary__c> sidq = [SELECT id FROM Service_Summary__c where name =: sid];
                    if(sidq.size()==1){
                        c.Service_ID__c = sidq.get(0).Id;
                    }
                    
                    c.Bypass_Validation_Reason__c = 'Asset Based Creation';
                    c.Pin_Verified__c = true;
                    if(wrapDataSubject.subject == null || wrapDataSubject.subject == ''){
                        c.Subject = 'NMD | ' + wrapDataSubject.alarmtype + ' | ' + wrapDataSubject.serviceid;
                    } else {
                        c.Subject = wrapDataSubject.subject;
                    }
                    
                    insert c;
                    System.debug(c);
                    
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
                    API_Response__c ar = new API_Response__c();
                    ar.Endpoint__c = 'Case_NMDalarm ::: \\NMDalarm\\';
                    ar.Http_Request__c = String.valueOf(req) + ' \n\n wrapDataSubject';
                    ar.Http_Response__c = String.valueOf(res);
                    ar.Incoming_from_External_System__c = true;
                    ar.Method__c = 'POST';
                    ar.Message__c = 'New Case Created';
                    ar.Success__c = 'Success';
                    ar.Status_Code__c = '200';
                    ar.Code__c = 'API_NMDalarmCase_CREATED';
                    ar.Internal_Record_Identifier__c = caseNumberAsString;
                    insert ar;
                    
                    Automation_Analytics__c aa = new Automation_Analytics__c();
                    aa.Automation_Name__c = 'API_Case_NMDalarm_Ins';
                    aa.Automation_Type__c = 'Apex Class';
                    aa.Calculation_Explanation__c = 'Case creation: (estimate provided by Benjamin Hickey 8/29/23) without this, the NMD alarm board would need to be manually monitored and a case manually created for each alarm';
                    aa.Description__c = 'TOC';
                    aa.Time_Saved__c = 1;
                    insert aa;
                } catch(Exception e){
                    
                    API_Response__c ar = new API_Response__c(Internal_Record_Identifier__c = 'no record created', Code__c = 'API_NMDalarmCase_ERROR', Status_Code__c = '500', Success__c = 'false', Message__c = 'Error Creating Case ::: Service Summary Id ' + wrapDataSubject.serviceid, Method__c = 'POST', Incoming_from_External_System__c = true, Http_Response__c = String.valueOf(res), Http_Request__c=String.valueOf(req) + '\n\n wrapdata', Endpoint__c='Case_NMDalarm ::: \\NMDalarm\\create\\');
                    insert ar;

                    HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' general error ::: Verify that Service Id exists as a Service Summary record in Salesforce ' + wrapDataSubject.serviceid + ' ::: '  + e, 'High');
                    
                    
                } 
            } else {
                try{
                    
                    Case r = [Select Id, Status, NMD_Alarm_Cleared__c, CaseNumber, Service_ID__c from Case where CaseNumber =: wrapDataSubject.casenumber].get(0);
                    
                    if(r.Status != 'Closed'){
                        
                        String cid = r.id;
                        String cn = wrapDataSubject.casenumber;
                        
                        Invocable.Action action = Invocable.Action.createStandardAction('chatterPost');
                        action.setInvocationParameter('text', 'ALARM RETRIGGERED');
                        action.setInvocationParameter('subjectNameOrId', cid);
                        List<Invocable.Action.Result> actionResults = action.invoke();
                        if (actionResults.size() > 0 && actionResults[0].isSuccess()) {
                            js.writeStringField('Status', 'Success');
                            js.writeIdField('CaseId', cid);
                        } else {
                            HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: chatter post was not created for case ::: ' + cid + ' ::: Alarm has been re-triggered ::: ', 'High'); 
                        }
                        
                        r.NMD_Alarm_Cleared__c = null;
                        r.Status = 'New';
                        
                        update r;
                        
                        List<Case> caseQueryResults = new List<Case>();
                        //on DML operations, Salesforce only autogenerates the ID, other 'auto-generated' fields must be queried for 
                        try{
                            caseQueryResults = [SELECT Id, CaseNumber FROM Case Where Id =: r.Id];
                        }catch(Exception e){
                            js.writeStringField('Status', 'Error');
                            js.writeStringField('Error', e.getMessage());   
                        }
                        
                        String caseNumberAsString = String.valueOf(caseQueryResults.get(0).CaseNumber);
                        
                        js.writeStringField('Status', 'Success');
                        js.writeIdField('Id', r.Id);
                        js.writeStringField('CaseNumber', caseNumberAsString);
                        
                        //API Response object creation for monitoring
                        API_Response__c ar = new API_Response__c(Endpoint__c='Case_NMDalarm ::: \\NMDalarm', Http_Request__c=String.valueOf(req) + '\n\n wrapDataSubject', Http_Response__c = String.valueOf(res), Incoming_from_External_System__c = true,Method__c = 'POST', Message__c = 'Case Retriggered', Success__c = 'true',Status_Code__c = '200', Code__c = 'API_NMDalarmCase_UPDATED', Internal_Record_Identifier__c = caseNumberAsString);
                        insert ar;
                        Automation_Analytics__c aa = new Automation_Analytics__c(Calculation_Explanation__c = 'Case retriggered: (estimate provided by Benjamin Hickey 8/29/23) without this, the NMD alarm board would need to be manually monitored and a case manually updated when the alarm occurred again', Time_Saved__c = 1, Description__c = 'TOC', Automation_Name__c = 'API_Case_NMDalarm_Ins', Automation_Type__c = 'Apex Class');
                        insert aa;
                        
                    } else {
                        String subj;
                        if(wrapDataSubject.subject == null || wrapDataSubject.subject == ''){
                            subj = 'NMD | ' + wrapDataSubject.alarmtype + ' | ' + wrapDataSubject.serviceid;
                        } else {
                            subj = wrapDataSubject.subject;
                        }
                        Case cl = new Case(RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Case' AND Name = 'External Customer Support'].get(0).Id,Support_Queue__c = 'TOC Support',Origin = 'Automated Alert',Status = 'New',OwnerId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue'].get(0).Queue.Id,Description = wrapDataSubject.logmsg,Service_ID__c = r.Service_ID__c, Bypass_Validation_Reason__c = 'Asset Based Creation',Pin_Verified__c = true, Subject = subj);
                        insert cl; 
                        List<Case> caseQueryResults = new List<Case>();
                        //on DML operations, Salesforce only autogenerates the ID, other 'auto-generated' fields must be queried for 
                        try{
                            caseQueryResults = [SELECT Id, CaseNumber FROM Case Where Id =: cl.Id];
                        }catch(Exception e){
                            js.writeStringField('Status', 'Error');
                            js.writeStringField('Error', e.getMessage());   
                        }
                        
                        Automation_Analytics__c aa = new Automation_Analytics__c(Time_Saved__c = 1, Description__c = 'TOC', Calculation_Explanation__c='Case creation: without this, the NMD alarm board would need to be manually monitored and a case manually created for each alarm', Automation_Type__c = 'Apex Class', Automation_Name__c = 'API_Case_NMDalarm_Ins');
                        insert aa;
                        
                        String caseNumberAsString = String.valueOf(caseQueryResults.get(0).CaseNumber);
                        
                        js.writeStringField('Status', 'Success');
                        js.writeIdField('Id', cl.Id);
                        js.writeStringField('CaseNumber', caseNumberAsString);
                        
                        //API Response object creation for monitoring        
                        API_Response__c ar = new API_Response__c(Endpoint__c='Case_NMDalarm ::: \\NMDalarm', Http_Request__c=String.valueOf(req) + '\n\n wrapDataSubject', Http_Response__c = String.valueOf(res), Incoming_from_External_System__c = true,Method__c = 'POST', Message__c = 'New Case Created', Success__c = 'true',Status_Code__c = '200', Code__c = 'API_NMDalarmCase_CREATED', Internal_Record_Identifier__c = caseNumberAsString);
                        insert ar;
                    }
                    
                } catch(Exception e){
                    API_Response__c ar = new API_Response__c();
                    ar.Internal_Record_Identifier__c = 'no record created';
                    ar.Code__c = 'API_NMDalarmCase_ERROR';
                    ar.Status_Code__c = '500';
                    ar.Success__c = 'false';
                    ar.Message__c = 'Error Creating Case ::: Service Summary Id ' + wrapDataSubject.serviceid;
                    ar.Method__c = 'POST';
                    ar.Incoming_from_External_System__c = true;
                    ar.Http_Response__c = String.valueOf(res);
                    ar.Http_Request__c=String.valueOf(req) + '\n\n wrapDataSubject';
                    ar.Endpoint__c='Case_NMDalarm ::: \\NMDalarm\\create\\';
                    insert ar;
                    HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' general error ::: Verify that Service Id exists as a Service Summary record in Salesforce ' + wrapDataSubject.serviceid + ' ::: '  + e, 'High');
                    
                } 
            } 
            // end handle a wrapper that includes a Subject
        } else {
            //retain prior functionality
            try{
                wrapData = (NMDCaseWrapper)System.JSON.deserialize(req.requestBody.toString(), NMDCaseWrapper.class);
            } catch(Exception e) {
                HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: wrapData deserialize Error ::: ' + e, 'High');                                      
            }
            
            if(String.isBlank(wrapData.casenumber) || String.isEmpty(wrapData.casenumber) || wrapData.casenumber == null){
                
                try{
                    String sid = wrapData.serviceid;
                    Case c = new Case();
                    c.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Case' AND Name = 'External Customer Support'].get(0).Id;
                    c.Support_Queue__c = 'TOC Support';
                    c.Origin = 'Automated Alert';
                    c.Status = 'New';
                    c.OwnerId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue'].get(0).Queue.Id;
                    c.Description = wrapData.logmsg;
                    
                    List<Service_Summary__c> sidq = [SELECT id FROM Service_Summary__c where name =: sid];
                    if(sidq.size()==1){
                        c.Service_ID__c = sidq.get(0).Id;
                    }
                    
                    c.Bypass_Validation_Reason__c = 'Asset Based Creation';
                    c.Pin_Verified__c = true;
                    c.Subject = 'NMD | ' + wrapData.alarmtype + ' | ' + wrapData.serviceid;
                    
                    insert c;
                    System.debug(c);
                    
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
                    API_Response__c ar = new API_Response__c();
                    ar.Endpoint__c = 'Case_NMDalarm ::: \\NMDalarm\\';
                    ar.Http_Request__c = String.valueOf(req) + '\n\n wrapdata';
                    ar.Http_Response__c = String.valueOf(res);
                    ar.Incoming_from_External_System__c = true;
                    ar.Method__c = 'POST';
                    ar.Message__c = 'New Case Created';
                    ar.Success__c = 'Success';
                    ar.Status_Code__c = '200';
                    ar.Code__c = 'API_NMDalarmCase_CREATED';
                    ar.Internal_Record_Identifier__c = caseNumberAsString;
                    insert ar;
                    
                    Automation_Analytics__c aa = new Automation_Analytics__c();
                    aa.Automation_Name__c = 'API_Case_NMDalarm_Ins';
                    aa.Automation_Type__c = 'Apex Class';
                    aa.Calculation_Explanation__c = 'Case creation: (estimate provided by Benjamin Hickey 8/29/23) without this, the NMD alarm board would need to be manually monitored and a case manually created for each alarm';
                    aa.Description__c = 'TOC';
                    aa.Time_Saved__c = 1;
                    insert aa;
                } catch(Exception e){
                    
                    HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' general error ::: Verify that Service Id exists as a Service Summary record in Salesforce ' + wrapData.serviceid + ' ::: '  + e, 'High');

                } 
            } else {
                try{
                    
                    Case r = [Select Id, Status, NMD_Alarm_Cleared__c, CaseNumber, Service_ID__c from Case where CaseNumber =: wrapData.casenumber].get(0);
                    
                    if(r.Status != 'Closed'){
                        
                        String cid = r.id;
                        String cn = wrapData.casenumber;
                        
                        Invocable.Action action = Invocable.Action.createStandardAction('chatterPost');
                        action.setInvocationParameter('text', 'ALARM RETRIGGERED');
                        action.setInvocationParameter('subjectNameOrId', cid);
                        List<Invocable.Action.Result> actionResults = action.invoke();
                        if (actionResults.size() > 0 && actionResults[0].isSuccess()) {
                            js.writeStringField('Status', 'Success');
                            js.writeIdField('CaseId', cid);
                        } else {
                            HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: chatter post was not created for case ::: ' + cid + ' ::: Alarm has been re-triggered ::: ', 'High'); 
                        }
                        
                        r.NMD_Alarm_Cleared__c = null;
                        r.Status = 'New';
                        
                        update r;
                        
                        List<Case> caseQueryResults = new List<Case>();
                        //on DML operations, Salesforce only autogenerates the ID, other 'auto-generated' fields must be queried for 
                        try{
                            caseQueryResults = [SELECT Id, CaseNumber FROM Case Where Id =: r.Id];
                        }catch(Exception e){
                            js.writeStringField('Status', 'Error');
                            js.writeStringField('Error', e.getMessage());   
                        }
                        
                        String caseNumberAsString = String.valueOf(caseQueryResults.get(0).CaseNumber);
                        
                        js.writeStringField('Status', 'Success');
                        js.writeIdField('Id', r.Id);
                        js.writeStringField('CaseNumber', caseNumberAsString);
                        
                        //API Response object creation for monitoring
                        API_Response__c ar = new API_Response__c();
                        ar.Endpoint__c='Case_NMDalarm ::: \\NMDalarm';
                        ar.Http_Request__c=String.valueOf(req) + '\n\n wrapdata';
                        ar.Http_Response__c = String.valueOf(res);
                        ar.Incoming_from_External_System__c = true;
                        ar.Method__c = 'POST';
                        ar.Message__c = 'Case Retriggered';
                        ar.Success__c = 'true';
                        ar.Status_Code__c = '200';
                        ar.Code__c = 'API_NMDalarmCase_UPDATED';
                        ar.Internal_Record_Identifier__c = caseNumberAsString;
                        insert ar;
                        
                        Automation_Analytics__c aa = new Automation_Analytics__c();
                        aa.Calculation_Explanation__c = 'Case retriggered: (estimate provided by Benjamin Hickey 8/29/23) without this, the NMD alarm board would need to be manually monitored and a case manually updated when the alarm occurred again';
                        aa.Time_Saved__c = 1;
                        aa.Description__c = 'TOC';
                        aa.Automation_Name__c = 'API_Case_NMDalarm_Ins';
                        aa.Automation_Type__c = 'Apex Class';
                        insert aa;
                        
                    } else {
                        Case cl = new Case(RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Case' AND Name = 'External Customer Support'].get(0).Id,Support_Queue__c = 'TOC Support',Origin = 'Automated Alert',Status = 'New',OwnerId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'TOC Queue'].get(0).Queue.Id,Description = wrapData.logmsg,Service_ID__c = r.Service_ID__c, Bypass_Validation_Reason__c = 'Asset Based Creation',Pin_Verified__c = true, Subject = 'NMD | ' + wrapData.alarmtype + ' | ' + wrapData.serviceid);
                        insert cl; 
                        List<Case> caseQueryResults = new List<Case>();
                        //on DML operations, Salesforce only autogenerates the ID, other 'auto-generated' fields must be queried for 
                        try{
                            caseQueryResults = [SELECT Id, CaseNumber FROM Case Where Id =: cl.Id];
                        }catch(Exception e){
                            js.writeStringField('Status', 'Error');
                            js.writeStringField('Error', e.getMessage());   
                        }
                        
                        Automation_Analytics__c aa = new Automation_Analytics__c(Time_Saved__c = 1, Description__c = 'TOC', Calculation_Explanation__c='Case creation: without this, the NMD alarm board would need to be manually monitored and a case manually created for each alarm', Automation_Type__c = 'Apex Class', Automation_Name__c = 'API_Case_NMDalarm_Ins');
                        insert aa;
                        
                        String caseNumberAsString = String.valueOf(caseQueryResults.get(0).CaseNumber);
                        
                        js.writeStringField('Status', 'Success');
                        js.writeIdField('Id', cl.Id);
                        js.writeStringField('CaseNumber', caseNumberAsString);
                        
                        //API Response object creation for monitoring        
                        API_Response__c ar = new API_Response__c(Endpoint__c='Case_NMDalarm ::: \\NMDalarm', Http_Request__c=String.valueOf(req) + '\n\n wrapdata', Http_Response__c = String.valueOf(res), Incoming_from_External_System__c = true,Method__c = 'POST', Message__c = 'New Case Created', Success__c = 'true',Status_Code__c = '200', Code__c = 'API_NMDalarmCase_CREATED', Internal_Record_Identifier__c = caseNumberAsString);
                        insert ar;
                    }
                    
                } catch(Exception e){
                    API_Response__c ar = new API_Response__c(Internal_Record_Identifier__c = 'no record created', Code__c = 'API_NMDalarmCase_ERROR', Status_Code__c = '500', Success__c = 'false', Message__c = 'Error Creating Case ::: Service Summary Id ' + wrapData.serviceid, Method__c = 'POST', Incoming_from_External_System__c = true, Http_Response__c = String.valueOf(res), Http_Request__c=String.valueOf(req) + '\n\n wrapdata', Endpoint__c='Case_NMDalarm ::: \\NMDalarm\\create\\');
                    insert ar;

                    HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' general error ::: Verify that Service Id exists as a Service Summary record in Salesforce ' + wrapData.serviceid + ' ::: '  + e, 'High');
                    
                } 
            }
            // end retain prior functionality
        }
        
        
        
        
        
        js.writeEndObject();
        String result = js.getAsString();
        
        return result;
    }
    global static String doClearPost(RestRequest req, RestResponse res){
        //update Case from an NMD Alarm with Cleared Post
        system.debug('request is '+req);
        system.debug('Response is '+res);
        
        System.JSONGenerator js = JSON.createGenerator(false);
        NMDAlarmClearedWrapper wrapData = new NMDAlarmClearedWrapper();
        
        try{
            wrapData = (NMDAlarmClearedWrapper)System.JSON.deserialize(req.requestBody.toString(), NMDAlarmClearedWrapper.class);
        } 
        catch(Exception e) {
            HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: wrapData deserialize Error ::: ' + e, 'High');                                      
        }
        
        js.writeStartObject();
        system.debug('WrapData is '+wrapData);
        try{
            
            String cn = wrapData.casenumber;
            String cid;
            Case cs = new Case();
            try{
                cs = [SELECT Id, OwnerId, CaseNumber FROM Case WHERE CaseNumber =: cn].get(0);
                cid = cs.Id;
                System.debug('cid ' + cid);
            }catch(Exception e){                
                HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: case number does not exist in Salesforce ::: ' + cn + ' ::: Alarm has been cleared ::: ' + e, 'High'); 
                js.writeStringField('Status', 'Error');
                js.writeStringField('Error', 'case number does not exist in Salesforce' + e.getMessage());  
            }
            
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.AssignmentRuleHeader.useDefaultRule=false;
            dmo.assignmentRuleHeader.assignmentRuleId='01QRo0000002YonMAE';
            
            cs.NMD_Alarm_Cleared__c = Datetime.now();
            //update cs;
            cs.setOptions(dmo);
            Database.update(cs);
            
            Invocable.Action action = Invocable.Action.createStandardAction('chatterPost');
            action.setInvocationParameter('text', 'ALARM CLEARED');
            action.setInvocationParameter('subjectNameOrId', cid);
            List<Invocable.Action.Result> actionResults = action.invoke();
            if (actionResults.size() > 0 && actionResults[0].isSuccess()) {
                js.writeStringField('Status', 'Success');
                js.writeIdField('CaseId', cid);
            } else {
                HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: chatter post was not created for case ::: ' + cid + ' ::: Alarm has been cleared ::: ', 'High'); 
            }
            
            //API Response object creation for monitoring        
            API_Response__c ar = new API_Response__c();
            ar.Endpoint__c = 'Case_NMDalarm ::: \\NMDalarm\\clear\\';
            ar.Http_Request__c = String.valueOf(req) + '\n\n wrapdata';
            ar.Http_Response__c = String.valueOf(res);
            ar.Incoming_from_External_System__c = true;
            ar.Method__c = 'POST';
            ar.Message__c = 'Alarm Cleared, chatter post created on case ' + cn;
            ar.Success__c = 'Success';
            ar.Status_Code__c = '200';
            ar.Code__c = 'API_NMDalarmCase_CLEARED'; 
            ar.Internal_Record_Identifier__c = cid;
            insert ar;
            
            Automation_Analytics__c aa = new Automation_Analytics__c();
            aa.Automation_Name__c = 'API_Case_NMDalarm_Ins';
            aa.Automation_Type__c = 'Apex Class'; 
            aa.Calculation_Explanation__c = 'Case clear: (estimate provided by Benjamin Hickey 8/29/23) without this, the NMD alarm board would need to be manually monitored and a case manually updated each time an alarm was cleared';
            aa.Description__c = 'TOC';
            aa.Time_Saved__c = 1;
            insert aa;
            
        } catch(Exception e){
            API_Response__c ar = new API_Response__c();
            ar.Endpoint__c='Case_NMDalarm ::: \\NMDalarm\\clear\\';
            ar.Http_Request__c=String.valueOf(req) + '\n\n wrapdata';
            ar.Http_Response__c = String.valueOf(res);
            ar.Incoming_from_External_System__c = true;
            ar.Method__c = 'POST';
            ar.Message__c = 'Error Posting to Case ::: Case Number ' + wrapData.casenumber;
            ar.Success__c = 'false';
            ar.Status_Code__c = '500';
            ar.Code__c = 'API_NMDalarmCase_ERROR';
            ar.Internal_Record_Identifier__c = 'no chatter post created';
            
            insert ar;
            
            js.writeStringField('Status', 'Error');
            js.writeStringField('Error', e.getMessage() + '  Verify that case number exists in Salesforce');
            HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' general error ::: Verify that case number exists in Salesforce ' + wrapData.casenumber + ' ::: '  + e, 'High');
        }
        
        js.writeEndObject();
        String result = js.getAsString();
        
        return result;
    }
    global static String doInvalidCall(RestRequest req, RestResponse res, String invalidUrl){
        System.JSONGenerator js = JSON.createGenerator(false);      
        
        HLP_Case_SFQueue_Ins.createSFQueueCase('API_Case_NMDalarm_Ins', ' ::: Invalid API Call ' + invalidUrl + ' ::: ', 'Medium');                                      
        API_Response__c ar = new API_Response__c();
        ar.Endpoint__c='Case_NMDalarm ::: \\NMDalarm\\' + invalidUrl + '\\';
        ar.Http_Request__c=String.valueOf(req) + '\n\n wrapdata';
        ar.Http_Response__c = String.valueOf(res);
        ar.Incoming_from_External_System__c = true;
        ar.Method__c = 'POST';
        ar.Message__c = 'Error in URL ::: '; 
        ar.Success__c = 'false';
        ar.Status_Code__c = '500';
        ar.Code__c = 'API_NMDalarmCase_InvalidURL';
        ar.Internal_Record_Identifier__c = 'API call was invalid';
        
        js.writeStartObject();
        js.writeStringField('Status', 'Error');
        js.writeStringField('Error', 'Invalid API Call to NMDalarm, ' + invalidUrl + ' is invalid');  
        
        js.writeEndObject();
        String result = js.getAsString();
        
        return result;
    }
    
}