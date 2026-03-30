/**
 * @author Ladd Partners
 * @date 4/21/2025
*/

public with sharing class lp_EcmsSummaryMockImpl {

    public static HttpResponse createSummarySuccess(List<String> updated, List<String> deleted) {
        HttpResponse response = new HttpResponse();
        response.setStatus('OK');
        response.setStatusCode(200);

        lp_EcmsTypes.GetSummaryResponse summaryResponse = new lp_EcmsTypes.GetSummaryResponse();
        summaryResponse.updated = updated;
        summaryResponse.deleted = deleted;

        response.setBody(JSON.serialize(summaryResponse));

        return response;
    }

}