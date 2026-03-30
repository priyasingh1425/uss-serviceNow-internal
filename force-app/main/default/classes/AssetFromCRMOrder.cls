public class AssetFromCRMOrder {
    
    public static void deactivateParent(Asset a){
       //method only receiving Assets in Closed status
        List<Asset> parentsM = new List<Asset>();	

        for(Asset parent : [select Id from Asset where Base_Order_ID__c =: a.Parent_Base_Order_ID__c]){
                    System.debug('AssetFromCRMOrder parent ' + parent);
                    parent.Inactive__c = true;    
            		parentsM.add(parent);
           
        }
        update parentsM;
        }
    
    public static void getParentAccountAccountForPending(Asset a){
        
        try{
            Asset parent = [select Id, AccountId from Asset where Base_Order_ID__c =: a.Parent_Base_Order_ID__c];
            System.debug('AssetFromCRMOrder parent, Pending ::: ' + parent);
            System.debug('AssetFromCRMOrder a, Pending ::: ' + a.AccountId);
                a.AccountId = parent.AccountId;
            System.debug('AssetFromCRMOrder a2, Pending ::: ' + a.AccountId);
        
        } catch (Exception e) {
            System.debug('Exception ::: ' + e.getMessage());
        } 
        finally {
            System.debug('finally executed');
        }  
    }
}