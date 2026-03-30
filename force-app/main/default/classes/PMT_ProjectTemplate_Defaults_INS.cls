/*************************************************
* Name: PMT_ProjectTemplate_Defaults_INS
* Description: Creates Phases and Activites for a Project based on the Selected Template
* Related Flows: 
      - PMT Project - Create Project Phases and Activities
* Test class: PMT_ProjectTemplate_Defaults_TEST (99%)
* ***********************************************/

public class PMT_ProjectTemplate_Defaults_INS {
    
/*************************************************
* Name: InputVariables
* Description: Inner class for invocable apex inputs
* ***********************************************/
    public class InputVariables{

        @InvocableVariable
        public String ProjectID;
        
        @InvocableVariable
        public String TemplateID;
        
        @InvocableVariable
        public List<PMT_Project_Phase_Junction__c> PhaseIDs;

    }
    
/************************************************
* Method Name: createPMTProjectTemplatePhasesActivities 
* Description: Creates Phases and Activites for a Project based on the Selected Template
* Component(s): Flow: PMT Project - Create Project Phases and Activities
* Parameters : list of PMT_ProjectTemplate_Defaults_INS.InputVariables
* Return Values:  void (success/fail)
* ***********************************************/    
    
    @InvocableMethod(label='Create Project Template Phases and Activities' description='Creates Phases and Activites for a Project based on the Selected Template')
    public static void createPMTProjectTemplatePhasesActivities(List<InputVariables> inputVariables){
        //loop ensures support for bulkification
        for(InputVariables iv: inputVariables){
            List<PMT_Project_Phase_Junction__c> pids = iv.PhaseIDs;
            
            List<PMT_Phase__c> phasesToCreate = new List<PMT_Phase__c>();
            Map<Id, PMT_Phase__c> mapPhases = new Map<Id, PMT_Phase__c>();
            List<PMT_Task__c> tasksToCreate = new List<PMT_Task__c>();
            Set<Case> casesToCreate = new Set<Case>();
            List<WorkOrder> workOrdersToCreate = new List<WorkOrder>();
            Map<Id, Case> mapCases = new Map<Id, Case>();
            List<PMTPhaseTempActivityTempJunction__c> junctions = new List<PMTPhaseTempActivityTempJunction__c>();
            List<CaseProjectPhaseJunction__c> casePhasesToCreate = new List<CaseProjectPhaseJunction__c>();
            Set<CasesWithActivityTemplate> cats = new Set<CasesWithActivityTemplate>();
            List<Id> casesCreated = new List<Id>();
            
            Map<String, Id> caseRecordTypes = new Map<String, Id>();
            
            //get list of all case record types
            for(RecordType rt : [select Id,Name from RecordType where sObjectType='Case']){
            	caseRecordTypes.put(rt.Name, rt.Id);  
            }
            
            mapPhases = mapInputVariablesPhases(pids, iv);
            phasesToCreate = mapPhases.values();

            //create all Project Phases indicated by the template
            try{
                insertSObjects(phasesToCreate);
            } catch(Exception e){
                System.debug('PMT Phases were not able to be created: ' + e);
                //add error handling for case after testing complete
            }

            
        	for(Id i: mapPhases.keyset()){
                
            //select all of the non-Task Activity template information from the PMTPhaseTempActivityTempJunction
            List<PMTPhaseTempActivityTempJunction__c> ptat = [Select PMT_Project_Activity_Template__r.Name,
                                                              PMT_Project_Activity_Template__r.Activity_Type__c, 
                                                              PMT_Project_Activity_Template__r.Case_Record_Type__c, 
                                                              PMT_Project_Activity_Template__r.Description__c, 
                                                              PMT_Project_Activity_Template__r.OwnerId, 
                                                              PMT_Project_Activity_Template__r.Required_Activity__c, 
                                                              PMT_Project_Activity_Template__r.Subject__c, 
                                                              PMT_Project_Activity_Template__r.Support_Group__c,
                                                              PMT_Project_Activity_Template__r.Id,
                                                              PMT_Project_Phase_Template__r.Id, 
                                                              PMT_Project_Phase_Template__r.Name 
                                                              from PMTPhaseTempActivityTempJunction__c 
                                                              where PMT_Project_Phase_Template__r.Id =:i ];
                
            for(PMTPhaseTempActivityTempJunction__c templateJunction: ptat){
                
                //create a list of Cases to be created
                if(templateJunction.PMT_Project_Activity_Template__r.Activity_Type__c == 'Case'){
                    if(templateJunction.PMT_Project_Activity_Template__r.Required_Activity__c){
                        cats.add(getCasesWithActivityTemplates(templateJunction, caseRecordTypes));
                    }
                }

                //add each PMTPhaseTempActivityTempJunction to a list for iteration on a Project level later.
                junctions.add(templateJunction);
                
            }

        //end of created phases mapPhases loop
        }

            //create all WorkOrders indicated by the template
            try{
                insertSObjects(workOrdersToCreate);
            } catch(Exception e){
                System.debug('Work Orders were not able to be created: ' + e);
                //add error handling for case after testing complete
            }

            //create all Cases indicated by the template
            try{
                for(CasesWithActivityTemplate ca: cats){
                    System.debug(ca);
                    
                    Case c = new Case();
                    c.Subject = ca.Subject;
                    c.RecordTypeId = ca.RecordTypeId;
                    c.Description = ca.Description;
                    c.Support_Queue__c = ca.SupportQueue;
                    c.Origin = ca.Origin;
                    c.OwnerId = ca.OwnerId;
                    System.debug(c);
                    insert c;

                    ca.CaseID = c.Id;
                    
                    casesCreated.add(c.Id);
                    mapCases.put(ca.ProjectActivityTemplateID, c);

                }
            } catch(Exception e){
                System.debug('Cases were not able to be created: ' + e);
                //add error handling for case after testing complete
            }
            
            casePhasesToCreate = casePhasesToCreate(junctions, mapPhases, mapCases);

            //create all CaseProjectPhaseJunctions__c indicated by the template
            try{  
                insertSObjects(casePhasesToCreate);
            } catch(Exception e){
                System.debug('CaseProjectPhaseJunctions__c were not able to be created: ' + e);
                //add error handling for case after testing complete
            }
                        
            for(Id d: mapPhases.keyset()){
                //find all tasks for the Project Phase Junction Template, loop and create tasks for each phase, add to a list for a bulk create after Phase creation
                for(PMT_Project_Activity_Template__c pat: [Select Name, 
                                                           Activity_Type__c, 
                                                           Case_Record_Type__c, 
                                                           OwnerId, 
                                                           Description__c, 
                                                           Parent_Case_Template__c, 
                                                           Phase_Name__c, 
                                                           Project_Phase__c, 
                                                           Required_Activity__c, 
                                                           Subject__c, 
                                                           Support_Group__c,
                                                           Task_Order__c,
                                                           Id 
                                                           from PMT_Project_Activity_Template__c 
                                                           where Project_Phase__c =: d]){
                                                               if(pat.Required_Activity__c){
                                                                   system.debug(pat);
                                                                   if(pat.Activity_Type__c == 'Task'){
                                                                       system.debug(d + ', ' + pat);
                                                                       tasksToCreate.add(tasksToCreate(d, mapPhases, mapCases, pat));
                                                                   }
                                                                   if(pat.Activity_Type__c == 'Work Order'){
                                                                       system.debug('work order ' + pat);
                                                                       workOrdersToCreate.add(createListOfWorkOrders(pat, d, mapPhases));
                                                                   }
                                                               }
                                                           }
            }
            
            //create all WorkOrders indicated by the template
            try{
                insertSObjects(workOrdersToCreate);
            } catch(Exception e){
                System.debug('WorkOrders were not able to be created: ' + e);
                //add error handling for case after testing complete
            }
            
            //create all Tasks indicated by the template
            try{
                insertSObjects(tasksToCreate);
            } catch(Exception e){
                System.debug('PMT Tasks were not able to be created: ' + e);
                //add error handling for case after testing complete
            }
            //iv loop end
            
            //remove extra cases
            List<Id> caseIdsToKeep = new List<Id>();
            for(CaseProjectPhaseJunction__c cppJunction: casePhasesToCreate){
                caseIdsToKeep.add(cppJunction.Case__c);
            }
            List<Id> caseIdsToRemove = new List<Id>();
            for(Id cid: casesCreated){
                if(caseIdsToKeep.contains(cid)){
                    //do nothing
                } else {
                   caseIdsToRemove.add(cid);
                }
            }
            try{
                Database.delete(caseIdsToRemove);
            } catch(Exception e){
                System.debug('Extra cases were not able to be removed: ' + e);
                //add error handling for case after testing complete
            }

            
        }
        //method end
    }
    
    
 /*************************************************
* Name: CasesWithActivityTemplate
* Description: Inner class for keeping the ProjectActivityTemplateID with the CaseID after case creation

* Test class: 
* ***********************************************/   
    
    
    public class CasesWithActivityTemplate{
        String Subject;
        String RecordTypeId;
        String Description;
        String SupportQueue;
        String Origin;
        String OwnerId;
        String ProjectActivityTemplateID;
        String CaseId;
    }
    
    /************************************************
* Method Name: mapInputVariablesPhases 
* Description: Takes a list of Project Phase Junctions and input variable to create a Map of Project Phase ID to phase object
* Component(s): Method: createPMTProjectTemplatePhasesActivities
* Parameters : list of PMT_Project_Phase_Junction__c objects and the current input variable
* Return Values:  Map of Project Phase ID to phase object
* ***********************************************/ 
    
    public static Map<Id, PMT_Phase__c> mapInputVariablesPhases(List<PMT_Project_Phase_Junction__c> pids, InputVariables iv){
        List<Id> ids = new List<Id>();
        for(PMT_Project_Phase_Junction__c juncId : pids){
            ids.add(juncId.Id);
        }
        List<PMT_Project_Phase_Junction__c> phaseJunctions = [Select Phase_Name__c, Phase_Description__c, Project_Phase__r.Phase_Order__c, Project_Phase__c from PMT_Project_Phase_Junction__c where Id in: ids];
        
        
        //customer account on the Project needs to be added to the Phases
        String customerAccountId = [Select Customer__r.Id 
                                    from PMT_Project__c 
                                    where Id =: iv.ProjectId].get(0).Customer__r.Id;
        
        Map<Id, PMT_Phase__c> mapPhases = new Map<Id, PMT_Phase__c>();
        //create phases based on the information in the PMT Project Phase Junction (would grab directly from the Project Phase Template but all of the information is already written up to the PMT Project Phase Junction)
            for(PMT_Project_Phase_Junction__c ppj: phaseJunctions){
                PMT_Phase__c p = new PMT_Phase__c();
                p.Name = ppj.Phase_Name__c;
                p.Phase_Description__c = ppj.Phase_Description__c;
                p.Project__c = iv.ProjectID;
                p.Phase_Order__c = ppj.Project_Phase__r.Phase_Order__c;
                
                if(customerAccountId == '' || customerAccountId == null){ 
                }else{
                    p.Customer__c = customerAccountId;
                }
                
                mapPhases.put(ppj.Project_Phase__c,p);
            }
        return mapPhases;
    }
    
        /************************************************
* Method Name: insertSObjects 
* Description: Performs dml instert on a list of sObjects
* Component(s): Method: createPMTProjectTemplatePhasesActivities
* Parameters : list of sObjects
* Return Values:  void
* ***********************************************/ 
    
    public static void insertSObjects(List<sObject> objects){
        insert objects;
    }
    
    public static WorkOrder createListOfWorkOrders(PMT_Project_Activity_Template__c pat, Id i, Map<Id, PMT_Phase__c> mapPhases){

        WorkOrder w = new WorkOrder(); 
 
                w.Subject = pat.Subject__c;
                w.PMT_Phase__c = mapPhases.get(i).Id;
                w.Description = pat.Description__c;
                w.OwnerId = pat.OwnerId;
                w.Work_Category__c = 'Customer Install';

        return w;
    }
    
        /************************************************
* Method Name: CasesWithActivityTemplate 
* Description: Constructs a CasesWithActivityTemplate object using PMTPhaseTempActivityTempJunction__c and a map of caseRecordTypes
* Component(s): Method: createPMTProjectTemplatePhasesActivities
* Parameters : PMTPhaseTempActivityTempJunction__c, map of caseRecordType type with ID
* Return Values:  CasesWithActivityTemplate
* ***********************************************/ 
    
    public static CasesWithActivityTemplate getCasesWithActivityTemplates(PMTPhaseTempActivityTempJunction__c templateJunction, Map<String, Id> caseRecordTypes){
        CasesWithActivityTemplate cat = new CasesWithActivityTemplate();

                cat.Subject = templateJunction.PMT_Project_Activity_Template__r.Subject__c;
                cat.RecordTypeId = caseRecordTypes.get(templateJunction.PMT_Project_Activity_Template__r.Case_Record_Type__c);
                cat.Description = templateJunction.PMT_Project_Activity_Template__r.Description__c;
                cat.SupportQueue = templateJunction.PMT_Project_Activity_Template__r.Support_Group__c;
                cat.Origin = 'Project';
                cat.OwnerId = templateJunction.PMT_Project_Activity_Template__r.OwnerId;
                cat.ProjectActivityTemplateID = templateJunction.PMT_Project_Activity_Template__r.Id;

        return cat;
    }
    
        /************************************************
* Method Name: casePhasesToCreate 
* Description: compiles a list of CaseProjectPhaseJunctions that will become cases on each project phase from a list of PMTPhaseTempActivityTempJunction objects and two maps, one of Project Phase Ids with PMT Phase objects and the other with project activity Id with case objects
* Component(s): Method: createPMTProjectTemplatePhasesActivities
* Parameters : List of PMTPhaseTempActivityTempJunction objects, Map of Project Phase IDs to corresponding Phase objects, Map of PMT_Project_Phase_Template IDs to Case objects
* Return Values:  List<CaseProjectPhaseJunction__c>
* ***********************************************/ 
    
    public static List<CaseProjectPhaseJunction__c> casePhasesToCreate(List<PMTPhaseTempActivityTempJunction__c> junctions, Map<Id, PMT_Phase__c> mapPhases, Map<Id, Case> mapCases){
        List<CaseProjectPhaseJunction__c> casePhasesToCreate = new List<CaseProjectPhaseJunction__c>();

        for(PMTPhaseTempActivityTempJunction__c t: junctions){
            if(t.PMT_Project_Activity_Template__r.Activity_Type__c == 'Case'){
                
                CaseProjectPhaseJunction__c cpj = new CaseProjectPhaseJunction__c();                   
                cpj.Project_Phase__c = mapPhases.get(t.PMT_Project_Phase_Template__r.Id).Id;                      
                
                if(mapCases.get(t.PMT_Project_Activity_Template__r.Id) != null){
                    
                    cpj.Case__c = mapCases.get(t.PMT_Project_Activity_Template__r.Id).Id;    
                    casePhasesToCreate.add(cpj);
                }  
            }
        }
        
        return casePhasesToCreate;
    }
    
        /************************************************
* Method Name: tasksToCreate 
* Description: Generates a task from the inputs for later insertion on the Project
* Component(s): Method: createPMTProjectTemplatePhasesActivities
* Parameters : Project Phase Id, Map of Project Phase Ids with Phase objects, Map of PMT_Project_Activity_Templates with Cases, current PMT_Project_Activity_Template__c object
* Return Values:  PMT_Task__c
* ***********************************************/ 
    
    public static PMT_Task__c tasksToCreate(Id d, Map<Id, PMT_Phase__c> mapPhases, Map<Id, Case> mapCases, PMT_Project_Activity_Template__c pat){
        PMT_Task__c t = new PMT_Task__c();
        try{
            t.Case__c = mapCases.get(pat.Parent_Case_Template__c).Id;            
        } catch(Exception e){
            System.debug('No Parent_Case_Template__c');
        }                  


        t.Description__c = pat.Description__c;
        t.Assigned_To1__c = pat.OwnerId; 
        t.Phase__c = mapPhases.get(d).Id;
        t.Name = pat.Subject__c; 
        t.Task_Order__c = pat.Task_Order__c;

        return t;
    }
    
    //Class end
}