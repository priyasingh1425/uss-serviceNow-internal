/**
 * Created by Ladd Partners on 5/7/2025.
 */

public with sharing class lp_Order {
    public static final String ORDER_TYPE_AMENDMENT = 'Change';
    public static final String ORDER_TYPE_DISCONNECT = 'Disco';
    public static final String ORDER_TYPE_NEW = 'New';
    public static final String ORDER_TYPE_RENEWAL = 'Renew';
    public static final Map<String, String> ASYNC_JOB_BY_ORDER_TYPE = new Map<String, String>{ ORDER_TYPE_AMENDMENT => lp_AsyncJobStaging.JOB_AMEND_ORDER_ITEMS, ORDER_TYPE_DISCONNECT => lp_AsyncJobStaging.JOB_DISCONNECT_ORDER_ITEMS, ORDER_TYPE_NEW => lp_AsyncJobStaging.JOB_BILL_ORDER_ITEMS, ORDER_TYPE_RENEWAL => lp_AsyncJobStaging.JOB_RENEW_ORDER_ITEMS };
}