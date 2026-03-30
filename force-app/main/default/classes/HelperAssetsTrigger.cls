public class HelperAssetsTrigger {
    
    public void checkForParent(list<Asset> triggerNew, map<Id, Asset> triggerNewMap){
     
        
        for(Asset a : triggerNew){
       
            if(a.Parent_Base_Order_ID__c != null || a.Parent_Base_Order_ID__c > 0){
                String stat = String.valueOf(a.Status);
                if(stat.equals('Closed')){
                	AssetFromCRMOrder.deactivateParent(a);                    
                }
                if(stat.equals('Pending') && (a.AccountId == a.Customer__c)){
                    AssetFromCRMOrder.getParentAccountAccountForPending(a);
                }
       		}
        }

        
    }

}