@IsTest
public class Scheduler_Flow_Generic_Test {
    
    public static testmethod void testScheduler_Flow_Generic_Init_Daily(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('Test_Configuration_Daily', CRON_EXP, new Scheduler_Flow_Generic_Init());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
    public static testmethod void testScheduler_Flow_Generic_Init_Weekly(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('Test_Configuration_Weekly', CRON_EXP, new Scheduler_Flow_Generic_Init());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
    public static testmethod void testScheduler_Flow_Generic_Init_Monthly(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('Test_Configuration_Monthly', CRON_EXP, new Scheduler_Flow_Generic_Init());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
    public static testmethod void testScheduler_Flow_Generic_Init_Quarterly(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('Test_Configuration_Quarterly', CRON_EXP, new Scheduler_Flow_Generic_Init());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
    public static testmethod void testScheduler_Flow_Generic_Init_Yearly(){
        Test.startTest();
        String CRON_EXP = '0 0 0 3 9 ? 2050';
        String jobId = System.schedule('Test_Configuration_Yearly', CRON_EXP, new Scheduler_Flow_Generic_Init());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        System.assertEquals('2050-09-03 00:00:00', String.valueOf(ct.NextFireTime));
        Test.stopTest();
    }
    public static testmethod void testScheduler_Flow_Generic_Helper_Daily(){
        Test.startTest();
        Scheduler_Flow_Generic__mdt settings = [SELECT Auto_Launch_Flow_to_Execute__c
                                                , Batch_Size__c
                                                , Flow_Input_Variable_Name__c
                                                , Input_Record_Type__c
                                                , Job_Frequency_in_Hours__c
                                                , Job_Frequency_in_Minutes__c
                                                , Job_Label__c
                                                , Job_Runs_Per_Day__c
                                                , Run_on_Friday__c
                                                , Run_on_Monday__c
                                                , Run_on_Saturday__c
                                                , Run_on_Sunday__c
                                                , Run_on_Thursday__c
                                                , Run_on_Tuesday__c
                                                , Run_on_Wednesday__c
                                                , Job_Start_Time_Hour__c
                                                , Job_Start_Time_Min__c
                                                , Schedule_Frequency__c
                                                , Start_Time_of_Day__c
                                                , Text_Query__c
                                                , Schedule_Month_Day__c
                                                , Run_Batches_Until_All_Records_Processed__c
                                                FROM Scheduler_Flow_Generic__mdt WHERE MasterLabel = 'Test_Configuration_Daily'].get(0);
        
        Scheduler_Flow_Generic_Helper schedme = new Scheduler_Flow_Generic_Helper(settings);
        
        String CRON_EXP = '0 0 * ? * *';
        String jobId = System.schedule('Test_Configuration_Daily', CRON_EXP, schedme);
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id =: jobId];
        System.assertEquals(0, ct.TimesTriggered);
        Test.stopTest();
    }
    public static testmethod void testScheduler_Flow_Generic_Batchable(){
        Test.startTest();
        try
        {
            Scheduler_Flow_Generic__mdt settings = [SELECT Auto_Launch_Flow_to_Execute__c
                                                    , Batch_Size__c
                                                    , Flow_Input_Variable_Name__c
                                                    , Input_Record_Type__c
                                                    , Job_Frequency_in_Hours__c
                                                    , Job_Frequency_in_Minutes__c
                                                    , Job_Label__c
                                                    , Job_Runs_Per_Day__c
                                                    , Run_on_Friday__c
                                                    , Run_on_Monday__c
                                                    , Run_on_Saturday__c
                                                    , Run_on_Sunday__c
                                                    , Run_on_Thursday__c
                                                    , Run_on_Tuesday__c
                                                    , Run_on_Wednesday__c
                                                    , Job_Start_Time_Hour__c
                                                    , Job_Start_Time_Min__c
                                                    , Schedule_Frequency__c
                                                    , Start_Time_of_Day__c
                                                    , Text_Query__c
                                                    , Schedule_Month_Day__c
                                                    ,Run_Batches_Until_All_Records_Processed__c
                                                    FROM Scheduler_Flow_Generic__mdt WHERE MasterLabel = 'Test_Configuration_Daily'].get(0);
            
            String soql = 'SELECT Id FROM Case_Template__c';
            
            Scheduler_Flow_Generic_Batchable testBatch = new Scheduler_Flow_Generic_Batchable(soql, settings);
            
            Database.executeBatch(testBatch);
        }
        catch (Exception expectedException)
        {
            system.assert(true, 'Batch should run but flow should not');
        }
        
        Test.stopTest();
    }
}