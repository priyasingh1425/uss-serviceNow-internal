// SC-0000100
// Interface class to fetch costs from Connectbase
public class API_CB_PricingModel_QRY implements API_CBintegration_ITF {
    public String status;
	public cls_pagination pagination;
	public cls_data data;
    public class cls_pagination {
        public Integer page;
        public Integer pageSize;
        public Integer totalPages;
    }
	public class cls_data {
		public Integer totalLocations;
		public Integer totalLocationSolutions;
		public Integer numSolutions;
		public cls_pricingStatus pricingStatus;
	}
	public class cls_pricingStatus {
		public Integer quoteId;
		public String quoteName;
		public Integer accountId;
		public String accountName;
		public Integer dealId;
		public String dealName;
		public String defaultCompanyCPQRuleChain;
		public cls_prices[] prices;
		public Integer externalApiProgress;
		public String transactionStatus;
		public String message;
	}
	public class cls_prices {
		public Integer id;
		public Integer quoteId;
		public String priceState;
		public String term;
		public Integer locationId;
		public String note;
		public String provider;
		public Double mrc;
		public Double mrcCost;
		public Double mrcTotalPrice;
		public Double nrc;
		public Double nrcCost;
		public Double nrcTotalPrice;
		public String baseCurrencyId;
		public String address;
		public String city;
		public String state;
		public String zip;
		public Integer addressValid;
		public String secondaryDesignator;
		public String secondaryNumber;
		public String latitude;
		public String longitude;
		public String uniqueKey;
		public String globalLocationId;
		public String countryCode;
		public String flexField1;
		public Integer preferredSupplier;
		public String product;
		public String apiProductName;
		public String speed;
		public Integer uploadSpeed;
		public Integer downloadSpeed;
		public String mediaType;
		public String netStatus;
		public String bldgStatus;
		public String status;
		public String dispositionCode;
		public String buildingCategories;
		public String buildingCompetitiveRating;
		public String pricingType;
		public String createdDate;
		public String createdBy;
		public String lastmileSupplier;
		public String catalog;
		public String resellerSupplier;
		public Double resellerProviderMrc;
		public Double resellerProviderNrc;
		public Double totalOrderValue;
		public String baseCurrency;
		public String quoteCurrency;
	}
    
    public class ApiResultWrapper {
        public API_CB_PricingModel_QRY parsedResponse { get; set; }
        public API_Response__c apiResponse { get; set; }
        
        public ApiResultWrapper(API_CB_PricingModel_QRY parsedResponse, API_Response__c apiResponse) {
            this.parsedResponse = parsedResponse;
            this.apiResponse = apiResponse;
        }
    }

    public String getEndpoint(List<Object> params) {
        return 'callout:Connectbase_Advanced_CPQ_API' +'/quotes/' + (String)params[0] + '/prices' + System.Label.CompanyId + '&page=' + (String)params[1] + '&pageSize=100';
    }

    public String getHttpMethod() {
        return 'GET';
    }

    public HttpRequest buildRequest(List<Object> params) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(getEndpoint(params));
            req.setMethod(getHttpMethod());
            req.setTimeout(120000);
            return req;
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_QRY.buildRequest at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
        
    }

    public Object parseResponse(String responseBody) {
        try {
            return (API_CB_PricingModel_QRY) System.JSON.deserialize(responseBody, API_CB_PricingModel_QRY.class); 
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_QRY.parseResponse at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
    
    public static ApiResultWrapper getPricing(String quoteId, List<String> sfQuoteLineIds, Integer pageNumber, String userId) {
        try {
            List<String> params = new List<String>{quoteId, String.valueOf(pageNumber)};
            API_CBintegration_ITF pricingHandler = new API_CB_PricingModel_QRY();
            HttpRequest request = pricingHandler.buildRequest(params);
            return handleApiRequest(request, pricingHandler, sfQuoteLineIds, userId);
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_QRY.getPricing at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            System.debug(ce.message);
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
    
    private static ApiResultWrapper handleApiRequest(HttpRequest request, API_CBintegration_ITF handler, List<String> sfQuoteLineIds, String userId) {
        Http http = new Http();
        List<SBQQ__QuoteLine__c> qlUpdate = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> qlList = [SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.Name FROM SBQQ__QuoteLine__c WHERE Id IN :sfQuoteLineIds];
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
        try {
            HttpResponse response = http.send(request);
            Integer maxLength = 32768;
            String responseBody;
            if (response.getStatusCode() == 200) {
                API_CB_PricingModel_QRY parsedResponse = (API_CB_PricingModel_QRY) handler.parseResponse(response.getBody());
                if (parsedResponse.status == 'success') {
                    responseBody = response.getBody().length() > maxLength ? response.getBody().substring(0, maxLength) : response.getBody(); 
                    API_Response__c ar = API_APIResponse_INS.returnAPIResponse(request.getEndpoint(), request.getBody(), responseBody, true, request.getMethod(), 'Connectbase Pricing Fetch', 'true', String.valueOf(response.getStatusCode()), response.getStatus(), null, qlList[0].SBQQ__Quote__c, null);
                    return new ApiResultWrapper(parsedResponse, ar);
                }
                else {
                    API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Pricing Fetch', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, qlList[0].SBQQ__Quote__c, null);
                    List<String> quoteLineNames = new List<String>();
                    for (SBQQ__QuoteLine__c ql : qlList) {
                        ql.Is_Errored__c = true;
                        ql.Error_Status__c = response.getBody() + ';GetPrices;RequestMade;'+response.getStatusCode();
                        qlUpdate.add(ql);
                        quoteLineNames.add(ql.Name);
                    }
                    update qlUpdate;
                    String quoteLineNamesStr = String.join(quoteLineNames, ', ');
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();
                    notification.setTitle('Error in Costing Quote Lines');
                    notification.setBody('There was an error in costing Quote Lines ' + quoteLineNames + ' of Quote ' + qlList[0].SBQQ__Quote__r.Name + ': ' + response.getBody());
                    notification.setNotificationTypeId(notificationType.Id);
                    notification.setTargetId(qlList[0].SBQQ__Quote__c);
                    notification.send(new Set<String> { userId });
                    return null;
                }
            } else {
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Pricing Fetch', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, qlList[0].SBQQ__Quote__c, null);
                List<String> quoteLineNames = new List<String>();
                for (SBQQ__QuoteLine__c ql : qlList) {
                    ql.Is_Errored__c = true;
                    ql.Error_Status__c = response.getBody() + ';GetPrices;RequestMade;'+response.getStatusCode();
                    qlUpdate.add(ql);
                    quoteLineNames.add(ql.Name);
                }
                update qlUpdate;
                String quoteLineNamesStr = String.join(quoteLineNames, ', ');
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Error in Costing Quote Lines');
                notification.setBody('There was an error in costing Quote Lines ' + quoteLineNames + ' of Quote ' + qlList[0].SBQQ__Quote__r.Name + ': ' + response.getBody());
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId(qlList[0].SBQQ__Quote__c);
                notification.send(new Set<String> { userId });
                return null;
            }
        } catch (Exception e) {
            List<String> quoteLineNames = new List<String>();
            for (SBQQ__QuoteLine__c ql : qlList) {
                ql.Is_Errored__c = true;
                ql.Error_Status__c = e.getMessage() + ';GetPrices;NoRequestMade';
                qlUpdate.add(ql);
                quoteLineNames.add(ql.Name);
            }
            update qlUpdate;
            String quoteLineNamesStr = String.join(quoteLineNames, ', ');
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Error in Costing Quote Lines');
            notification.setBody('There was an error in costing Quote Lines ' + quoteLineNames + ' of Quote ' + qlList[0].SBQQ__Quote__r.Name + ': ' + e.getMessage());
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(qlList[0].SBQQ__Quote__c);
            notification.send(new Set<String> { userId });

            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_PricingModel_QRY.handleApiRequest at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            System.debug(ce.message);
            return null;
        }
    }
}