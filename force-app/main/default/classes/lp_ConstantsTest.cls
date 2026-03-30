/**
 * Created by Ladd Partners on 2021-11-30.
 */

@IsTest
public with sharing class lp_ConstantsTest {

    @IsTest
    private static void test() {
        String value = lp_Constants.AP_VOUCHER_STATUS_NEW;
        value = lp_Constants.ORDER_PROCESSING_QUEUE_ID;
        value = lp_Constants.ORDER_PROCESSING_QUEUE_NAME;
        value = lp_Constants.PURCHASE_ORDER_LINE_STATUS_OPEN;
        value = lp_Constants.PURCHASE_ORDER_RECORD_TYPE_DROP_SHIP;
        value = lp_Constants.PURCHASE_ORDER_STATUS_OPEN;
    }
}