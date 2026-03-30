/*************************************************
* Name: INV_API_OPSramp_GenMaintWin_INS
* Description: Invocable action class that is used by a flow trigger to create maintenance windows from downtime events & configuration items in the external system OpsRamp
* Called by flow: Case - OpsRamp - Generate Maintenance Window
* Related Classes: 
	- API_OPSramp_GenMaintWin_HLP
	- API_OPSramp_GenMaintWin_FUT
	- API_OPSramp_GetDevicesForTenant_QRY
	- API_OPSramp_GenMaintWin_INS
	- HLP_Case_SFQueue_Ins
	- HLP_GenericCreate_UTL
* Test class: INV_API_OPSramp_GenMaintWin_INS_Test
* ***********************************************/

public class INV_API_OPSramp_GenMaintWin_INS {
    
    public class InputVariables{
        @InvocableVariable
        public Case inputCase;
    }
    
/*************************************************
* Method Name: generateMaintenanceWindowInOpsRamp
* Description: Invocable action method that is used by a flow trigger to create maintenance windows from downtime events & configuration items in the external system OpsRamp
* ***********************************************/   
        
    @InvocableMethod(label='OpsRamp Generate Maintenance window' description='generates a maintenance window in Ops Ramp using information from the change request case')
    public static void generateMaintenanceWindowInOpsRamp(List<InputVariables> ivs){
        
        List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder> bulkHelpCases = new List<API_OPSramp_GenMaintW_UTL.HelpCaseHolder>();
        for(InputVariables i : ivs){
            try{
                API_OPSramp_GenMaintW_HLP.generateMaintWindow(i.inputCase.Id);
                System.debug(i.inputCase.Id);   
            } catch(Exception e){
                API_OPSramp_GenMaintW_UTL.HelpCaseHolder caseHolder = new API_OPSramp_GenMaintW_UTL.HelpCaseHolder();
                caseHolder.subject = caseHolder.subject + 'OpsRamp Generate Maintenance window Unhandled Exception';
                caseHolder.description = 'OpsRamp Generate Maintenance window Unhandled Exception ::: ' + e.getMessage();
                bulkHelpCases.add(caseHolder);
            }
        }
    }
}