/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_BillingDocumentLineSelector extends lp_Selector {
    public lp_BillingDocumentLineSelector() {
        setSObjectType(fferpcore__BillingDocumentLineItem__c.getSObjectType());
        addField(fferpcore__BillingDocumentLineItem__c.Id);
        addField(fferpcore__BillingDocumentLineItem__c.Name);
        addField(fferpcore__BillingDocumentLineItem__c.fferpcore__BillingDocument__c);
        addField(fferpcore__BillingDocumentLineItem__c.fferpcore__NetValue__c);
        addField(fferpcore__BillingDocumentLineItem__c.fferpcore__NetValueOverride__c);
        addField(fferpcore__BillingDocumentLineItem__c.fferpcore__ProductService__c);
        addField(fferpcore__BillingDocumentLineItem__c.fferpcore__Quantity__c);
        addField(fferpcore__BillingDocumentLineItem__c.fferpcore__UnitPrice__c);
        addField('fferpcore__BillingDocument__r.fferpcore__Account__c');
        addField('fferpcore__ProductService__r.Id');
    }
}