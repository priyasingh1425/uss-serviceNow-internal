@isTest
public with sharing class API_Order_OmniIntegration_Util_Test {
    @isTest
    public static void testInit(){
        API_Order_OmniIntegration_Util util = API_Order_OmniIntegration_Util.getService();

        Assert.isNotNull(util.runningUserCRMId);
        //Assert.isTrue(util.orderFields.contains('Id'));
        Assert.isTrue(util.orderItemFields.contains('ServiceDate'));
    }

    @isTest
    public static void testSubmitOrders(){
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

        Test.startTest();

        API_Order_OmniIntegration_Util.getService().submitOrders(quote.Id, new List<API_OM_SubmitOrdersContact_Model>(), new List<Id>());

        Test.stopTest();

        SBQQ__Quote__c q2 = [SELECT Id, OM_Payload_Status__c FROM SBQQ__Quote__c WHERE Id = :quote.Id];

        Assert.areEqual('review', q2.OM_Payload_Status__c);

        Order o2 = [SELECT Id, OM_Status__c FROM Order WHERE Id = :o.Id];

        Assert.areEqual('none', o2.OM_Status__c);
    }

    @isTest
    public static void isValidLocation(){
        OrderItem item = new OrderItem();
        item.Customer_Service_Location__c = '123';

        Boolean isValid = API_Order_OmniIntegration_Util.getService().isValidLocation(item);

        Assert.istrue(isValid);
    }

   // @isTest
   // public static void testCreateService(){
   //     OrderItem item = new OrderItem();

   //     API_Order_OmniIntegration_Util.getService().createService();
   // }

    @isTest
    public static void testCreateNoteBlob(){
        ContentNote cnote = new ContentNote();
        cnote.Title = 'Title';
        cnote.Content = Blob.valueOf('Test');

        API_OM_Connection_Util.Note note = API_Order_OmniIntegration_Util.getService().createNotes(cnote);

        Assert.areEqual('Title', note.subject);
    }

    @isTest
    public static void testCreateNote(){
        OrderItem item = new OrderItem();
        item.Order_Notes__c = 'Test note';

        API_OM_Connection_Util.Note note = API_Order_OmniIntegration_Util.getService().createOrderNote(item);

        Assert.areEqual('Test note', note.note);
        Assert.areEqual('Order Note', note.subject);
    }

    @isTest
    public static void testCalculateServiceBandwidth(){
        API_Order_OmniIntegration_Util.getService().calculateServiceBandwidth('123');
    }
}