/**
 * @author Ladd Partners
 * @date 5/22/2025
*/

public with sharing class lp_SalesOrderLine {

    public static final String RECORD_TYPE_ITEM = 'Item';
    public static final String RECORD_TYPE_DROP_SHIP = 'Drop_Ship';
    public static final String STATUS_NEW = 'New';
    public static final String STATUS_REVISED = 'Revised';
    public static final String STATUS_ALLOCATED = 'Allocated';
    public static final String STATUS_BACKORDERED = 'Backordered';
    public static final String STATUS_SHIPPED = 'Shipped';
    public static final String STATUS_CANCELLED = 'Cancelled';

    public static void createDropShipPerpetualTransaction(Map<Id, Decimal> dropShipQtyShipBySalesOrderLineIds) {
        Map<ID, SCMC__Sales_Order_Line_Item__c> salesOrderLineById = new lp_SalesOrderLineSelector().getMapByIds(dropShipQtyShipBySalesOrderLineIds.keySet());

        List<lp_PerpetualTransaction> perpetualTransactions = new List<lp_PerpetualTransaction>();
        for (Id salesOrderLineId : dropShipQtyShipBySalesOrderLineIds.keySet()) {
            Decimal qtyShipped = dropShipQtyShipBySalesOrderLineIds.get(salesOrderLineId);
            SCMC__Sales_Order_Line_Item__c salesOrderLine = salesOrderLineById.get(salesOrderLineId);

            lp_PerpetualTransaction perpetualTransaction = new lp_PerpetualTransaction(salesOrderLine);
            perpetualTransaction.shipDropShipSalesOrderLine(qtyShipped, null);
            perpetualTransactions.add(perpetualTransaction);
        }

        List<SCMC__Inventory_Transaction_Perpetual_Record__c> perpetualRecords = new List<SCMC__Inventory_Transaction_Perpetual_Record__c>();
        for (lp_PerpetualTransaction perpetualTransaction : perpetualTransactions) {
            SCMC__Inventory_Transaction_Perpetual_Record__c perpetualTransactionRecord = perpetualTransaction.perpetualRecord;
            perpetualRecords.add(perpetualTransactionRecord);
        }
        insert perpetualRecords;

        List<SCMC__Inventory_Transaction_Financial_Records__c> financialRecords = new List<SCMC__Inventory_Transaction_Financial_Records__c>();
        for (lp_PerpetualTransaction perpetualTransaction : perpetualTransactions) {
            perpetualTransaction.updateFinancialTransactions();
            financialRecords.addAll(perpetualTransaction.financialRecords);
        }
        insert financialRecords;
    }

}