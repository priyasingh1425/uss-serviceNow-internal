public class BNR_Case_Escalation_CTRL {
    @AuraEnabled
    public static Case getCase(String recordId) {
        Case c = [SELECT Id, Escalation_Level__c FROM Case WHERE Id=:recordId];        
        return c;
    }
}