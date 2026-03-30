/*************************************************
* Name: API_OPSramp_GenMaintWin_QUE
* Description: Queueable class that handles client-specific logic, verifies listed devices against OpsRamp devices listed for the client, and groups devices in batches of 100 to send.
* Related Classes: 
    - API_OPSramp_GenMaintW_UTL
	- INV_API_OPSramp_GenMaintWin_INS
	- API_OPSramp_GenMaintW_HLP
	- API_OPSramp_GetDevicesForTenant_QRY
	- API_OPSramp_GenMaintWin_QUE_CallOut
	- HLP_Case_SFQueue_Ins
	- HLP_GenericCreate_UTL
* Test class: API_OPSramp_GenMaintWin_QUE_Test
* ***********************************************/

public class API_OPSramp_GenMaintWin_QUE implements Queueable, Database.AllowsCallouts {
    
    private String clientId;
    private List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> events;
    
    public API_OPSramp_GenMaintWin_QUE(String clientId, List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> events) {
        this.clientId = clientId;
        this.events = events;
    }
    
/*************************************************
* Method Name: execute
* Description: Queueable execute method that handles client-specific logic, verifies listed devices against OpsRamp devices listed for the client, and groups devices in batches of 100 to send.
* ***********************************************/ 
    
    public void execute(QueueableContext context) {
        //for any cases that need to be created after these callouts run
        List<API_OPSramp_GenMaintW_UTL.CaseHolder> cases = new List<API_OPSramp_GenMaintW_UTL.CaseHolder>();
        List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder> helpCases = new List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder>();
        String queueId;
        try{
            queueId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'Ops - Monitoring'].get(0).Queue.Id;
        } catch (Exception e){
            API_OPSramp_GenMaintW_UTL.HelpCaseHolder helpCase = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
            helpCase.description = 'API_OPSramp_GenMaintWin_QUE error querying queuesobject.  Ensure that the queue.name for Ops - Monitoring has not been changed. Message ::: ' + e.getMessage();
            helpCases.add(helpCase);
        }
        
        //variables to set and send to callout
        DateTime startDate;
        DateTime endDate;
        String caseNumber;     
        Integer maintWindowIndex = 0;
        
        //initial request to OpsRamp to get all devices for comparison
        List<API_OPSramp_GetDevicesForTenant_QRY.Device> allDevices = API_OPSramp_GetDevicesForTenant_QRY.getDevicesForTenantFromOpsRamp(clientId);
        
        //loop all Devices to get list of device Ids for comparisons
        List<String> allDeviceIds = new List<String>();
        List<String> allHostNames = new List<String>();
        Map<String, String> mapHostNameToDeviceId = new Map<String, String>();
        
        if(!allDevices.isEmpty() && allDevices != null){
            for(API_OPSramp_GetDevicesForTenant_QRY.Device d : allDevices){
                allDeviceIds.add(d.uniqueId);
                allHostNames.add(d.hostName);
                mapHostNameToDeviceId.put(d.hostName, d.uniqueId);
            }
        }
        
        // Process events and validate devices
        List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent> validatedEvents = new List<API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent>();
        
        for(API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent e : events){
            System.debug('Processing event: ' + e.deviceMaintenanceUniqueId);  
            
            startDate = e.startDateTime;
            endDate = e.endDateTime;
            caseNumber = e.caseNumber;
            
            //check if the list of Devices from OpsRamp for this client contains the device ID for this downtime event
            if(e.deviceMaintenanceUniqueId == null || e.deviceMaintenanceUniqueId == ''){
                if(!allHostNames.isEmpty() && allHostNames.contains(e.hostName)){
                    e.deviceMaintenanceUniqueId = mapHostNameToDeviceId.get(e.hostName);
                    validatedEvents.add(e);
                } else {
                    API_OPSramp_GenMaintW_UTL.CaseHolder c = new API_OPSramp_GenMaintW_UTL.CaseHolder();
                    c.subject = c.subject + '  No device found';
                    c.description = 'Error for case number: ' + e.caseId + ' No device found for hostName: ' + e.hostName + ' with client: ' + e.clientId;
                    c.ownerId = queueId;
                    cases.add(c);
                }
            } else if(!allDeviceIds.isEmpty() && allDeviceIds.contains(e.deviceMaintenanceUniqueId)){
                validatedEvents.add(e);
            } else {
                API_OPSramp_GenMaintW_UTL.CaseHolder c = new API_OPSramp_GenMaintW_UTL.CaseHolder();
                c.subject = c.subject + '  Device Unique ID does not exist for client';
                c.description = 'Error for case number: ' + e.caseId + ' Device unique ID: ' + e.deviceMaintenanceUniqueId + ' Host name: ' + e.hostName + ' does not exist for client: ' + e.clientId;
                c.ownerId = queueId;
                cases.add(c);
            }
        }
        
        // Group validated events into batches of 100 and create maintenance windows
        List<MaintenanceWindowHolder> windowHolders = new List<MaintenanceWindowHolder>();
        List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice> currentBatch = new List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice>();
        List<String> dteIds = new List<String>();
        
        for(API_OPSramp_GenMaintW_UTL.ApexDowntimeEvent validEvent : validatedEvents) {
            API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice sd = new API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice();
            sd.uniqueId = validEvent.deviceMaintenanceUniqueId;
            currentBatch.add(sd);
            dteIds.add(validEvent.downtimeEventId);
            
            // Create a batch when we reach 100 devices or at the end
            if(currentBatch.size() >= 100 || validEvent == validatedEvents[validatedEvents.size()-1]) {
                maintWindowIndex++;
                
                MaintenanceWindowHolder mwh = new MaintenanceWindowHolder();
                mwh.clientId = clientId;
                mwh.sendDevices = currentBatch.clone();
                mwh.startDate = startDate.format('yyyy-MM-dd\'T\'HH:mm:ss');
                mwh.endDate = endDate.format('yyyy-MM-dd\'T\'HH:mm:ss');
                mwh.caseNumber = caseNumber;
                mwh.maintWindowIndex = maintWindowIndex;
                mwh.downtimeEventIds = dteIds.clone();
                windowHolders.add(mwh);
                
                currentBatch.clear();
                dteIds.clear();
            }
        }
        
        // Queue callouts for each maintenance window
        for(MaintenanceWindowHolder m : windowHolders){
            API_OPSramp_GenMaintWin_QUE_CallOut calloutJob = new API_OPSramp_GenMaintWin_QUE_CallOut(m);
            System.enqueueJob(calloutJob);
        }
        
        // Handle cases
        if(!cases.isEmpty()){
            for(API_OPSramp_GenMaintW_UTL.CaseHolder ch : cases){
                HLP_GenericCreate_UTL.createGenericCase(ch.subject, ch.description, ch.supportQueue, ch.caseGroup, ch.ownerID, ch.isBulk);
            }
        } 
        if(!helpCases.isEmpty()){
            for(API_OPSramp_GenMaintW_UTL.HelpCaseHolder hc : helpCases){
                System.debug('HelpCase creation: ' + hc.subject + ' ::: ' + hc.description);
                HLP_Case_SFQueue_Ins.createSFQueueCase(hc.subject, hc.description, hc.casePriority);
            }
        } 
    }

    /*************************************************
* Name: MaintenanceWindowHolder
* Description: Apex class for holding Maintenance Window information so that the callout to OpsRamp can receive the correct information.
* Used by classes: 
	- API_OPSramp_GenMaintWin_QUE
	- API_OPSramp_GenMaintWin_QUE_CallOut
* ***********************************************/  
    public class MaintenanceWindowHolder{
        public String clientId;
        public List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice> sendDevices;
        public String startDate; 
        public String endDate; 
        public String caseNumber; 
        public Integer maintWindowIndex;
        public List<String> downtimeEventIds;
    }
}