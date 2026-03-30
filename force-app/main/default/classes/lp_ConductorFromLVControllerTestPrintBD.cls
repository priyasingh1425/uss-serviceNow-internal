/**
* @description Test Class for the lp_ConductorFromLVControllerPrintBD Class
*/
@isTest
public with sharing class lp_ConductorFromLVControllerTestPrintBD {
    /**
    * @description setup - test data setup method
    */
    @testSetup
    public static void setup(){
        lp_SetupTest setupTest = new lp_SetupTest();
         Account account1 = setupTest.createAccount(true);
        fferpcore__BillingDocument__c billingDocument1 = lp_SetupTest.createBillingDocument(account1.Id, true);
    }
    /**
    * @description testMethod1 - Test Happy Path of code
    */
    public static testMethod void testMethod1() {
        List<sObject> BDs = (List<fferpcore__BillingDocument__c>)[Select Id From fferpcore__BillingDocument__c];
        System.debug(BDs);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(BDs);
        ssc.setSelected(BDs);
        lp_ConductorFromLVControllerPrintBD cn = new lp_ConductorFromLVControllerPrintBD(ssc);
        cn.prepareConductorUrl();
        Test.startTest();
        PageReference pr = cn.prepareConductorUrl();
        String fieldName = pr.getParameters().get('UrlFieldName');
        System.assertEquals('Print_Billing_Document_PDF__c',fieldName, 'The UrlFieldName parameter is not set' );
        Test.stopTest();
    }  
}