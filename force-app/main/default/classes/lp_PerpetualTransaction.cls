/**
 * @author Ladd Partners
 * @date 5/22/2025
*/

public with sharing class lp_PerpetualTransaction {

    private lp_FinancialTransaction financialTransaction;
    private SCMC__Sales_Order_Line_Item__c salesOrderLine;

    public static final String TRANSACTION_BILL_DROP_SHIP_ITEM = 'Bill Drop Ship Item';

    public SCMC__Inventory_Transaction_Perpetual_Record__c perpetualRecord;
    public SCMC__Inventory_Transaction_Financial_Records__c[] financialRecords;

    public lp_PerpetualTransaction(SCMC__Sales_Order_Line_Item__c salesOrderLine) {
        this.salesOrderLine = salesOrderLine;
        this.financialTransaction = new lp_FinancialTransaction();
        this.financialRecords = new List<SCMC__Inventory_Transaction_Financial_Records__c>();
    }

    public void shipDropShipSalesOrderLine(Decimal qty, String comments) {
        this.perpetualRecord = new SCMC__Inventory_Transaction_Perpetual_Record__c();
        this.perpetualRecord.SCMC__Inventory_Transactions__c = TRANSACTION_BILL_DROP_SHIP_ITEM;
        this.perpetualRecord.SCMC__Item_Master__c = salesOrderLine.SCMC__Item_Master__c;
        this.perpetualRecord.SCMC__Quantity__c = qty;
        this.perpetualRecord.SCMC__Sales_Order_Line_Item__c = salesOrderLine.Id;
//        this.perpetualRecord.Order_Product__c = salesOrderLine.Order_Product__c;
        this.perpetualRecord.SCMC__Inventory_Location__c = null;
        this.perpetualRecord.SCMC__Reason_Code__c = null;
        this.perpetualRecord.SCMC__Comment__c = comments;
        this.perpetualRecord.SCMC__Unit_of_Measure__c = salesOrderLine.SCMC__Item_Master__r.SCMC__Stocking_UOM__c;
        this.perpetualRecord.SCMC__Purchase_Order_Line_Item__c = salesOrderLine.SCMC__Purchase_Order_Line_Item__c;
        this.perpetualRecord.SCMFFA__Accounting_Company__c = salesOrderLine.SCMC__Sales_Order__r.SCMFFA__Company__c;        
        this.financialTransaction = new lp_FinancialTransaction(this.perpetualRecord);
        this.financialRecords.addAll(financialTransaction.billDropShipInventory(salesOrderLine.SCMC__Sales_Order__r.SCMC__Currency__c, salesOrderLine.SCMC__Unit_Cost__c));
    }

    public void updateFinancialTransactions() {
        for (SCMC__Inventory_Transaction_Financial_Records__c financialRecord : this.financialRecords) {
            financialRecord.SCMC__Inventory_Transaction__c = this.perpetualRecord.Id;
        }
    }

}