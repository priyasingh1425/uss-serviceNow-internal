/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_BillingSettings {
  
  @TestVisible private static Boolean autoActivateContactsOrApplyChangeIsEnabled { get; set; }
  @TestVisible private static Boolean autoCreateCreditLinesIsEnabled { get; set; }
  @TestVisible private static Boolean customTriggersAreEnabled { get; set; }
  private static Decimal daysPastDue { get; set; }
  private static Product2 financeChargeProduct { get; set; }
  private static String financeChargeProductName { get; set; }
  private static Integer lateFeesBatchSize { get; set; }
  @TestVisible private static Boolean orderProductBillingIsEnabled { get; set; }

  public static Boolean customTriggersAreEnabled(){
    if(customTriggersAreEnabled == null) {
      LPC_Billing_Central_Configuration__c settings = LPC_Billing_Central_Configuration__c.getInstance();
      customTriggersAreEnabled = !settings.Disable_Custom_Triggers__c;

      if(Test.isRunningTest()) {
        customTriggersAreEnabled = true;
      }
    }
    return customTriggersAreEnabled;
  }

  public static Boolean orderProductBillingIsEnabled() {
    if (orderProductBillingIsEnabled == null) {
      LPC_Billing_Central_Configuration__c currentConfig = LPC_Billing_Central_Configuration__c.getInstance();
      orderProductBillingIsEnabled = currentConfig.Enable_Order_Product_Billing__c;

      if(Test.isRunningTest()){
        // Set the class property to false in your test, if required
        orderProductBillingIsEnabled = true;
      }
    }

    return orderProductBillingIsEnabled;
  }
  
  public static Boolean autoActivateContactsOrApplyChangeIsEnabled() {
    if (autoActivateContactsOrApplyChangeIsEnabled == null) {
      LPC_Billing_Central_Configuration__c currentConfig = LPC_Billing_Central_Configuration__c.getInstance();
      autoActivateContactsOrApplyChangeIsEnabled = currentConfig.Automatically_Activate_Billing_Contract__c;
      
      if(Test.isRunningTest()){
        // Set the class property to false in your test, if required
        autoActivateContactsOrApplyChangeIsEnabled = true;
      }
    }

    return autoActivateContactsOrApplyChangeIsEnabled;
  }

  public static Decimal getDaysPastDue() {
    if (daysPastDue == null) {
      LPC_Billing_Central_Configuration__c currentConfig = LPC_Billing_Central_Configuration__c.getInstance();
      daysPastDue = currentConfig.Days_Past_Due__c;

      if (daysPastDue == null && Test.isRunningTest()) {
        daysPastDue = 10.0;
      }
    }

    return daysPastDue;
  }

  public static String getFinanceChargeProductName() {
    if (String.ISBLANK(financeChargeProductName)) {
      LPC_Billing_Central_Configuration__c currentConfig = LPC_Billing_Central_Configuration__c.getInstance();
      financeChargeProductName = currentConfig.Finance_Charge_SF_Product__c;

      if (String.ISBLANK(financeChargeProductName) && Test.isRunningTest()) {
        financeChargeProductName = '2 x 1 Gbps CDC Connection';
      }
    }

    return financeChargeProductName;
  }

  public static Product2 getFinanceChargeProduct(String productName) {
    lp_ProductSelector settingQuery = new lp_ProductSelector();
    if (financeChargeProduct == null) {
      financeChargeProduct = settingQuery.getByName(
        productName
      );

      if(financeChargeProduct == null) {
        throw new lp_Exception('Searching for Finance Prod Name returned 0 results!', false);
      }
    }
    
    return financeChargeProduct;
  }

  public static Id getFinanceChargeProductId() {
    Id financeProdId = lp_BillingSettings.getFinanceChargeProduct(lp_BillingSettings.getFinanceChargeProductName()).Id;

    if(financeProdId == null) {
      throw new lp_Exception('The Finance Charge Product could not be found from custom settings!', null);
    }

    return financeProdId;
  }

  public static Integer getLateFeesBatchSize() {
    LPC_Billing_Central_Configuration__c currentConfig = LPC_Billing_Central_Configuration__c.getInstance();
    Integer batchScope = 200;

    if (currentConfig.Batch_Size__c < 200 &&
      currentConfig.Batch_Size__c != null &&
      currentConfig.Batch_Size__c >= 1) {
      batchScope = (Integer) currentConfig.Batch_Size__c;
    }

    if (Test.isRunningTest()) {
      batchScope = 5;
    }

    return batchScope;
  }

  public static Boolean getAutoCreateCreditLinesIsEnabled() {
    if (autoCreateCreditLinesIsEnabled == null) {
      LPC_Billing_Central_Configuration__c currentConfig = LPC_Billing_Central_Configuration__c.getInstance();
      autoCreateCreditLinesIsEnabled = currentConfig.Auto_Create_Credit_Lines__c;
      
      if(Test.isRunningTest()){
        // Set the class property to false in your test, if required
        autoCreateCreditLinesIsEnabled = true;
      }
    }
    return autoCreateCreditLinesIsEnabled;
  }
}