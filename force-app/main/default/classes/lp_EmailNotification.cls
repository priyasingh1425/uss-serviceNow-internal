/**
 * @author Ladd Partners
 * @date 4/22/2025
*/

public with sharing class lp_EmailNotification {

    private static final String FIELD_NAME_EMAIL_ADDRESS = 'Email_Address__c';
    private static final String FIELD_AFC_EXEMPTION_CREATION = 'AFC_Exemption_Creation__c';
    private static final String FIELD_ECMS_CERTIFICATE_IMPORT = 'ECMS_Certificate_Import__c';

    private static final List<Email_Notification__mdt> SUBSCRIBERS;

    static {
        SUBSCRIBERS = Test.isRunningTest() ? mockSubscribers() : Email_Notification__mdt.getAll().values();
    }

    public static List<String> getAFCExemptionCreation() {
        return filterSubscribers(FIELD_AFC_EXEMPTION_CREATION);
    }

    public static List<String> getECMSCertificateImport() {
        return filterSubscribers(FIELD_ECMS_CERTIFICATE_IMPORT);
    }

    private static List<String> filterSubscribers(String fieldToSearch) {
        Set<String> subscriberEmails = new Set<String>();

        for (Email_Notification__mdt subscriber : SUBSCRIBERS) {
            if ((subscriber.get(fieldToSearch) != null && (Boolean) subscriber.get(fieldToSearch))) {
                subscriberEmails.add((String)subscriber.get(FIELD_NAME_EMAIL_ADDRESS));
            }
        }

        return new List<String>(subscriberEmails);
    }

    private static List<Email_Notification__mdt> mockSubscribers(){
        Email_Notification__mdt mockSub = new Email_Notification__mdt();
        mockSub.put(FIELD_NAME_EMAIL_ADDRESS, 'test@test.com');
        mockSub.put(FIELD_AFC_EXEMPTION_CREATION, true);
        mockSub.put(FIELD_ECMS_CERTIFICATE_IMPORT, true);

        return new List<Email_Notification__mdt>{ mockSub };
    }

}