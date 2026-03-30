// SC-0000100
// Class to define the interface for all API requests in Connectbase (best practice for integration implementations)
public interface API_CBintegration_ITF {
    String getEndpoint(List<Object> params);
    String getHttpMethod();
    HttpRequest buildRequest(List<Object> params);
    Object parseResponse(String responseBody);
}