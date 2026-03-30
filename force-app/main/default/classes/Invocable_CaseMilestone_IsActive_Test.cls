@isTest
public class Invocable_CaseMilestone_IsActive_Test {
    @isTest
    public static void testCaseMilestoneIsActive(){
        Test.startTest();
        List<Entitlement> entitles = new List<Entitlement>();
        
        Entitlement entUse = new Entitlement();
        SlaProcess slaps = new SlaProcess();
        
        for(Entitlement ent : [SELECT SlaProcessId, Type FROM Entitlement]){
            List<SlaProcess> slas = [SELECT Id, Name FROM SlaProcess WHERE IsActive = true AND SobjectType = 'Case' AND Id =: ent.SlaProcessId];
            if(!slas.isEmpty()){
                entUse = ent;
                slaps = slas.get(0);
            }
        }

        Id customerAccountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer').getRecordTypeId();
        
        Account custAccount = new Account(Name='Test Customer Account', RecordTypeId=customerAccountRecordType);
        
        Test.stopTest();
        //Entitlement entitleTest = new entitlement(name='Test Entitlement', account)
    }
    
}