/*************************************************
* Name: PMT_WorkOrder_TableEditor_CTL
* Description: Helper for WorkOrder Management related components:
            - PMT_WorkOrder_TableEditor.cmp
* Test class: PMT_WorkOrder_TableEditor_TEST 
* ***********************************************/

public with Sharing class PMT_WorkOrder_TableEditor_CTL{
    
    /************************************************
* Method Name: getWorkOrdersForProject 
* Description: Get workorders for the current project
* Component(s): PMT_WorkOrder_TableEditor.cmp
*Parameters : project id
* Return Values: list of WorkORders
* ***********************************************/    
    @AuraEnabled
    public static List<WorkOrder> getWorkOrdersForProject(Id projectId)
    {
        List<String> lstWorkOrderFields = new List<String>{'Id','Subject','Status','OwnerId', 'WorkOrderNumber', 'Requested_Delivery_Date__c','Priority','Description','PMT_Phase__c','Service_Id__c'};
             
        List<String> lstUserFields = new List<String>{'Name'};
        
        List<String> lstPhaseFields = new List<String>{'Name', 'Id'};
		
            //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('WorkOrder', lstWorkOrderFields, 'isAccessible') && PMT_Utility.validateCRUD('User', lstUserFields, 'isAccessible') && PMT_Utility.validateCRUD('PMT_Phase__c', lstPhaseFields, 'isAccessible')){
            
            return [SELECT id,WorkOrderNumber,Requested_Delivery_Date__c, Service_ID__c, Service_ID__r.Name, Priority, OwnerId, Owner.Name, AccountId, Subject,Description,PMT_Phase__c,Status,PMT_Phase__r.Name,
                    PMT_Phase__r.Id FROM WorkOrder WHERE Project_Id__c=:projectId order by Requested_Delivery_Date__c ASC limit: limits.getLimitQueryRows()];                     
                    
                    
        }else{
            throw new AuraHandledException('Access restricted. Please contact system administartor.');
        }
    }    
    
    /*************************************************
* Method Name: updateWorkOrders
* Description: Update WorkOrders
* Component(s): PMT_WorkOrder_TableEditor.cmp
* Parameters : workorders
* Return Values: list of WorkOrders
* ***********************************************/
    @AuraEnabled
    public static List<WorkOrder> updateWorkOrders(List<WorkOrder> workorders){
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('WorkOrder', null, 'isUpdateable')){ 
            try {            
                if(!workorders.isEmpty()){
                    UPDATE workorders;
                    return workorders;  
                }else{
                    return null;
                }
                
            } catch(Exception e) {
                //Calling util method to check CRUD
                List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
            	if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                	INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_WorkOrder_TableEditor_CTL', Error_Message__c = e.getMessage() , Method_Name__c = 'updateWorkOrders');
                }
                AuraHandledException ae = new AuraHandledException('Error occurred while updating workorder:');
                ae.setMessage(e.getMessage());
                throw ae;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to update WorkOrders. Please contact system administartor.');
        }   
    }  
    
    /*************************************************
* Method Name: deleteRecord
* Description: delete records
* Component(s): PMT_WorkOrder_TableEditor.cmp
* Parameters : recordToDelete
* Return Values: null
* ***********************************************/
    @auraEnabled
    public static Boolean deleteRecord(sObject recordToDelete) {
        //Calling util method to check CRUD
        if(PMT_Utility.validateCRUD('WorkOrder', null, 'isDeletable')){       
            try {
                DELETE recordToDelete;
                return true;
            } catch(Exception e) {
                List<String> lstOfLogFields = new List<String>{'Apex_Class__c', 'Error_Message__c','Method_Name__c'};
            	if(PMT_Utility.validateCRUD('PMT_Error_Log__c', lstOfLogFields, 'isCreatable')){
                	INSERT new PMT_Error_Log__c(Apex_Class__c='PMT_WorkOrder_TableEditor_CTL', Error_Message__c = e.getMessage() , Method_Name__c = 'deleteRecord');
                }
                return false;
            }
        }else{
            throw new AuraHandledException('You don\'t have access to delete WorkOrders. Please contact system administartor.');
        }   
    }
    
        /*************************************************
* Method Name: getWorkOrdersList
* Description: Get list of Project workorders from Ids
* Component(s): PMT_WorkORder_TableEditor.cmp
* Parameters : workorderIds
* Return Values: WorkOrder list
* ***********************************************/   
    @AuraEnabled
    public static List<WorkOrder> getWorkOrdersList(List<ID> workorderIds) {
        List<WorkOrder> items = new List<WorkOrder>();
        List<String> lstOfWorkOrderFields = new List<String>{'Id','OwnerId', 'Status'};
        //Calling util method to check CRUD
        if(workorderIds != null && workorderIds.size() > 0 && PMT_Utility.validateCRUD('WorkOrder', lstOfWorkOrderFields, 'isAccessible')) {
            items = [select Id, OwnerId, Status from WorkOrder where Id IN: workorderIds limit :limits.getLimitQueryRows()];
            return items;
        }else{
            throw new AuraHandledException('You don\'t have access to WorkOrder. Please contact system administrator.');
        }
    }
}