/**
 * @author Ladd Partners
 * @date 11/23/2020
*/

@IsTest
private class lp_BatchNotifyTest {

    @IsTest
    private static void testAll() {
        Account account1 = lp_SetupTestFFA.createAccount('Test Account1', null, null, true);
        lp_BatchNotify batchNotify = new lp_BatchNotify();
        batchNotify.addNotification('Test Notification', new lp_Exception('Test error'));
        batchNotify.addNotification('Test Notification', account1.Id, 'RecName', new lp_Exception('Test error'));
        System.assertEquals(2, batchNotify.notifications.size(), 'unexpected notification size');
        batchNotify.sendUserEmailNotification('a@b.com', 'Test Job', Account.getSObjectType());
        batchNotify.sendChatterMessages();
    }

}