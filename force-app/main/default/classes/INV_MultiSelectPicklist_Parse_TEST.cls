@isTest
public class INV_MultiSelectPicklist_Parse_TEST {

    @isTest

    static void INV_MultiSelectPicklist_Parse_TEST(){

    

        List<INV_MultiSelectPicklist_ParseToComma_UTL.InputVariables> tempLst = new list<INV_MultiSelectPicklist_ParseToComma_UTL.InputVariables>();
        INV_MultiSelectPicklist_ParseToComma_UTL.InputVariables vals = new INV_MultiSelectPicklist_ParseToComma_UTL.InputVariables();
        vals.values = 'Test;Salesforce';

        tempLst.add(vals);

        INV_MultiSelectPicklist_ParseToComma_UTL.checkValues(tempLst);



    }

}