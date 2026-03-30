@isTest
public with sharing class API_OM_Connection_Util_Test {

    private static FINAL Long ACCOUNT_ID = 001;
    private static FINAL Long CUSTOMER_ID = 002;
    private static FINAL Long CREATED_BY_ID = 003;
    private static FINAL String REFERENCE_ID = 'referenceId';

    private static ebtls.MockServer mockServer = ebtls.MockServer.initMatched();

    public static ebtls.MockServer initWithToken(){
        mockServer.reset();
        mockServer.whenRequest()
        .endpoint().endsWith('/get-token')
        .thenReturn()
        .statusCode(200)
        .body(
            '{'+
            '"success": true,'+
            '"message": "Token acquired",'+
            '"code": "TOKEN_ACQUIRED",'+
            '"data": {'+
            '"token": "TOKEN_STRING"'+
            '}}');

        return mockServer;
    }

    @isTest
    public static void init_Success(){
        initWithToken();

        Test.startTest();

        API_OM_Connection_Util util = API_OM_Connection_Util.getService();

        Test.stopTest();

        Assert.areEqual('TOKEN_STRING', util.authToken, 'The token returned doesn\'t match.');

        HttpRequest req = mockServer.takeRequest();

        Assert.areEqual('POST', req.getMethod());
        Assert.isTrue(req.getEndpoint().contains('/get-token'));
        Assert.isTrue(req.getBody().contains('name="api_key"\r\n\r\n{!$Credential.OM_DEV.API_KEY}'));
    }

    @isTest
    public static void init_Failed(){
        mockServer.reset();

        mockServer.whenRequest()
            .endpoint().endsWith('/get-token')
            .thenReturn()
            .statusCode(401)
            .body(
                '{'+
                '"success": false,'+
                '"error": 401,'+
                '"message": "The provided api key is invalid.",'+
                '"code": "API_CLIENT_AUTHENTICATION_FAILURE"'+
                '}')
            .build();

        Test.startTest();

        try{
            API_OM_Connection_Util util = API_OM_Connection_Util.getService();

            Assert.fail('An exception should have been thrown');
        }catch(Exception ex){
            Assert.isInstanceOfType(ex, API_OM_Connection_Util.OMException.class, 'The wrong type of exception was thrown: ' + ex.getTypeName());
            Assert.isTrue(ex.getMessage().startsWith('401'));
        }

        Test.stopTest();
    }

    @isTest
    public static void getToken_Success(){
        initWithToken();

        Test.startTest();

        String token = API_OM_Connection_Util.getToken();

        Test.stopTest();

        Assert.areEqual('TOKEN_STRING', token, 'The token returned doesn\'t match.');
    }

    @isTest
    public static void getToken_InvalidKey(){
        mockServer.reset();

        mockServer.whenRequest()
            .endpoint().endsWith('/get-token')
            .thenReturn()
            .statusCode(401)
            .body(
                '{'+
                '"success": false,'+
                '"error": 401,'+
                '"message": "The provided api key is invalid.",'+
                '"code": "API_CLIENT_AUTHENTICATION_FAILURE"'+
                '}')
            .build();

        Test.startTest();

        try{
            API_OM_Connection_Util.getToken();

            Assert.fail('An exception should have been thrown');
        }catch(Exception ex){
            Assert.isInstanceOfType(ex, API_OM_Connection_Util.OMException.class, 'The wrong type of exception was thrown: ' + ex.getTypeName());

            Assert.isTrue(ex.getMessage().startsWith('401'));
        }

        Test.stopTest();
    }

    @isTest
    public static void getToken_InvalidRequest(){
        mockServer.reset();

        mockServer.whenRequest()
            .endpoint().endsWith('/get-token')
            .thenReturn()
            .statusCode(422)
            .body(
                '{'+
                '"success": false,'+
                '"error": 422,'+
                '"message": "A validation error occurred.",'+
                '"code": "VALIDATION_ERROR",'+
                '"data": {'+
                '"api_key": ["The api key field is required."]'+
                '}}')
            .build();

        Test.startTest();

        try{
            API_OM_Connection_Util.getToken();

            Assert.fail('An exception should have been thrown');
        }catch(Exception ex){
            Assert.isInstanceOfType(ex, API_OM_Connection_Util.OMException.class, 'The wrong type of exception was thrown: ' + ex.getTypeName());
            Assert.isTrue(ex.getMessage().startsWith('422'));
        }

        Test.stopTest();
    }

    @isTest
    public static void createOrders(){
        initWithToken();

        mockServer.whenRequest()
            .endpoint().endsWith('/create-om-order')
            .thenReturn()
            .statusCode(200)
            .body(
                '{'+
                '"success": true,'+
                '"messages": ['+
                '{}'+
                '],'+
                '"code": "CREATE_ORDER_RESPONSE",'+
                '"data": {'+
                '"payload_reference_id": "ABC123",'+
                '"payload_state": "review"'+
                '}}')
            .build();

        List<API_OM_Connection_Util.Order> orders = new List<API_OM_Connection_Util.Order>();
        List<API_OM_Connection_Util.Contact> contacts = new List<API_OM_Connection_Util.Contact>();
        List<API_OM_Connection_Util.Attachment> attachments = new List<API_OM_Connection_Util.Attachment>();

        Test.startTest();

        API_OM_Connection_Util.QuoteStatus status = API_OM_Connection_Util.getService().createOrders(REFERENCE_ID, 'ORDER NAME', CUSTOMER_ID, ACCOUNT_ID, CREATED_BY_ID, 'description', orders, attachments, contacts);

        Test.stopTest();

        Assert.areEqual('review', status.payload_state);

        HttpRequest req = mockServer.takeRequest();//Get the token request
        req = mockServer.takeRequest();//Get the create order request

        Assert.areEqual('POST', req.getMethod());
        Assert.isTrue(req.getEndpoint().endsWith('/create-om-order'));
        Assert.areEqual('Bearer TOKEN_STRING', req.getHeader('Authorization'));
    }

    @isTest
    public static void createOrders_Unauthorized(){
        initWithToken();

        mockServer.whenRequest()
            .endpoint().endsWith('/create-om-order')
            .thenReturn()
            .statusCode(401)
            .body(
                '{'+
                '"success": false,'+
                '"error": 401,'+
                '"message": "Unauthorized"'+
                '}')
            .build();

        API_OM_Connection_Util util = API_OM_Connection_Util.getService();

        Test.startTest();

        try{
            util.createOrders(REFERENCE_ID, 'NAME', CUSTOMER_ID, ACCOUNT_ID, CREATED_BY_ID, 'description', new List<API_OM_Connection_Util.Order>(), new List<API_OM_Connection_Util.Attachment>(), new List<API_OM_Connection_Util.Contact>());
        }catch(Exception ex){
            Assert.isInstanceOfType(ex, API_OM_Connection_Util.OMException.class, 'The wrong type of exception was thrown: ' + ex.getTypeName());
            Assert.areEqual('401:Unauthorized', ex.getMessage());
        }

        Test.stopTest();
    }

    @isTest
    public static void createOrders_Failure(){
        initWithToken();

        mockServer.whenRequest()
            .endpoint().endsWith('/create-om-order')
            .thenReturn()
            .statusCode(400)
            .body(
                '{'+
                '"success": false,'+
                '"code": "CREATE_ORDER_RESPONSE",'+
                '"messages": ['+
                '{'+
                '"message": "Message",'+
                '"field": "general",'+
                '"type": "failure"'+
                '}'+
                ']}');

        API_OM_Connection_Util util = API_OM_Connection_Util.getService();

        Test.startTest();

        try{
            util.createOrders(REFERENCE_ID, 'NAME', CUSTOMER_ID, ACCOUNT_ID, CREATED_BY_ID, 'description', new List<API_OM_Connection_Util.Order>(), new List<API_OM_Connection_Util.Attachment>(), new List<API_OM_Connection_Util.Contact>());
        }catch(Exception ex){
            System.debug(ex.getMessage());
            Assert.isInstanceOfType(ex, API_OM_Connection_Util.OMException.class, 'The wrong type of exception was thrown: ' + ex.getTypeName());
            Assert.areEqual('Message;', ex.getMessage());
        }

        Test.stopTest();
    }

    @isTest
    public static void quoteStatus(){
        initWithToken();

        mockServer.whenRequest()
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
                '"payload_reference_id": "payloadId",'+
                '"payload_state": "review",'+
                '"orders":[{"order_reference_id":"orderId","order_state":"none"}]'+
                '}}');

        API_OM_Connection_Util util = API_OM_Connection_Util.getService();

        Test.startTest();

        API_OM_Connection_Util.QuoteStatus status = util.getQuoteStatus(REFERENCE_ID);

        Test.stopTest();

        Assert.areEqual('review',status.payload_state);
        Assert.areEqual('none', status.orders[0].order_state);
    }

    @isTest
    public static void quoteStatus_general(){
        initWithToken();

        mockServer.whenRequest()
            .endpoint().contains('order-state-inquiry')
            .thenReturn()
            .statusCode(400)
            .body('{'+
                '"success": false,'+
                '"code": "ORDER_STATE_INQUIRY_RESPONSE",'+
                '"messages": ['+
                '{'+
                '"message": "Message",'+
                '"field": "general",'+
                '"type": "failure"'+
                '}'+
                ']}');

        API_OM_Connection_Util util = API_OM_Connection_Util.getService();

        Test.startTest();

        try{
            util.getQuoteStatus(REFERENCE_ID);
        }catch(Exception ex){
            System.debug(ex.getMessage());
            Assert.isInstanceOfType(ex, API_OM_Connection_Util.OMException.class, 'The wrong type of exception was thrown: ' + ex.getTypeName());
            Assert.areEqual('Message;', ex.getMessage());
        }

        Test.stopTest();
    }

    @isTest
    public static void testClassCreation(){
        new API_OM_Connection_Util.Order();
        new API_OM_Connection_Util.Order('orderReference');
        new API_OM_Connection_Util.Attachment('fileId', 'fileName', 'MimeType', 'Date');
        new API_OM_Connection_Util.Attachment(new ContentVersion());
        new API_OM_Connection_Util.Contact('contactId', 'type');
    }
}