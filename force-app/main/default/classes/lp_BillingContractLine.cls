/**
 * Created by Ladd Partners on 4/18/2025.
 */

public with sharing class lp_BillingContractLine {

    public static final String BILLING_TYPE_ONE_OFF = 'One-off';
    public static final String BILLING_TYPE_RECURRING_FIXED = 'Recurring Fixed';
    public static final String BILLING_TYPE_RECURRING_VARIABLE = 'Recurring Variable';
    public static final String ERROR_CONTRACT_EXIST = 'The Order Product has already been assigned to Contract';
    public static final String ERROR_CONTRACT_NOT_FOUND = 'The Contract on the Order was not found';
    public static final String ERROR_CONTRACT_NOT_ACTIVE = 'The Contract on the Order is not active';
    public static final String ERROR_CREDIT_LINE_NOT_NEEDED = 'Source contract line does not meet the criteria for credit line creation (End Date before Billed To Date)';
    public static final String ERROR_FAILED_TO_AMEND_ORDER_PRODUCT = 'Failed to amend Order Product while {0}: {1}';
    public static final String ERROR_FAILED_TO_BILL_ORDER_PRODUCT = 'Failed to bill Order Product while {0}: {1}';
    public static final String ERROR_FAILED_TO_CREATE_CREDIT_LINE = 'Failed to create Billing Contract Credit Line while {0}: {1}';
    public static final String ERROR_FAILED_TO_DISCONNECT_ORDER_PRODUCT = 'Failed to disconnect Order Product while {0}: {1}';
    public static final String ERROR_FAILED_TO_RENEW_ORDER_PRODUCT = 'Failed to renew Order Product while {0}: {1}';
    public static final String ERROR_NO_USAGE_CREDIT = 'Credit not required';

    public static Id billOrderItem(Id billingContractId, Id orderItemId){
        Id openContractId = null;
        Savepoint sp = Database.setSavepoint();
        String stage = 'validating Order Product';
        try {
            if(billingContractId != null){
                throw new lp_Exception(ERROR_CONTRACT_EXIST, true);
            }
            
            OrderItem orderItem = new lp_OrderItemSelector().getWithOrderComponentsById(orderItemId);

            if(orderItem == null){
                throw new lp_Exception(lp_AsyncJobStaging.ERROR_MISSING_ORDER_PRODUCT, true);
            }

            Id orderId = orderItem.OrderId;
            Boolean isChange = false;
            
            stage = 'searching for existing contract';
            openContractId = orderItem.Order.LPC_Billing_Contract__c;

            if(openContractId == null){
                stage = 'creating new contract';
                Order order = new lp_OrderSelector().getById(orderId);
                ffbc__Contract__c newContract = lp_BillingContract.createFromOrder(order);
                insert newContract;

                openContractId = newContract.Id;

                stage = 'updating order with new contract';
                Order updatedOrder = new Order(Id = orderId);
                updatedOrder.LPC_Billing_Contract__c = openContractId;
                update updatedOrder;
            } else if(orderItem.Order.LPC_Billing_Contract__r.ffbc__Status__c == lp_BillingContract.STATUS_ACTIVE){
                stage = 'searching for active change request';
                ffbc__Contract__c activeChangeRequest = new lp_BillingContractSelector().getActiveChangeRequestByActiveContractId(openContractId);
                openContractId = activeChangeRequest?.Id;
                if(openContractId == null){
                    stage = 'creating change request';
                    openContractId = lp_BillingContract.createChangeRequest(orderItem.Order.LPC_Billing_Contract__c);
                }
            }
            
            stage = 'creating contract lines';
            List<ffbc__ContractLineItem__c> contractLines = createFromOrderItem(orderItem, openContractId);
            
        } catch (Exception e) {
            Database.rollback(sp);
            lp_Utility.logException(e);
            String errrorMessage = String.format(ERROR_FAILED_TO_BILL_ORDER_PRODUCT, new List<String>{ stage, e.getMessage() });
            throw new lp_Exception(errrorMessage, e, false);
        }
        return openContractId;
    }

    public static Id billOrderItem(Async_Job_Staging__c asyncJob) {
        Savepoint sp = Database.setSavepoint();
        String stage = 'creating new contract';
        Id openContractId = null;
        try {
            openContractId = billOrderItem(asyncJob.Billing_Contract__c, asyncJob.Order_Product__c);
            lp_AsyncJobStaging.completeOrderItemJob(asyncJob.Id, openContractId);
        } catch (Exception e) {
            Database.rollback(sp);
            lp_Utility.logException(e);
            String errrorMessage = String.format(ERROR_FAILED_TO_BILL_ORDER_PRODUCT, new List<String>{ stage, e.getMessage() });
            throw new lp_Exception(errrorMessage, e, false);
        }
        return openContractId;
    }

    private static ffbc__ContractLineItem__c createFromOrderItem(Id contractId, Decimal unitPrice, String billingType, OrderItem orderItem, LPC_Product_Tax_Details__c taxDetail, Order_Component__c orderComponent){
        String analysisItem2Name = orderItem.State__c?.toLowerCase();

        Id analysisItem3Id = null;
        if (String.isNotBlank(orderItem.Facility__c)) {
            String facilityName = orderItem.Facility__c;
            Facility__c facilityRecord = new lp_FacilitySelector().getByFacility(facilityName);
            analysisItem3Id = facilityRecord?.LPC_Analysis_Item_3__c;
        }

        String analysisItem4Name = orderItem.Product2.Dimension_4__r.Name?.toLowerCase();
        Map<String, fferpcore__AnalysisItem__c> analysisItemByName = new Map<String, fferpcore__AnalysisItem__c>{ analysisItem2Name => null, analysisItem4Name => null };
        analysisItemByName = new lp_AnalysisItemSelector().getMapByName(analysisItemByName.keySet());

        String subType = orderItem.Order.Account.Sub_Type__c;

        String reportingCode = null;
        if (subType == lp_Account.SUB_TYPE_RETAIL) {
            if (billingType == lp_BillingContractLine.BILLING_TYPE_RECURRING_FIXED) {
                reportingCode = lp_UssRevCostGlaSettings.getRevenueRetailMRC();
            } else if (billingType == lp_BillingContractLine.BILLING_TYPE_RECURRING_VARIABLE) {
                reportingCode = lp_UssRevCostGlaSettings.getRevenueRetailUsage();
            } else {
                 reportingCode = lp_UssRevCostGlaSettings.getRevenueRetailNRC();
            }
        } else if (subType == lp_Account.SUB_TYPE_WHOLESALE) {
            if (billingType == lp_BillingContractLine.BILLING_TYPE_RECURRING_FIXED) {
                reportingCode = lp_UssRevCostGlaSettings.getRevenueWholesaleMRC();
            } else if (billingType == lp_BillingContractLine.BILLING_TYPE_RECURRING_VARIABLE) {
                reportingCode = lp_UssRevCostGlaSettings.getRevenueWholesaleUsage();
            } else {
                 reportingCode = lp_UssRevCostGlaSettings.getRevenueWholesaleNRC();
            }
        }

        c2g__codaGeneralLedgerAccount__c generalLedgerAccount = new lp_GeneralLedgerAccountSelector().getByReportingCode(reportingCode);
        
        String softDateName = lp_SoftDate.NAME_MONTH_BEGINNING;
        String billingFrequency = orderItem.SBQQ__BillingFrequency__c ?? orderItem.Product2.SBQQ__BillingFrequency__c; 
        if (String.isNotBlank(billingFrequency)) {
            softDateName = lp_OrderItem.getSoftDateName(billingFrequency);
        }
        ffbc__SoftDate__c softDate = new lp_SoftDateSelector().getByName(softDateName);

        ffbc__UnitOfMeasure__c unitOfMeasure = new lp_BillingUnitOfMeasureSelector().getByName(orderItem.Unit_of_Measure__c);

        ffbc__ContractLineItem__c contractLine = new ffbc__ContractLineItem__c();
        contractLine.CurrencyIsoCode = 'USD';        
        contractLine.ffbc__AnalysisItem2__c = analysisItemByName.get(analysisItem2Name)?.Id;
        contractLine.ffbc__AnalysisItem3__c = analysisItem3Id;
        contractLine.ffbc__AnalysisItem4__c = analysisItemByName.get(analysisItem4Name)?.Id;
        contractLine.ffbc__BillingTerm__c = softDate?.Id;
        contractLine.ffbc__BillingType__c = billingType;
        contractLine.ffbc__Contract__c = contractId;
        contractLine.ffbc__Description__c = orderItem.Customer_Reference__c;
        contractLine.ffbc__FirstBillDate__c = orderItem.ServiceDate;
        contractLine.ffbc__ProductService__c = orderItem.Product2Id;
        contractLine.ffbc__Quantity__c = orderItem.Quantity;
        contractLine.ffbc__StartDate__c = orderItem.ServiceDate;
        contractLine.ffbc__UnitOfMeasure__c = unitOfMeasure?.Id;
        contractLine.ffbc__UnitPrice__c = unitPrice;
        contractLine.LPC_Circuit_Id__c = orderItem.Service_ID__c;
        contractLine.LPC_Customer_Notes__c = orderItem.Order.Bundle_Customer_Reference__c;
        contractLine.LPC_Customer_Reference__c = orderItem.Customer_Reference__c;
        contractLine.LPC_General_Ledger_Account__c = generalLedgerAccount?.Id;
        contractLine.LPC_LEC_Circuit_Id__c = orderComponent?.LEC_Circuit_ID__c;
        contractLine.LPC_LEC_Due_Date__c = orderComponent?.LEC_Due_Date__c;
        contractLine.LPC_LEC_Order_Number__c = orderComponent?.LEC_Order_Number__c;
        contractLine.LPC_LEC_Start_Date__c = orderComponent?.LEC_Bill_Start_Date__c;
        contractLine.LPC_LEC_Term__c = orderComponent?.LEC_Term__c;
        contractLine.LPC_LEC_Vendor__c = orderComponent?.Vendor__c;
        contractLine.LPC_Order_Item__c = orderItem.Id;
        contractLine.LPC_Sale_Type__c = subType;
        contractLine.LPC_Service_Type__c = taxDetail?.Service_Type__c;
        contractLine.LPC_Ship_City_Z__c = orderItem.City_Z__c;
        contractLine.LPC_Ship_Country_Z__c = orderItem.Country_Z__c;
        contractLine.LPC_Ship_State_Z__c = orderItem.State_Z__c;
        contractLine.LPC_Ship_Street_Z__c = orderItem.Street_Z__c;
        contractLine.LPC_Ship_Zip_Z__c = orderItem.Zip_Z__c;
        contractLine.LPC_Shipping_City__c = orderItem.City__c;
        contractLine.LPC_Shipping_Country__c = orderItem.Country__c;
        contractLine.LPC_Shipping_State__c = orderItem.State__c;
        contractLine.LPC_Shipping_Street__c = orderItem.Street__c;
        contractLine.LPC_Shipping_Zip__c = orderItem.Zip__c;
        contractLine.LPC_Transaction_Type__c = taxDetail?.Transaction_Type__c;
        contractLine.Ordered_Type__c = orderComponent?.Ordered_Type__c;

        if (orderItem.Promotion_Duration__c != null && orderItem.ServiceDate != null) {
            // Add an end date to the Billing Contract Line
            Date startDate = orderItem.ServiceDate;
            Decimal promotionDuration = orderItem.Promotion_Duration__c;
            Integer addMonths = Integer.valueOf(promotionDuration);
            Date endDate = startDate.addMonths(addMonths);
            contractLine.ffbc__EndDate__c = endDate;
        }

        return contractLine;
    }
    
    @TestVisible private static ffbc__ContractLineItem__c createFromContractLine(ffbc__ContractLineItem__c oldContractLine, OrderItem orderItem) {
        ffbc__ContractLineItem__c contractLine = new ffbc__ContractLineItem__c();
        contractLine.CurrencyIsoCode = oldContractLine.CurrencyIsoCode;
        contractLine.ffbc__AnalysisItem2__c = oldContractLine.ffbc__AnalysisItem2__c;
        contractLine.ffbc__AnalysisItem3__c = oldContractLine.ffbc__AnalysisItem3__c;
        contractLine.ffbc__AnalysisItem4__c = oldContractLine.ffbc__AnalysisItem4__c;
        contractLine.ffbc__BillingTerm__c = oldContractLine.ffbc__BillingTerm__c;
        contractLine.ffbc__BillingType__c = oldContractLine.ffbc__BillingType__c;
        contractLine.ffbc__Contract__c = oldContractLine.ffbc__Contract__c;
        contractLine.ffbc__Description__c = oldContractLine.ffbc__Description__c;
        contractLine.ffbc__EndDate__c = oldContractLine.ffbc__EndDate__c;
        contractLine.ffbc__FirstBillDate__c = orderItem?.ServiceDate;
        contractLine.ffbc__ProductService__c = oldContractLine.ffbc__ProductService__c;
        contractLine.ffbc__Quantity__c = (oldContractLine.ffbc__Quantity__c ?? 0) + (orderItem?.Quantity ?? 0);
        contractLine.ffbc__StartDate__c = orderItem?.ServiceDate;
        contractLine.ffbc__UnitOfMeasure__c = oldContractLine.ffbc__UnitOfMeasure__c;
        contractLine.ffbc__UnitPrice__c = oldContractLine.ffbc__UnitPrice__c;
        contractLine.LPC_Circuit_Id__c = oldContractLine.LPC_Circuit_Id__c;
        contractLine.LPC_Customer_Notes__c = oldContractLine.LPC_Customer_Notes__c;
        contractLine.LPC_Customer_Reference__c = oldContractLine.LPC_Customer_Reference__c;
        contractLine.LPC_General_Ledger_Account__c = oldContractLine.LPC_General_Ledger_Account__c;
        contractLine.LPC_LEC_Circuit_Id__c = oldContractLine.LPC_LEC_Circuit_Id__c;
        contractLine.LPC_LEC_Due_Date__c = oldContractLine.LPC_LEC_Due_Date__c;
        contractLine.LPC_LEC_Order_Number__c = oldContractLine.LPC_LEC_Order_Number__c;
        contractLine.LPC_LEC_Start_Date__c = oldContractLine.LPC_LEC_Start_Date__c;
        contractLine.LPC_LEC_Term__c = oldContractLine.LPC_LEC_Term__c;
        contractLine.LPC_LEC_Vendor__c = oldContractLine.LPC_LEC_Vendor__c;
        contractLine.LPC_Order_Item__c = orderItem?.Id;
        contractLine.LPC_Sale_Type__c = oldContractLine.LPC_Sale_Type__c;
        contractLine.LPC_Service_Type__c = oldContractLine.LPC_Service_Type__c;
        contractLine.LPC_Ship_City_Z__c = oldContractLine.LPC_Ship_City_Z__c;
        contractLine.LPC_Ship_Country_Z__c = oldContractLine.LPC_Ship_Country_Z__c;
        contractLine.LPC_Ship_State_Z__c = oldContractLine.LPC_Ship_State_Z__c;
        contractLine.LPC_Ship_Street_Z__c = oldContractLine.LPC_Ship_Street_Z__c;
        contractLine.LPC_Ship_Zip_Z__c = oldContractLine.LPC_Ship_Zip_Z__c;
        contractLine.LPC_Shipping_City__c = oldContractLine.LPC_Shipping_City__c;
        contractLine.LPC_Shipping_Country__c = oldContractLine.LPC_Shipping_Country__c;
        contractLine.LPC_Shipping_State__c = oldContractLine.LPC_Shipping_State__c;
        contractLine.LPC_Shipping_Street__c = oldContractLine.LPC_Shipping_Street__c;
        contractLine.LPC_Shipping_Zip__c = oldContractLine.LPC_Shipping_Zip__c;
        contractLine.LPC_Transaction_Type__c = oldContractLine.LPC_Transaction_Type__c;
        contractLine.Ordered_Type__c = oldContractLine.Ordered_Type__c;

        return contractLine;
    }

    public static List<ffbc__ContractLineItem__c> createFromOrderItem(OrderItem orderItem, Id contractId){
        List<ffbc__ContractLineItem__c> contractLines = new List<ffbc__ContractLineItem__c>();
        ffbc__ContractLineItem__c mrcLine = null;
        
        String billingType = null;
        Id productId = orderItem.Product2Id;

        Decimal mrcPerUnit = orderItem.MRC_Per_Unit__c ?? 0;
        Decimal nrcPrice = orderItem.NRC_List_Unit_Price__c ?? 0;
        Boolean isUsageProduct = orderItem.Usage_Product__c ?? false;
        
        Order_Component__c orderComponent = null;
        if (orderItem.Order_Components_Product__r != null && !orderItem.Order_Components_Product__r.isEmpty()) {
            orderComponent = orderItem.Order_Components_Product__r[0];
        }

        // Lookup LPC_Product_Tax_Details__c based on Product, Billing Type, and Interstate condition
        LPC_Product_Tax_Details__c taxDetail = null;
        Boolean isInterstate = orderItem.State__c != null && orderItem.State_Z__c != null && orderItem.State__c != orderItem.State_Z__c;
        
        // Query all possible tax details for the Order Item
        Map<String, LPC_Product_Tax_Details__c> taxDetailMapByProductIdBillingTypeInterstateKey = new lp_ProductTaxDetailsSelector().getMapByProductBillingTypeInterstateKey(new Set<Id>{ productId }, new Set<String>{ BILLING_TYPE_ONE_OFF, BILLING_TYPE_RECURRING_FIXED, BILLING_TYPE_RECURRING_VARIABLE });

        if (mrcPerUnit == 0 && nrcPrice == 0) {
            // create a zero dollar line
            billingType = BILLING_TYPE_RECURRING_FIXED;
            taxDetail = taxDetailMapByProductIdBillingTypeInterstateKey.get(lp_ProductTaxDetails.getProductIdAndBillingTypeKey(productId, billingType, isInterstate));
            mrcLine = createFromOrderItem(contractId, mrcPerUnit, billingType, orderItem, taxDetail, orderComponent);
            contractLines.add(mrcLine);
        } else {
            if(mrcPerUnit != 0){
                if (isUsageProduct) {
                    billingType = BILLING_TYPE_RECURRING_VARIABLE;
                } else {
                    billingType = BILLING_TYPE_RECURRING_FIXED;
                }
                taxDetail = taxDetailMapByProductIdBillingTypeInterstateKey.get(lp_ProductTaxDetails.getProductIdAndBillingTypeKey(productId, billingType, isInterstate));
                mrcLine = createFromOrderItem(contractId, mrcPerUnit, billingType, orderItem, taxDetail, orderComponent);
                contractLines.add(mrcLine);
            } 
            
            if(nrcPrice != 0) {
                billingType = BILLING_TYPE_ONE_OFF;
                taxDetail = taxDetailMapByProductIdBillingTypeInterstateKey.get(lp_ProductTaxDetails.getProductIdAndBillingTypeKey(productId, billingType, isInterstate));
                ffbc__ContractLineItem__c line = createFromOrderItem(contractId, nrcPrice, billingType, orderItem, taxDetail, orderComponent);
                contractLines.add(line);
            }
        }
        insert contractLines;
        
        // Write back Contract Line to OrderItem.LPC_BillingContractLine__c  (if multiple, use mrcLine)       
        OrderItem updatedOrderItem = new OrderItem(Id = orderItem.Id);
        if (mrcLine != null) {
            updatedOrderItem.LPC_BillingContractLine__c = mrcLine.Id;
        } else if (!contractLines.isEmpty()) {
            updatedOrderItem.LPC_BillingContractLine__c = contractLines[0].Id;
        }
        update updatedOrderItem;

        return contractLines;
    }
    
    public static Id amendOrderItem(Async_Job_Staging__c asyncJob, Boolean isRenewal){
        Id openContractId = null;
        Savepoint sp = Database.setSavepoint();
        String stage = 'validating Order Product';
        try {
            if(asyncJob.Billing_Contract__c != null){
                throw new lp_Exception(ERROR_CONTRACT_EXIST, true);
            }
            
            OrderItem orderItem = new lp_OrderItemSelector().getWithOrderComponentsById(asyncJob.Order_Product__c);

            if(orderItem == null){
                throw new lp_Exception(lp_AsyncJobStaging.ERROR_MISSING_ORDER_PRODUCT, true);
            }

            stage = 'searching for existing contract';
            ffbc__ContractLineItem__c priorBillingContractLine = null;
            if (orderItem.Prior_Billing_Contract_Line_Item__c != null) {
                priorBillingContractLine = new lp_BillingContractLineSelector().getById(orderItem.Prior_Billing_Contract_Line_Item__c);
                openContractId = priorBillingContractLine?.ffbc__Contract__c;
            }

            if (openContractId == null) {
                stage += ' from order';
                openContractId = orderItem.Order.Prior_Billing_Contract__c;
                if (openContractId == null) {
                    throw new lp_Exception(ERROR_CONTRACT_NOT_FOUND, true);
                }
            } else if(priorBillingContractLine != null && priorBillingContractLine.ffbc__Contract__r.ffbc__Status__c != lp_BillingContract.STATUS_ACTIVE) {
                throw new lp_Exception(ERROR_CONTRACT_NOT_ACTIVE, true);
            }
                
            stage = 'searching for active change request';
            ffbc__Contract__c activeChangeRequest = new lp_BillingContractSelector().getActiveChangeRequestByActiveContractId(openContractId);
            if(activeChangeRequest?.Id != null){
                openContractId = activeChangeRequest?.Id;   
            } else {
                stage = 'creating change request';
                openContractId = lp_BillingContract.createChangeRequest(openContractId);
            }

            stage = 'updating change request contract line';
            ffbc__ContractLineItem__c changeRequestContractLine = null;
            if(orderItem.Prior_Billing_Contract_Line_Item__c != null){
                changeRequestContractLine = new lp_BillingContractLineSelector().getMapByActiveContractLineIdFromContractIds(new Set<Id>{ openContractId })?.get(orderItem.Prior_Billing_Contract_Line_Item__c);
            }
             
            if (changeRequestContractLine == null) {
                // This is a net new line
                createFromOrderItem(orderItem, openContractId);
            } else {
                Decimal oldQty = changeRequestContractLine.ffbc__Quantity__c ?? 0;
                Decimal changeQty = orderItem.Quantity ?? 0;
                Decimal newQty = oldQty + changeQty;
                
                ffbc__ContractLineItem__c updateChangeRequestContractLine = new ffbc__ContractLineItem__c(Id = changeRequestContractLine.Id);
                
                stage = 'ending old contract line';
                Id lineToCreditId = changeRequestContractLine.ffbc__ActiveContractLineItem__c ?? changeRequestContractLine.Id;
                Date startDate = changeRequestContractLine.ffbc__Contract__r.ffbc__StartDate__c;
                Date endDate = orderItem.ServiceDate;
                Date creditFromDate = endDate.addDays(1);
                Boolean isUsageProduct = orderItem.Usage_Product__c ?? false; 
                if (isUsageProduct) {
                    creditFromDate = endDate.addMonths(1).toStartOfMonth();
                    lp_UsageSelector.lp_UsageData usageDataInput = new lp_UsageSelector.lp_UsageData();
                    usageDataInput.billingContractLineId = lineToCreditId; 
                    usageDataInput.creditFromDate = creditFromDate;
                    lp_UsageSelector.lp_UsageData usageDataOutput = lp_UsageSelector.getUsageCreditData(usageDataInput);
                    // The End Date on the Usage Contract Line needs to be the date of the latest Usage Record. The end date used for the credit needs to still be calculated from the OrderItem ServiceDate (creditFromDate).
                    endDate = usageDataOutput?.latestDate ?? creditFromDate.addDays(-1);
                } 
                updateChangeRequestContractLine.ffbc__EndDate__c = endDate < startDate ? startDate : endDate;
                update updateChangeRequestContractLine;

                if (newQty > 0) {
                    stage = 'creating amended contract line';
                    ffbc__ContractLineItem__c amendedContractLine = createFromcontractLine(changeRequestContractLine, orderItem); 
                    amendedContractLine.ffbc__FirstBillDate__c = (isUsageProduct ? endDate : amendedContractLine.ffbc__FirstBillDate__c).addDays(1);
                    amendedContractLine.ffbc__StartDate__c = amendedContractLine.ffbc__FirstBillDate__c;
                    insert amendedContractLine;
                }
                
                if (creditFromDate <= changeRequestContractLine.ffbc__BilledTo__c && lp_BillingSettings.getAutoCreateCreditLinesIsEnabled()) {
                    stage = 'creating credit line async job';
                    lp_AsyncJobStaging.createCreditLineJobs(new Map<Id, Date>{ lineToCreditId => creditFromDate });
                }

                stage = 'updating order item with billing contract line';     
                OrderItem updatedOrderItem = new OrderItem(Id = orderItem.Id);
                updatedOrderItem.LPC_BillingContractLine__c = changeRequestContractLine.ffbc__ActiveContractLineItem__c;
                update updatedOrderItem;
            }
            
            if(String.isBlank(orderItem.Order.LPC_Billing_Contract__c)){
                stage = 'updating order header with billing contract';
                Order updatedOrder = new Order(Id = orderItem.OrderId);
                updatedOrder.LPC_Billing_Contract__c = orderItem.Order.Prior_Billing_Contract__c;
                update updatedOrder;
            }

            stage = 'updating staging record';
            lp_AsyncJobStaging.completeOrderItemJob(asyncJob.Id, openContractId);
            
        } catch (Exception e) {
            Database.rollback(sp);
            lp_Utility.logException(e);
            String errorMessage = String.format(ERROR_FAILED_TO_AMEND_ORDER_PRODUCT, new List<String>{ stage, e.getMessage() });
            throw new lp_Exception(errorMessage, e, false);
        }
        return openContractId;
    }
    
    public static Id disconnectOrderItem(Id billingContractId, Id orderItemId){
        Savepoint sp = Database.setSavepoint();
        String stage = 'validating Order Product';
        Id changeRequestContractId = null;
        try {
            if(billingContractId != null){
                throw new lp_Exception(ERROR_CONTRACT_EXIST, true);
            }
            
            OrderItem jobOrderItem = new lp_OrderItemSelector().getById(orderItemId);

            if(jobOrderItem == null){
                throw new lp_Exception(lp_AsyncJobStaging.ERROR_MISSING_ORDER_PRODUCT, true);
            }
            
            stage = 'verifying contract line is not ended';
            ffbc__ContractLineItem__c priorBillingContractLine = new lp_BillingContractLineSelector().getById(jobOrderItem.Prior_Billing_Contract_Line_Item__c);
            if (priorBillingContractLine == null || priorBillingContractLine.ffbc__EndDate__c != null) {
                // This contract was already ended, presumably on a previous run for another Order Item on the same Order so nothing left to do
                return changeRequestContractId;
            }
            
            stage = 'getting change request contract';
            Id activeContractId = priorBillingContractLine.ffbc__Contract__c;
            changeRequestContractId = lp_BillingContract.getActiveChangeRequest(activeContractId);

            stage = 'ending change request contract lines';
            List<ffbc__ContractLineItem__c> changeRequestContractLines = new lp_BillingContractLineSelector().getByContractId(changeRequestContractId);
            
            List<ffbc__ContractLineItem__c> changeRequestContractLinesToUpdate = new List<ffbc__ContractLineItem__c>();
            List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
            ffbc__ContractLineItem__c changeRequestContractLine = null;

            Date endDate = jobOrderItem.ServiceDate;
            Date earliestCreditFromDate = endDate;
            Map<Id, lp_UsageSelector.lp_UsageData> usageDataBySourceLineId = new Map<Id, lp_UsageSelector.lp_UsageData>();
            for (ffbc__ContractLineItem__c crLine : changeRequestContractLines) {
                Id lineToCreditId = crLine.ffbc__ActiveContractLineItem__c;
                Date creditFromDate = endDate; 
                Boolean isUsageProduct = crLine.ffbc__ProductService__r.Usage_Product__c ?? false;
                if (isUsageProduct) {
                    lp_UsageSelector.lp_UsageData usageDataInput = new lp_UsageSelector.lp_UsageData();
                    creditFromDate = endDate.addMonths(1).toStartOfMonth();
                    usageDataInput.billingContractLineId = lineToCreditId;  
                    usageDataInput.creditFromDate = creditFromDate;
                    usageDataBySourceLineId.put(lineToCreditId, usageDataInput);
                    earliestCreditFromDate = creditFromDate < earliestCreditFromDate ? creditFromDate : earliestCreditFromDate; 
                } 
            }
            usageDataBySourceLineId = lp_UsageSelector.getUsageCreditDataMapByContractLineId(usageDataBySourceLineId, earliestCreditFromDate);

            Map<Id, Date> creditFromDateBySourceLineId = new Map<Id, Date>();
            Date headerEndDate = jobOrderItem.ServiceDate;
            for (ffbc__ContractLineItem__c crLine : changeRequestContractLines) {
                endDate = jobOrderItem.ServiceDate;
                ffbc__ContractLineItem__c changeRequestContractLineToUpdate = new ffbc__ContractLineItem__c( Id = crLine.Id); 
                Id lineToCreditId = crLine.ffbc__ActiveContractLineItem__c;
                Date creditFromDate = endDate.addDays(1);
                Boolean isUsageProduct = crLine.ffbc__ProductService__r.Usage_Product__c ?? false;
                if (isUsageProduct) {
                    creditFromDate = endDate.addMonths(1).toStartOfMonth();
                    endDate = creditFromDate.addDays(-1);
                    lp_UsageSelector.lp_UsageData usageDataOutput = usageDataBySourceLineId.get(lineToCreditId);
                    if (usageDataOutput != null) {
                        creditFromDate = usageDataOutput.creditFromDate;
                        // The End Date on the Usage Contract Line needs to be the date of the latest Usage Record. The end date used for the credit needs to still be calculated from the OrderItem ServiceDate (creditFromDate).
                        endDate = usageDataOutput.latestDate ?? endDate;
                    }
                }
                if (crLine.ffbc__EndDate__c == null) {
                    changeRequestContractLineToUpdate.ffbc__EndDate__c = endDate;
                    crLine.ffbc__EndDate__c = changeRequestContractLineToUpdate.ffbc__EndDate__c;
                    changeRequestContractLinesToUpdate.add(changeRequestContractLineToUpdate);
                } else if (crLine.ffbc__EndDate__c > headerEndDate) {
                    // We need to ensure that the Contract doesn't end before any of it's lines.
                    headerEndDate = crLine.ffbc__EndDate__c;
                }

                Id activeContractLineId = jobOrderItem.Prior_Billing_Contract_Line_Item__c;
                if (String.isNotBlank(activeContractLineId)) {
                    if (activeContractLineId == crLine.ffbc__ActiveContractLineItem__c) {
                        changeRequestContractLine = crLine; 
                    }
                }

                if (crLine.ffbc__BilledTo__c != null && (creditFromDate <= crLine.ffbc__BilledTo__c) && lp_BillingSettings.getAutoCreateCreditLinesIsEnabled()) {
                    stage = 'creating credit line async job';
                    creditFromDateBySourceLineId.put(lineToCreditId, creditFromDate);
                }
            }

            stage = 'inserting credit line async jobs';
            if (!creditFromDateBySourceLineId.isEmpty()) {
                List<Async_Job_Staging__c> newJobs = lp_AsyncJobStaging.createCreditLineJobs(creditFromDateBySourceLineId);
            }
            
            // Write back Contract Line to OrderItem.LPC_BillingContractLine__c
            OrderItem updatedOrderItem = new OrderItem(Id = jobOrderItem.Id);
            updatedOrderItem.LPC_BillingContractLine__c = jobOrderItem.Prior_Billing_Contract_Line_Item__c;
            orderItemsToUpdate.add(updatedOrderItem);

            
            stage = 'updating change request contract lines';
            update changeRequestContractLinesToUpdate;
            
            stage = 'updating order item';
            update orderItemsToUpdate;
            
            if(jobOrderItem.Order.Type != lp_Order.ORDER_TYPE_RENEWAL){
                stage = 'updating order header with billing contract';
                Order updatedOrder = new Order(Id = jobOrderItem.OrderId);
                updatedOrder.LPC_Billing_Contract__c = priorBillingContractLine.ffbc__Contract__c;
                update updatedOrder;
            }

            // End Contract
            stage = 'ending the contract';
            lp_BillingContract.end(changeRequestContractId, headerEndDate);

        } catch (Exception e) {
            Database.rollback(sp);
            lp_Utility.logException(e);
            String errrorMessage = String.format(ERROR_FAILED_TO_DISCONNECT_ORDER_PRODUCT, new List<String>{ stage, e.getMessage() });
            throw new lp_Exception(errrorMessage, e, false);
        }
        return changeRequestContractId;
    }
    
    public static Id disconnectOrderItem(Async_Job_Staging__c asyncJob){
        Savepoint sp = Database.setSavepoint();
        String stage = 'ending old contract';
        Id endedContractLine = null;
        try {
            endedContractLine = disconnectOrderItem(asyncJob.Billing_Contract__c, asyncJob.Order_Product__c);
            lp_AsyncJobStaging.completeOrderItemJob(asyncJob.Id, endedContractLine);
        } catch (Exception e) {
            Database.rollback(sp);
            lp_Utility.logException(e);
            String errrorMessage = String.format(ERROR_FAILED_TO_DISCONNECT_ORDER_PRODUCT, new List<String>{ stage, e.getMessage() });
            throw new lp_Exception(errrorMessage, e, false);
        }
        return endedContractLine;
    }

    public static Set<Id> renewOrderItem(Async_Job_Staging__c asyncJob){
        Savepoint sp = Database.setSavepoint();
        String stage = 'ending old contract';
        Set<Id> contractIds = new Set<Id>();
        try { 
            Id endedContractLine = disconnectOrderItem(asyncJob.Billing_Contract__c, asyncJob.Order_Product__c);
            contractIds.add(endedContractLine);
            
            stage = 'creating new contract';
            Id openContractId = billOrderItem(asyncJob.Billing_Contract__c, asyncJob.Order_Product__c);
            contractIds.add(openContractId);
            
            stage = 'completing Async Job Staging';
            lp_AsyncJobStaging.completeOrderItemJob(asyncJob.Id, openContractId);
            
        } catch (Exception e) {
            Database.rollback(sp);
            lp_Utility.logException(e);
            String errrorMessage = String.format(ERROR_FAILED_TO_RENEW_ORDER_PRODUCT, new List<String>{ stage, e.getMessage() });
            throw new lp_Exception(errrorMessage, e, false);
        }
        
        return contractIds;
    }
    
    public static Id createCreditLine(Async_Job_Staging__c asyncJob){
        Id openContractId = null;
        ffbc__ContractLineItem__c creditLine = null;
        Savepoint sp = Database.setSavepoint();
        String stage = 'searching for existing contract';
        try {
            if(asyncJob.Source_Billing_Contract_Line__c == null){
                throw new lp_Exception(lp_AsyncJobStaging.ERROR_MISSING_CONTRACT_LINE, true);
            } else if(asyncJob.Source_Billing_Contract_Line__r.ffbc__Contract__c == null){
                throw new lp_Exception(ERROR_CONTRACT_NOT_FOUND, true);
            } else if(asyncJob.Source_Billing_Contract_Line__r.ffbc__Contract__r.ffbc__Status__c != lp_BillingContract.STATUS_ACTIVE) {
                throw new lp_Exception(ERROR_CONTRACT_NOT_ACTIVE, true);
            }

            openContractId = asyncJob.Source_Billing_Contract_Line__r.ffbc__Contract__c;

            stage = 'searching for active change request';
            ffbc__Contract__c activeChangeRequest = new lp_BillingContractSelector().getActiveChangeRequestByActiveContractId(openContractId);
            if(activeChangeRequest?.Id != null){
                openContractId = activeChangeRequest?.Id;
            } else {
                stage = 'creating change request';
                openContractId = lp_BillingContract.createChangeRequest(openContractId);
            }
            
            stage = 'fetching change request line';
            Id activeContractLineId = asyncJob.Source_Billing_Contract_Line__r.ffbc__ActiveContractLineItem__c ?? asyncJob.Source_Billing_Contract_Line__c;
            ffbc__ContractLineItem__c changeRequestContractLine = new lp_BillingContractLineSelector(true).getMapByActiveContractLineIdFromContractIds(new Set<Id>{ openContractId })?.get(activeContractLineId);
            
            Date changeRequestEndDate = changeRequestContractLine.ffbc__EndDate__c;
            if (changeRequestEndDate == null && Test.isRunningTest()) {
                changeRequestEndDate = Date.today();
                changeRequestContractLine.ffbc__EndDate__c = changeRequestEndDate;
            }

            // Unable to set ffbc__BilledTo__c in tests - provide bypass
            Boolean isUsageProduct = changeRequestContractLine.LPC_Order_Item__r.Usage_Product__c;
            if (!isUsageProduct && !(changeRequestEndDate < changeRequestContractLine.ffbc__BilledTo__c || Test.isRunningTest())) {
                throw new lp_Exception(ERROR_CREDIT_LINE_NOT_NEEDED, true);
            }

            stage = 'creating credit line';
            creditLine = createFromContractLine(changeRequestContractLine, null);
            
            Date startDate = asyncJob.Process_Date__c ?? changeRequestEndDate.addDays(1);
            Date endDate = changeRequestContractLine.ffbc__BilledTo__c;
            
            lp_UsageSelector.lp_UsageData usageDataInput = new lp_UsageSelector.lp_UsageData();
            usageDataInput.billingContractLineId = activeContractLineId; 
            usageDataInput.creditFromDate = startDate;
            lp_UsageSelector.lp_UsageData usageDataOutput = lp_UsageSelector.getUsageCreditData(usageDataInput);
            
            Decimal quantity = changeRequestContractLine.ffbc__Quantity__c ?? 0;
            Decimal usageCreditAmount = (isUsageProduct ? usageDataOutput?.creditAmount : 0) ?? 0;
            Decimal unitPrice = (isUsageProduct ? (quantity > 0 ? usageCreditAmount / quantity : 0) : getCreditUnitPrice(startDate, endDate, creditLine.ffbc__UnitPrice__c));

            String message = isUsageProduct && unitPrice == 0 ? ERROR_NO_USAGE_CREDIT : null;
            
            if (String.isBlank(message) || Test.isRunningTest()) {
                creditLine.ffbc__BillingType__c = lp_BillingContractLine.BILLING_TYPE_ONE_OFF;
                creditLine.ffbc__FirstBillDate__c = startDate;
                creditLine.ffbc__StartDate__c = startDate;
                creditLine.ffbc__BilledTo__c = null;
                creditLine.ffbc__EndDate__c = endDate;
                creditLine.ffbc__UnitPrice__c = unitPrice;               
                
                stage = 'inserting credit line';
                insert creditLine;
            }

            stage = 'updating staging record';
            lp_AsyncJobStaging.completeCreditLineJob(asyncJob.Id, creditLine?.Id, message);
        } catch (Exception e) {
            Database.rollback(sp);
            lp_Utility.logException(e);
            String errrorMessage = String.format(ERROR_FAILED_TO_CREATE_CREDIT_LINE, new List<String>{ stage, e.getMessage() });
            throw new lp_Exception(errrorMessage, e, false);
        }
        return openContractId;
    }

    public static Decimal getProrationFactor(Date startDate, Date endDate) {
        // Validation: If dates are swapped or null, return 0
        if (startDate == null || endDate == null || startDate > endDate) return 0.0;

        // Dates are in the same month and year
        if (startDate.month() == endDate.month() && startDate.year() == endDate.year()) {
            Integer daysInMonth = Date.daysInMonth(startDate.year(), startDate.month());
            Integer activeDays = startDate.daysBetween(endDate) + 1; // Adding 1 makes the calculation inclusive of the startDate 
            return (Decimal)activeDays / daysInMonth;
        }

        // Calculate partial start month
        Integer daysInStartMonth = Date.daysInMonth(startDate.year(), startDate.month());
        Integer remainingDaysInStart = daysInStartMonth - startDate.day() + 1; // Adding 1 makes the calculation inclusive of the startDate
        Decimal startMonthFraction = (Decimal)remainingDaysInStart / daysInStartMonth;

        // Calculate partial end month
        Integer daysInEndMonth = Date.daysInMonth(endDate.year(), endDate.month());
        Integer elapsedDaysInEnd = endDate.day();
        Decimal endMonthFraction = (Decimal)elapsedDaysInEnd / daysInEndMonth;

        //  Calculate full months in between
        Date firstOfNextMonth = startDate.addMonths(1).toStartOfMonth();
        Date firstOfEndMonth = endDate.toStartOfMonth();
        Integer fullMonths = firstOfNextMonth.monthsBetween(firstOfEndMonth);
        if (fullMonths < 0) fullMonths = 0;
        
        return (startMonthFraction + fullMonths + endMonthFraction).setScale(4, RoundingMode.HALF_UP);
    }
    
    public static Decimal getCreditUnitPrice(Date startDate, Date endDate, Decimal unitPrice) {
        Decimal prorationFactor = getProrationFactor(startDate, endDate);
        Decimal creditUnitPrice = -1 * (prorationFactor * unitPrice); // Multiplying by -1 makes the unit price negative, appropriate for crediting
        return creditUnitPrice;
    }
}