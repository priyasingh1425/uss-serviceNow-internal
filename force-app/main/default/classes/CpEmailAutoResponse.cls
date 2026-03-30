public class CpEmailAutoResponse {

    public static void tocEmailAutoResponse(Id caseId, String toAddress, String firstName){
        EmailMessage e = new EmailMessage();

        e.ToAddress = toAddress;
        e.EmailTemplateId = '00X6Q0000053wQQ';
        //ID for email template: Customer Portal Auto Response  Production: 00X6Q0000053wQQ, Sandbox: 00X8M000000UL6a 
        e.FromAddress = 'servicecloud@ussignal.com';
        String replyTo = 'toc@ussignal.com';
        
        basicMailer_withTemplate.sendEmailWithTemplateContactAgnostic(e, e.EmailTemplateId, caseId, replyTo, firstName);
        
    }
    
}