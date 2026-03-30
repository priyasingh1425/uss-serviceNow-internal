@isTest
public with sharing class API_OM_Status_SchedBatch_Test {
    @isTest
    public static void schedule(){
        System.schedule('Status Poll', '0 0 * * * ? *', new API_OM_Status_SchedBatch());
    }

    @isTest
    public static void batchable(){
        Database.executeBatch(new API_OM_Status_SchedBatch(new Set<Id>()));
    }

    @isTest
    public static void statusPull(){
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
        quote.OM_Payload_Status__c = 'review';
        insert quote;

        Order o = new Order();
        o.AccountId = a.Id;
        o.SBQQ__Quote__c = quote.Id;
        o.EffectiveDate = Date.today();
        o.Status = 'Draft';
        insert o;

        EBTLS.MockServer mock = API_OM_Connection_Util_Test.initWithToken();

        mock.whenRequest()
            .endpoint().contains('order-state-inquiry')
            .thenReturn()
            .statusCode(200)
            .body('{'+
                '"success": true,'+
                '"messages": ['+
                '{}'+
                '],'+
                '"code": "ORDER_STATE_INQUIRY_RESPONSE",'+
                '"data": {'+
                '"payload_reference_id": "'+quote.Id+'",'+
                '"payload_state": "pending",'+
                '"orders":[{"order_reference_id":"'+
                o.Id+
                '","order_state":"none"}]'+
                '}}');

        Test.startTest();

        Database.executeBatch(new API_OM_Status_SchedBatch());

        Test.stopTest();

        SBQQ__Quote__c q2 = [SELECT Id, OM_Payload_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];

        Assert.areEqual('pending', q2.OM_Payload_Status__c);

        Order o2 = [SELECT Id, OM_Status__c FROM Order WHERE Id = :o.Id];

        Assert.areEqual('none', o2.OM_Status__c);
    }
}