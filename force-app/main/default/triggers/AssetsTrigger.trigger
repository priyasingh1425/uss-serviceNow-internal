trigger AssetsTrigger on Asset (before insert, before update) {

    //update this trigger with any additional triggers needed on Assets and add handler methods to the Helper class indicated below.    
    
    HelperAssetsTrigger triggerHandler = new HelperAssetsTrigger();
    //Helper class is HelperAssetsTrigger
    
    if(Trigger.isBefore) {
        try{triggerHandler.checkForParent(trigger.New,trigger.newMap);
            } catch (Exception e) {
            System.debug('Exception ' + e.getMessage());
        }
    }
    
    
}