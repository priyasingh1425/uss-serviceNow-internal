/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_BillingDocumentLineItem {
  public static fferpcore__BillingDocumentLineItem__c create(Id billingDocumentId) {
    fferpcore__BillingDocumentLineItem__c billingDocumentLineItem = new fferpcore__BillingDocumentLineItem__c();
    billingDocumentLineItem.fferpcore__BillingDocument__c = billingDocumentId;

    return billingDocumentLineItem;
  }

  public static fferpcore__BillingDocumentLineItem__c createLateFees(Id billingDocumentId, Decimal totalOutstandingValue) {
    fferpcore__BillingDocumentLineItem__c billingDocumentLineItem = create(billingDocumentId);

    billingDocumentLineItem.fferpcore__NetValueOverride__c = totalOutstandingValue;
    billingDocumentLineItem.fferpcore__ProductService__c = lp_BillingSettings.getFinanceChargeProductId();

    return billingDocumentLineItem;
  }
}