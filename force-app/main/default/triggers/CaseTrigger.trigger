trigger CaseTrigger on Case (before insert, after update) {

    HelperCaseTrigger triggerHandler = new HelperCaseTrigger();

    if (Trigger.isBefore && Trigger.isInsert) {
        triggerHandler.emailToCaseChanges(Trigger.New, Trigger.newMap);
        triggerHandler.checkForAssetBaseID(Trigger.New, Trigger.newMap);
        triggerHandler.stampCloneSource(Trigger.New);
    }

    if (Trigger.isUpdate && Trigger.isAfter) {
        ChangeRequestHandler.afterUpdate(Trigger.oldMap, Trigger.new);
    }
}