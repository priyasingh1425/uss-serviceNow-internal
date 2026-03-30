/**
 * @author Ladd Partners
 * @date 11/17/17
 * @group
 * @description Manage actions on a sales order
 */

public with sharing class lp_SalesOrderTriggerHandler extends lp_AbstractTriggerHandler {

    public class Factory implements lp_TriggerHandlerFactory {
        public lp_TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new lp_SalesOrderTriggerHandler(objects, oldObjectsById);
        }
    }

    private final List<SCMC__Sales_Order__c> salesOrders;
    private final Map<Id, SCMC__Sales_Order__c> oldSalesOrdersById;

    private lp_SalesOrderTriggerHandler(List<SObject> salesOrders, Map<Id, SObject> oldSalesOrdersById) {
        this.salesOrders = salesOrders;
        this.oldSalesOrdersById = (Map<Id, SCMC__Sales_Order__c>) oldSalesOrdersById;
    }

    public override void beforeInsert() {
		Id order_queue_id = lp_Utility.getOrderProcessQueueId();
		//set the ownerId on sales order to the appropriate Queue
		for (SCMC__Sales_Order__c so : salesOrders) {
			so.OwnerId = order_queue_id;
		}
	}

}