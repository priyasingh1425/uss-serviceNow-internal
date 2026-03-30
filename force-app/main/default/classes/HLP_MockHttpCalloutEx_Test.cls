// Additional mock classes for different test scenarios
@isTest
public class HLP_MockHttpCalloutEx_Test implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        // This will cause an exception to be thrown
        throw new CalloutException('Simulated callout exception');
    }
}