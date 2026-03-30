/**
 * @author Ladd Partners
 * @date 4/21/2025
*/

public with sharing class lp_EcmsHttpCalloutMock implements HttpCalloutMock {

    List<HttpResponse> responses = new HttpResponse[0];

    public void addResponse(HttpResponse response) {
        responses.add(response);
    }

    public HttpResponse respond(HttpRequest request) {
        return responses.remove(0);
    }

}