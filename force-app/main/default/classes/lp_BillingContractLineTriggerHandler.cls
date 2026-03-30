/**
 * Created by Ladd Partners on 5/21/2025.
 */

public with sharing class lp_BillingContractLineTriggerHandler extends lp_AbstractTriggerHandler {
    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new lp_BillingContractLineTriggerHandler(objects, oldObjectsById);
        }
    }

    private final List<ffbc__ContractLineItem__c> billingContractLines;
    private final Map<Id, ffbc__ContractLineItem__c> oldBillingContractLineById;

    private lp_BillingContractLineTriggerHandler(List<SObject> billingContractLines, Map<Id, SObject> oldBillingContractLineById) {
        this.billingContractLines = billingContractLines;
        this.oldBillingContractLineById = (Map<Id, ffbc__ContractLineItem__c>)oldBillingContractLineById;
    }

    public override void afterInsert() {
        Map<Id, List<ffbc__ContractLineItem__c>> billingContractLinesByOrderItemId = new Map<Id, List<ffbc__ContractLineItem__c>>();
        for (ffbc__ContractLineItem__c billingContractLine : billingContractLines) {
            if (billingContractLine.LPC_Order_Item__c != null) {
                List<ffbc__ContractLineItem__c> currentBillingContractLines = billingContractLinesByOrderItemId.get(billingContractLine.LPC_Order_Item__c);
                if (currentBillingContractLines == null) {
                    currentBillingContractLines = new List<ffbc__ContractLineItem__c>();
                    billingContractLinesByOrderItemId.put(billingContractLine.LPC_Order_Item__c, currentBillingContractLines);
                }
                currentBillingContractLines.add(billingContractLine);
            }
        }

        if (!billingContractLinesByOrderItemId.isEmpty()) {
            lp_OrderItem.updateBillingContractReference(billingContractLinesByOrderItemId);
        }
    }
}