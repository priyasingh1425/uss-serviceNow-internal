trigger FeedItemTrigger on FeedItem (after insert) {
    if(Trigger.isInsert && Trigger.isAfter){
        FeedItemTriggerHandler.afterInsert(trigger.new);
    }
}