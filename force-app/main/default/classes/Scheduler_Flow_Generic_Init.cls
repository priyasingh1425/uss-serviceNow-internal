global class Scheduler_Flow_Generic_Init Implements Schedulable{
    
    global void execute(SchedulableContext sc){
        CustomException ce = new CustomException();
        try{
            
            Scheduler_Flow_Generic__mdt settings = Scheduler_Flow_Generic_MDTBuilder.settings();
            
            Scheduler_Flow_Generic_Helper scheduleBatchFlow = new Scheduler_Flow_Generic_Helper(settings);
            
            List<String> crons = new List<String>();
            system.debug('frequency' + settings.Schedule_Frequency__c);
            system.debug('settings ' + settings);
            switch on String.valueOf(settings.Schedule_Frequency__c) {
                when 'Daily' {
                    
                    crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForDaily(settings));
                    
                } when 'Weekly' {
                    if(settings.Run_on_Sunday__c){
                        crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForWeekDay(settings, 1));
                    }
                    
                    if(settings.Run_on_Monday__c){
                        crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForWeekDay(settings, 2));
                    }
                    
                    if(settings.Run_on_Tuesday__c){
                        crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForWeekDay(settings, 3));
                    } 
                    
                    if(settings.Run_on_Wednesday__c){
                        crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForWeekDay(settings, 4));
                    }
                    
                    if(settings.Run_on_Thursday__c){
                        crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForWeekDay(settings, 5));
                    }
                    
                    if(settings.Run_on_Friday__c){
                        crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForWeekDay(settings, 6));
                    }
                    
                    if(settings.Run_on_Saturday__c){
                        crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForWeekDay(settings, 7));
                    }
                } when 'Monthly' {
                    crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForMonthly(settings, settings.Schedule_Month_Day__c));
                } when 'Quarterly' {
                    crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForQuarterly(settings));
                } when 'Yearly' {
                    crons.addAll(Scheduler_Flow_Generic_MDTBuilder.buildCronForYearly(settings));
                } when else {
                    ce.message = 'APEX Custom Error ::: Scheduler_Flow_Generic_Init ::: no schedule frequency found';
                    CustomException.sendErrorNotification(ce);
                }
            }
            Integer iter = 1;
            Set<String> cronUnique = new Set<String>(crons);
            List<String> iterCrons = new List<String>(cronUnique);
            for(String cron : iterCrons){
                System.schedule(settings.Job_Label__c + ' ' + iter, cron, scheduleBatchFlow);
                iter = iter + 1;
            }
        } catch(Exception e){
            ce.message = 'APEX Custom Error ::: line: ' + e.getLineNumber() + ' ::: ' + e.getMessage() + ' ::: ' + e.getCause();
            CustomException.sendErrorNotification(ce);
        }
    }
}