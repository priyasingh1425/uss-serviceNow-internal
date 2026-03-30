// SC-0000100
// Interface class to create accounts in Connectbase
public class API_CB_AccountModel_INS implements API_CBintegration_ITF {
    public String status;
    public cls_data[] data;
    
    public class cls_data {
        public String account_id;
        public String user_account_id;
        public String company_name;    
        public String user_id;    
        public String createddate;    
        public Integer is_created_by_corporate_user;
    }

    public String getEndpoint(List<Object> params) {
        return 'callout:Connectbase_Advanced_CPQ_API' + '/accounts' + System.Label.CompanyId;
    }

    public String getHttpMethod() {
        return 'POST';
    }

    public HttpRequest buildRequest(List<Object> accName) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(getEndpoint(new List<String>()));
            req.setMethod(getHttpMethod());
            req.setHeader('Content-Type', 'application/json');
            String requestBody = '{"company_name": "' + (String)accName[0] + '"}';
            req.setBody(requestBody);
            return req;
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AccountModel_INS.buildRequest at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }

    public Object parseResponse(String responseBody) {
        try { 
            return (API_CB_AccountModel_INS) System.JSON.deserialize(responseBody, API_CB_AccountModel_INS.class);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AccountModel_INS.parseResponse at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
        
    }
    
    public static String createAccount(String accName, String sfQuoteId) {
        try {
            API_CBintegration_ITF handler = new API_CB_AccountModel_INS();
            HttpRequest request = handler.buildRequest(new List<Object>{accName});
            return sendRequestAndHandleResponse(request, handler, sfQuoteId);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AccountModel_INS.createAccount at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
        
    }

    private static String sendRequestAndHandleResponse(HttpRequest request, API_CBintegration_ITF handler, String sfQuoteId) {
        Http http = new Http();
        SBQQ__Quote__c sfQuote = [SELECT Id, Name, SBQQ__Account__c FROM SBQQ__Quote__c WHERE Id =: sfQuoteId];
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                API_CB_AccountModel_INS parsedResponse = (API_CB_AccountModel_INS) handler.parseResponse(response.getBody());
                if (parsedResponse.status == 'success') {
                    Account sfAcc = [SELECT Id FROM Account WHERE Id =: sfQuote.SBQQ__Account__c LIMIT 1];
                    API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Account Creation', 'true', String.valueOf(response.getStatusCode()), response.getStatus(), parsedResponse.data[0].account_id, sfQuote.SBQQ__Account__c, null);
                    sfAcc.External_Connectbase_Id__c = parsedResponse.data[0].account_id;
                    update sfAcc;
                    sfQuote.Is_Errored__c = false;
                    sfQuote.Error_Status__c = null;
                    update sfQuote;
                    return parsedResponse.data[0].account_id;
                }
                else {
                    API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Account Creation', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, sfQuote.SBQQ__Account__c, null);
                    sfQuote.Is_Errored__c = true;
                    sfQuote.Error_Status__c = response.getBody() + ';CreateAccount;RequestMade;'+response.getStatusCode();
                    update sfQuote;
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Error in Costing Quote');
                    notification.setBody('There was an error in costing Quote ' + sfQuote.Name + ': ' + response.getBody());
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(sfQuote.Id);
                    notification.send(new Set<String> { UserInfo.getUserId()});
                    return null;
                }
            } else {
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Account Creation', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, sfQuote.SBQQ__Account__c, null);
                sfQuote.Is_Errored__c = true;
                sfQuote.Error_Status__c = response.getBody() + ';CreateAccount;RequestMade;'+response.getStatusCode();
                update sfQuote;
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Error in Costing Quote');
                notification.setBody('There was an error in costing Quote ' + sfQuote.Name + ': ' + response.getBody());
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(sfQuote.Id);
                notification.send(new Set<String> { UserInfo.getUserId()});
                return null;
            }
        } catch (Exception e) {
            sfQuote.Is_Errored__c = true;
            sfQuote.Error_Status__c = e.getMessage() + ';CreateAccount;NoRequestMade';
            update sfQuote;
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Error in Costing Quote');
            notification.setBody('There was an error in costing Quote ' + sfQuote.Name + ': ' + e.getMessage());
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(sfQuote.Id);
            notification.send(new Set<String> { UserInfo.getUserId()});
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AccountModel_INS.sendRequestAndHandleResponse at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
}