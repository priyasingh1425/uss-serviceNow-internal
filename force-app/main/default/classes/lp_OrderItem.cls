/**
 * Created by Ladd Partners on 4/11/2025.
 */

public with sharing class lp_OrderItem {
    public static final String BILLING_DISPLAY_DISPLAY = 'Display';
    public static final String BILLING_DISPLAY_SUPPRESS = 'Suppress';
    public static final String BILLING_FREQUENCY_ANNUAL = 'Annual';
    public static final String BILLING_FREQUENCY_MONTHLY = 'Monthly';
    public static final String BILLING_FREQUENCY_QUARTERLY = 'Quarterly';
    public static final String BILLING_FREQUENCY_SEMIANNUAL = 'Semiannual';


    public static void processBilling(Set<Id> orderItemIds) {
        List<OrderItem> orderItems = new lp_OrderItemSelector().getByIds(orderItemIds);
        Map<String, Set<Id>> orderItemIdsByJob = new Map<String, Set<Id>>();
        for (OrderItem orderItem : orderItems) {
            String currentJob = lp_Order.ASYNC_JOB_BY_ORDER_TYPE.get(orderItem.Order.Type);
            if (String.isNotBlank(currentJob)) {
                Set<Id> currentJobOrderItemIds = orderItemIdsByJob.get(currentJob);
                if (currentJobOrderItemIds == null) {
                    currentJobOrderItemIds = new Set<Id>();
                    orderItemIdsByJob.put(currentJob, currentJobOrderItemIds);
                }
                currentJobOrderItemIds.add(orderItem.Id);
            }
        }
        
        if (!orderItemIdsByJob.isEmpty()) {
            lp_AsyncJobStaging.createOrderItemJobs(orderItemIdsByJob);
        }
    }
    
    public static String getSoftDateName(String billingFrequency) {
        String softDateName = null;
        if (billingFrequency == BILLING_FREQUENCY_ANNUAL) {
            softDateName = lp_SoftDate.NAME_YEAR_BEGINNING;
        } else if (billingFrequency == BILLING_FREQUENCY_MONTHLY) {
            softDateName = lp_SoftDate.NAME_MONTH_BEGINNING;
        } else if (billingFrequency == BILLING_FREQUENCY_QUARTERLY) {
            softDateName = lp_SoftDate.NAME_QUARTER_BEGINNING;
        } else if (billingFrequency == BILLING_FREQUENCY_SEMIANNUAL) {
            softDateName = lp_SoftDate.NAME_HALF_YEAR_BEGINNING;
        }
        return softDateName;
    }
    
    public static void updateBillingContractReference(Map<Id, List<ffbc__ContractLineItem__c>> billingContractLinesByOrderItemId) {
        if (billingContractLinesByOrderItemId != null) {
            List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
            for (Id orderItemId : billingContractLinesByOrderItemId.keySet()) {
                Id billingContractLineId = null;
                List<ffbc__ContractLineItem__c> billingContractLines = billingContractLinesByOrderItemId.get(orderItemId) ?? new List<ffbc__ContractLineItem__c>();
                for (ffbc__ContractLineItem__c billingContractLine : billingContractLines) {
                    if (billingContractLine.ffbc__BillingType__c == lp_BillingContractLine.BILLING_TYPE_ONE_OFF) {
                        if (billingContractLines.size() == 1) {
                            // NRC only line
                            billingContractLineId = billingContractLine.ffbc__ActiveContractLineItem__c ?? billingContractLine.Id;
                        }
                    } else {
                        // Line has MRC
                        billingContractLineId = billingContractLine.ffbc__ActiveContractLineItem__c ?? billingContractLine.Id;
                    }
                }
                orderItemsToUpdate.add(new OrderItem(Id = orderItemId, LPC_BillingContractLine__c = billingContractLineId));
            }
            update orderItemsToUpdate;
        }
    }
}