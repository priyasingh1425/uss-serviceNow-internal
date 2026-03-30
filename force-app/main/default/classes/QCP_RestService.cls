@RestResource(urlMapping='/QCPRestService/*')
global without sharing class QCP_RestService {

    @HttpPost
    global static String getQuoteDetails(String endpoint, String salesforceToken, String quoteLineId, Boolean refreshPricing){
        HttpRequest req = new HttpRequest();

        if(refreshPricing){
            endpoint = endpoint.replace('/quote/','/refresh-quote/');
        }

        req.setEndpoint(endpoint+quoteLineId+'?salesforce_token='+salesforceToken);
        req.setMethod('GET');

        System.debug('::: Request');
        System.debug(req);

        Http http = new Http();
        HTTPResponse res = http.send(req);

        System.debug('::: Response');
        System.debug(res);

        System.debug(res.getBody());

        return res.getBody();
    }
    
}