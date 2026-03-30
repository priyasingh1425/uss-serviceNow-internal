@isTest
public class DeleteRecordsBatchable_Test {

    public static testmethod void testDelete_Scheduled_PardotListEmails(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('DeleteRecordsBatchable_Test', CRON_EXP, new Delete_Scheduled_PardotListEmails());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
        
    }
    public static testmethod void testDelete_Scheduled_AutoResponse(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('DeleteRecordsBatchable_Test', CRON_EXP, new Delete_Scheduled_AutoResponse());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
        
    }
    public static testmethod void testDelete_Scheduled_SalesloftAdminCalls(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('DeleteRecordsBatchable_Test', CRON_EXP, new Delete_Scheduled_SalesloftAdminCalls());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
    public static testmethod void testDeleteRecordsBatchable(){
        Test.startTest();
        
        Task testTask = new Task(Subject = 'Test: Delete Me');
        insert testTask;
        String soql = 'Select Id FROM Task';
 
        DeleteRecordsBatchable testBatch = new DeleteRecordsBatchable(soql);
        System.assertEquals(1, [Select Count() FROM Task WHERE Subject =: testTask.Subject]);
        Database.executeBatch(testBatch);
        Test.stopTest();
    }
}