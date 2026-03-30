trigger ChangetaskTrigger on Task (after update) {

    if (Trigger.isUpdate && Trigger.isAfter) {
        ChangeRequestHandler.afterTaskUpdate(Trigger.oldMap, Trigger.new);
    }
}