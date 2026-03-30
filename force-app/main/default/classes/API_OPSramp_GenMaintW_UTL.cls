/*************************************************
* Name: API_OPSramp_GenMaintW_UTL
* Description: Helper class that handles initial logic from all clients/devices that were listed in the change request.
* Related Classes: 
    - API_OPSramp_GenMaintW_HLP
	- INV_API_OPSramp_GenMaintWin_INS
	- API_OPSramp_GenMaintWin_QUE
	- API_OPSramp_GetDevicesForTenant_QRY
	- API_OPSramp_GenMaintWin_QUE_CallOut
	- HLP_Case_SFQueue_Ins
	- HLP_GenericCreate_UTL
* Test class: API_OPSramp_GenMaintW_UTL_Test
* ***********************************************/

public class API_OPSramp_GenMaintW_UTL {
/*************************************************
* Name: ApexDowntimeEvent
* Description: Apex class for holding the initial change request information.
* Used by classes: 
	- API_OPSramp_GenMaintW_HLP
	- API_OPSramp_GenMaintWin_QUE
* ***********************************************/    
    
    public class ApexDowntimeEvent{
        public String caseId;
        public String configurationId;
        public DateTime startDateTime;
        public DateTime endDateTime;
        public String deviceMaintenanceUniqueId;
        public String clientId;
        public String hostName;
        public String caseNumber;
        public String downtimeEventId;
    }
    
    /*************************************************
* Name: CaseHolder
* Description: Apex class for holding case information so that cases can be sent after callouts are made.
* Used by classes: 
	- API_OPSramp_GenMaintWin_QUE
	- API_OPSramp_GenMaintW_HLP
* ***********************************************/        
    public class CaseHolder{
        public String ownerID;
        public String supportQueue = 'Unassigned';
        public String caseGroup = 'OPS - Monitoring';
        public Boolean isBulk = false;
        public String subject = 'API_OPSramp_GenMaintWin process failed.';
        public String description = '';
    }
    
    /*************************************************
* Name: HelpCaseHolder
* Description: Apex class for holding Salesforce Support case information so that cases can be sent after callouts are made.
* Used by classes: 
	- API_OPSramp_GenMaintWin_QUE
	- API_OPSramp_GenMaintW_HLP
	- INV_API_OPSramp_GenMaintWin_INS
	- API_OPSramp_GetDevicesForTenant_QRY
	- API_OPSramp_GenMaintWin_QUE_CallOut
* ***********************************************/   
    public class HelpCaseHolder{
        public String subject = 'API_OPSramp_GenMaintWin process failed with errors.';
        public String description;
        public String casePriority = 'Medium';
    }
}