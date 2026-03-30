@isTest
public with sharing class QCP_RestService_Test {
    
    @isTest
	public static void testRestPost()
	{	
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Test.startTest();
		//invoking functionality
        String result1 = QCP_RestService.getQuoteDetails('http://www.google.com','test','1234',false); 
		String result2 = QCP_RestService.getQuoteDetails('http://www.google.com','test','1234',true);
		Test.stopTest();
    }
    
}