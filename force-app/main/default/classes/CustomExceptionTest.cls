@isTest
public class CustomExceptionTest {
    @isTest
    public static void testSendErrorNotification(){
        CustomException ce = new CustomException();
    	ce.message = 'test notification';
        
        System.assertEquals(0, Limits.getEmailInvocations(),'No emails should be sent');
        Test.startTest();
        CustomException.sendErrorNotification(ce);
        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations(),'No emails should be sent');
    }

    @isTest
    public static void testSendErrorNotificationBypass() {
        CustomException ce = new CustomException();
        ce.message = 'test notification';
        Messaging.SingleEmailMessage notification = new Messaging.SingleEmailMessage();
        notification.setSubject('APEX Custom Error');
        notification.setToAddresses(new List<String>{'SFAdmins@ussignal.com'});
        notification.setPlainTextBody('APEX CUSTOM ERROR ::: ' + ce.message);
        Boolean EmailDeliverabilityEnabled = true;

        // check if we are able to send emails
        try {
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.reserveMassEmailCapacity(1);
        } catch (System.NoAccessException e) {
            EmailDeliverabilityEnabled = false;
        }

        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(),'No emails should be sent');
        if(EmailDeliverabilityEnabled){

            CustomException.sendEmail(notification);
            System.assertEquals(1, Limits.getEmailInvocations(),'Emails should be sent');
        }else{
            try{
                CustomException.sendEmail(notification);
            }catch(Exception e){
                System.assertEquals('SendEmail failed. First exception on row 0; first error: NO_SINGLE_MAIL_PERMISSION, Single email is not enabled for your organization or profile.: []', e.getMessage(),'Email did not throw correct error');
            }
            // We do not test email ending in lower environments
        }
        Test.stopTest();
    }
}