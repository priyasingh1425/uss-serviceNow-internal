public class Email_genericSend_withTemplate {
    
    @InvocableMethod(label='Send Email with Template' description='Sends an email from a list of text: Text required IN ORDER: Email Template ID, WhatID, ReplyTo, ToAddress')
    public static void sendEmailGenericTemplate(List<List<String>> buildEmail){
        for(List<String> email : buildEmail){
            System.debug('email from flow ::: ' + email);
        String firstName;
        //handling for Salesforce bug that pulls collections of text as lists of lists of strings, but with "" rather than ''
        String template = email.get(0).replace('"','').replace(',','');
            System.debug('template ::: ' + template);
        String to = email.get(3).replace('"','').replace(',','');
            System.debug('to ::: ' + to);
        String what = email.get(1).replace('"','').replace(',','');
            System.debug('what ::: ' + what);
        String replyTo = email.get(2).replace('"','').replace(',','');
            System.debug('replyTo ::: ' + replyTo);
            system.debug(email.size());
            if(email.size() != 5){
                firstName = '';
            } else{
                if(email.get(4) == null || String.isBlank(email.get(4)) || String.isEmpty(email.get(4))){
                    firstName = '';
                }else{
        		firstName = email.get(4).replace('"','').replace(',','');                       
                }
            }
    
        EmailMessage e = new EmailMessage();
        e.FromAddress = 'servicecloud@ussignal.com';
        e.EmailTemplateId = template;
        e.ToAddress = to;
        Id whatId = Id.valueOf(what);
        
        basicMailer_withTemplate.sendEmailWithTemplateContactAgnostic(e, e.EmailTemplateId, whatId, replyTo, firstName);   
        }
    }

}