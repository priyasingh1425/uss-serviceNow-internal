@isTest
public class INV_Flow_CollectionIndex_TEST {

    @isTest
    static void getIndexTest(){
        
        List<INV_Flow_CollectionIndex_UTL.InputVariables> inputVariables = new List<INV_Flow_CollectionIndex_UTL.InputVariables>();
        INV_Flow_CollectionIndex_UTL.InputVariables inputs = new INV_Flow_CollectionIndex_UTL.InputVariables();
        List<String> inl = new List<String>();
        inl.add('A');
        inl.add('B');
        inl.add('C');
        inputs.collection = inl;
        inputs.value = 'C';
        inputVariables.add(inputs);
        
        
        Assert.areEqual(INV_Flow_CollectionIndex_UTL.getIndex(inputVariables).get(0).listIndex,2);
    }
    
}