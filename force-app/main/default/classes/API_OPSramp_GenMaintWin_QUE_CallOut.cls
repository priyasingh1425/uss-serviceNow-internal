/*************************************************
* Name: API_OPSramp_GenMaintWin_QUE_CallOut
* Description: Queueable callout class to OpsRamp to create maintenance windows for a specific client (up to 100 devices included per call).
* Related Classes: 
- API_OPSramp_GenMaintW_UTL
- INV_API_OPSramp_GenMaintWin_INS
- API_OPSramp_GenMaintW_HLP
- API_OPSramp_GenMaintWin_QUE
- API_OPSramp_GetDevicesForTenant_QRY
- HLP_Case_SFQueue_Ins
- HLP_GenericCreate_UTL
* Test classes: 
- API_OPSramp_GenMaintWin_QUE_CallOut_Test
- API_OPSramp_WrapperClasses_Test

* ***********************************************/
public class API_OPSramp_GenMaintWin_QUE_CallOut implements Queueable, Database.AllowsCallouts {
    
    private API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder maintWindowHolder;
    
    public API_OPSramp_GenMaintWin_QUE_CallOut(API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder maintWindowHolder) {
        this.maintWindowHolder = maintWindowHolder;
    }
    
    /*************************************************
* Method Name: execute
* Description: Queueable execute method that performs callout to OpsRamp to create maintenance windows for a specific client (up to 100 devices included per call).
* ***********************************************/
    public void execute(QueueableContext context) {
        //this callout creates maintenance windows for a client for each downtime event
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        req.setHeader('Content-Type', 'application/json');
        
        //for any cases that need to be created after these callouts run
        List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder> helpCases = new List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder>();
        //for downtime events that need to be updated post callouts
        List<Downtime_Event__c> downEvents = new List<Downtime_Event__c>();
        
        try{
            String name = maintWindowHolder.caseNumber + ' - ' + String.valueOf(System.NOW()) + ' - ' + maintWindowHolder.clientId + ' - ' + String.valueOf(maintWindowHolder.maintWindowIndex);
            System.debug('Name ::: ' + name);
            
            SendSchedule sched = new SendSchedule();
            sched.type = 'One-Time';
            sched.endTime = maintWindowHolder.endDate;
            sched.startTime = maintWindowHolder.startDate;
            sched.timezone = 'GMT';
            
            SendEventWrapper scheduleMaintenance = new SendEventWrapper();
            scheduleMaintenance.name = name;
            scheduleMaintenance.description = name;
            scheduleMaintenance.devices = maintWindowHolder.sendDevices;
            scheduleMaintenance.schedule = sched;
            
            req.setEndpoint('callout:OpsRamp_Oauth' +'/api/v2/tenants/' + maintWindowHolder.clientId +'/scheduleMaintenances');
            System.debug('Endpoint with ID ::: ' + req.getEndpoint());
            req.setMethod('POST');
            
            //set body
            try{
                req.setBody(JSON.serialize(scheduleMaintenance));  
                System.debug('requestBody ::: ' + req.getBody());          
            } catch (Exception e){
                System.debug('Error serializing scheduleMaintenance: ' + e.getMessage());
                API_OPSramp_GenMaintW_UTL.HelpCaseHolder c = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
                c.description = 'Failed to serialize scheduleMaintenance. Error: ' + e.getMessage();
                helpCases.add(c);
            } 
            
            //send request        
            if(maintWindowHolder.sendDevices.isEmpty()){
                //DO NOT SEND
                API_OPSramp_GenMaintW_UTL.HelpCaseHolder c = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
                c.description = 'This is a bug, there are no devices.  Address this in code';
                helpCases.add(c);
            } else {
                res = http.send(req);
                system.debug(res.getBody());
            } 
            
        } catch (Exception e){
            API_OPSramp_GenMaintW_UTL.HelpCaseHolder c = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
            c.subject = c.subject + '  !!! Callout Failed!!!';
            c.description = 'Callout to generate Maintenance Windows failed. Error: ' + e.getMessage();
            helpCases.add(c);
            
            API_Response__c ar = new API_Response__c();
            ar.Method__c = 'POST'; 
            ar.Success__c = 'false';
            ar.Endpoint__c = 'https://oneneck.api.opsramp.com/api/v2/tenants/%7BTenantID%7D/scheduleMaintenances'; 
            ar.Http_Request__c = req.getBody() != null ? req.getBody().left(32765) : '';
            ar.Http_Response__c = res.getBody() != null ? res.getBody().left(32765) : ''; 
            ar.Status_Code__c = String.valueOf(res.getStatusCode()); 
            ar.Message__c = 'Maintenance Windows FAILED for client: ' + maintWindowHolder.clientId;
            ar.Wrapper__c = 'API_OPSramp_GenMaintWin_QUE_CallOut.sendEventWrapper';
            ar.Code__c = 'OpsRamp_MaintenanceWindow_FAILED';
            insert ar;
        }
        
        if(res.getStatusCode() != 200){ 
            
            if(!maintWindowHolder.downtimeEventIds.isEmpty()){
                for(String s : maintWindowHolder.downtimeEventIds){
                    Downtime_Event__c curEvent = new Downtime_Event__c();
                    curEvent.Id = s;
                    curEvent.Status__c = 'Failed';
                    curEvent.Notes__c = res.getBody() != null ? res.getBody().left(32765) : '';
                    downEvents.add(curEvent);
                }
                
            }
            
            API_Response__c ar = new API_Response__c();
            ar.Method__c = 'POST'; 
            ar.Success__c = 'false';
            ar.Endpoint__c = 'https://oneneck.api.opsramp.com/api/v2/tenants/%7BTenantID%7D/scheduleMaintenances'; 
            ar.Http_Request__c = req.getBody() != null ? req.getBody().left(32765) : '';
            ar.Http_Response__c = res.getBody() != null ? res.getBody().left(32765) : ''; 
            ar.Status_Code__c = String.valueOf(res.getStatusCode()); 
            ar.Message__c = 'Maintenance Windows FAILED for client: ' + maintWindowHolder.clientId;
            ar.Wrapper__c = 'API_OPSramp_GenMaintWin_QUE_CallOut.sendEventWrapper';
            ar.Code__c = 'OpsRamp_MaintenanceWindow_FAILED';
            insert ar;
            
            API_OPSramp_GenMaintW_UTL.HelpCaseHolder c = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
            c.subject = c.subject + '  !!! Callout Failed!!!';
            c.description = 'Callout to generate Maintenance Windows failed. Error: see API Response: ' + ar.Id;
            helpCases.add(c);
            
            
        } else {
            API_Response__c ar = new API_Response__c();
            ar.Method__c = 'POST'; 
            ar.Success__c = 'true';
            ar.Endpoint__c = 'https://oneneck.api.opsramp.com/api/v2/tenants/%7BTenantID%7D/scheduleMaintenances'; 
            ar.Http_Request__c = req.getBody() != null ? req.getBody().left(32765) : '';
            ar.Http_Response__c = res.getBody() != null ? res.getBody().left(32765) : ''; 
            ar.Status_Code__c = String.valueOf(res.getStatusCode()); 
            ar.Message__c = 'Maintenance Windows Scheduled in OpsRamp for client: ' + maintWindowHolder.clientId;
            ar.Wrapper__c = 'API_OPSramp_GenMaintWin_QUE_CallOut.sendEventWrapper';
            ar.Code__c = 'OpsRamp_MaintenanceWindow_CREATED';
            insert ar;
            
            String jsonBody = res.getBody();
            Response parsedResponse = (Response) JSON.deserialize(jsonBody, Response.class);
            System.debug('Scheduled Maintenance ID: ' + parsedResponse.uniqueId);
            
            for(String s : maintWindowHolder.downtimeEventIds){
                Downtime_Event__c curEvent = new Downtime_Event__c();
                curEvent.Id = s;
                curEvent.Scheduled_ID__c = parsedResponse.uniqueId;
                curEvent.Status__c = 'Scheduled';
                downEvents.add(curEvent);
            }
            
        }
        
        List<Database.SaveResult> srList = Database.update(downEvents, false);
        
        List<String> exception_list = new List<String>();
        for(Database.SaveResult sr : srList){
            if(!sr.isSuccess()){
                for (Database.Error err : sr.getErrors()) {
                    String errMsg = 'The following error occurred for record ID: ' + sr.getId() + ' With the status code: ' + err.getStatusCode() + ' Error Message: ' + err.getMessage();
                    System.debug(errMsg);
                    exception_list.add(errMsg);
                }
            }
        }
        
        if(!exception_list.isEmpty()){
            API_OPSramp_GenMaintW_UTL.HelpCaseHolder c = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
            c.subject = c.subject + '  Update Salesforce Downtime Events failed';
            c.description = String.join(exception_list, ' || ');
            helpCases.add(c);
        }
        
        for(API_OPSramp_GenMaintW_UTL.HelpCaseHolder hc : helpCases){
            System.debug('HelpCase creation: ' + hc.subject + ' ::: ' + hc.description);
            HLP_Case_SFQueue_Ins.createSFQueueCase(hc.subject, hc.description, hc.casePriority);
        }
    }
    
    /*************************************************
* Name: SendEventWrapper
* Description: Apex class for wrapping the JSON send to OpsRamp.  Optional variables that are not sent are included and commented out.  Structure based on OpsRamp API resource documentation.
* Used by classes: 
- API_OPSramp_GenMaintWin_QUE_CallOut
* ***********************************************/     
    public class SendEventWrapper{
        public String name;
        public String description;
        //public Boolean runRBA;
        //public Boolean installPatch;
        //public Boolean correlateAlerts;
        public List<SendDevice> devices;
        //public List<DeviceGroup> deviceGroups;
        //public List<DeviceLocations> locations;
        public SendSchedule schedule;
    }
    
    /*************************************************
* Name: SendDevice
* Description: Apex class for wrapping the JSON send to OpsRamp.  Optional variables that are not sent are included and commented out.  Structure based on OpsRamp API resource documentation.
* Used by classes: 
- API_OPSramp_GenMaintWin_QUE_CallOut
- API_OPSramp_GenMaintWin_QUE
* ***********************************************/
    public class SendDevice{
        public String uniqueId;
    }
    
    /*************************************************
* Name: SendSchedule
* Description: Apex class for wrapping the JSON send to OpsRamp.  Optional variables that are not sent are included and commented out.  Structure based on OpsRamp API resource documentation.
* Used by classes: 
- API_OPSramp_GenMaintWin_QUE_CallOut
* ***********************************************/
    public class SendSchedule{
        public String type;
        public String startTime;
        public String endTime;
        public String timezone;
        //public Pattern pattern;
    }
    
    /*************************************************
* Name: DeviceGroup
* Description: Apex class for wrapping the JSON send to OpsRamp.  Optional variables that are not sent are included and commented out.  Structure based on OpsRamp API resource documentation.
* Used by classes: (not in use, optional)
* ***********************************************/    
    public class DeviceGroup{
        public String name;
        public String id;
    }
    
    /*************************************************
* Name: DeviceLocations
* Description: Apex class for wrapping the JSON send to OpsRamp.  Optional variables that are not sent are included and commented out.  Structure based on OpsRamp API resource documentation.
* Used by classes: (not in use, optional)
* ***********************************************/    
    public class DeviceLocations{
        public String name;
        public String id;
    }
    
    /*************************************************
* Name: Pattern
* Description: Apex class for wrapping the JSON send to OpsRamp.  Optional variables that are not sent are included and commented out.  Structure based on OpsRamp API resource documentation.
* Used by classes: (not in use, optional)
* ***********************************************/    
    public class Pattern{
        public String type;
        public String weekDays;
    }
    
    /*************************************************
* Name: Response
* Description: Apex class for deserializing the JSON response.  Structure based on OpsRamp API resource documentation.
* Used by classes: API_OPSramp_GenMaintWin_QUE_CallOut
* ***********************************************/   
    public class Response{
        public String uniqueId;
    }
}