public class HLP_DowntimeEventOverlapHandler_QRY {

    public static void markOverlaps(List<Downtime_Event__c> newEvents) {
        try {
            Set<Id> configItemIds = new Set<Id>();
            for (Downtime_Event__c de : newEvents) {
                if (de.Configuration_Item__c != null &&
                    de.Start_Date_Time__c != null &&
                    de.End_Date_Time__c != null) {
                    configItemIds.add(de.Configuration_Item__c);
                }
            }

            if (configItemIds.isEmpty()) return;

            List<Downtime_Event__c> relatedEvents;

            if (newEvents.isEmpty() || newEvents[0].Id == null) {
                relatedEvents = [
                    SELECT Id, Configuration_Item__c, Start_Date_Time__c, End_Date_Time__c, Overlapping_Downtime__c
                    FROM Downtime_Event__c
                    WHERE Configuration_Item__c IN :configItemIds
                    AND Start_Date_Time__c != null
                    AND End_Date_Time__c != null
                ];
            } else {
                Set<Id> newEventIds = new Set<Id>();
                for (Downtime_Event__c e : newEvents) {
                    newEventIds.add(e.Id);
                }
                relatedEvents = [
                    SELECT Id, Configuration_Item__c, Start_Date_Time__c, End_Date_Time__c, Overlapping_Downtime__c
                    FROM Downtime_Event__c
                    WHERE Configuration_Item__c IN :configItemIds
                    AND Start_Date_Time__c != null
                    AND End_Date_Time__c != null
                    AND Id NOT IN :newEventIds
                ];
            }

            Map<Id, List<Downtime_Event__c>> groupedByConfig = new Map<Id, List<Downtime_Event__c>>();
            for (Downtime_Event__c event : relatedEvents) {
                Id key = event.Configuration_Item__c;
                if (!groupedByConfig.containsKey(key)) {
                    groupedByConfig.put(key, new List<Downtime_Event__c>());
                }
                groupedByConfig.get(key).add(event);
            }
            for (Downtime_Event__c newEvent : newEvents) {
                Id key = newEvent.Configuration_Item__c;
                if (!groupedByConfig.containsKey(key)) {
                    groupedByConfig.put(key, new List<Downtime_Event__c>());
                }
                groupedByConfig.get(key).add(newEvent);
            }

            // Detect overlaps
            Set<Id> overlappingIds = new Set<Id>();
            Set<String> overlappingKeys = new Set<String>();

            for (Id configId : groupedByConfig.keySet()) {
                List<Downtime_Event__c> eventList = groupedByConfig.get(configId);
                Integer n = eventList.size();
                for (Integer i = 0; i < n; i++) {
                    Downtime_Event__c a = eventList[i];
                    for (Integer j = 0; j < n; j++) {
                        if (i == j) continue;
                        Downtime_Event__c b = eventList[j];
                        if (doOverlap(a, b)) {
                            overlappingKeys.add(getKey(a));
                            overlappingKeys.add(getKey(b));
                            if (a.Id != null) overlappingIds.add(a.Id);
                            if (b.Id != null) overlappingIds.add(b.Id);
                        }
                    }
                }
            }

            for (Downtime_Event__c e : newEvents) {
                String key = getKey(e);
                e.Overlapping_Downtime__c = overlappingKeys.contains(key) ||
                                             (e.Id != null && overlappingIds.contains(e.Id));
            }

            List<Downtime_Event__c> existingToUpdate = new List<Downtime_Event__c>();
            for (Downtime_Event__c e : relatedEvents) {
                Boolean shouldBeTrue = overlappingIds.contains(e.Id);
                if (e.Overlapping_Downtime__c != shouldBeTrue) {
                    e.Overlapping_Downtime__c = shouldBeTrue;
                    existingToUpdate.add(e);
                }
            }

            if (!existingToUpdate.isEmpty()) {
                update existingToUpdate;
            }

        } catch (Exception ex) {
            HLP_Case_SFQueue_Ins.createSFQueueCase(
                'Error in HLP_DowntimeEventOverlapHandler_QRY.markOverlaps',
                'Exception: ' + ex.getMessage() + '\nStack Trace: ' + ex.getStackTraceString(),
                'High'
            );
        }
    }

    private static Boolean doOverlap(Downtime_Event__c a, Downtime_Event__c b) {
        return a.Start_Date_Time__c <= b.End_Date_Time__c &&
               b.Start_Date_Time__c <= a.End_Date_Time__c;
    }

    private static String getKey(Downtime_Event__c e) {
        return String.valueOf(e.Configuration_Item__c) + '|' +
               String.valueOf(e.Start_Date_Time__c) + '|' +
               String.valueOf(e.End_Date_Time__c);
    }
}