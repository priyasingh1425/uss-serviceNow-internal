/*************************************************
* Name: API_OPSramp_GenMaintW_HLP
* Description: Helper class that handles initial logic from all clients/devices that were listed in the change request.
* Related Classes: 
    - API_OPSramp_GenMaintW_UTL
	- INV_API_OPSramp_GenMaintWin_INS
	- API_OPSramp_GenMaintWin_QUE
	- API_OPSramp_GetDevicesForTenant_QRY
	- API_OPSramp_GenMaintWin_QUE_CallOut
	- HLP_Case_SFQueue_Ins
	- HLP_GenericCreate_UTL
* Test class: API_OPSramp_GenMaintW_HLP_Test
* ***********************************************/

public class API_OPSramp_GenMaintW_HLP{
    
/*************************************************
* Method Name: generateMaintWindow
* Description: Method that takes in a change request case and handles the initial logic from all clients/devices that were listed in the change request.  No callouts here directly, just queries and data arrangement.
* ***********************************************/ 
    
    public static void generateMaintWindow(Id inputCase){
        //get user's timezone offset for datetime calculation
        TimeZone userTimeZone = UserInfo.getTimeZone();
        Integer gmtOffsetMilliseconds = userTimeZone.getOffset(DateTime.now());
        Integer gmtOffsetHours = (gmtOffsetMilliseconds / (1000 * 60 * 60))*-1;
        
        //for any cases that need to be created after these callouts run
        List<API_OPSramp_GenMaintW_UTL.CaseHolder> cases = new List<API_OPSramp_GenMaintW_UTL.CaseHolder>();
        List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder> helpCases = new List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder>();
        
        //for downtime events that need to be updated as failures prior to callouts
        List<Downtime_Event__c> failedDownEvents = new List<Downtime_Event__c>();
        
        String queueId;
        try{
            queueId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'Ops - Monitoring'].get(0).Queue.Id;
        } catch (Exception e){
            API_OPSramp_GenMaintW_UTL.HelpCaseHolder helpCase = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
            helpCase.description = 'API_OPSramp_GenMaintW_HLP error querying queuesobject.  Ensure that the queue.name for Ops - Monitoring has not been changed. Message ::: ' + e.getMessage();
            helpCases.add(helpCase);
        }
        List<Downtime_Event__c> downEvents = new List<Downtime_Event__c>();
        try{
          downEvents = [Select Case__r.Id, Configuration_Item__r.Id, Start_Date_Time__c, End_Date_Time__c, Configuration_Item__r.Device_Maintenance_UniqueID__c, Configuration_Item__r.Device_Maintenance_ClientID__c, Configuration_Item__r.Name, Case__r.CaseNumber, Configuration_Item__r.Monitoring_System__c, Id  from Downtime_Event__c where Case__r.Id =: inputCase]; 
        } catch (Exception e) {
            API_OPSramp_GenMaintW_UTL.HelpCaseHolder helpCase = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
            helpCase.description = 'API_OPSramp_GenMaintW_HLP error querying Downtime_Event__c.  Error retreiving the following fields: Case__r.Id, Configuration_Item__r.Id, Start_Date_Time__c, End_Date_Time__c, Configuration_Item__r.Device_Maintenance_UniqueID__c, Configuration_Item__r.Device_Maintenance_ClientID__c, Configuration_Item__r.Name, Case__r.CaseNumber ::: ensure nothing has changed ::: ' + e.getMessage();
            helpCases.add(helpCase);
        }
        //maps client ID to related list of downtime events
        Map<String, List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>> clientMap = new Map<String, List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>>();
        
        //get unique client IDs
        Set<String> clientUniqIds = new Set<String>();
        
        for(Downtime_Event__c d : downEvents){
            if(d.Configuration_Item__r.Monitoring_System__c == 'OpsRamp'){
                if(d.Configuration_Item__r.Device_Maintenance_ClientID__c == null || d.Configuration_Item__r.Device_Maintenance_ClientID__c == ''){
                    API_OPSramp_GenMaintW_UTL.CaseHolder c = new API_OPSramp_GenMaintW_UTL.CaseHolder();
                    c.subject = c.subject + '  No Client Id specified' ;
                    c.description = 'Error for case number: ' + d.Case__r.Id + ' No client Id found for hostName: ' + d.Configuration_Item__r.Name + ' with device maintenance unique Id: ' + d.Configuration_Item__r.Device_Maintenance_UniqueID__c;
                    c.ownerID = queueId;
                    cases.add(c);
                } else {
                    clientUniqIds.add(d.Configuration_Item__r.Device_Maintenance_ClientID__c);
                }
            } else {
                d.Status__c = 'Failed';
                d.Notes__c = 'Monitoring System is not listed as OpsRamp.  Listed Monitoring System for this Configuration Item: ' + d.Configuration_Item__r.Monitoring_System__c;
                failedDownEvents.add(d);
            }

        }
        
        //map client ID to related list of downtime events
        for(String cid : clientUniqIds){
            List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> eventsForClient = new List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>();
            
            for(Downtime_Event__c de : downEvents){
                if(cid == de.Configuration_Item__r.Device_Maintenance_ClientID__c){
                    API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent ade = new API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent();
                    ade.caseId = de.Case__r.Id;
                    ade.configurationId = de.Configuration_Item__r.Id;
                    ade.startDateTime = de.Start_Date_Time__c.addHours(gmtOffsetHours);
                    ade.endDateTime = de.End_Date_Time__c.addHours(gmtOffsetHours);
                    ade.deviceMaintenanceUniqueId = de.Configuration_Item__r.Device_Maintenance_UniqueID__c;
                    ade.clientId = de.Configuration_Item__r.Device_Maintenance_ClientID__c;
                    ade.hostName = de.Configuration_Item__r.Name;
                    ade.caseNumber = de.Case__r.CaseNumber;
                    ade.downtimeEventId = de.Id;
                    
                    eventsForClient.add(ade);
                }
            }
            
            clientMap.put(cid, eventsForClient);
        }
        
        // Queue the device verification and maintenance window creation for each client
        for(String clientId : clientMap.keySet()){
            API_OPSramp_GenMaintWin_QUE queueableJob = new API_OPSramp_GenMaintWin_QUE(clientId, clientMap.get(clientId));
            System.enqueueJob(queueableJob);
        }
        
        // Handle immediate cases
        for(API_OPSramp_GenMaintW_UTL.CaseHolder ch : cases){
            HLP_GenericCreate_UTL.createGenericCase(ch.subject, ch.description, ch.supportQueue, ch.caseGroup, ch.ownerID, ch.isBulk);
        }
        for(API_OPSramp_GenMaintW_UTL.HelpCaseHolder hc : helpCases){
            System.debug('HelpCase creation: ' + hc.subject + ' ::: ' + hc.description);
            HLP_Case_SFQueue_Ins.createSFQueueCase(hc.subject, hc.description, hc.casePriority);
        }
        
        if(!failedDownEvents.isEmpty()){
            update failedDownEvents;
        }
        
    }
}