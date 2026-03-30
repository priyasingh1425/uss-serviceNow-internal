/**
 * @author Ladd Partners
 * @date 5/22/2025
*/

@IsTest
private class lp_PerpetualTransactionTest {

    private static final lp_SetupTest scmSetupTest = new lp_SetupTest();

    @IsTest
    static void partiallyDropShipAll() {
        createAPVoucherAndRelease(false);
    }

    @IsTest
    static void dropShipAll() {
        createAPVoucherAndRelease(true);
    }

    private static void createAPVoucherAndRelease(Boolean receiveAllInventory) {
        lp_BillingSetupTest setupTest = new lp_BillingSetupTest();
//        OrderItem orderProduct = setupTest.setupOrderProductForBillingContract();

        lp_BillingSettings.customTriggersAreEnabled = true;

        SCMC__Warehouse__c warehouse = scmSetupTest.setupWarehouse();
        SCMC__Supplier_Site__c supplierSite = scmSetupTest.createSupplier(scmSetupTest.currency_master, true);

        SCMC__Item__c orderProductItem = scmSetupTest.createItem(true);

        SCMC__Sales_Order__c salesOrder = scmSetupTest.createSalesOrder(setupTest.acct, false);
//        salesOrder.Order__c = orderProduct.OrderId;
        insert salesOrder;

        SCMC__Sales_Order_Line_Item__c salesOrderLine = scmSetupTest.createSalesOrderLine(salesOrder, orderProductItem, lp_SalesOrderLine.STATUS_NEW, false);
//        salesOrderLine.Order_Product__c = orderProduct.Id;
        salesOrderLine.RecordTypeId = lp_Utility.getRecordType(lp_SalesOrderLine.RECORD_TYPE_DROP_SHIP, salesOrderLine);
        salesOrderLine.SCMC__Quantity__c = 10;
        salesOrderLine.SCMC__Item_Cost__c = 100;
        insert salesOrderLine;

        salesOrder.SCMC__Status__c = lp_SalesOrder.STATUS_APPROVED;
        salesOrder.SCMFFA__Company_Name__c = lp_BillingSetupTest.companyName;
        update salesOrder;

        SCMC__Purchase_Order__c purchaseOrder = scmSetupTest.createPurchaseOrder(supplierSite, warehouse.Id, false);
        purchaseOrder.RecordTypeId = lp_Utility.getRecordType('Drop_Ship_Purchase_Order', purchaseOrder);
        purchaseOrder.SCMC__Sales_Order__c = salesOrder.Id;
        insert purchaseOrder;

        SCMC__Purchase_Order_Line_Item__c purchaseOrderLine = scmSetupTest.createPurchaseOrderLine(purchaseOrder, null, orderProductItem, 'Item', false);
//        purchaseOrderLine.Order_Product__c = orderProduct.Id;
        purchaseOrderLine.SCMC__Sales_Order_Line_Item__c = salesOrderLine.Id;
        purchaseOrderLine.SCMC__Quantity__c = salesOrderLine.SCMC__Quantity__c;
        purchaseOrderLine.SCMC__Quantity_Received__c = 0;
        purchaseOrderLine.SCMC__Unit_Cost__c = salesOrderLine.SCMC__Item_Cost__c;
        insert purchaseOrderLine;

        SCMC__Sales_Order_Line_Item__c updatedSalesOrderLine = new SCMC__Sales_Order_Line_Item__c(Id = salesOrderLine.Id);
        updatedSalesOrderLine.SCMC__Purchase_Order_Line_Item__c = purchaseOrderLine.Id;
        update updatedSalesOrderLine;

        SCMC__Purchase_Order__c updatedPurchaseOrder = new SCMC__Purchase_Order__c(Id = purchaseOrder.Id);
        updatedPurchaseOrder.SCMC__Status__c = 'Approved';
        updatedPurchaseOrder.SCMFFA__Company_Name__c = lp_BillingSetupTest.companyName;
        updatedPurchaseOrder.RecordTypeId = lp_Utility.getRecordType('Approved_Drop_Ship_Purchase_Order', purchaseOrder);
        update updatedPurchaseOrder;

        lp_BillingSettings.customTriggersAreEnabled = false;

        SCMC__AP_Voucher__c apVoucher = scmSetupTest.createAPVoucher(supplierSite, purchaseOrder, true);
        SCMC__AP_Voucher_Line__c apVoucherLine = scmSetupTest.createAPVoucherLine(apVoucher, purchaseOrderLine, false);
        apVoucherLine.SCMC__Quantity__c = 3;
        if (receiveAllInventory) {
            apVoucherLine.SCMC__Quantity__c = salesOrderLine.SCMC__Quantity__c;
        }
        insert apVoucherLine;

        Test.startTest();

        SCMC.AccountPayableVouchersService.receive(new Set<Id>{apVoucher.Id});
        Test.getEventBus().deliver();

        Test.stopTest();

            List<SCMC__Purchase_Order_Line_Item__c> pols = [SELECT Id, SCMC__Quantity_Received__c, SCMC__Quantity_Vouchered__c, SCMC__Status__c FROM SCMC__Purchase_Order_Line_Item__c];
            System.debug('pols: ' + pols);
            List<SCMC__Sales_Order_Line_Item__c> sols = [SELECT Id, SCMC__Quantity__c, SCMC__Quantity_Shipped__c, SCMC__Status__c FROM SCMC__Sales_Order_Line_Item__c];
            System.debug('sols: ' + sols);
        List<SCMC__Inventory_Transaction_Perpetual_Record__c> itprs1 = [
                SELECT Id, SCMC__Quantity__c, SCMC__Sales_Order_Line_Item__c, SCMC__Inventory_Transactions__c
        FROM SCMC__Inventory_Transaction_Perpetual_Record__c
        ];
        System.debug('itprs1: ' + itprs1);

        // Order_Product__c,
        List<SCMC__Inventory_Transaction_Perpetual_Record__c> itprs = [
                SELECT Id, SCMC__Quantity__c
                FROM SCMC__Inventory_Transaction_Perpetual_Record__c
                WHERE SCMC__Inventory_Transactions__c = :lp_PerpetualTransaction.TRANSACTION_BILL_DROP_SHIP_ITEM
                AND SCMC__Sales_Order_Line_Item__c = :salesOrderLine.Id
        ];

        Assert.areEqual(1, itprs.size(), 'Could not locate the Perpetual Transaction for ' + lp_PerpetualTransaction.TRANSACTION_BILL_DROP_SHIP_ITEM);
        SCMC__Inventory_Transaction_Perpetual_Record__c itpr = itprs[0];
//        Assert.isNotNull(itpr.Order_Product__c, 'Could not locate the Order Product');
        Assert.areEqual(apVoucherLine.SCMC__Quantity__c, itpr.SCMC__Quantity__c, 'Wrong Qty');

        List<SCMC__Inventory_Transaction_Financial_Records__c> itfrs = [
                SELECT Id
                FROM SCMC__Inventory_Transaction_Financial_Records__c
                WHERE SCMC__Inventory_Transaction__c = :itpr.Id
        ];
        Assert.areEqual(2, itfrs.size(), 'Could not locate all the Financial Transaction for ' + lp_PerpetualTransaction.TRANSACTION_BILL_DROP_SHIP_ITEM);
    }

}