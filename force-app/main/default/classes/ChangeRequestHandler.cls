public with sharing class ChangeRequestHandler {

    public static void afterUpdate(Map<Id, Case> oldCases, List<Case> newCases) {
        if (TriggerBypass.isChangeRequestHandlerBypassed()) {
            return;
        }

        Set<Id> eligibleRtIds = new Set<Id>{
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CityIntegrationConstants.RT_CHANGE_REQUEST).getRecordTypeId(),
            Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(CityIntegrationConstants.RT_EXTERNAL_CUSTOMER_SUPPORT).getRecordTypeId()
        };

        List<Case> statusUpdateCases = new List<Case>();
        List<Case> priorityUpdateCases = new List<Case>();
        Set<Id> caseIdsForNotes = new Set<Id>();

        for (Case newCase : newCases) {
            if (!eligibleRtIds.contains(newCase.RecordTypeId)) {
                continue;
            }
            Case oldCase = oldCases.get(newCase.Id);

            if (newCase.AccountId == CityIntegrationConstants.ACCOUNT_ID
                && (hasStatusChanged(oldCase, newCase) || isParkedWaitingForCustomer(oldCase, newCase) || hasTechnicalApprovalChanged(oldCase, newCase))) {
                statusUpdateCases.add(newCase);
            }

            if (hasPriorityChanged(oldCase, newCase)) {
                priorityUpdateCases.add(newCase);
            }

            if (hasNewChangeRequestNumber(oldCase, newCase)) {
                caseIdsForNotes.add(newCase.Id);
            }
        }

        if (!statusUpdateCases.isEmpty()) {
            if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                System.enqueueJob(new CreateRequestQueueable(statusUpdateCases, new List<Task>(), new List<FeedItem>(), true, false, false));
            } else {
                API_APIResponse_INS.createAPIResponse(null, null, 'Queueable limit reached — skipped status sync for ' + statusUpdateCases.size() + ' Case(s)', false, null, 'ChangeRequestHandler afterUpdate', 'false', '500', 'QueueableLimitExceeded', null, null, null);
            }
        }

        if (!priorityUpdateCases.isEmpty()) {
            if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                System.enqueueJob(new CreateRequestQueueable(priorityUpdateCases, new List<Task>(), new List<FeedItem>(), false, false, true));
            } else {
                API_APIResponse_INS.createAPIResponse(null, null, 'Queueable limit reached — skipped priority sync for ' + priorityUpdateCases.size() + ' Case(s)', false, null, 'ChangeRequestHandler afterUpdate', 'false', '500', 'QueueableLimitExceeded', null, null, null);
            }
        }

        if (!caseIdsForNotes.isEmpty()) {
            syncFeedItemsForCases(caseIdsForNotes, 'ChangeRequestHandler afterUpdate');
        }
    }

    public static void syncFeedItemsForCases(Set<Id> caseIds, String logContext) {
        if (caseIds.isEmpty()) {
            return;
        }

        List<FeedItem> feedItems = [
            SELECT Id, ParentId, Body, Visibility, Type
            FROM FeedItem
            WHERE ParentId IN :caseIds
            AND Visibility = 'AllUsers'
            AND Type = 'TextPost'
            LIMIT 1000
        ];

        if (feedItems.isEmpty()) {
            return;
        }

        Integer remainingQueueables = Limits.getLimitQueueableJobs() - Limits.getQueueableJobs();
        if (remainingQueueables <= 0) {
            API_APIResponse_INS.createAPIResponse(null, null, 'Queueable limit reached — skipped work note sync for ' + feedItems.size() + ' FeedItem(s)', false, null, logContext, 'false', '500', 'QueueableLimitExceeded', null, null, null);
        } else if (feedItems.size() <= remainingQueueables) {
            for (FeedItem feedItem : feedItems) {
                System.enqueueJob(new CreateRequestQueueable(new List<Case>(), new List<Task>(), new List<FeedItem>{feedItem}, false, false, false));
            }
        } else {
            Integer batchesEnqueued = 0;
            for (Integer i = 0; i < feedItems.size() && batchesEnqueued < remainingQueueables; i += CityIntegrationConstants.MAX_FEEDITEMS_PER_QUEUEABLE) {
                Integer endIndex = Math.min(i + CityIntegrationConstants.MAX_FEEDITEMS_PER_QUEUEABLE, feedItems.size());
                List<FeedItem> batch = new List<FeedItem>();
                for (Integer j = i; j < endIndex; j++) {
                    batch.add(feedItems[j]);
                }
                System.enqueueJob(new CreateRequestQueueable(new List<Case>(), new List<Task>(), batch, false, false, false));
                batchesEnqueued++;
            }
            Integer totalBatchesPossible = (Integer) Math.ceil((Decimal) feedItems.size() / CityIntegrationConstants.MAX_FEEDITEMS_PER_QUEUEABLE);
            if (batchesEnqueued < totalBatchesPossible) {
                Integer skippedItems = feedItems.size() - (batchesEnqueued * CityIntegrationConstants.MAX_FEEDITEMS_PER_QUEUEABLE);
                API_APIResponse_INS.createAPIResponse(null, null, 'Queueable limit reached — skipped work note sync for ~' + skippedItems + ' FeedItem(s) (' + batchesEnqueued + '/' + totalBatchesPossible + ' batches enqueued)', false, null, logContext, 'false', '500', 'QueueableLimitExceeded', null, null, null);
            }
        }
    }

    public static void afterTaskUpdate(Map<Id, Task> oldTasks, List<Task> newTasks) {
        List<Task> tasksToUpdate = new List<Task>();

        for (Task newTask : newTasks) {
            Task oldTask = oldTasks.get(newTask.Id);

            if (isTaskEligibleForUpdate(oldTask, newTask)) {
                tasksToUpdate.add(newTask);
            }
        }

        if (!tasksToUpdate.isEmpty()) {
            if (Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() > 0) {
                System.enqueueJob(new CreateRequestQueueable(new List<Case>(), tasksToUpdate, new List<FeedItem>(), false, true, false));
            } else {
                API_APIResponse_INS.createAPIResponse(null, null, 'Queueable limit reached — skipped task sync for ' + tasksToUpdate.size() + ' Task(s)', false, null, 'ChangeRequestHandler afterTaskUpdate', 'false', '500', 'QueueableLimitExceeded', null, null, null);
            }
        }
    }

    private static Boolean hasStatusChanged(Case oldCase, Case newCase) {
        return oldCase.Status != newCase.Status && newCase.Status != CityIntegrationConstants.STATUS_CLOSED;
    }

    private static Boolean hasPriorityChanged(Case oldCase, Case newCase) {
        return oldCase.Priority != newCase.Priority
            && newCase.AccountId == CityIntegrationConstants.ACCOUNT_ID;
    }

    private static Boolean isParkedWaitingForCustomer(Case oldCase, Case newCase) {
        return oldCase.Status != newCase.Status
            && newCase.Status == CityIntegrationConstants.STATUS_PARKED
            && oldCase.Status_Reason__c != newCase.Status_Reason__c
            && newCase.Status_Reason__c == CityIntegrationConstants.STATUS_REASON_WAITING;
    }

    private static Boolean hasTechnicalApprovalChanged(Case oldCase, Case newCase) {
        return oldCase.Technical_Approved__c != newCase.Technical_Approved__c
            && newCase.Technical_Approved__c == true;
    }

    private static Boolean hasNewChangeRequestNumber(Case oldCase, Case newCase) {
        return String.isBlank(oldCase.Customer_Rec_Id__c)
            && String.isNotBlank(newCase.Customer_Rec_Id__c)
            && (newCase.Customer_Rec_Id__c.startsWith(CityIntegrationConstants.PREFIX_CHANGE)
                || newCase.Customer_Rec_Id__c.startsWith(CityIntegrationConstants.PREFIX_INCIDENT));
    }

    private static Boolean isTaskEligibleForUpdate(Task oldTask, Task newTask) {
         return newTask.Customer_Rec_Id__c != null
             && (oldTask.Status != newTask.Status || String.valueOf(oldTask.Subject) != String.valueOf(newTask.Subject));
    }
}