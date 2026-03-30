public class CaseChangesForEmailToCase {
    
    public static void silentlyFailIfSameSubject(Case c){
        try{
            List<Case> sameSubject = [select Id, CreatedDate, Status, Subject from Case where Subject =: c.Subject and SuppliedEmail =: c.SuppliedEmail and Origin =: c.Origin and IsClosed = FALSE order by CreatedDate asc];
            
            if(sameSubject.size() > 0){
                c.Triggering_Flow__c = 'Disallow Creation';
                EmailMessage email = new EmailMessage();
                email.Subject = c.Subject;
                email.TextBody = c.Description;
                
                email.FromAddress = c.SuppliedEmail;
                email.ToAddress = c.SuppliedEmail;
                email.Incoming = true;
                
                email.RelatedToId = sameSubject.get(0).Id;
                insert email;
                
                FeedItem post = new FeedItem();
                post.ParentId = sameSubject.get(0).Id;
                post.Body = 'A case with the same subject was deleted and the email was posted here.  If the email that was added to this Case should have generated a NEW Case, contact the Helpdesk.  The email added to this case can be found here: https://ussignal.lightning.force.com/lightning/r/Email/' + email.Id + '/view';
                insert post; 
            }
        }catch(Exception e){
            HLP_Case_SFQueue_Ins.createSFQueueCase('CaseChangesForEmailToCase', 'Could not post Same Subject message ::: Verify that the Case still exists -- many identical cases created at the same time can prevent this post from occurring' + c.Id + ' ::: Only one case with the following Subject should exist: ' + c.Subject + ' ::: merge any cases that are in excess.  This process can take a few minutes, so wait at least 5min before merging.  Merging too soon can cause this error to occur again.'  + e, 'Medium');
        }
    }
}