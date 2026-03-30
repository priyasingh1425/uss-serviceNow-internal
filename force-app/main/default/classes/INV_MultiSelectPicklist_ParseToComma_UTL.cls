public class INV_MultiSelectPicklist_ParseToComma_UTL {
    public class InputVariables{
        
        @InvocableVariable
        public String values;
    }
    
    @InvocableMethod(label='Parse MultiSelect Picklist to use list in Collection Variable' description='Parses a MultiSelect Picklist from semicolon to comma delimited for use with Collection Variables')
    public static List<list<string>> checkValues(List<InputVariables> inputVariables) {
        
        list<list<string>> finalLst = new list<list<string>>();
        
        for(InputVariables iv: inputVariables){
            if(iv.values == null || iv.values == ''){
                finalLst.clear();
                return finalLst;
            }else{
                List<String> values = iv.values.split(';');
                system.debug('iniList: ' + values);
                if(!(values.isEmpty()) && (values.size() > 0)){
                    
                    List<String> lstnew = new List<String>(); 
                    
                    for(Integer i = 0; i < (values.size()); i++){
                        string tempStr = values[i];
                        system.debug('iniNewList: ' + tempStr);
                        List<String> tempList = tempStr.split(';');
                        lstnew.addAll(tempList);
                    }
                    
                    if(lstnew.isEmpty() || lstnew.size() <= 0){
                        finalLst.clear();
                        return finalLst;
                    }
                    system.debug('newList: ' + lstnew);
                    
                    
                    finalLst.add(lstnew);
                    system.debug('finalLst: ' + finalLst);
                    
                }  
            }
            
        }
        
        return finalLst;
        
    }
    
}