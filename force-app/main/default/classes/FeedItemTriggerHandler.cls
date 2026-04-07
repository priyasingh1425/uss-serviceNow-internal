public with sharing class FeedItemTriggerHandler {
    public static void afterInsert(List<FeedItem> newRecords) {
        if (TriggerBypass.isFeedItemTriggerBypassed()) {
            return;
        }
        List<FeedItem> records = new List<FeedItem>();
        for (FeedItem record : newRecords) {
            if (record.ParentId != null
                && record.ParentId.getSObjectType() == Case.SObjectType
                && record.Visibility == 'AllUsers'
                && record.Type == 'TextPost') {
                records.add(record);
            }
        }

        if (!records.isEmpty()) {
            if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                System.enqueueJob(new CreateRequestQueueable(new List<Case>(), new List<Task>(), records, false, false, false));
            } else {
                API_APIResponse_INS.createAPIResponse(null, null, 'Queueable limit reached — skipped work note sync for ' + records.size() + ' FeedItem(s)', false, null, 'FeedItemTriggerHandler afterInsert', 'false', '500', 'QueueableLimitExceeded', null, null, null);
            }
        }
    }
}
