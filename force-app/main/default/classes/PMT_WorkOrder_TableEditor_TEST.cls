/*************************************************
* Name: PMT_WorkOrder_TableEditor_TEST
* Test class for : PMT_WorkOrder_TableEditor_CTL 
* ***********************************************/
@isTest
public class PMT_WorkOrder_TableEditor_TEST {
    @testSetup static void setup(){
        List<WorkOrder> lstOfWorkOrders = new List<WorkOrder>();
        Integer resourceAvailability = Integer.valueOf(PMT_Utility.getPMTSettings('Default').Default_Availability_for_Scheduler__c);
        
        //PMT project record
        PMT_Project__c project = new PMT_Project__c(Name='Project Controller Test', 
                                                    Portfolio__c='R2R',
                                                    Initial_End_Date__c=System.today()+30,
                                                    Initial_Start_Date__c=System.today(),
                                                    Level_of_Effort__c = 'Small');
        INSERT project;
        
        //PMT phase record
        PMT_Phase__c phases = new PMT_Phase__c(Name = 'Phase 1',
                                               Project__c = project.Id);
        INSERT phases;
        
        //PMT resource availability record
        PMT_Resource_Availability__c resAvail = new PMT_Resource_Availability__c( User__c = UserInfo.getUserId(),
                                                                                 Fiscal_Year__c = 'FY21',
                                                                                 Jan__c = resourceAvailability, Feb__c = resourceAvailability, 
                                                                                 Mar__c = resourceAvailability, Apr__c = resourceAvailability, 
                                                                                 May__c = resourceAvailability, Jun__c = resourceAvailability, 
                                                                                 Jul__c = resourceAvailability, Aug__c = resourceAvailability, 
                                                                                 Sep__c = resourceAvailability, Oct__c = resourceAvailability,
                                                                                 Nov__c = resourceAvailability, Dec__c = resourceAvailability);
        
        INSERT resAvail;
        
        //Allocation records
        PMT_Resource_Allocation__c resAllocation = new PMT_Resource_Allocation__c(Project__c = project.Id,
                                                                                  Resource_Availability__c = resAvail.Id,
                                                                                  Role__c = 'SME' );                                                                                        
        INSERT resAllocation;
        
        //WorkOrder records
        WorkOrder workorder1 = new WorkOrder(Subject = 'WorkOrder 1', 
                                             Status = 'New',
                                             Priority = 'Low',
                                             Description = 'WorkOrder 1',
                                             Requested_Delivery_Date__c = System.today()+30,
                                             OwnerId = UserInfo.getUserId(), 
                                             PMT_Phase__c = phases.Id,
                                             Work_Category__c = 'Scheduled Maintenance'
                                            );
        lstOfWorkOrders.add(workorder1);
        
        WorkOrder workorder2 = new WorkOrder(Subject = 'WorkOrder 2', 
                                             Status = 'In Progress',
                                             Requested_Delivery_Date__c = System.today()+30, 
                                             OwnerId = UserInfo.getUserId(), 
                                             PMT_Phase__c = phases.Id,
                                             Work_Category__c = 'Scheduled Maintenance');
        lstOfWorkOrders.add(workorder2);
        
        INSERT lstOfWorkOrders;
    }
    
    static testmethod void getWorkOrdersForProjectTestCase(){

            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            Test.startTest();
            List<WorkOrder> lstOfResult = PMT_WorkOrder_TableEditor_CTL.getWorkOrdersForProject(project.Id);
            Test.stopTest();
            system.assertEquals(2, lstOfResult.size(), 'There should be 2 WorkOrders present.');
        
    }
    
    static testmethod void updateWorkOrderTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            WorkOrder workorder1 = new WorkOrder(Subject = 'WorkOrder 1', 
                                             Status = 'New',
                                             Priority = 'Low',
                                             Description = 'WorkOrder 1',
                                             Requested_Delivery_Date__c = System.today()+30,
                                             OwnerId = UserInfo.getUserId(), 
                                             PMT_Phase__c = phase.Id,
                                             Work_Category__c = 'Scheduled Maintenance'
                                            );
            insert workorder1;
            
            WorkOrder workorderrec = [SELECT Id, Status FROM WorkOrder LIMIT 1];
            workorderrec.Status = 'In Progress';
                
            Test.startTest();
            List<WorkOrder> lstOfResult = PMT_WorkOrder_TableEditor_CTL.updateWorkOrders(new List<WorkOrder>{workorderrec});
            WorkOrder workorderUpdated = [SELECT Id, Status FROM WorkOrder LIMIT 1];
            Test.stopTest();
            system.assertEquals('In Progress', workorderUpdated.Status, 'WorkOrder status must be updated.');
        }
    }
    
    static testmethod void updateWorkOrderNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            
            //Create WorkOrder        
            WorkOrder workorder = new WorkOrder(Subject = 'WorkOrder 1', 
                                             Status = 'New',
                                             Priority = 'Low',
                                             Description = 'WorkOrder 1',
                                             Requested_Delivery_Date__c = System.today()+30,
                                             OwnerId = UserInfo.getUserId(), 
                                             PMT_Phase__c = phase.Id,
                                             Work_Category__c = 'Scheduled Maintenance'); 
            
            Test.startTest();
            try{
                List<WorkOrder> lstOfResult = PMT_WorkOrder_TableEditor_CTL.updateWorkOrders(new List<WorkOrder>{workorder});
            }catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('error'),'The error should occur');
            }
            
            Test.stopTest();
        }
    }
    
    static testmethod void deleteRecordTestCase(){

            WorkOrder worec = [SELECT Id, Status FROM WorkOrder LIMIT 1];
            
            Test.startTest();
            Boolean result = PMT_WorkOrder_TableEditor_CTL.deleteRecord(worec);
            List<WorkOrder> lstOfResult = [SELECT Id, Status FROM WorkOrder];
            Test.stopTest();

            system.assertEquals(1, lstOfResult.size(), 'Only 1 workorder should be present on delete.');  

    }
    
    static testmethod void deleteRecordNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_Global_Admin'});
        System.runAs(testUser){
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            
            //Create Tasks        
            WorkOrder workorder = new WorkOrder(Subject = 'WorkOrder 1', 
                                             Status = 'New',
                                             Priority = 'Low',
                                             Description = 'WorkOrder 1',
                                             Requested_Delivery_Date__c = System.today()+30,
                                             OwnerId = UserInfo.getUserId(), 
                                             PMT_Phase__c = phase.Id,
                                             Work_Category__c = 'Scheduled Maintenance');
            
            Test.startTest();
            try{
                Boolean result = PMT_WorkOrder_TableEditor_CTL.deleteRecord(workorder);
                system.assertEquals(false, result, 'There should be error.');
            }catch(Exception e){
                
            }
            
            Test.stopTest();    
        }
    }

    static testmethod void getWorkOrdersListTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            WorkOrder workorder1 = new WorkOrder(Subject = 'WorkOrder 1', 
                                             Status = 'New',
                                             Priority = 'Low',
                                             Description = 'WorkOrder 1',
                                             Requested_Delivery_Date__c = System.today()+30,
                                             OwnerId = UserInfo.getUserId(), 
                                             PMT_Phase__c = phase.Id,
                                             Work_Category__c = 'Scheduled Maintenance'
                                            );
            insert workorder1;
            
            Test.startTest();
            WorkOrder workorder = [SELECT Id FROM WorkOrder LIMIT 1]; 
            List<WorkOrder> lstOfResult = PMT_WorkOrder_TableEditor_CTL.getWorkOrdersList(new List<ID>{workorder.Id});
            Test.stopTest();
            system.assertEquals(true, lstOfResult[0].OwnerId != null, 'Assigned to field must be queried.');
        }
    }
}