global class Quote_ExpirationSchedulableHandler implements Schedulable 
{
    global void execute(SchedulableContext ctx) 
    {
        List<SBQQ__Quote__c> quotes = [SELECT ID, Reminder_Email_Date__c, Reminder_Sent__c
                                        FROM SBQQ__Quote__c
                                        WHERE Reminder_Email_Date__c <= TODAY AND Reminder_Sent__c = FALSE];


        if (!quotes.isEmpty())
        {
            for(SBQQ__Quote__c q : quotes)
            {
                q.Reminder_Sent__c = true;
            }
    
            update quotes;
        }
    }
}