/**
 * @author Ladd Partners
 * @date 3/13/2019
*/

@IsTest
public with sharing class lp_TestTriggerHandler extends lp_AbstractTriggerHandler {

    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new lp_TestTriggerHandler(objects, oldObjectsById);
        }
    }

    private lp_TestTriggerHandler(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
    }

    public override void beforeInsert() { }

    public override void afterInsert() { }

    public override void beforeUpdate() { }

    public override void afterUpdate() { }

    public override void beforeDelete() { }

    public override void afterDelete() { }

    public override void afterUndelete() { }
}