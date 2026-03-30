/**
 * @author Ladd Partners
 * @date 5/22/2025
*/

public with sharing class lp_SalesOrderLineTriggerHandler extends lp_AbstractTriggerHandler {

    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new lp_SalesOrderLineTriggerHandler(objects, oldObjectsById);
        }
    }

    private final List<SCMC__Sales_Order_Line_Item__c> salesOrderLines;
    private final Map<Id, SCMC__Sales_Order_Line_Item__c> oldSalesOrderLineById;

    private lp_SalesOrderLineTriggerHandler(List<SObject> salesOrderLines, Map<Id, SObject> oldSalesOrderLineById) {
        this.salesOrderLines = salesOrderLines;
        this.oldSalesOrderLineById = (Map<Id, SCMC__Sales_Order_Line_Item__c>) oldSalesOrderLineById;
    }

    public override void afterUpdate() {
        Map<Id, Decimal> dropShipQtyShipBySalesOrderLineIds = new Map<Id, Decimal>();

        Id dropShipRecordTypeId = lp_Utility.getRecordType(lp_SalesOrderLine.RECORD_TYPE_DROP_SHIP, new SCMC__Sales_Order_Line_Item__c());

        for (SCMC__Sales_Order_Line_Item__c salesOrderLine : salesOrderLines) {
            SCMC__Sales_Order_Line_Item__c oldSalesOrderLine = oldSalesOrderLineById.get(salesOrderLine.Id);

            if (salesOrderLine.RecordTypeId == dropShipRecordTypeId && salesOrderLine.SCMC__Quantity_Shipped__c != oldSalesOrderLine.SCMC__Quantity_Shipped__c) {
                Decimal shippedQty = salesOrderLine.SCMC__Quantity_Shipped__c - oldSalesOrderLine.SCMC__Quantity_Shipped__c;
                dropShipQtyShipBySalesOrderLineIds.put(salesOrderLine.Id, shippedQty);
            }
        }

        if (!dropShipQtyShipBySalesOrderLineIds.isEmpty()) {
            lp_SalesOrderLine.createDropShipPerpetualTransaction(dropShipQtyShipBySalesOrderLineIds);
        }
    }

}