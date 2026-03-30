public class Scheduler_Flow_Generic_MDTBuilder {
    public static Scheduler_Flow_Generic__mdt settings(){
        
        //construct settings from admin-configurable metadata type record: metadata type = Scheduler_Flow_Generic__mdt, record to use = Job Label from init run.
        
        Scheduler_Flow_Generic__mdt settings = new Scheduler_Flow_Generic__mdt();
        CustomException ce = new CustomException();
        
        try{
            
            //first get the Apex Class Id from the generic scheduler -- this is the class that would be run from "Schedule Apex" by the admin
            //from this Id we are going to identify the "Schedule Apex" that was just run to see what metadata record (configuration settings, essentially) needs to be picked up -- the Job Label should match the metadata record name exactly
            Id apexClassId = [SELECT Id FROM ApexClass WHERE Name = 'Scheduler_Flow_Generic_Init'].get(0).Id;
            System.debug('apexClassId ' + apexClassId);
            //then get the CronTrigger Id from the recent AsyncApexJob "Schedule Apex" that was just created to initialize this run
            Id cronTriggerId = [SELECT Id, CronTriggerId FROM AsyncApexJob WHERE ApexClassId =: apexClassId ORDER BY CreatedDate desc].get(0).CronTriggerId;
            System.debug('cronTriggerId ' + cronTriggerId);
            Id cronJobId = [SELECT Id, CronJobDetailId FROM CronTrigger WHERE Id =: cronTriggerId].get(0).CronJobDetailId;
            System.debug('cronJobId ' + cronJobId);
            //then get the Job Name from the recent AsyncApexJob "Schedule Apex" based on the CronTrigger Id associated with the CronJobDetail
            //this is the name of the metadata record to use
            String initJobName = [SELECT Id, Name FROM CronJobDetail WHERE Id =: cronJobId].get(0).Name;
            System.debug('initJobName ' + initJobName);
            List<Scheduler_Flow_Generic__mdt> settingsAsList = [SELECT Auto_Launch_Flow_to_Execute__c
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
                                                                FROM Scheduler_Flow_Generic__mdt WHERE MasterLabel =: initJobName];
            
            if(!settingsAsList.isEmpty()){
                settings = settingsAsList.get(0);
            } 
        }catch(Exception e){
            ce.message = 'APEX Custom Error ::: Scheduler_Flow_Generic_MDTBuilder ::: line: ' + e.getLineNumber() + ' ::: ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
        return settings;
    }
    
    public static List<String> buildCronForDaily(Scheduler_Flow_Generic__mdt settings){
        //initialize start times
        Integer hourTime = Integer.valueOf(settings.Job_Start_Time_Hour__c);
        Integer minuteTime = Integer.valueOf(settings.Job_Start_Time_Min__c);
        
        //initialize cron String list to return
        List<String> crons = new List<String>();
        
        //convert 12hr time to 24hr time
        if(hourTime != 12 && settings.Start_Time_of_Day__c == 'PM'){
            hourTime = hourTime + 12;
        } else if(hourTime == 12 && settings.Start_Time_of_Day__c == 'AM'){
            hourTime = 0;
        }
        
        for(Integer i = 0; i < settings.Job_Runs_Per_Day__c; i++){
            String cronString = '0 ' + minuteTime + ' ' + hourTime + ' ? * *';
            crons.add(cronString);
            minuteTime = minuteTime + Integer.valueOf(settings.Job_Frequency_in_Minutes__c);
            hourTime = hourTime + Integer.valueOf(settings.Job_Frequency_in_Hours__c);
            if(minuteTime >= 60){
                minuteTime = minuteTime - 60;
                hourTime = hourTime + 1;
            }
            if(hourTime >= 24){
                hourTime = hourTime - 24;
            }
        }
		return crons;        
    }
    
    public static List<String> buildCronForWeekDay(Scheduler_Flow_Generic__mdt settings, Integer dayOfWeek){
        //initialize start times
        Integer hourTime = Integer.valueOf(settings.Job_Start_Time_Hour__c);
        Integer minuteTime = Integer.valueOf(settings.Job_Start_Time_Min__c);
        
        //initialize cron String list to return
        List<String> crons = new List<String>();
        
        //convert 12hr time to 24hr time
        if(hourTime != 12 && settings.Start_Time_of_Day__c == 'PM'){
            hourTime = hourTime + 12;
        } else if(hourTime == 12 && settings.Start_Time_of_Day__c == 'AM'){
            hourTime = 0;
        }
        
        for(Integer i = 0; i < settings.Job_Runs_Per_Day__c; i++){
            String cronString = '0 ' + minuteTime + ' ' + hourTime + ' ? * ' + dayOfWeek;
            crons.add(cronString);
            minuteTime = minuteTime + Integer.valueOf(settings.Job_Frequency_in_Minutes__c);
            hourTime = hourTime + Integer.valueOf(settings.Job_Frequency_in_Hours__c);
            if(minuteTime >= 60){
                minuteTime = minuteTime - 60;
                hourTime = hourTime + 1;
            }
            if(hourTime >= 24){
                hourTime = hourTime - 24;
            }
        }
        
        return crons;
    }
    
    public static List<String> buildCronForMonthly(Scheduler_Flow_Generic__mdt settings, String monthday){
        //initialize start times
        Integer hourTime = Integer.valueOf(settings.Job_Start_Time_Hour__c);
        Integer minuteTime = Integer.valueOf(settings.Job_Start_Time_Min__c);
        
        //initialize cron String list to return
        List<String> crons = new List<String>();
        
        //convert 12hr time to 24hr time
        if(hourTime != 12 && settings.Start_Time_of_Day__c == 'PM'){
            hourTime = hourTime + 12;
        } else if(hourTime == 12 && settings.Start_Time_of_Day__c == 'AM'){
            hourTime = 0;
        }
        
        for(Integer i = 0; i < settings.Job_Runs_Per_Day__c; i++){
            String cronString = '0 ' + minuteTime + ' ' + hourTime + ' ' + monthday + ' * ?';
            crons.add(cronString);
            minuteTime = minuteTime + Integer.valueOf(settings.Job_Frequency_in_Minutes__c);
            hourTime = hourTime + Integer.valueOf(settings.Job_Frequency_in_Hours__c);
            if(minuteTime >= 60){
                minuteTime = minuteTime - 60;
                hourTime = hourTime + 1;
            }
            if(hourTime >= 24){
                hourTime = hourTime - 24;
            }
        }
        
        return crons;
    }
    public static List<String> buildCronForQuarterly(Scheduler_Flow_Generic__mdt settings){
        //initialize start times
        Integer hourTime = Integer.valueOf(settings.Job_Start_Time_Hour__c);
        Integer minuteTime = Integer.valueOf(settings.Job_Start_Time_Min__c);
        Integer monthNumber = Integer.valueOf(Date.today().month());
        
        //initialize cron String list to return
        List<String> crons = new List<String>();
        
        //convert 12hr time to 24hr time
        if(hourTime != 12 && settings.Start_Time_of_Day__c == 'PM'){
            hourTime = hourTime + 12;
        } else if(hourTime == 12 && settings.Start_Time_of_Day__c == 'AM'){
            hourTime = 0;
        }
        for(Integer j = 0; j < 4; j++){
            for(Integer i = 0; i < settings.Job_Runs_Per_Day__c; i++){
                String cronString = '0 ' + minuteTime + ' ' + hourTime + ' ? ' + monthNumber + ' ?';
                crons.add(cronString);
                minuteTime = minuteTime + Integer.valueOf(settings.Job_Frequency_in_Minutes__c);
                hourTime = hourTime + Integer.valueOf(settings.Job_Frequency_in_Hours__c);
                
                if(minuteTime >= 60){
                    minuteTime = minuteTime - 60;
                    hourTime = hourTime + 1;
                }
                if(hourTime >= 24){
                    hourTime = hourTime - 24;
                }
            }
            monthNumber = monthNumber + 3;
            if(monthNumber >= 12){
                monthNumber = monthNumber - 12;
            }
        }
        
        return crons;
    }
    
    public static List<String> buildCronForYearly(Scheduler_Flow_Generic__mdt settings){
        //initialize start times
        Integer hourTime = Integer.valueOf(settings.Job_Start_Time_Hour__c);
        Integer minuteTime = Integer.valueOf(settings.Job_Start_Time_Min__c);
        Integer monthNumber = Integer.valueOf(Date.today().month());
        Integer monthDay = Integer.valueOf(Date.today().day());
        
        //initialize cron String list to return
        List<String> crons = new List<String>();
        
        //convert 12hr time to 24hr time
        if(hourTime != 12 && settings.Start_Time_of_Day__c == 'PM'){
            hourTime = hourTime + 12;
        } else if(hourTime == 12 && settings.Start_Time_of_Day__c == 'AM'){
            hourTime = 0;
        }
        for(Integer i = 0; i < settings.Job_Runs_Per_Day__c; i++){
            String cronString = '0 ' + minuteTime + ' ' + hourTime + ' ' + monthDay + ' ' + monthNumber + ' ? *';
            crons.add(cronString);
            minuteTime = minuteTime + Integer.valueOf(settings.Job_Frequency_in_Minutes__c);
            hourTime = hourTime + Integer.valueOf(settings.Job_Frequency_in_Hours__c);
            
            if(minuteTime >= 60){
                minuteTime = minuteTime - 60;
                hourTime = hourTime + 1;
            }
            if(hourTime >= 24){
                hourTime = hourTime - 24;
            }
        }
        return crons;
    }
}