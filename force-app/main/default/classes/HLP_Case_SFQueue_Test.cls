@IsTest
public class HLP_Case_SFQueue_Test {
    @IsTest
    public static void hlpMethodCreateSFQueueCaseTest(){
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];

        if(a_ORG.IsSandbox){
            System.debug('This is Sandbox.  Case would be created in Production');
        } else {
            String testDescription = 'testDescription';
            String testSubject = 'testSubject';
            String testPriority = 'Medium';
            Test.startTest();
            HLP_Case_SFQueue_Ins.createSFQueueCase(testSubject, testDescription, testPriority);
            Case actualCase = [Select Subject, Description, Priority From Case Where Subject =: testSubject].get(0);
            System.assertEquals(testDescription, actualCase.Description);
            Test.stopTest();
        }
    }
    @IsTest
    public static void invCreateSFQueueCaseInvTest(){
            Organization a_ORG = [Select Id, Name, IsSandbox from Organization];

        if(a_ORG.IsSandbox){
            System.debug('This is Sandbox.  Case would be created in Production');
        } else {
            String testDescription = 'testDescription';
            String testSubject = 'testSubject';
            String testPriority = 'Medium';
            Invocable.Action action = Invocable.Action.createCustomAction('apex', 'INV_Case_SFQueue_Ins');
            action.setInvocationParameter('CaseSubject', testSubject);
            action.setInvocationParameter('CasePriority', testPriority);
            action.setInvocationParameter('CaseDescription', testDescription);
            Test.startTest();
            action.invoke();
            Case actualCase = [Select Subject, Description, Priority From Case Where Subject =: testSubject].get(0);
            System.assertEquals(testDescription, actualCase.Description);
            Test.stopTest();
        }
    }
    
}