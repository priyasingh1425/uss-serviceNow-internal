// SC-0000100
// Interface class to create costs in Connectbase
public class API_CB_PricingModel_INS implements API_CBintegration_ITF {
    public String status;
	public cls_data data;
	class cls_data {
		public String quoteId;
		public String[] configIds;
	}

    public String getEndpoint(List<Object> params) {
        return 'callout:Connectbase_Advanced_CPQ_API' + '/accounts/' + (String)params[0] + '/deals/' + (String)params[1] + '/' + System.Label.CompanyId;
    }

    public String getHttpMethod() {
        return 'POST';
    }

    public HttpRequest buildRequest(List<Object> params) {
        try {
            System.debug('params: '+ params);
            HttpRequest req = new HttpRequest();
            String product = (String)params[3];
            Map<String, Decimal> speedMap = (Map<String, Decimal>)params[6];
            req.setEndpoint(getEndpoint(params));
            req.setMethod(getHttpMethod());
            req.setHeader('Content-Type', 'application/json');
            req.setTimeout(60000);
            Set<String> addresses = (Set<String>)params[7];
            String locationsString = '';
            Integer i = 0;
            for (String address : addresses) {
                locationsString += '{"address": "' + address + '"}';
                if (i < addresses.size() - 1) {
                    locationsString += ',';
                }
                i++;
            }
            System.debug('locationsString@@@' + locationsString);
            String requestBody;
            if (product == 'Broadband') {
                requestBody = '{' +
                    '"quoteName": "' + (String)params[2] + '",' +
                    '"config": {' +
                    '"productCriteria": [{' +
                    '"product": "' + (String)params[3] + '",' +
                    '"mediaTypes": [' + (String)params[4] + '],' +
                    '"channel": "Default",' +
                    '"term": [' + (String)params[5] + '],' +
                    '"includeOffnet": true,' +
                    '"speedParameterDownload": {' +
                    '"greaterThan": ' + String.valueOf(speedMap.get('lowestSpeed')) +
                    '},' +
                    '"selection": {' +
                    '"desiredSpeed": ' + String.valueOf(speedMap.get('lowestSpeed')) +
                    '}' +
                    '}]' +
                    '},' +
                    '"locations": [' + locationsString + ']' +
                    '}';
            }
            else if (product == 'Ethernet - Switched') {
                requestBody = '{' +
                    '"quoteName": "' + (String)params[2] + '",' +
                    '"config": {' +
                    '"productCriteria": [{' +
                    '"product": "' + (String)params[3] + '",' +
                    '"mediaTypes": [' + (String)params[4] + '],' +
                    '"channel": "Default",' +
                    '"term": [' + (String)params[5] + '],' +
                    '"includeOffnet": true,' +
                    '"speedParameterDownload": {' +
                    '"greaterThan": ' + String.valueOf(speedMap.get('lowestSpeed')) + ',' +
                    '"lessThan": ' + String.valueOf(speedMap.get('highestSpeed') + 500) + 
                    '},' +
                    '"selection": {' +
                    '"desiredSpeed": ' + String.valueOf(speedMap.get('lowestSpeed')) +
                    '}' +
                    '}]' +
                    '},' +
                    '"locations": [' + locationsString + ']' +
                    '}';
            }
            else {
                requestBody = '{' +
                    '"quoteName": "' + (String)params[2] + '",' +
                    '"config": {' +
                    '"productCriteria": [{' +
                    '"product": "' + (String)params[3] + '",' +
                    '"mediaTypes": [' + (String)params[4] + '],' +
                    '"channel": "Default",' +
                    '"term": [' + (String)params[5] + '],' +
                    '"includeOffnet": true,' +
                    '"speedParameterDownload": {' +
                    '"equal": [' + String.valueOf(speedMap.get('lowestSpeed')) + ']' +
                    '},' +
                    '"speedParameterUpload": {' +
                    '"equal": [' + String.valueOf(speedMap.get('lowestSpeed')) + ']' +
                    '}' +
                    '}]' +
                    '},' +
                    '"locations": [' + locationsString + ']' +
                    '}';
            }
            System.debug(product + ' ' + requestBody);
            req.setBody(requestBody);
            return req;
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_INS.buildRequest at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }

    }

    public Object parseResponse(String responseBody) {
        try {
            return (API_CB_PricingModel_INS) System.JSON.deserialize(responseBody, API_CB_PricingModel_INS.class);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_INS.parseResponse at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
	
    public static void createPricing(String accId, String dealId, String quoteName, String product, String mediaType, String term, Map<String, Decimal> speedMap, Set<String> addresses, Map<String, String> senderToReceiverMap, String groupId) {
        try {
            List<Object> params = new List<Object>{accId, dealId, quoteName, product, mediaType, term, speedMap, addresses};
            API_CBintegration_ITF handler = new API_CB_PricingModel_INS();
            HttpRequest request = handler.buildRequest(params);
            System.debug('request.getBody()@@@' + request.getBody());
            sendRequestAndHandleResponse(request, handler, senderToReceiverMap, product, groupId);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_INS.createPricing at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }

    private static void sendRequestAndHandleResponse(HttpRequest request, API_CBintegration_ITF handler, Map<String, String> senderToReceiverMap, String product, String groupId) {
        Http http = new Http();
        List<SBQQ__QuoteLine__c> qlList = [SELECT Id, Name, SBQQ__Quote__c FROM SBQQ__QuoteLine__c WHERE Id IN : senderToReceiverMap.values()];
        SBQQ__Quote__c sfQuote = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Id =: qlList[0].SBQQ__Quote__c LIMIT 1];
        List<SBQQ__QuoteLine__c> qlListUpdate = new List<SBQQ__QuoteLine__c>();
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];

        try {
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {
                API_CB_PricingModel_INS parsedResponse = (API_CB_PricingModel_INS) handler.parseResponse(response.getBody());
                if (parsedResponse.status == 'success') {
                    API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Pricing Creation', 'true', String.valueOf(response.getStatusCode()), response.getStatus(), parsedResponse.data.quoteId, sfQuote.Id, null);
                    for (SBQQ__QuoteLine__c ql : qlList) {
                        ql.External_Connectbase_Id__c = parsedResponse.data.quoteId;
                        ql.Is_Errored__c = false;
                        ql.Error_Status__c = null;
                        qlListUpdate.add(ql);
                    }
                    update qlListUpdate;
                    List<String> senderReceiverPairs = new List<String>();
                    for (String sender : senderToReceiverMap.keySet()) {
                        String senderReceiver = sender + '=' + senderToReceiverMap.get(sender);
                        senderReceiverPairs.add(senderReceiver);
                    }
                    String s = String.join(senderReceiverPairs, ',');
                    Get_Pricing_Request__c gpr = new Get_Pricing_Request__c(User__c = UserInfo.getUserId(), SF_Quote__c = sfQuote.Id, Connectbase_Quote_Id__c = parsedResponse.data.quoteId, SF_Quote_Line_Ids__c = s, Page_Number__c = 0, Connectbase_Product__c = product, SF_Group__c = groupId);
                    insert gpr; 
                }
                else {
                    API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Pricing Creation', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, sfQuote.Id, null);
                    List<String> quoteLineNames = new List<String>();
                    for (SBQQ__QuoteLine__c ql : qlList) {
                        ql.Is_Errored__c = true;
                        ql.Error_Status__c = response.getBody() + ';CreatePricing;RequestMade;'+response.getStatusCode();
                        qlListUpdate.add(ql);
                        quoteLineNames.add(ql.Name);
                    }
                    update qlListUpdate;
                    String quoteLineNamesStr = String.join(quoteLineNames, ', ');
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Error in Costing Quote Lines');
                    notification.setBody('There was an error in costing Quote Lines ' + quoteLineNamesStr + ' on Quote ' + sfQuote.Name + ': ' + response.getBody());
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(sfQuote.Id);
                    notification.send(new Set<String> { UserInfo.getUserId()});
                }
            } else {
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Pricing Creation', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, sfQuote.Id, null);
                List<String> quoteLineNames = new List<String>();
                for (SBQQ__QuoteLine__c ql : qlList) {
                    ql.Is_Errored__c = true;
                    ql.Error_Status__c = response.getBody() + ';CreatePricing;RequestMade;'+response.getStatusCode();
                    qlListUpdate.add(ql);
                    quoteLineNames.add(ql.Name);
                }
                update qlListUpdate;
                String quoteLineNamesStr = String.join(quoteLineNames, ', ');
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Error in Costing Quote Lines');
                notification.setBody('There was an error in costing Quote Lines ' + quoteLineNamesStr + ' on Quote ' + sfQuote.Name + ': ' + response.getBody());
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(sfQuote.Id);
                notification.send(new Set<String> { UserInfo.getUserId()});
            }
        } catch (Exception e) {
            List<String> quoteLineNames = new List<String>();
            for (SBQQ__QuoteLine__c ql : qlList) {
                ql.Is_Errored__c = true;
                ql.Error_Status__c = e.getMessage() + ';CreatePricing;NoRequestMade';
                qlListUpdate.add(ql);
                quoteLineNames.add(ql.Name);
            }
            update qlListUpdate;
            String quoteLineNamesStr = String.join(quoteLineNames, ', ');
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Error in Costing Quote');
            notification.setBody('There was an error in costing Quote Lines ' + quoteLineNamesStr + ' on Quote ' + sfQuote.Name + ': ' + e.getMessage());
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(sfQuote.Id);
            notification.send(new Set<String> { UserInfo.getUserId()});
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_INS.sendRequestAndHandleResponse at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
}