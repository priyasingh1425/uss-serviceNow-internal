public class INV_Flow_CollectionIndex_UTL {

    public class InputVariables{
        
        @InvocableVariable
        public List<String> collection;
        
        @InvocableVariable
        public String value;
           
    } 
    
    public class FlowOutputs{
        
        @InvocableVariable
        public Integer listIndex;
        
    }
    
    @InvocableMethod(label='Get Index of String in List' description='Takes a collection from a flow and finds the index of a string')
    public static List<FlowOutputs> getIndex(List<InputVariables> inputVariables) {
     
        List<FlowOutputs> returnValue = new List<FlowOutputs>();
        
        for(InputVariables iv: inputVariables){
            FlowOutputs valueIndex = new FlowOutputs();
            valueIndex.listIndex = iv.collection.indexOf(iv.value);
            returnValue.add(valueIndex);
        }
        
        return returnValue;        
        
    }
    
}