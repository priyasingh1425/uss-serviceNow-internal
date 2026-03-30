public class CustomException extends Exception {
    Public String message;
    String[] notificationEmail = new String[]{'SFAdmins@ussignal.com', 'jfleckenstein@ussignal.com'};
    
    public static void sendErrorNotification(CustomException ce){
                Messaging.SingleEmailMessage notification = new Messaging.SingleEmailMessage();
                notification.setSubject('APEX Custom Error');
                notification.setToAddresses(ce.notificationEmail);
                notification.setPlainTextBody('APEX CUSTOM ERROR ::: ' + ce.message);
                if(!Test.isRunningTest()){
                        sendEmail(notification);
                }
    }

    @TestVisible
    private static void sendEmail(Messaging.SingleEmailMessage notification){
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                notification
        });

    }
}