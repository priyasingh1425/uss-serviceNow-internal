@isTest
public class EmailCase_SilentFail_andReattach_Tests {

    @isTest
    public static void caseChangesTest(){
        //CaseChangesForEmailToCase.silentlyFailIfSameSubject test
        
        Case testCase = new Case(Subject = 'testCase', Status = 'New', Origin = 'Email - CMC', SuppliedEmail = 'test@test.com');
        Case c = new Case(Subject = 'testCase', Status = 'New', Origin = 'Email - CMC', SuppliedEmail = 'test@test.com');
        
        insert testCase;
        
        Test.startTest();
        
        insert c;
        CaseChangesForEmailToCase.silentlyFailIfSameSubject(c);
        System.assertEquals('Disallow Creation', c.Triggering_Flow__c);
      
        Test.stopTest();
        
    }
}