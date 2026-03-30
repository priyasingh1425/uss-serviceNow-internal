public class INV_MultiSelectPicklist_NewDeleted_UTL {
    public class InputVariables{
        
        @InvocableVariable
        public List<String> PriorList;
        
        @InvocableVariable
        public List<String> CurrentList;
    }
    
    public class OutputVariables{
        @InvocableVariable
        public List<String> deletedList;
        
        @InvocableVariable
        public List<String> newList;
    }
    
    @InvocableMethod(label='Compare MultiSelect Picklist values for New or Deleted' description='Compares values within two MultiSelect Picklists to determine which values are new and which were deleted -- can only return either new or deleted at one time')
    public static List<OutputVariables> compareLists(List<InputVariables> inputVariables){
        List<OutputVariables> finalList = new List<OutputVariables>();
        for(InputVariables iv: inputVariables){
            system.debug('23' + iv);
            List<String> prior = iv.PriorList;
            system.debug('25');
            List<String> current = iv.CurrentList;
            system.debug('27');
            List<String> comparedNewValues = new List<String>();
            List<String> comparedDeletedValues = new List<String>();
            OutputVariables output = new OutputVariables();
            if(iv.PriorList == null || iv.PriorList.isEmpty()){
                system.debug('prior is empty');
                comparedNewValues = current;
                comparedDeletedValues.clear();
            } else if(iv.CurrentList == null || iv.CurrentList.isEmpty()){
                system.debug('current is empty');
                comparedDeletedValues = prior;
                comparedDeletedValues.clear();
            } else{
                for(String c : current){
                    
                    System.debug('current ' + c);
                    if(!prior.contains(c)){
                        System.debug(c);
                        comparedNewValues.add(c);
                    }
                }
                
                for(String p : prior){
                    if(!current.contains(p)){
                        comparedDeletedValues.add(p);
                    }
                }
            }
            
            
            
            if(comparedNewValues.isEmpty()){
                output.newList = null;
            } else {
                output.newList = comparedNewValues; 
                System.debug('newList: ' + output.newList);
            }
            if(comparedDeletedValues.isEmpty()){
                output.deletedList =  null;
            } else {
                output.deletedList = comparedDeletedValues;
                System.debug('deletedList: ' + output.deletedList);
            }
            finalList.add(output);
            
        }
        return finalList;
    }
}