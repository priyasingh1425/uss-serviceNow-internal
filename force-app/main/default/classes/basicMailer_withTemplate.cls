public class basicMailer_withTemplate {
    
    public static void sendEmailWithTemplateContactAgnostic(EmailMessage flowEmail, Id templateId, Id whatId, String replyTo, String firstName){
        //firstName currently only configured for use with templates that contain the greeting "Hello ,"
        List<Messaging.SingleEmailMessage> messageList = new List<Messaging.SingleEmailMessage>();
        Integer cap = 0;
        System.debug('incoming body ' + flowEmail.HtmlBody);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        system.debug('fromAddress ' + flowEmail.FromAddress);
        if((String.isNotBlank(flowEmail.ToAddress) && String.isNotEmpty(flowEmail.ToAddress) && flowEmail.ToAddress !=null)){
            system.debug('toAddress ' + flowEmail.ToAddress);
            email.setToAddresses(flowEmail.ToAddress.split(';'));
            cap = cap + email.getToAddresses().size();
        }    
        if((String.isNotBlank(flowEmail.CCAddress) && String.isNotEmpty(flowEmail.CCAddress) && flowEmail.CcAddress != null)){
			email.setCCAddresses(flowEmail.CCAddress.split(';'));
            cap = cap + email.getCcAddresses().size();
        }
        
        if((String.isNotBlank(flowEmail.FromAddress) && String.isNotEmpty(flowEmail.FromAddress) && flowEmail.FromAddress != null)){
            for(OrgWideEmailAddress owe : [Select Id, Address, DisplayName from OrgWideEmailAddress]){
                if(owe.Address.contains(flowEmail.FromAddress)){
                    String param1 = owe.Id;
                    system.debug('owe.Id ' + param1);
                    email.setOrgWideEmailAddressId(param1);
                }
            }
        }
        
		        email.setSubject(flowEmail.Subject);
                email.setHtmlBody(flowEmail.HtmlBody);
                email.setWhatId(flowEmail.RelatedToId);   
        		
    		// set the email template id
    		email.setTemplateId(templateId);     
    
    		// do not save email as activity
    		email.setSaveAsActivity(false);

    		// set the id for the object
    		email.setWhatId(whatId);

    		// add current message to message list
    		messageList.add(email);

    		// create savepoint before executing statement
    		Savepoint sp = Database.setSavepoint();
        
        	// set target object id as a contact  WhatId is not available for sending emails to UserIds
        	Account tempA = new Account(Name = 'test', RecordTypeId = '0120a000000qfgbAAA');
        //Production: 0120a000000qfgbAAA Sandbox: 0120a000000qfgbAAA
        	insert tempA;
        	Contact temp = new Contact(AccountId = tempA.Id, LastName = ':::::', Email = 'dummyaddress@donotcreate.com');
        if(firstName != ''){
            temp.FirstName = firstName;
        }
        	insert temp;
        	email.setTargetObjectId(temp.id);
        
     		// send the temporary email list
    		Messaging.sendEmail(messageList);
        
        	CustomException ce = new CustomException();
        	ce.message = 'basicMailer_withTemplate line 63 ::: This error should never be seen.  The transaction is not rolling back properly, contact Salesforce immediately to check on service outage or bug.  This means junk contacts and accounts have been created in the system.';
        	CustomException.sendErrorNotification(ce);

    		// rollback the transaction before commiting to database
    		Database.rollback(sp);

    // initialize the actual message list to be sent
    List<Messaging.SingleEmailMessage> actualMessageList = new List<Messaging.SingleEmailMessage>();
    
    // loop through the previous message list and set the email fields
    for (Messaging.SingleEmailMessage e : messageList) {
        System.debug('body in for ' + e.htmlbody);
        Messaging.SingleEmailMessage emailToSend = new Messaging.SingleEmailMessage();
        emailToSend.setToAddresses(e.getToAddresses());
        emailToSend.setHTMLBody((e.getHTMLBody().replace(':::::','')).replace('Apex_Full_Name', firstName));
        emailToSend.setSubject(e.getSubject());
        emailToSend.setOrgWideEmailAddressId(e.getOrgWideEmailAddressId());
        emailToSend.setFileAttachments(e.getFileAttachments());
        emailToSend.setReplyTo(replyTo);
        emailToSend.setReferences(null);
        emailToSend.setSaveAsActivity(true);
        emailToSend.setWhatId(e.getWhatId());
        actualMessageList.add(emailToSend);
    }

    // send the actual message list
    Messaging.SendEmailResult [] serList = Messaging.sendEmail(actualMessageList);

    // make sure the emails are sent successfully
    String errorMessage = '';
    for(Messaging.SendEmailResult ser : serList){
        if(!ser.isSuccess()){
            for(Messaging.SendEmailError err : ser.getErrors()) {
                errorMessage += err.getMessage() + '\n';
            }
        }
    }
    }
    
       
}