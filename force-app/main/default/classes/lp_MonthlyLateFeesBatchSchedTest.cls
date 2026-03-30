/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

 @IsTest
 public with sharing class lp_MonthlyLateFeesBatchSchedTest {
 
     @IsTest
     private static void runMonthlyBatch() {
         Test.startTest();
         lp_MonthlyLateFeesBatchSched lateFeesBatch = new lp_MonthlyLateFeesBatchSched();
         String chron = '0 0 23 * * ?';
         String jobId = System.schedule('Test Sched', chron, lateFeesBatch);
         Test.stopTest();
 
         CronTrigger ct = [SELECT Id, TimesTriggered
         FROM CronTrigger WHERE id = :jobId];
 
         System.assertEquals(0, ct.TimesTriggered);
     }
 }