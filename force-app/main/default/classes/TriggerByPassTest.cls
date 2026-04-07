@isTest
private class TriggerByPassTest {

    @isTest
    static void test_isFeedItemTriggerBypassed_defaultState_returnsFalse() {
        Test.startTest();
        Boolean result = TriggerBypass.isFeedItemTriggerBypassed();
        Test.stopTest();

        System.assertEquals(false, result,
            'FeedItem trigger bypass should default to false before any setter is called');
    }

    @isTest
    static void test_setBypassFeedItemTrigger_true_getterReturnsTrue() {
        Test.startTest();
        TriggerBypass.setBypassFeedItemTrigger(true);
        Boolean result = TriggerBypass.isFeedItemTriggerBypassed();
        Test.stopTest();

        System.assertEquals(true, result,
            'FeedItem trigger bypass should return true after being set to true');
    }

    @isTest
    static void test_setBypassFeedItemTrigger_toggleBackToFalse_getterReturnsFalse() {
        TriggerBypass.setBypassFeedItemTrigger(true);
        System.assertEquals(true, TriggerBypass.isFeedItemTriggerBypassed(),
            'Pre-condition: bypass should be true before toggling back');

        Test.startTest();
        TriggerBypass.setBypassFeedItemTrigger(false);
        Boolean result = TriggerBypass.isFeedItemTriggerBypassed();
        Test.stopTest();

        System.assertEquals(false, result,
            'FeedItem trigger bypass should return false after being toggled back to false');
    }

    @isTest
    static void test_isChangeRequestHandlerBypassed_defaultState_returnsFalse() {
        Test.startTest();
        Boolean result = TriggerBypass.isChangeRequestHandlerBypassed();
        Test.stopTest();

        System.assertEquals(false, result,
            'ChangeRequest handler bypass should default to false before any setter is called');
    }

    @isTest
    static void test_setBypassChangeRequestHandler_true_getterReturnsTrue() {
        Test.startTest();
        TriggerBypass.setBypassChangeRequestHandler(true);
        Boolean result = TriggerBypass.isChangeRequestHandlerBypassed();
        Test.stopTest();

        System.assertEquals(true, result,
            'ChangeRequest handler bypass should return true after being set to true');
    }

    @isTest
    static void test_setBypassChangeRequestHandler_toggleBackToFalse_getterReturnsFalse() {
        TriggerBypass.setBypassChangeRequestHandler(true);
        System.assertEquals(true, TriggerBypass.isChangeRequestHandlerBypassed(),
            'Pre-condition: bypass should be true before toggling back');

        Test.startTest();
        TriggerBypass.setBypassChangeRequestHandler(false);
        Boolean result = TriggerBypass.isChangeRequestHandlerBypassed();
        Test.stopTest();

        System.assertEquals(false, result,
            'ChangeRequest handler bypass should return false after being toggled back to false');
    }

    @isTest
    static void test_setBypassFeedItemTrigger_nullValue_assignsNull() {
        Test.startTest();
        TriggerBypass.setBypassFeedItemTrigger(null);
        Boolean result = TriggerBypass.isFeedItemTriggerBypassed();
        Test.stopTest();

        System.assertEquals(null, result,
            'FeedItem trigger bypass should hold null when null is explicitly passed to the setter');
    }

    @isTest
    static void test_setBypassChangeRequestHandler_nullValue_assignsNull() {
        Test.startTest();
        TriggerBypass.setBypassChangeRequestHandler(null);
        Boolean result = TriggerBypass.isChangeRequestHandlerBypassed();
        Test.stopTest();

        System.assertEquals(null, result,
            'ChangeRequest handler bypass should hold null when null is explicitly passed to the setter');
    }

    @isTest
    static void test_bypassFlags_areIndependent_feedItemDoesNotAffectChangeRequest() {
        Test.startTest();
        TriggerBypass.setBypassFeedItemTrigger(true);
        Test.stopTest();

        System.assertEquals(true, TriggerBypass.isFeedItemTriggerBypassed(),
            'FeedItem bypass should be true after being set');
        System.assertEquals(false, TriggerBypass.isChangeRequestHandlerBypassed(),
            'ChangeRequest bypass should remain false — it was never toggled');
    }

    @isTest
    static void test_bypassFlags_areIndependent_changeRequestDoesNotAffectFeedItem() {
        Test.startTest();
        TriggerBypass.setBypassChangeRequestHandler(true);
        Test.stopTest();

        System.assertEquals(true, TriggerBypass.isChangeRequestHandlerBypassed(),
            'ChangeRequest bypass should be true after being set');
        System.assertEquals(false, TriggerBypass.isFeedItemTriggerBypassed(),
            'FeedItem bypass should remain false — it was never toggled');
    }

    @isTest
    static void test_bypassFlags_areIndependent_bothToggledSimultaneously() {
        Test.startTest();
        TriggerBypass.setBypassFeedItemTrigger(true);
        TriggerBypass.setBypassChangeRequestHandler(true);
        Test.stopTest();

        System.assertEquals(true, TriggerBypass.isFeedItemTriggerBypassed(),
            'FeedItem bypass should be true');
        System.assertEquals(true, TriggerBypass.isChangeRequestHandlerBypassed(),
            'ChangeRequest bypass should be true');

        TriggerBypass.setBypassFeedItemTrigger(false);

        System.assertEquals(false, TriggerBypass.isFeedItemTriggerBypassed(),
            'FeedItem bypass should be false after toggling off');
        System.assertEquals(true, TriggerBypass.isChangeRequestHandlerBypassed(),
            'ChangeRequest bypass should remain true — it was not toggled off');
    }
}
