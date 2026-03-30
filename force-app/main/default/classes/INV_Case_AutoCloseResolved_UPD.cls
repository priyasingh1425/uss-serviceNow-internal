/*************************************************
* Name: INV_Case_AutoCloseResolved_UPD
* Description: Invocable action class 
* Called by flow: Auto Close Resolved Cases
* Related Classes: INV_Case_AutoCloseResolved_BTC
* Test class: INV_Case_AutoCloseResolved_TEST
* ***********************************************/

public class INV_Case_AutoCloseResolved_UPD {
    
    /*************************************************
* Method Name: getAndCloseResolvedCases
* Description: Invocable action method that is used by a flow trigger to resolve closed cases
* ***********************************************/   
    
    @InvocableMethod(label='Auto Close Resolved Cases' description='auto close resolved cases in bulk with Salesforce implicit batching') 
    public static void getAndCloseResolvedCases(){
            INV_Case_AutoCloseResolved_BTC batchJob = new INV_Case_AutoCloseResolved_BTC();
            
            Id batchJobId = Database.executeBatch(batchJob, 100);        
    }
    
}