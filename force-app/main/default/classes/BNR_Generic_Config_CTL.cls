public class BNR_Generic_Config_CTL {

    @AuraEnabled
    public static String getFieldValue(String objectAPIName, String fieldAPIName, String recordId){
        
        String query = 'select ' + fieldAPIName + ' from ' + objectAPIName + ' where Id = \'' + recordId + '\'';
        System.debug('query: ' + query);
        sObject[] returnobjects = Database.query(query);
        System.debug(returnobjects);
        String returnValue = string.valueOf(returnobjects.get(0).get(fieldAPIName));
        //Date time format is default and not the correct timezone.  CR says to leave as is 5/23/2023
        System.debug('return: ' + returnValue);
        
        return returnValue;
    }
    
}