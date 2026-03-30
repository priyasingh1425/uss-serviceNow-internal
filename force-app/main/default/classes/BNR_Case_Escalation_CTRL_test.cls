@IsTest
public class BNR_Case_Escalation_CTRL_test {
    
    @IsTest
    public static void testGetCase(){
        Case c = new Case();
        String expected = 'Level 2 - TOC Supervisor';
        c.Escalation_Level__c = expected;
        insert c;
        Test.startTest();
        Case actual = BNR_Case_Escalation_CTRL.getCase(c.Id);
        System.assertEquals(expected, actual.Escalation_Level__c);
        Test.stopTest();
    }

}