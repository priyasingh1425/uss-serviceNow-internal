/********************************************************
* Name: PMT_ProjectTemplate_Defaults_TEST
* Test class for : PMT_ProjectTemplate_Defaults_INS (%)
* Version : 61
* *******************************************************/

@isTest
public class PMT_ProjectTemplate_Defaults_TEST {

    @TestSetup
    static void setup(){
        //user setup
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        
        User usr = new User(Alias = 'standt', Email = 'standarduser@pmttemplate.com',
                            EmailEncodingKey = 'UTF-8', LastName = 'Testing', LanguageLocaleKey = 'en_US',
                            LocaleSidKey = 'en_US', ProfileId = p.Id,
                            TimeZoneSidKey = 'America/Los_Angeles', UserName = 'standarduser@pmtdeepclone.com');
        
        insert usr;
        
        List<PermissionSetAssignment> lstOfPSA = new List<PermissionSetAssignment> ();
        
        for (PermissionSet psRec: [SELECT Id FROM PermissionSet WHERE Name IN('PMT_User')]) {
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = usr.Id, PermissionSetId = psRec.Id);
            lstOfPSA.add(psa);
        }
        
        INSERT lstOfPSA;
        //end user setup
        
        System.runAs(usr) {
            
            //recordTypeId from Customer Account record Type
            Id CustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();

            Account cust = new Account(Name = 'Test Customer Account', Type='Customer', RecordTypeId=CustomerRecordTypeId);
            insert cust;
            
            //PMT project template record
            PMT_Project__c project = new PMT_Project__c(Name = 'ProjectTemplate Defaults Test',
                                                        Customer__c = cust.Id,
                                                        IsTemplate__c = true
                                                       );
            INSERT project;
            //PMT project non-template record
            PMT_Project__c projectTest = new PMT_Project__c(Name = 'ProjectTest',
                                                        Customer__c = cust.Id
                                                       );
            INSERT projectTest;
            
            //PMT Project Phase Templates
            List<PMT_Project_Phase_Template__c> phaseTemplates = new List<PMT_Project_Phase_Template__c>();
            PMT_Project_Phase_Template__c phase1 = new PMT_Project_Phase_Template__c(Name = 'phase1',
                                                                                     Phase_Description__c = 'description for phase1',
                                                                                     Phase_Order__c = 3
                                                                                    );
            phaseTemplates.add(phase1);
            PMT_Project_Phase_Template__c phase2 = new PMT_Project_Phase_Template__c(Name = 'phase2',
                                                                                     Phase_Description__c = 'description for phase2',
                                                                                     Phase_Order__c = 2
                                                                                    );
            phaseTemplates.add(phase2);
            PMT_Project_Phase_Template__c phase3 = new PMT_Project_Phase_Template__c(Name = 'phase3',
                                                                                     Phase_Description__c = 'description for phase3',
                                                                                     Phase_Order__c = 1
                                                                                    );
            phaseTemplates.add(phase3);
            
            insert phaseTemplates;
            
            //PMT Project Phase Junctions
            List<PMT_Project_Phase_Junction__c> phaseJunctions = new List<PMT_Project_Phase_Junction__c>();
            PMT_Project_Phase_Junction__c junction1 = new PMT_Project_Phase_Junction__c(Project__c = project.Id,                                                                                        Project_Phase__c = phase1.Id);
            phaseJunctions.add(junction1);

            PMT_Project_Phase_Junction__c junction2 = new PMT_Project_Phase_Junction__c(Project__c = project.Id,                                                                                        Project_Phase__c = phase2.Id);
            phaseJunctions.add(junction2);

            PMT_Project_Phase_Junction__c junction3 = new PMT_Project_Phase_Junction__c(Project__c = project.Id,                                                                                       Project_Phase__c = phase3.Id);
            phaseJunctions.add(junction3);
            
            insert phaseJunctions;
            
            //get help case record type
            RecordType helpRecordType = [select Id,Name from RecordType where sObjectType='Case' and Name = 'Help'].get(0); 
            
            //Project Activity Templates
            List<PMT_Project_Activity_Template__c> patsToCreate = new List<PMT_Project_Activity_Template__c>();
            PMT_Project_Activity_Template__c pat1 = new PMT_Project_Activity_Template__c(Name = 'task to phase', 
                                                                                         Activity_Type__c = 'Task', 
                                                                                         OwnerId = usr.Id, 
                                                                                         Description__c = 'task to phase',  
                                                                                         Project_Phase__c = phase1.Id, 
                                                                                         Required_Activity__c = true, 
                                                                                         Subject__c = 'task to phase');
            patsToCreate.add(pat1);
            PMT_Project_Activity_Template__c pat2 = new PMT_Project_Activity_Template__c(Name = 'case2 parent', 
                                                                                         Activity_Type__c = 'Case',
                                                                                         Support_Group__c = 'Facilities',
                                                                                         Case_Record_Type__c = 'Help',
                                                                                         OwnerId = usr.Id, 
                                                                                         Description__c = 'case2 parent',  
                                                                                         Required_Activity__c = true, 
                                                                                         Subject__c = 'case2 parent');
            patsToCreate.add(pat2);            
            PMT_Project_Activity_Template__c pat3 = new PMT_Project_Activity_Template__c(Name = 'case1 solo', 
                                                                                         Activity_Type__c = 'Case', 
                                                                                         OwnerId = usr.Id, 
                                                                                         Description__c = 'case1 solo',  
                                                                                         Support_Group__c = 'Facilities',
                                                                                         Case_Record_Type__c = 'Help', 
                                                                                         Required_Activity__c = true, 
                                                                                         Subject__c = 'case1 solo');
            patsToCreate.add(pat3);                     
            PMT_Project_Activity_Template__c pat5 = new PMT_Project_Activity_Template__c(Name = 'work order', 
                                                                                         Activity_Type__c = 'Work Order', 
                                                                                         OwnerId = usr.Id, 
                                                                                         Description__c = 'work order',  
                                                                                         Project_Phase__c = phase3.Id, 
                                                                                         Required_Activity__c = true, 
                                                                                         Subject__c = 'work order');
            patsToCreate.add(pat5);            
            PMT_Project_Activity_Template__c pat6 = new PMT_Project_Activity_Template__c(Name = 'case with multiple phases', 
                                                                                         Activity_Type__c = 'Case', 
                                                                                         OwnerId = usr.Id, 
                                                                                         Description__c = 'case with multiple phases',  
                                                                                         Support_Group__c = 'Facilities',
                                                                                         Case_Record_Type__c = 'Help', 
                                                                                         Required_Activity__c = true, 
                                                                                         Subject__c = 'case with multiple phases');
            patsToCreate.add(pat6);
            insert patsToCreate;
    
            //PMTPhaseTempActivityTempJunctions to link Project Phase Templates with associated Project Activity Templates
            List<PMTPhaseTempActivityTempJunction__c> ptatsToCreate = new List<PMTPhaseTempActivityTempJunction__c>();
            PMTPhaseTempActivityTempJunction__c ptat1 = new PMTPhaseTempActivityTempJunction__c(PMT_Project_Activity_Template__c = pat2.Id, 
                                                                                                PMT_Project_Phase_Template__c = phase2.Id);
            ptatsToCreate.add(ptat1);
            PMTPhaseTempActivityTempJunction__c ptat2 = new PMTPhaseTempActivityTempJunction__c(PMT_Project_Activity_Template__c = pat3.Id, 
                                                                                                PMT_Project_Phase_Template__c = phase3.Id);
            ptatsToCreate.add(ptat2);
            PMTPhaseTempActivityTempJunction__c ptat3 = new PMTPhaseTempActivityTempJunction__c(PMT_Project_Activity_Template__c = pat6.Id, 
                                                                                                PMT_Project_Phase_Template__c = phase1.Id);
            ptatsToCreate.add(ptat3);
            PMTPhaseTempActivityTempJunction__c ptat4 = new PMTPhaseTempActivityTempJunction__c(PMT_Project_Activity_Template__c = pat6.Id, 
                                                                                                PMT_Project_Phase_Template__c = phase2.Id);
            ptatsToCreate.add(ptat4);
            PMTPhaseTempActivityTempJunction__c ptat5 = new PMTPhaseTempActivityTempJunction__c(PMT_Project_Activity_Template__c = pat6.Id, 
                                                                                                PMT_Project_Phase_Template__c = phase3.Id);
            ptatsToCreate.add(ptat5);
            
            insert ptatsToCreate;
            
        }
    }
    
    /*****************************************************************
* Method Name:  createPMTProjectTemplatePhasesActivitiesTest
* Class : PMT_ProjectTemplate_Defaults_INS 
******************************************************************/
        static testmethod void createPMTProjectTemplatePhasesActivitiesTest() {
        
            User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
         	PMT_Project__c testProject = [select id from PMT_Project__c where Name = 'ProjectTest'];   
            PMT_Project__c projectTemplate = [select id from PMT_Project__c where Name = 'ProjectTemplate Defaults Test']; 
        	List<PMT_Project_Phase_Junction__c> PhaseIDs = [select id, Name, Phase_Description__c, Phase_Name__c, Project__c, Project_Phase__c, Project_Phase__r.Phase_Order__c from PMT_Project_Phase_Junction__c where Project__c =: projectTemplate.Id];

            PMT_ProjectTemplate_Defaults_INS.InputVariables iv = new PMT_ProjectTemplate_Defaults_INS.InputVariables();
            iv.PhaseIDs = PhaseIDs;
            iv.ProjectID = testProject.Id;
            iv.TemplateID = projectTemplate.Id;
            
            List<PMT_ProjectTemplate_Defaults_INS.InputVariables> inputVariables = new List<PMT_ProjectTemplate_Defaults_INS.InputVariables>();
            inputVariables.add(iv);
            
            System.runAs(testUser) {
            
                Test.startTest();
                PMT_ProjectTemplate_Defaults_INS.createPMTProjectTemplatePhasesActivities(inputVariables);
            	Test.stopTest();
            }
        }
    
        /*****************************************************************
* Method Name:  createListOfWorkOrdersTest
* Class : PMT_ProjectTemplate_Defaults_INS 
******************************************************************/
    
    static testmethod void createListOfWorkOrdersTest(){
        PMT_Project_Activity_Template__c pat = [select Subject__c, Description__c, OwnerId from PMT_Project_Activity_Template__c where Activity_Type__c = 'Work Order' and Subject__c = 'work order'];
        Id CustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        
        Account cust = new Account(Name = 'Test Customer Account', Type='Customer', RecordTypeId=CustomerRecordTypeId);
        insert cust;
        
        PMT_Project__c projectTest = new PMT_Project__c(Name = 'ProjectTest',
                                                            Customer__c = cust.Id
                                                           );
        INSERT projectTest;
        PMT_Phase__c phase = new PMT_Phase__c(Project__c = projectTest.Id, Name = 'phaseTest');
        
        Map<Id, PMT_Phase__c> mapPhases = new Map<ID, PMT_Phase__c>();
        User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
        
        System.runAs(testUser) {
            
            Test.startTest();
        mapPhases.put(phase.Id, phase);
        WorkOrder actual = PMT_ProjectTemplate_Defaults_INS.createListOfWorkOrders(pat, phase.Id, mapPhases);
        
        System.assertEquals(actual.Work_Category__c, 'Customer Install');
            Test.stopTest();
        }

    }
        /*****************************************************************
* Method Name:  tasksToCreateTest
* Class : PMT_ProjectTemplate_Defaults_INS 
******************************************************************/
    
    static testmethod void tasksToCreateTest(){
        User testUser = [select id from User where Email = 'standarduser@pmttemplate.com'];
        
        PMT_Project_Activity_Template__c patc = new PMT_Project_Activity_Template__c(Subject__c = 'Patchy', 
                                                                                    Description__c = 'case pat',
                                                                                    OwnerId = testUser.Id,
                                                                                    Support_Group__c = 'Facilities',
                                                                                    Case_Record_Type__c = 'Help',
                                                                                    Activity_Type__c = 'Case',
                                                                                    Name = 'unique1');
        insert patc;
        Case cpat = new Case(Subject = 'Cpat');
        insert cpat;
        
        PMT_Project_Activity_Template__c patty = new PMT_Project_Activity_Template__c(Subject__c = 'Patty', 
                                                                                    Description__c = 'case pat',
                                                                                    OwnerId = testUser.Id,
                                                                                    Parent_Case_Template__c = patc.Id,
                                                                                    Activity_Type__c = 'Task',
                                                                                    Name = 'unique2');
        
        Id CustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();        
        Account cust = new Account(Name = 'Test Customer Account', Type='Customer', RecordTypeId=CustomerRecordTypeId);
        insert cust;
        
        PMT_Project__c projectTest = new PMT_Project__c(Name = 'ProjectTest',
                                                            Customer__c = cust.Id
                                                           );
        INSERT projectTest;
        PMT_Phase__c phase = new PMT_Phase__c(Project__c = projectTest.Id, Name = 'phaseTest');
        
        Map<Id, Case> mapCases = new Map<Id, Case>();
        mapCases.put(patc.Id, cpat);
        
        Map<Id, PMT_Phase__c> mapPhases = new Map<Id, PMT_Phase__c>();
        mapPhases.put(phase.Id, phase);
        
        System.runAs(testUser) {
            
            Test.startTest();
            PMT_Task__c actual = PMT_ProjectTemplate_Defaults_INS.tasksToCreate(phase.Id, mapPhases, mapCases, patty);
            System.assertEquals(actual.Description__c, patty.Description__c);
            Test.stopTest();
        } 
    }
}