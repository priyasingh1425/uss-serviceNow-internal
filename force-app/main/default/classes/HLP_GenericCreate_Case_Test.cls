@IsTest
public class HLP_GenericCreate_Case_Test {
	@IsTest
    public static void hlpMethodGenericCreateCaseTest()
    {
        String testDescription = 'Test Generic Case Description';
        String testSubject = 'Test Generic Case Subject';
        String ownerID = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'Ops - Monitoring'].get(0).Queue.Id;
        
        Test.startTest();
        HLP_GenericCreate_UTL.createGenericCase(testSubject,
                                                testDescription,
                                                'Unassigned',
                                                'Ops - Monitoring',
                                                ownerID,
                                                false);
        Case actualCase = [Select Subject, Description, Priority From Case Where Subject =: testSubject].get(0);
        System.assertEquals(testDescription, actualCase.Description);
        System.assertEquals(testSubject, actualCase.Subject);
        Test.stopTest();
    }
    @IsTest
    public static void hlpMethodGenericCreateBulkCaseTest()
    {
        String testDescription = 'Test Generic Case Description';
        String testSubject = 'Test Generic Case Subject';
        String ownerID = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'Ops - Monitoring'].get(0).Queue.Id;
        
        Test.startTest();
        HLP_GenericCreate_UTL.createGenericCase(testSubject,
                                                testDescription,
                                                'Unassigned',
                                                'Ops - Monitoring',
                                                ownerID,
                                                true);
        Case actualCase = [Select Subject, Description, Priority From Case Where Subject =: testSubject].get(0);
        System.assertEquals(testDescription, actualCase.Description);
        System.assertEquals(testSubject, actualCase.Subject);
        Test.stopTest();
    }
}