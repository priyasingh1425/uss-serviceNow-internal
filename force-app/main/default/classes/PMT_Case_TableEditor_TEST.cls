/*************************************************
* Name: PMT_Case_TableEditor_TEST
* Test class for : PMT_Case_TableEditor_CTL 
* ***********************************************/
@isTest
public class PMT_Case_TableEditor_TEST {

	@testSetup static void setup(){
		List<PMT_Task__c> lstOfTasks = new List<PMT_Task__c>();
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
        
        //PMT Task records
		PMT_Task__c task1 = new PMT_Task__c(Name = 'Task 1', 
											Status__c = 'Not Started',
											Start_Date__c = System.today(), 
											Due_Date__c = System.today()+30, 
											Assigned_To1__c = UserInfo.getUserId(),
											Is_Milestone__c = true,
											Phase__c = phases.Id); 
		lstOfTasks.add(task1);
		
        PMT_Task__c task2 = new PMT_Task__c(Name = 'Task 2', 
											Status__c = 'Not Started',
											Start_Date__c = System.today(), 
											Due_Date__c = System.today()+30, 
											Assigned_To1__c = UserInfo.getUserId(), 
											Is_Milestone__c = false, 
											Phase__c = phases.Id);
        lstOfTasks.add(task2);
		
		INSERT lstOfTasks;
	}
    
    static testmethod void getCasesForProjectTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            Test.startTest();
            List<Case> lstOfResult = PMT_Case_TableEditor_CTL.getCasesForProject(project.Id);
            Test.stopTest();
            system.assertEquals(0, lstOfResult.size());
        }
    }
	
	static testmethod void updateCaseTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            RecordType rec = [SELECT Id from RecordType where Name = 'Provisioning' and SobjectType='Case'];
            
            //Create Cases        
            Case ncase = new Case(Subject = 'Case 1', 
                                  Status = 'New',
                                  Origin = 'Project',
                                  Group__c = 'Assistance',
                                  Support_Queue__c = 'Cloud Provisioning',
                                  RecordTypeId = rec.Id); 

            PMT_Case_TableEditor_CTL.saveCases(new List<Case> {ncase});
            
            Case caserec = [SELECT Id, Status FROM Case LIMIT 1];
            caserec.Status = 'In Progress';
            
            Test.startTest();
            List<Case> lstOfResult = PMT_Case_TableEditor_CTL.updateCases(new List<Case>{caserec});
            Case caseUpdated = [SELECT Id, Status FROM Case LIMIT 1];
            Test.stopTest();
            system.assertEquals('In Progress', caseUpdated.Status, 'Case status must be updated.');
        }
    }
    
    static testmethod void updateCaseNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            RecordType rec = [SELECT Id from RecordType where Name = 'External Customer Support' and SobjectType='Case'];
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            
            //Create Cases        
            Case ncase = new Case(Subject = 'Case 1', 
                                  Status = 'New',
                                  Origin = 'Project',
                                  Support_Queue__c = 'Cloud Engineering',
                                 RecordTypeId = rec.Id); 
            
            Test.startTest();
            try{
                List<Case> lstOfResult = PMT_Case_TableEditor_CTL.updateCases(new List<Case>{ncase});
            }catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('error'),'The error should occur');
            }
            
            Test.stopTest();
        }
    }
	
    static testmethod void savePhasesTestCase(){

            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            
            //Create Phases        
            PMT_Phase__c phase = new PMT_Phase__c(Name='Phase 3', Project__c = project.Id);
            Test.startTest();
            PMT_Case_TableEditor_CTL.savePhases(new List<PMT_Phase__c> {phase});
            
            PMT_Project__c projectUpdated = [SELECT Id, (SELECT Id FROM Project_Phases__r) FROM PMT_Project__c WHERE Id=: project.Id];			
            system.assertEquals(2, projectUpdated.Project_Phases__r.size(), 'There should be 2 phases available.');
            Test.stopTest();

        
	}
    
    static testmethod void savePhasesNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            //Create Phases        
            PMT_Phase__c phase = new PMT_Phase__c(Name='Phase 3');
            Test.startTest();
            try{
                PMT_Case_TableEditor_CTL.savePhases(new List<PMT_Phase__c> {phase});
            }catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('error'),'The error should occur for negative test');
            }
            Test.stopTest();
        }
	}
    
    static testmethod void saveCasesTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            RecordType rec = [SELECT Id from RecordType where Name = 'External Customer Support' and SobjectType='Case'];
            PMT_Phase__c phase = [SELECT Id FROM PMT_Phase__c LIMIT 1];
            
            //Create Cases        
            Case ncase = new Case(Subject = 'Case 1', 
                                  Status = 'New',
                                  Origin = 'Project',
                                  Support_Queue__c = 'Cloud Engineering',
                                 RecordTypeId = rec.Id); 
            
            Test.startTest();
            PMT_Case_TableEditor_CTL.saveCases(new List<Case> {ncase});
	
            Test.stopTest();
        }
        
	}
    
    static testmethod void saveCasesNegTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            RecordType rec = [SELECT Id from RecordType where Name = 'External Customer Support' and SobjectType='Case'];
            
            //Create Cases        
            Case ncase = new Case(Subject = 'Case 1', 
                                  Status = 'New',
                                  Origin = 'Project',
                                  Support_Queue__c = 'Cloud Engineering',
                                 RecordTypeId = rec.Id); 
            
            Test.startTest();
            try{	
                PMT_Case_TableEditor_CTL.saveCases(new List<Case> {ncase});
            }catch(Exception e){
                System.assertEquals(true, e.getMessage().contains('error'),'The error should occur for negative test');
            }					
            Test.stopTest();
        }
	}
    
    static testmethod void getPicklistvaluesTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            Test.startTest();
            List<String> lstOfResult = PMT_Case_TableEditor_CTL.getPicklistvalues('Case','Status', false);
            Test.stopTest();
        }
	}
    
    static testmethod void getCaseWrapperTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            PMT_Project__c project = [SELECT Id FROM PMT_Project__c LIMIT 1];
            Test.startTest();
            PMT_Case_TableEditor_CTL.createTasksWrapper options = PMT_Case_TableEditor_CTL.getTaskWrapper(project.Id);
            Test.stopTest();
            system.assertEquals(1, options.phasesList.size(), 'There should be 1 phase available.');
            system.assertEquals(1, options.memberList.size(), 'There should be 1 member available.');
        }
	}
    
    static testmethod void getCasesListTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            RecordType rec = [SELECT Id from RecordType where Name = 'External Customer Support' and SobjectType='Case'];
            
            //Create Cases        
            Case ncase = new Case(Subject = 'Case 1', 
                                  Status = 'New',
                                  Origin = 'Project',
                                  Support_Queue__c = 'Cloud Engineering',
                                 RecordTypeId = rec.Id); 
            
            insert ncase;
            
            Case caserec = [SELECT Id FROM Case LIMIT 1]; 
            
            Test.startTest();
            List<Case> lstOfResult = PMT_Case_TableEditor_CTL.getCasesList(new List<ID>{caserec.Id});
            Test.stopTest();
        }
	}
    
    static testmethod void submitCaseForApprovalTestCase(){
        User testUser = PMT_Testcoverage.createUser('Standard User', new List<String>{'PMT_User'});
        System.runAs(testUser){
            RecordType rec = [SELECT Id from RecordType where Name = 'External Customer Support' and SobjectType='Case'];
            
            //Create Cases        
            Case ncase = new Case(Subject = 'Case 1', 
                                  Status = 'New',
                                  Origin = 'Project',
                                  Support_Queue__c = 'Cloud Engineering',
                                 RecordTypeId = rec.Id); 
            
            PMT_Case_TableEditor_CTL.saveCases(new List<Case> {ncase});
            
            Case caserec = [SELECT Id FROM Case LIMIT 1]; 		
            Test.startTest();
            Boolean result = PMT_Case_TableEditor_CTL.submitTaskForApproval(caserec.Id);
            Test.stopTest();
            system.assertEquals(false, result, 'No approval process found'); //NOTE: Need to update assert on set up of approval process
        }
	}
	
}