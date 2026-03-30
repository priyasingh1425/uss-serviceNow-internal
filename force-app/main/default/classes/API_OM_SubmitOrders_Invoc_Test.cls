@isTest
public with sharing class API_OM_SubmitOrders_Invoc_Test {
    @isTest
    public static void testSubmitOrder(){
        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = a.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        insert quote;

        Order o = new Order();
        o.AccountId = a.Id;
        o.SBQQ__Quote__c = quote.Id;
        o.EffectiveDate = Date.today();
        o.Status = 'Draft';
        insert o;

        EBTLS.MockServer mock = API_OM_Connection_Util_Test.initWithToken();

        mock.whenRequest()
            .endpoint().contains('create-om-order')
            .thenReturn()
            .statusCode(200)
            .body('{'+
                '"success": true,'+
                '"messages": ['+
                '{}'+
                '],'+
                '"code": "CREATE_ORDER_RESPONSE",'+
                '"data": {'+
                '"payload_reference_id": "'+quote.Id+'",'+
                '"payload_state": "review",'+
                '"orders":[{"order_reference_id":"'+
                o.Id+
                '","order_state":"none"}]'+
                '}}');

        API_OM_SubmitOrders_Invoc.OMSubmitRequest req = new API_OM_SubmitOrders_Invoc.OMSubmitRequest();
        req.quoteId = quote.Id;
        req.contacts = new List<API_OM_SubmitOrdersContact_Model>();
        req.fileIds = new List<Id>();

        Test.startTest();

        API_OM_SubmitOrders_Invoc.submitOrdersInvoc(new List<API_OM_SubmitOrders_Invoc.OMSubmitRequest>{req});

        Test.stopTest();

        SBQQ__Quote__c q2 = [SELECT Id, OM_Payload_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];

        Assert.areEqual('review', q2.OM_Payload_Status__c);

        Order o2 = [SELECT Id, OM_Status__c FROM Order WHERE Id = :o.Id];

        Assert.areEqual('none', o2.OM_Status__c);
    }

    @isTest
    public static void testException(){
        Account a = new Account();
        a.Name = 'Test';
        insert a;

        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;

        SBQQ__Quote__c quote = new SBQQ__Quote__c();
        quote.SBQQ__Account__c = a.Id;
        quote.SBQQ__Opportunity2__c = opp.Id;
        quote.SBQQ__Primary__c = true;
        insert quote;

        Order o = new Order();
        o.AccountId = a.Id;
        o.SBQQ__Quote__c = quote.Id;
        o.EffectiveDate = Date.today();
        o.Status = 'Draft';
        insert o;

        EBTLS.MockServer mock = API_OM_Connection_Util_Test.initWithToken();

        API_OM_SubmitOrders_Invoc.OMSubmitRequest req = new API_OM_SubmitOrders_Invoc.OMSubmitRequest();
        req.quoteId = quote.Id;
        req.contacts = new List<API_OM_SubmitOrdersContact_Model>();
        req.fileIds = new List<Id>();

        Test.startTest();

        List<API_OM_SubmitOrders_Invoc.OMSubmitResult> results = API_OM_SubmitOrders_Invoc.submitOrdersInvoc(new List<API_OM_SubmitOrders_Invoc.OMSubmitRequest>{req});

        Test.stopTest();

        Assert.areEqual(1, results.size());
        Assert.isFalse(results[0].success);
    }
}