public with sharing class API_OM_CheckOrderStatus_Invoc {
    @InvocableMethod(label='Update OM Order Status' callout=true category='OM Integration')
    public static void updateStatusInvoc(List<List<Id>> quoteIdSet){
        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        List<Order> orders = new List<Order>();

        API_Order_OmniIntegration_Util service = API_Order_OmniIntegration_Util.getService();

        for(List<Id> quoteIds:quoteIdSet){
            for(Id quoteId:quoteIds){
                API_Order_OmniIntegration_Util.OfsStatus status = service.checkOrderStatus(quoteId);
                quotes.add(status.quote);
                orders.addAll(status.orders);
            }
        }

        update orders;
        update quotes;
    }
}