public class Invocable_CaseMilestone_IsActive {
    
    public class InputVariables{
        @InvocableVariable
        public String caseId;
        
        @InvocableVariable
        public String milestoneName;
    }
    
    public class ReturnVariables{
        @InvocableVariable
        public Boolean isActive;
        
        @InvocableVariable
        public String milestoneId;
        
        @InvocableVariable
        public Boolean noMilestoneFound;
        
    }
    
    @InvocableMethod(label='Determine if Case Milestone is Active from Case Id and Milestone Name' description='Returns IsActive true or false based on the input case Id and milestone name')
    public static List<ReturnVariables> caseMilestoneIsActive(List<InputVariables> inputVariables){
        //output initiation
        List<ReturnVariables> returnVariables = new List<ReturnVariables>();
        ReturnVariables returnVars = new ReturnVariables();
        //error monitoring initiation
        CustomException ce = new CustomException();
        try{
            //get the inputs
            System.debug('input caseId ::: ' + inputVariables.get(0).caseId);
            System.debug('input caseId ::: ' + inputVariables.get(0).milestoneName);
            String passedInCaseId = inputVariables.get(0).caseId;
            String passedInMilestoneName = inputVariables.get(0).milestoneName;
            
            //get the milestoneTypeId from the case Id and milestone Name
            List<MilestoneType> typeList = [SELECT Id FROM MilestoneType WHERE Id IN (SELECT MilestoneTypeId FROM CaseMilestone WHERE CaseId =: passedInCaseId) AND Name =: passedInMilestoneName];
            
            if(typeList.isEmpty()){
                returnVars.noMilestoneFound = true;
                System.debug('typeList isEmpty');
            } else {
                Id milestoneTypeId = typeList.get(0).Id;
                //from the milestoneTypeId, get the Case Milestone information (is completed?) from the Case Id & milestone type id.  Get only the most recent--some milestone types are recurring & only the most recent should be complete or not
                List<CaseMilestone> fullMilestoneList = [SELECT Id, IsCompleted FROM CaseMilestone WHERE CaseId =: passedInCaseId AND MilestoneTypeId =: milestoneTypeId ORDER BY CreatedDate Desc];
                
                CaseMilestone fullMilestone = new CaseMilestone();
                if(fullMilestoneList.isEmpty()){
                    returnVars.noMilestoneFound = true;
                    System.debug('fullMilestoneList isEmpty');
                } else {
                    //ready the outputs
                    //initialize returnVars.isActive as false
                    returnVars.isActive = false;
                    for(CaseMilestone cm : fullMilestoneList){
                    //if any are active, return that, otherwise false
                        if(!(cm.isCompleted)){
                            returnVars.isActive = true;
                        }
                    }
                    
                    fullMilestone = fullMilestoneList.get(0);
                    returnVars.isActive = !(fullMilestone.IsCompleted);
                    System.debug('isActive ::: ' + returnVars.isActive);
                    returnVars.milestoneId = fullMilestone.Id;
                    System.debug('milestoneId ::: ' + returnVars.milestoneId); 
                }
            }
            
            returnVariables.add(returnVars);
        } catch (Exception e) {
            returnVars.noMilestoneFound = true;
            returnVariables.add(returnVars);
            ce.message = 'APEX Custom Error ::: Invocable_CaseMilestone_IsActive ::: line: ' + e.getLineNumber() + ' ::: ' + e.getMessage() + ' ::: likely caused by erroneous flow input data ::: input Case Id ' + inputVariables.get(0).caseId + ' ::: input Milestone Name ' + inputVariables.get(0).milestoneName;
            CustomException.sendErrorNotification(ce);
        }
        
        return returnVariables;
    }
    
}