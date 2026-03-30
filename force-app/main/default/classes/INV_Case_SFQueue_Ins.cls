public class INV_Case_SFQueue_Ins {
    public class InputVariables{
        @InvocableVariable
        public String CaseSubject;
        
        @InvocableVariable
        public String CasePriority;
        
        @InvocableVariable
        public String CaseDescription;
    }
    
    @InvocableMethod(label='Create a Case for Salesforce Support' description='Creates a Break/Fix Case for Salesforce Support')
    public static void createSFQueueCaseInv(List<InputVariables> inputVariables){
        HLP_Case_SFQueue_Ins.createSFQueueCase(inputVariables.get(0).CaseSubject, inputVariables.get(0).CaseDescription, inputVariables.get(0).CasePriority);
    }
}