/**
  * @author Ladd Partners
  * @date 1/26/2017
  * @group
  * @description Constant values used in the custom Solution.
*/


public with sharing class lp_Constants {

    public static final String ORDER_PROCESSING_QUEUE_NAME = 'Order_Processing';
    public static ID ORDER_PROCESSING_QUEUE_ID = null;

    //constants used by lp_SetupTest
    public static final String AP_VOUCHER_STATUS_NEW = 'New';
	
	public static final String PURCHASE_ORDER_STATUS_OPEN = 'Open';
	public static final String PURCHASE_ORDER_RECORD_TYPE_DROP_SHIP = 'Drop_Ship_Purchase_Order';
	public static final String PURCHASE_ORDER_LINE_STATUS_OPEN = 'Open';
}