@isTest
public class INV_MultiSelectPicklist_NewDeleted_TEST {
    
    
    @isTest
    static void compareListsNewTest(){
        List<String> currentList = new List<String>();
        currentList.add('valueOne');
        currentList.add('valueTwo');
        currentList.add('valueThree');
        List<String> priorList = new List<String>();
        priorList.add('valueOne');
        priorList.add('valueTwo');
        
        List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables> variables = new List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables>();
        INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables inputs = new INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables();
        inputs.PriorList = priorList;
        inputs.CurrentList = currentList;
        variables.add(inputs);
        
        Test.startTest();
        try{List<String> comparedValues = INV_MultiSelectPicklist_NewDeleted_UTL.compareLists(variables).get(0).newList;
           }catch(Exception e){}
        Test.stopTest();
    }
    @isTest
    static void compareListsNewNULLTest(){
        List<String> currentList = new List<String>();
        currentList.add('valueOne');
        currentList.add('valueTwo');
        List<String> priorList = new List<String>();
        priorList.add('valueOne');
        priorList.add('valueTwo');
        
        List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables> variables = new List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables>();
        INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables inputs = new INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables();
        inputs.PriorList = priorList;
        inputs.CurrentList = currentList;
        variables.add(inputs);
        
        Test.startTest();
        try{List<String> comparedValues = INV_MultiSelectPicklist_NewDeleted_UTL.compareLists(variables).get(0).newList;
           }catch(Exception e){}
        Test.stopTest();
        
    }
    @isTest
    static void compareListsDeletedTest(){
        List<String> currentList = new List<String>();
        currentList.add('valueOne');
        currentList.add('valueTwo');
        List<String> priorList = new List<String>();
        priorList.add('valueOne');
        priorList.add('valueTwo');
        priorList.add('valueThree');
        
        List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables> variables = new List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables>();
        INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables inputs = new INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables();
        inputs.PriorList = priorList;
        inputs.CurrentList = currentList;
        variables.add(inputs);
        
        Test.startTest();
        try{List<String> comparedValues = INV_MultiSelectPicklist_NewDeleted_UTL.compareLists(variables).get(0).newList;
           }catch(Exception e){}
        Test.stopTest(); 
        
    }
    @isTest
    static void compareListsDeletedNULLTest(){
        List<String> currentList = new List<String>();
        currentList.add('valueOne');
        currentList.add('valueTwo');
        List<String> priorList = new List<String>();
        priorList.add('valueOne');
        priorList.add('valueTwo');
        
        List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables> variables = new List<INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables>();
        INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables inputs = new INV_MultiSelectPicklist_NewDeleted_UTL.inputVariables();
        inputs.PriorList = priorList;
        inputs.CurrentList = currentList;
        variables.add(inputs); 
        
        Test.startTest();
        try{List<String> comparedValues = INV_MultiSelectPicklist_NewDeleted_UTL.compareLists(variables).get(0).deletedList;
           }catch(Exception e){}
        Test.stopTest();
    }
    
}