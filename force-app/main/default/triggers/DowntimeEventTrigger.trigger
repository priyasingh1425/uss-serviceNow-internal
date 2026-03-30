trigger DowntimeEventTrigger on Downtime_Event__c (before insert, before update) {
    try {
        List<Downtime_Event__c> changedRecords = new List<Downtime_Event__c>();

        if (Trigger.isInsert) {
            changedRecords = Trigger.new;
        } else if (Trigger.isUpdate) {
            for (Downtime_Event__c newRec : Trigger.new) {
                Downtime_Event__c oldRec = Trigger.oldMap.get(newRec.Id);

                if (
                    newRec.Start_Date_Time__c != oldRec.Start_Date_Time__c ||
                    newRec.End_Date_Time__c != oldRec.End_Date_Time__c ||
                    newRec.Configuration_Item__c != oldRec.Configuration_Item__c
                ) {
                    changedRecords.add(newRec);
                }
            }
        }

        if (!changedRecords.isEmpty()) {
            HLP_DowntimeEventOverlapHandler_QRY.markOverlaps(changedRecords);
        }

    } catch (Exception ex) {
        HLP_Case_SFQueue_Ins.createSFQueueCase(
            'DowntimeEventTrigger Error','An error occurred in DowntimeEventTrigger during ' +(Trigger.isInsert ? 'insert' : 'update') +' on Downtime_Event__c\n\n' +'Error Message: ' + ex.getMessage() + '\n\n' +'Stack Trace: ' + ex.getStackTraceString(),'High'
        );
    }
}