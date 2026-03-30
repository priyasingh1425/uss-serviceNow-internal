public class HLP_UserNotifications_Ins {
    
    //post to Chatter on an Object with a user mention.  Truncate to length
    public static void chatterPostToRecordWithMentionTruncated(Id recordId, Id userIdToMention, String postText, Integer truncate) {
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        mentionSegmentInput.id = userIdToMention;
        
        //max post is 10000 characters
        postText = postText.left(truncate);
        
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = postText;
        
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = recordId;
        
        try {
            ConnectApi.ChatterFeeds.postFeedElement(null, (String) recordId, ConnectApi.FeedElementType.FeedItem, postText);
        } catch (Exception e) {
            HLP_Case_SFQueue_Ins.createSFQueueCase('API_SellCPQ_GetQuotes_QRY', 'Unable to post error message to chatter: ' + e.getMessage(), 'Medium');
        }
    }
    
    public static void sendCustomSingleEmail(List<String> toAddresses, List<String> ccAddresses, String replyTo, String senderDisplayName, String subject, String htmlBody){
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
        if(a_ORG.IsSandbox){
            System.debug('This is Sandbox.  Email would be sent in Production: Subject: ' + subject + ' Body: ' + htmlBody);
        }else{       
            //reserve email capacity for the current Apex transaction to not exceed limits
            Messaging.reserveSingleEmailCapacity(2);
            
            //create email to send
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setCcAddresses(ccAddresses);
            mail.setReplyTo(replyTo);
            mail.setSenderDisplayName(senderDisplayName);
            mail.setSubject(subject);
            mail.setHtmlBody(htmlBody);
            
            //send email
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });            
            } catch (Exception e){
                HLP_Case_SFQueue_Ins.createSFQueueCase('HLP_UserNotifications_Ins.sendSingleEmail', 'Unable to send Email: ' + e.getMessage(), 'Medium');
            }   
        }
    }
    
    public static void sendCustomSingleEmailNoCC(List<String> toAddresses, String replyTo, String senderDisplayName, String subject, String htmlBody){
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
        if(a_ORG.IsSandbox){
            System.debug('This is Sandbox.  Email would be sent in Production: Subject: ' + subject + ' Body: ' + htmlBody);
        }else{        
            //reserve email capacity for the current Apex transaction to not exceed limits
            Messaging.reserveSingleEmailCapacity(2);
            
            //create email to send
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setReplyTo(replyTo);
            mail.setSenderDisplayName(senderDisplayName);
            mail.setSubject(subject);
            mail.setHtmlBody(htmlBody);
            
            //send email
            try{
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });            
            } catch (Exception e){
                HLP_Case_SFQueue_Ins.createSFQueueCase('HLP_UserNotifications_Ins.sendSingleEmail', 'Unable to send Email: ' + e.getMessage(), 'Medium');
            }
        }
        
    }
    
    
}