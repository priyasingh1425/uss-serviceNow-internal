@IsTest
private class basicMailer_withTemplateTest {
    
    static testMethod void validateBasicMailer_withTemplateAndTocEmailAutoResponse() {
        Boolean sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].get(0).IsSandbox;
        String testAddress = 'jfleckensteinTEST@gmail.com';
        //dummy address

        Case c = new Case();
        insert c;
        
        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(),'No emails should be sent');
        if(!sandbox){
            CpEmailAutoResponse.tocEmailAutoResponse(c.Id,testAddress,testAddress);
        
            System.assertEquals(2, Limits.getEmailInvocations(),'Emails should be sent');  
        }

        Test.stopTest();
        
    }
    
    static testMethod void validateEmail_genericSend_withTemplate() {
        Boolean sandbox = [SELECT IsSandbox FROM Organization LIMIT 1].get(0).IsSandbox;
        List<String> innerList = new List<String>();

        Id templateId = [Select Id From EmailTemplate where Name Like 'Conga Email%'].get(0).Id;
        String tempString = '"' + templateId + '"';
        System.debug(tempString);
        
			innerList.add(tempString);
        
        Case c = new Case();
        insert c;
        String cidString = '"' + c.Id + '"';

			innerList.add(cidString);

			innerList.add('"test@gmail.com"');
			innerList.add('"test@ussignal.com"');
		List<List<String>> outerList = new List<List<String>>();
		outerList.add(innerList);
        
        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(),'No emails should be sent');
        if(!sandbox){
            Email_genericSend_withTemplate.sendEmailGenericTemplate(outerList);
            
            System.assertEquals(2, Limits.getEmailInvocations(),'Emails should be sent');
        }
        Test.stopTest();
    }

}