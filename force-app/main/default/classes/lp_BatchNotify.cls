/**
 * @author Ladd Partners
 * @date 8/22/2017
 * @group
*/

public with sharing class lp_BatchNotify {

    public class Notification {

        public String description { get; set; }
        public Id recordId { get; set; }
        public String recordName { get; set; }
        public Exception ex { get; set; }

        public Notification(String description, Id recordId, String recordName, Exception ex) {
            this.description = description;
            this.recordId = recordId;
            this.recordName = recordName;
            this.ex = ex;
        }

    }

    public List<Notification> notifications { get; private set; }
    public Integer processedRecordCount { get; set; }
    public Integer errorRecordCount { get; set; }

    public lp_BatchNotify() {
        this.notifications = new List<Notification>();
        this.processedRecordCount = 0;
        this.errorRecordCount = 0;
    }

    public void addNotification(String description, Exception ex) {
        addNotification(description, null, ex);
    }

    public void addNotification(String description, Id recordId, Exception ex) {
        this.notifications.add(new Notification(description, recordId, null, ex));
    }

    public void addNotification(String description, Id recordId, String recordName, Exception ex) {
        this.notifications.add(new Notification(description, recordId, recordName, ex));
    }

    public void sendUserEmailNotification(String userEmail, String jobName, Schema.SObjectType sobjType) {
        String subject = jobName + ' batch completed';
        sendEmailNotification(new List<String>{userEmail}, subject, sobjType);
    }

    public void sendEmailNotification(String[] emailTo, String subject, Schema.SObjectType sobjType) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

        if (emailTo == null || emailTo.isEmpty()) {
            throw new lp_Exception('Notification email not sent - no email address found.');
        }

        subject += (this.errorRecordCount == 0) ? ' successfully.' : ' with errors.';
        subject += ' [' + UserInfo.getOrganizationName() + ']';

        String body = String.format('Job processed {0} record(s) with {1} error(s).', new String[]{ String.valueOf(this.processedRecordCount), String.valueOf(this.errorRecordCount) });

        for (Notification notification : this.notifications) {
            body += '\n\n' + notification.description;
            if (notification.recordName != null) {
                body += ' [record: ' + notification.recordName + ']';
            } else if (notification.recordId != null) {
                body += ' [record: ' + notification.recordId + ']';
            }
            if (notification.ex != null) {
                body += '\n' + notification.ex.getMessage();
                body += '\n' + notification.ex.getStackTraceString();
            }
        }

        if (sobjType != null) {
            Schema.DescribeSObjectResult dsr = sobjType.getDescribe();
            body += '\n\nSee ' + dsr.getLabelPlural() + ' for more information.';
            body += '\n' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + dsr.getKeyPrefix();
        }

        body += '\n\nOrgId: ' + UserInfo.getOrganizationId();

        email.setToAddresses(emailTo);
        email.setSaveAsActivity(false);
        email.setSubject(subject);
        email.setPlainTextBody(body);

        if (!Test.isRunningTest()) {
            try {
                Messaging.reserveSingleEmailCapacity(1);

                Messaging.SendEmailResult[] emailResults = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                for (Messaging.SendEmailResult sendEmailResult : emailResults) {
                    System.debug('sendEmailResult: ' + sendEmailResult);
                    System.debug('success:' + sendEmailResult.isSuccess());
                    System.debug('errors:' + sendEmailResult.getErrors());
                }
            } catch (Exception emailEx) {
                System.debug('Send email exception: ' + emailEx.getMessage());
                System.debug('Stack: ' + emailEx.getStackTraceString());
                System.debug('Email body: ' + email.plainTextBody);
                // TODO: find alternate means of communicating the info from this email
            }
        }
    }

    public void sendChatterMessages() {
        List<FeedItem> feedItems = new List<FeedItem>();

        List<String> objectNames = new List<String>();
        for (Notification notification : notifications) {
            if (notification.recordId != null) {
                SObjectType objectType = (SObjectType) notification.recordId.getSobjectType();
                objectNames.add(objectType.toString());
            }
        }

        if (!objectNames.isEmpty()) {
            List<Schema.DescribeSObjectResult> descResults = Schema.describeSObjects(objectNames);
            Map<String, Boolean> feedEnabledBySObjectName = new Map<String, Boolean>();
            for (DescribeSObjectResult describeResult : descResults) {
                feedEnabledBySObjectName.put(describeResult.getName(), describeResult.isFeedEnabled());
            }

            for (Notification notification : notifications) {
                if (notification.recordId != null) {
                    String sobjectName = ((SObjectType) notification.recordId.getSobjectType()).toString();
                    if (feedEnabledBySObjectName.get(sobjectName)) {
                        FeedItem feed = new FeedItem();
                        feed.ParentId = notification.recordId;
                        feed.Body = notification.description;
                        feedItems.add(feed);
                    } else {
                        System.debug('Chatter not created. Feed is not enabled for ' + sobjectName);
                    }
                }
            }

            insert feedItems;
        }
    }

}