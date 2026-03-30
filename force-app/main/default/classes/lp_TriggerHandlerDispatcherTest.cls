/**
 * @author Ladd Partners
 * @date 3/13/2019
 */

@IsTest
private class lp_TriggerHandlerDispatcherTest {
    @IsTest
    private static void handlerTestNonTrigger() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            false,
            true,
            false,
            false,
            true,
            false,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(null, triggerContext);
            System.assert(false, 'expecting exception');
        } catch (Exception ex) {
            System.assert(
                ex.getMessage().contains('Trigger handler must only be invoked in the context of an executing trigger.'),
                'unexpected exception - ' + ex.getMessage()
            );
        }
    }

    @IsTest
    private static void handlerTestNull() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            true,
            false,
            false,
            true,
            false,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(null, triggerContext);
            System.assert(false, 'expecting exception');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Factory type must be specified.'), 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestNonFactory() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            true,
            false,
            false,
            true,
            false,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_Selector.class, triggerContext);
            System.assert(false, 'expecting exception');
        } catch (Exception ex) {
            System.assert(ex.getMessage().contains('Trigger handler factory must implement'), 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestBeforeInsert() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            true,
            false,
            false,
            true,
            false,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_TestTriggerHandler.Factory.class, triggerContext);
        } catch (Exception ex) {
            System.assert(false, 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestAfterInsert() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            true,
            false,
            false,
            false,
            true,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_TestTriggerHandler.Factory.class, triggerContext);
        } catch (Exception ex) {
            System.assert(false, 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestBeforeUpdate() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            false,
            true,
            false,
            true,
            false,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_TestTriggerHandler.Factory.class, triggerContext);
        } catch (Exception ex) {
            System.assert(false, 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestAfterUpdate() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            false,
            true,
            false,
            false,
            true,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_TestTriggerHandler.Factory.class, triggerContext);
        } catch (Exception ex) {
            System.assert(false, 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestBeforeDelete() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            false,
            false,
            true,
            true,
            false,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_TestTriggerHandler.Factory.class, triggerContext);
        } catch (Exception ex) {
            System.assert(false, 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestAfterDelete() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            false,
            false,
            true,
            false,
            true,
            false,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_TestTriggerHandler.Factory.class, triggerContext);
        } catch (Exception ex) {
            System.assert(false, 'unexpected exception - ' + ex.getMessage());
        }
    }

    @IsTest
    private static void handlerTestAfterUnDelete() {
        lp_TriggerContext triggerContext = new lp_TriggerContext(
            true,
            false,
            false,
            false,
            false,
            true,
            true,
            new List<SObject>(),
            new Map<Id, SObject>(),
            new List<SObject>(),
            new Map<Id, SObject>(),
            1
        );
        try {
            lp_TriggerHandlerDispatcher.dispatch(lp_TestTriggerHandler.Factory.class, triggerContext);
        } catch (Exception ex) {
            System.assert(false, 'unexpected exception - ' + ex.getMessage());
        }
    }
	
	@IsTest
	static void testDispatch() {
		lp_SetupTest setupTest = new lp_SetupTest();
        Account newAccount = setupTest.createAccount(true);
        SCMC__Sales_Order__c salesOrder = setupTest.createSalesOrder(newAccount, true);
	}
}