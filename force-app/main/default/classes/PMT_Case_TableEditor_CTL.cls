/*************************************************
* Name: PMT_Case_TableEditor_CTL
* Description: Helper for Case Table related components:
            - PMT_Case_TableEditor_FRL.cmp

* Test class: PMT_Case_TableEditor_TEST
* ***********************************************/

public class PMT_Case_TableEditor_CTL {
    
    /*************************************************
* Name: CreateTasksWrapper

* Used by : 
* ***********************************************/
    
    public class CreateTasksWrapper
    {
        @AuraEnabled public List<Map<String, String>> phasesList;
        @AuraEnabled public List<Map<String, String>> memberList;      
    }
    
    /************************************************
* Method Name: getTaskWrapper 
* Description: Get tasks for the current project
* Component(s): 
* Parameters : project id
* Return Values:  CreateTasksWrapper instance
* ***********************************************/    
    @AuraEnabled
    public static CreateTasksWrapper getTaskWrapper(Id projectId)
    {
        CreateTasksWrapper taskWrapper = new CreateTasksWrapper();
        //Calling util method to check CRUD
        List<String> lstPhaseFields = new List<String>{'Name', 'Project__c'};
        if(PMT_Utility.validateCRUD('PMT_Phase__c', lstPhaseFields , 'isAccessible')) {
            taskWrapper.phasesList = getPhasesList(projectId);
        }else{
            throw new AuraHandledException('You don\'t have access to PMT phases. Please contact system administartor.');
        }
        
        //Calling util method to check CRUD
        List<String> lstAllocationFields = new List<String>{'Allocated_Resource_Id__c', 'Resource_Name__c'};
        if(PMT_Utility.validateCRUD('PMT_Resource_Allocation__c', lstAllocationFields, 'isAccessible')) {
            taskWrapper.memberList = getMemberList(projectId);
        }else{
            throw new AuraHandledException('You don\'t have access to PMT Resource allocations. Please contact system administartor.');
        }
        
        return taskWrapper;
    }
    
    /*************************************************
* Method Name: getPhasesList
* Description: Get list of Project related Phases
* Component(s): 
* Parameters : projectId
* Return Values: items
* ***********************************************/  
    private static List<Map<String, String>> getPhasesList(ID projectId) {    
        List<Map<String, String>> items = new List<Map<String, String>>();        
        for (PMT_Phase__c ph : [SELECT id, Name FROM PMT_Phase__c WHERE Project__c =:projectId limit :limits.getLimitQueryRows()]){
            items.add(new Map<String, String>{'value' => ph.Id, 'label'=> ph.Name});
        }
        
        return items;
    }
    
    /*************************************************
* Method Name: getMemberList
* Description: Get list of Project Members
* Component(s): 
* Parameters : projectId
* Return Values: items
* ***********************************************/    
    private static List<Map<String, String>> getMemberList(ID projectId) {    
        List<Map<String, String>> items = new List<Map<String, String>>();  
        Set<Id> uniqueUserIds = new Set<Id>();
        for (PMT_Resource_Allocation__c mb : [SELECT id, Allocated_Resource_Id__c, Resource_Name__c FROM PMT_Resource_Allocation__c WHERE Project__c =:projectId and Resource_IsActive__c = true limit :limits.getLimitQueryRows()]){
            if(uniqueUserIds.add(mb.Allocated_Resource_Id__c)){
                items.add(new Map<String, String>{'value' => mb.Allocated_Resource_Id__c, 'label'=> mb.Resource_Name__c});
            }
        }
        
        return items;
    }
    
    
    /************************************************
* Method Name: getCasesForProject 
* Description: Get cases for the current project
* Component(s): PMT_Case_TableEditor_FRL.cmp
*Parameters : project id
* Return Values: list of Cases
* ***********************************************/    
    @AuraEnabled
    public static List<Case> getCasesForProject(Id projectId)
    {
        List<String> lstCaseFields = new List<String>{'Id','CaseNumber','Subject','Status','Priority','CreatedDate','ClosedDate','OwnerId'};
             
        List<String> lstUserFields = new List<String>{'Name'};
        
        List<String> lstPhaseFields = new List<String>{'Name', 'Id'};
            
        List<PMT_Phase__c> phaseIds = [SELECT Id FROM PMT_Phase__c WHERE Project__c =: projectId];
        List<CaseProjectPhaseJunction__c> junctionIds = [SELECT Case__r.Id FROM CaseProjectPhaseJunction__c WHERE Project_Phase__c IN: phaseIds];      
        List<String> caseIds = new List<String>();
        
        for(CaseProjectPhaseJunction__c j : junctionIds){
            system.debug(j.Case__r.Id);
            caseIds.add(j.Case__r.Id);
        }
            
		
            //Calling util method to check CRUD
        //if(PMT_Utility.validateCRUD('Case', lstCaseFields, 'isAccessible') && PMT_Utility.validateCRUD('User', lstUserFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Phase__c', lstPhaseFields, 'isAccessible')){
            
            //List<Case> c = [SELECT id,PMT_Phase__c,CaseNumber,Subject,Status,Priority,Start_Date__c,CreatedDate,ClosedDate,Owner.Name,PMT_Phase__r.Name,
            //        PMT_Phase__r.Id, PMT_Phase__r.Project__c FROM Case WHERE Id IN: caseIds order by Start_Date__c ASC limit: limits.getLimitQueryRows()];  
            
       //     System.debug(c);
        List<Case> c = new List<Case>();
            return c;
                    
                    
      //  }else{
      //      throw new AuraHandledException('Access restricted. Please contact your system administartor.');
      //  }
    }
    
        /************************************************
* Method Name: getCasePhaseJunctionsForProject 
* Description: Get cases for the current project
* Component(s): PMT_Case_TableEditor_FRL.cmp
*Parameters : projectId
* Return Values: list of CasePhaseJunctionWrapper	
* ***********************************************/    
    @AuraEnabled
    public static List<CasePhaseJunctionWrapper> getCasePhaseJunctionsForProject(Id projectId)
    {
        List<String> lstCaseFields = new List<String>{'Id','CaseNumber','Subject','Status','Priority','CreatedDate','ClosedDate','OwnerId'};
             
        List<String> lstUserFields = new List<String>{'Name'};
        
        List<String> lstPhaseFields = new List<String>{'Name', 'Id'};
            
        List<PMT_Phase__c> phaseIds = [SELECT Id FROM PMT_Phase__c WHERE Project__c =: projectId];   
		
            //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('Case', lstCaseFields, 'isAccessible') && PMT_Utility.validateCRUD('User', lstUserFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Phase__c', lstPhaseFields, 'isAccessible')){
            
            List<CaseProjectPhaseJunction__c> c = [SELECT Id, Case__r.id,Case__r.CaseNumber,Case__r.Subject,Case__r.Status,Case__r.Priority,Case__r.Start_Date__c,Case__r.CreatedDate,Case__r.ClosedDate,Case__r.Owner.Name,Project_Phase__r.Name,
                    Project_Phase__r.Id, Project_Phase__r.Project__c FROM CaseProjectPhaseJunction__c WHERE Project_Phase__c IN: phaseIds order by Case__r.Start_Date__c ASC limit: limits.getLimitQueryRows()];  
            List<CasePhaseJunctionWrapper> wraps = new List<CasePhaseJunctionWrapper>();
            for(CaseProjectPhaseJunction__c j : c){
                CasePhaseJunctionWrapper w = new CasePhaseJunctionWrapper();
                     	w.CaseId = j.Case__r.id;
         				w.CaseNumber = j.Case__r.CaseNumber;
         				w.Subject = j.Case__r.Subject;
        				w.Status = j.Case__r.Status;
        				w.Priority = j.Case__r.Priority;
                		w.CaseStartDate = j.Case__r.CreatedDate;
						w.CaseCloseDate = j.Case__r.ClosedDate;
                		w.CaseOwner = j.Case__r.Owner.Name;
                		w.PhaseName = j.Project_Phase__r.Name;
                		w.ProjectId = j.Project_Phase__r.Project__c;
                		w.PhaseId = j.Project_Phase__r.Id; 
                		w.JunctionId = w.CaseId + w.PhaseId;
                wraps.add(w);
            }
            
            System.debug(wraps);
            return wraps;
                    
                    
        }else{
            throw new AuraHandledException('Access restricted. Please contact your system administartor.');
        }
    }
    /*************************************************
* Method Name: CasePhaseJunctionWrapper
* Description: Wrapper class for CasePhaseJunction
* Component(s): PMT_Case_TableEditor_FRL.cmp
* ***********************************************/ 
    public class CasePhaseJunctionWrapper {
     	@AuraEnabled public String CaseId;
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String Subject;
        @AuraEnabled public String Status;
        @AuraEnabled public String Priority;
        @AuraEnabled public Datetime CaseStartDate;
        @AuraEnabled public Datetime CaseCloseDate;
        @AuraEnabled public String CaseOwner;
        @AuraEnabled public String PhaseName;
        @AuraEnabled public String ProjectId;
        @AuraEnabled public String PhaseId;    
        @AuraEnabled public String JunctionId;
        
    }
    
    
    /*************************************************
* Method Name: updateCases
* Description: Update cases
* Component(s): PMT_Case_TableEditor_FRL.cmp
* Parameters : cases
* Return Values: list of cases
* ***********************************************/
    @AuraEnabled
    public static List<Case> updateCases(List<Case> cases){
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('Case', null, 'isUpdateable')){ 
            try {            
                if(!cases.isEmpty()){
                    UPDATE cases;
                    return cases;  
                }else{
                    return null;
                }
                
            } catch(Exception e) {
                //Calling util method to check CRUD
                List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
            	if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                	INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_Case_TableEditor_CTL', Error_Message__c = e.getMessage() , Method_Name__c = 'updateCases');
                }
                AuraHandledException ae = new AuraHandledException('Error occurred while updating case:');
                ae.setMessage(e.getMessage());
                throw ae;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to update Cases. Please contact your system administartor.');
        }   
    }  
    
    /*************************************************
* Method Name: submitCaseForApproval
* Description: Submit case for Approval
* Component(s): 
* Parameters : caseId
* Return Values: null
* NOTE: It will need approval process to update status on case on approval.
* ***********************************************/
    @auraEnabled
    public static Boolean submitTaskForApproval(Id caseId) {        
        Boolean res = false;
        try {
            if(caseId != null) {
                // create the new approval request to submit
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitted for approval.');
                req.setObjectId(caseId);
                // submit the approval request for processing
                Approval.ProcessResult result = Approval.Process(req);
                // display if the reqeust was successful
                if(result.isSuccess()) {
                    res = true;
                } 
                else 
                {
                    return res;
                }
            }
            return res;
        } catch(Exception e) {
            //Calling util method to check CRUD
            List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
            if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
            	INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_Case_TableEditor_CTL', Error_Message__c = e.getMessage() , Method_Name__c = 'submitCaseForApproval');
            }
            return false;
        }        
    }
    
    /*************************************************
* Method Name: savePhases
* Description: Create phases on submission
* Component(s): 
* Parameters : phaseList
* Return Values: null
* ***********************************************/
    @AuraEnabled
    public static void savePhases(List<PMT_Phase__c> phaseList){
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('PMT_Phase__c', null, 'isCreateable')){
            try{
                Insert phaseList;
                
            }catch(Exception e) {   
                //Calling util method to check CRUD
                List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
            	if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                	INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_Case_TableEditor_CTL', Error_Message__c = e.getMessage() , Method_Name__c = 'savePhases');
                }
                AuraHandledException ae = new AuraHandledException('Error occurred while creating phase:');
                ae.setMessage(e.getMessage());
                throw ae;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to create phases. Please contact your system administartor.');
        }   
    }
    
    /*************************************************
    * Method Name: getPicklistvalues
    * Description: Get values from picklist fields
    * Component(s): 
    * Parameters : objectName, field_apiname
    * Return Values: optionlist
    * ***********************************************/
    
    @AuraEnabled
    public static List<String> getPicklistvalues(String objectName, String field_apiname,Boolean nullRequired){
        
        List<String> optionlist = new List<String>();
        
        Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Map<String, Schema.SObjectField> field_map = gd.get(objectName.toLowerCase()).getDescribe().fields.getMap(); 
        List<Schema.PicklistEntry> picklistValues = field_map.get(field_apiname.toLowerCase()).getDescribe().getPickListValues();
        if(nullRequired == true){
            optionlist.add('--None--');
        }
        
        for (Schema.PicklistEntry pv : picklistValues) {
            optionlist.add(pv.getValue());
        }
        return optionlist;
    }
    
    /*************************************************
* Method Name: saveCases
* Description: 
* Component(s): 
* Parameters : caseList
* Return Values: caseList
* ***********************************************/    
    @AuraEnabled
    public static void saveCases(List<Case> caseList){
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('Case', null, 'isCreateable')){
            try{    
                Insert caseList;
            }catch(Exception e) {
                //Calling util method to check CRUD
                List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
            	if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
	                INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_Case_TableEditor_CTL', Error_Message__c = e.getMessage() , Method_Name__c = 'saveCases');
                }
                AuraHandledException ae = new AuraHandledException('Error occurred while creating a Case:');
                ae.setMessage(e.getMessage());
                throw ae;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to create Case. Please contact your system administrator.');
        } 
    }
    /*************************************************
* Method Name: getCaseRecordTypeId
* Description: Get list of Project cases from Ids
* Component(s): PMT_Case_TableEditor_FRL.cmp
* Parameters : caseId
* Return Values: recordTypeId
* ***********************************************/   
	@AuraEnabled
    public static Id getCaseRecordTypeId(Id caseId){
        return [Select recordTypeId from Case where Id=: caseId].get(0).recordTypeId;
    }
    
    /*************************************************
* Method Name: getCasesList
* Description: Get list of Project cases from Ids
* Component(s): PMT_Case_TableEditor_FRL.cmp
* Parameters : caseIds
* Return Values: Cases list
* ***********************************************/   
    @AuraEnabled
    public static List<Case> getCasesList(List<ID> caseIds) {
        List<Case> items = new List<Case>();
        List<String> lstOfCaseFields = new List<String>{'Id','OwnerId', 'Status'};
        //Calling util method to check CRUD
        if(caseIds != null && caseIds.size() > 0 && PMT_Utility.validateCRUD('Case', lstOfCaseFields, 'isAccessible')) {
            items = [select Id, OwnerId, Status from Case where Id IN: caseIds limit :limits.getLimitQueryRows()];
            return items;
        }else{
            throw new AuraHandledException('You don\'t have access to Cases. Please contact system administrator.');
        }
    }
    
    /*************************************************
* Method Name: getCasePhaseMap
* Description: Get map of phases with their associated cases
* Component(s): PMT_Case_TableEditor_FRL.cmp
* Parameters : projectId
* Return Values: Map<PhaseName,List<Case>>
* ***********************************************/   
    @AuraEnabled
    public static Map<String,List<String>> getCasePhaseMap(String projectId) {
        Map<String, List<String>> casePhaseMap = new Map<String, List<String>>();
            
        List<PMT_Phase__c> phaseIds = [SELECT Id, Name FROM PMT_Phase__c WHERE Project__c =: projectId];          

        List<CaseProjectPhaseJunction__c> junctionCaseIds = [SELECT Case__r.Id, Project_Phase__r.Name FROM CaseProjectPhaseJunction__c WHERE Project_Phase__c IN: phaseIds]; 
        
        for(PMT_Phase__c p : phaseIds){
            List<String> cases = new List<String>();
            for(CaseProjectPhaseJunction__c j : junctionCaseIds){
                if(p.Name == j.Project_Phase__r.Name){
                    cases.add(j.Case__r.Id);
                }
            }
            casePhaseMap.put(p.Name,cases);
        }
        
            return casePhaseMap;
        
	}
    
        /*************************************************
* Method Name: getPhases
* Description: Get list of phases
* Component(s): PMT_Case_TableEditor_FRL.cmp
* Parameters : projectId
* Return Values: Phase Names
* ***********************************************/   
    @AuraEnabled
    public static List<String> getPhases(String projectId) {
            
        List<PMT_Phase__c> phaseIds = [SELECT Id, Name FROM PMT_Phase__c WHERE Project__c =: projectId];      
        
        List<String> phaseNames = new List<String>();
            
            for(PMT_Phase__c p : phaseIds){
                phaseNames.add(p.Name);
            }
        
            return phaseNames;
        
	}
}