// SC-0000100
// Interface class to create deals in Connectbase
public class API_CB_DealModel_INS implements API_CBintegration_ITF {
    public String status;
    public cls_data[] data;

    public class cls_data {
        public String deal_id;
        public String deal_name;
        public String company_name;
        public Integer isbulk_deal;
        public String createddate;
        public String deal_currency;
    }

    public String getEndpoint(List<Object> params) {
        return 'callout:Connectbase_Advanced_CPQ_API' +'/accounts/' + (String)params[0] + '/deals' + System.Label.CompanyId;
    }

    public String getHttpMethod() {
        return 'POST';
    }

    public HttpRequest buildRequest(List<Object> params) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(getEndpoint(params));
            req.setMethod(getHttpMethod());
            req.setHeader('Content-Type', 'application/json');
            String requestBody = '{"deal_name": "' + (String)params[1] + '"}';
            req.setBody(requestBody);
            return req;
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_DealModel_INS.buildRequest at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }

    public Object parseResponse(String responseBody) {
        try {
            return (API_CB_DealModel_INS) System.JSON.deserialize(responseBody, API_CB_DealModel_INS.class);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_DealModel_INS.parseResponse at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
	
    public static String createDeal(String accountId, String dealName, String sfQuoteId) {
        try {
            List<String> params = new List<String>{accountId, dealName};
            API_CBintegration_ITF handler = new API_CB_DealModel_INS();
            HttpRequest request = handler.buildRequest(params);
            return sendRequestAndHandleResponse(request, handler, sfQuoteId);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_DealModel_INS.createDeal at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }

    private static String sendRequestAndHandleResponse(HttpRequest request, API_CBintegration_ITF handler, String sfQuoteId) {
        Http http = new Http();
        SBQQ__Quote__c sfQuote = [SELECT Id, Name, SBQQ__Account__r.External_Connectbase_Id__c FROM SBQQ__Quote__c WHERE Id =: sfQuoteId];
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                API_CB_DealModel_INS parsedResponse = (API_CB_DealModel_INS) handler.parseResponse(response.getBody());
                if (parsedResponse.status == 'success') {
                    API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Deal Creation', 'true', String.valueOf(response.getStatusCode()), response.getStatus(), parsedResponse.data[0].deal_id, sfQuote.Id, null);
                    sfQuote.External_Connectbase_Id__c = parsedResponse.data[0].deal_id;
                    sfQuote.Is_Errored__c = false;
                    sfQuote.Error_Status__c = null;
                    update sfQuote;
                    return parsedResponse.data[0].deal_id;
                }
                else {
                    API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Deal Creation', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, sfQuote.Id, null);
                    sfQuote.Is_Errored__c = true;
                    sfQuote.Error_Status__c = response.getBody() + ';CreateDeal;RequestMade;'+response.getStatusCode();
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
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Deal Creation', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, sfQuote.Id, null);
                sfQuote.Is_Errored__c = true;
                sfQuote.Error_Status__c = response.getBody() + ';CreateDeal;RequestMade;'+response.getStatusCode();
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
            sfQuote.Error_Status__c = e.getMessage() + ';CreateDeal;NoRequestMade';
            update sfQuote;
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Error in Costing Quote');
            notification.setBody('There was an error in costing Quote ' + sfQuote.Name + ': ' + e.getMessage());
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(sfQuote.Id);
            notification.send(new Set<String> { UserInfo.getUserId()});
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_DealModel_INS.sendRequestAndHandleResponse at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
}