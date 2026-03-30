/**
 * @author Ladd Partners
 * @date 4/16/2025
*/

public with sharing class lp_EcmsService {

    public static final String API_SUMMARY = 'api/v2/summary/afc';
    public static final String API_GET_BY_ID = 'api/v2/accounts/{0}/afc';

    public static final String DATETIME_FORMAT = 'YYYY-MM-dd HH:MM:ss';

    public static final Boolean isProd = lp_EcmsSettings.useProduction();

    public static final String PRODUCTION_TOKEN = '{!$Credential.ECMS_prod.api_token}'; // external credential parameter
    public static final String SANDBOX_TOKEN = '{!$Credential.ECMS_sb.api_token}'; // external credential parameter

    public static lp_EcmsTypes.GetSummaryResponse getChangesSummary() {
        Datetime currentDatetime = Datetime.now();
        Datetime lastImportCall = lp_EcmsSettings.getPreviousECMSImportRunTime();
        return getChangesSummary(lastImportCall, currentDatetime);
    }

    public static lp_EcmsTypes.GetSummaryResponse getChangesSummary(Datetime startDate, Datetime endDate) {
        lp_EcmsTypes.GetSummaryRequest requestBody = new lp_EcmsTypes.GetSummaryRequest();
        requestBody.start = startDate.format(DATETIME_FORMAT);
        requestBody.end_Z = endDate.format(DATETIME_FORMAT);
        if (isProd) {
            requestBody.api_token = PRODUCTION_TOKEN;
        } else {
            requestBody.api_token = SANDBOX_TOKEN;
        }

        String body = JSON.serialize(requestBody);
        body = body.replace('end_Z', 'end');

        System.debug(LoggingLevel.FINEST, 'body: ' + body);
        HttpRequest req = createHttpRequest(API_SUMMARY, body);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            throw new lp_Exception('Failed to retrieve exemption changes. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }

        lp_EcmsTypes.GetSummaryResponse exemptionResponseWrapper =
                (lp_EcmsTypes.GetSummaryResponse)JSON.deserialize(
                        res.getBody(),
                        lp_EcmsTypes.GetSummaryResponse.class
                );
        System.debug(LoggingLevel.DEBUG, 'exemptionResponseWrapper: ' + exemptionResponseWrapper);

        return exemptionResponseWrapper;
    }

    public static lp_EcmsTypes.GetByAccountIdResponse importByAccountId(String ecmsAccountId, Integer recordOffset) {
        Integer pageSize = lp_EcmsSettings.getECMSExemptionsBatchSize();
        if (recordOffset == null) { recordOffset = 0; }

        lp_EcmsTypes.GetByAccountIdRequest requestBody = new lp_EcmsTypes.GetByAccountIdRequest();
        requestBody.count = true;
        requestBody.countOnly = false;
        requestBody.top = pageSize;
        requestBody.skip = recordOffset;
        requestBody.approved = true;
        if (isProd) {
            requestBody.api_token = PRODUCTION_TOKEN;
        } else {
            requestBody.api_token = SANDBOX_TOKEN;
        }

        String body = JSON.serialize(requestBody);
        System.debug(LoggingLevel.FINEST, 'body: ' + body);

        String apiUrl = String.format(API_GET_BY_ID, new List<String>{ecmsAccountId});
        System.debug(LoggingLevel.DEBUG, 'apiUrl: ' + apiUrl);
        HttpRequest req = createHttpRequest(apiUrl, body);

        Http http = new Http();
        HttpResponse res = http.send(req);
        System.debug(LoggingLevel.FINEST, 'Response: ' + res);

        if (res.getStatusCode() != 200) {
            throw new lp_Exception('Failed to retrieve exemptions. Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        }

        lp_EcmsTypes.GetByAccountIdResponse exemptionResponse =
                (lp_EcmsTypes.GetByAccountIdResponse)JSON.deserialize(
                        res.getBody(),
                        lp_EcmsTypes.GetByAccountIdResponse.class
                );

        return exemptionResponse;
    }

    private static HttpRequest createHttpRequest(String apiURL, String body) {
        HttpRequest req = new HttpRequest();
        if (isProd) {
            req.setEndpoint('callout:ECMS_production/' + apiURL); // named credential name
        } else {
            req.setEndpoint('callout:ECMS_sandbox/' + apiURL);  // named credential name
        }
        req.setMethod('POST');
        req.setHeader('Accept','application/json');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);

        Decimal timeout = lp_CertifySettings.importExpenseReportsTimeout;
        if(timeout != null) {
            req.setTimeout(Integer.valueOf(timeout));
        }
        System.debug('request: ' + req);

        return req;
    }

}