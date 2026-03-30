/**
 * @author Ladd Partners
 * @date 12/11/18
 * @group
*/

public with sharing class lp_toolsUtility {

    public static void setStageError(SCMImpToolsSO_Stage__c target, String message){
        target.Error__c = true;
        if(target.Error_Message__c != null){
            target.Error_Message__c += ', ' + message;
        }else{
            target.Error_Message__c = message;
        }
        System.debug('Stage error set: ' + message);
    }

    public static Object getData(Map<String, Schema.SObjectField> stagefs, SCMImpToolsSO_Stage__c stage, String column) {
        Object retValue  = null;
        System.debug('column ' + column);
        Schema.SObjectField sfield =  stagefs.get(column);
        System.debug('sfield ' + sfield);
        if (sfield !=  null){
            retValue = stage.get(column);
        }
        System.debug('retValue ' + retValue);
        return retValue;
    }

}