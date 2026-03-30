public class OFSController {
    @AuraEnabled 
    public static List<Account> getChildAccounts(String recordId) {
        Opportunity opp = [SELECT AccountId FROM Opportunity WHERE Id=:recordId];      
        String customerId = opp.AccountId;
    	List<Account> accounts = [SELECT Id, Name, CRM_ID__c, Customer_Number__c 
                                  FROM Account 
                                  WHERE ParentId=:customerId 
                                    AND Disabled_Chk__c=False
                                    AND Status__c IN('Pending','Active','Prospect')];   //11/14/19: Added Status check #USS-22 //11/22/19: Added Prospect
        return accounts;
    }   
    
    @AuraEnabled
    public static Map<String, String> processWrapper(String opp_id, String account_string, String order_type, String current_user_id, String descr) {  
        List<API_Response__c> apiResponses = new List<API_Response__c>();   
        API_Response__c tokenResponse = new API_Response__c();
        Map<String, String> log = new Map<String, String>();
        String isOFSCreated = 'false', message = '', token = '', ofsId = '', cust_string = '', retention_rep_string='';
        Integer customer_id;
        Long retention_rep_id, sales_rep_id;
        
        try {
            message = 'Process Wrapper started ... ';
            //Step 1: Create Token via Callout to API             
            tokenResponse = createToken();
            
            //Step 2: If we have a token, Create OFS via Callout to API
            if((tokenResponse != null) && (tokenResponse.Token__c != null)) {
                message += 'createToken(): Token received successfully ...';
                tokenResponse.Opportunity__c = opp_id;
                
                //Step 2a: Add first API Response to be inserted at the end for logging purposes
                apiResponses.add(tokenResponse);
                
                //Step 2b: Query for and build all inputs for creating OFS
                Opportunity opp = [SELECT Id, AccountId, Name, Partner__r.CRM_ID__c FROM Opportunity WHERE Id=:opp_id]; 
                
                if(Test.isRunningTest()) { //Test Mode -- Set these values explicitly instead of trying to query them, or test class will error
                    //Customer
                    cust_string = '213123';
                    //Sales Rep
                    sales_rep_id = 9999;
                    //Retention Rep
                    retention_rep_string = '9999';
                    if(retention_rep_string != null) { retention_rep_id = Long.valueOf(retention_rep_string); }
                } else { //Live Mode -- Get these values dynamically
                	//Customer
                	Account customer = [SELECT Id, CRM_ID__c, Owner.CRM_User_ID__c, Client_Development_Rep__r.CRM_User_ID__c FROM Account WHERE Id=:opp.AccountId];
                	cust_string = customer.CRM_ID__c;
                	customer_id = Integer.valueOf(cust_string.removeStart('C')); 
                    //Sales Rep
               		sales_rep_id = Long.valueOf(customer.Owner.CRM_User_ID__c);
                	//Retention Rep
                	retention_rep_string = customer.Client_Development_Rep__r.CRM_User_ID__c;
                	if(retention_rep_string != null) { retention_rep_id = Long.valueOf(retention_rep_string); }
                }
                
                //Step 2b continued ... (Will work whether in Test or Live mode)
                User created_by = [SELECT Id, CRM_User_ID__c FROM User WHERE Id=:current_user_id];
                //Opp Name
                String opp_name = opp.Name;
                //Partner
                String partner_string = opp.Partner__r.CRM_ID__c;
                Integer partner_id;
                if(partner_string != null) { partner_id = Integer.valueOf(partner_string.removeStart('AG')); }
                //Created By User
                Long created_by_id = Long.valueOf(created_by.CRM_User_ID__c);
                //Order Description 
                String desc_clean = String.escapeSingleQuotes(descr);
                desc_clean = desc_clean.left(255);
				
                //Step 3: Create OFS in back office system and OFS record on Opportunity
                API_Response__c ofsResponse = new API_Response__c();
            	ofsResponse = createOFS(tokenResponse.Token__c, opp_id, customer_id, account_string, opp_name, order_type, sales_rep_id, retention_rep_id, partner_id, created_by_id, desc_clean);  
            	
                //Step 4: If we have an OFS, insert API Responses for logging purposes, and build log to be returned to client controller
                if(ofsResponse != null) {
                    //Step 4a: Determine ofsResponse has an OFS Id or not
                    message += 'OFS Response Code Received: ' + ofsResponse.Code__c + ' ... ';
                    if(ofsResponse.OFS_Id__c != null && ofsResponse.OFS_Id__c != '') {
                        isOFSCreated = 'true';
                        ofsId = ofsResponse.OFS_Id__c;
                        message += 'OFS Id created: ' + ofsId + ' ... ';                        
                    } else {
                        message += 'No OFS Id ... ';
                    }
                    //Step 4b: Add second API Response to be inserted at the end for logging purposes
                    ofsResponse.Opportunity__c = opp_id;
                    apiResponses.add(ofsResponse);   
                    //Step 4c: Insert API Responses for logging purposes
                    if(apiResponses != null) { insert apiResponses; }                    
                } else {
                    message = 'Error creating OFS - likely the OFS API response came back null';
                }    
            } else {
                message = 'Error creating token - likely the token API response came back null';
            }
            //Step 5: Send log back to client controller for display in console and to end user
            System.Debug('#### processWrapper() OFS Created: ' + isOFSCreated);
            System.Debug('#### processWrapper() Result: ' + message);  
            log.put('isOFSCreated', isOFSCreated);
            log.put('message', message);
            log.put('ofsId', ofsId);
            return log;
        } catch (Exception e) {
            //Step 5 Exception: Send log back to client controller for display in console and to end user
            System.debug('An exception occurred in processWrapper(): ' + e.getMessage() + ' ... Line Number: ' + e.getLineNumber());
            log.put('isOFSCreated', 'false');
            log.put('message', 'An exception occurred in processWrapper(): ' + e.getMessage() + ' ... Line Number: ' + e.getLineNumber());
            log.put('ofsId', 'No Id');
            return log;
        }
    }
        
    private static API_Response__c createToken() { 
        API_Response__c apiResp = new API_Response__c();            
        String strToken = '', API_KEY = '', TOKEN_URL = '';
        Integer statusCode;
        
        try {
            //Get API Key and createToken endpoint url from custom metadata stored in SF
            OFS_API_Settings__mdt[] settings = [SELECT OFS_API_KEY__c, OFS_Create_Token_URI__c FROM OFS_API_Settings__mdt WHERE DeveloperName='OFS_API'];
            for (OFS_API_Settings__mdt setting : settings) { //should only be one record
                API_KEY = setting.OFS_API_KEY__c;
                TOKEN_URL = setting.OFS_Create_Token_URI__c;
            }
            
            //Build Http Request, and build API Response record as we go > to be inserted later for logging purposes
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(TOKEN_URL);
            apiResp.Endpoint__c = 'OFS Create Token'; //
            request.setMethod('POST');
            apiResp.Method__c = 'POST'; //
            Blob headerValue = Blob.valueOf(API_KEY + ':');
            String authHeader = EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', authHeader);
            request.setBody('api_key=' + API_KEY);
            apiResp.Http_Request__c = '{API_KEY}';
            
            HttpResponse resp = new HttpResponse();
            
            if(!Test.isRunningTest()) { //If Live mode - call actual API endpoint
                resp = http.send(request);
                statusCode = resp.getStatusCode();
                apiResp.Http_Response__c = resp.getBody(); //
                apiResp.Status_Code__c = String.valueOf(statusCode); //
                //if(statusCode != 200) {  //Error 
                    //TODO: Process the response differently depending on status code if desired
                //} else {  //Success - StatusCode 200  
                //}  
            } else { //If Test mode - build mock API response
                apiResp.Http_Response__c = '{"success":"true","message":"The Order for Service has been created.","code":"API_OFS_CREATED","data":{"token":"OFS!","order_for_service_id":12345,"description":"Just a description"}}';
                statusCode = 200;
                apiResp.Status_Code__c = String.valueOf(statusCode);
            }  
            
            //Parse the response, regardless whether Live mode or Test mode
            JSONParser parser = JSON.createParser(apiResp.Http_Response__c);
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    parser.nextValue();
                    if(parser.getCurrentName() == 'success') { apiResp.Success__c = parser.getText(); }
                    if(parser.getCurrentName() == 'message') { apiResp.Message__c = parser.getText(); }
                    if(parser.getCurrentName() == 'code') { apiResp.Code__c = parser.getText(); }
                    if(parser.getCurrentName() == 'token') { 
                        apiResp.Token__c = parser.getText();
                        strToken = apiResp.Token__c;
                    }
                }
            }
			//Return API Response which contains Token for next call to createOFS()            
            return apiResp;
        } catch (Exception e) {
            System.debug('An exception occurred in createToken(): ' + e.getMessage() + ' ... Line Number: ' + e.getLineNumber());
			return null;
        }    
    }  
    
    private static API_Response__c createOFS(String token, String opp_id, Integer customer_id, String account_string, String opportunity_name, String order_type, Long sales_rep_id, Long retention_rep_id, Integer partner_id, Long created_by_id, String descr) {                                            
		OFS__c newOFS = new OFS__c();
        String strOFS = '', account_id = 'new', OFS_URL = '';
        Integer statusCode;        
        API_Response__c apiResp = new API_Response__c();
        
        try {
            //If the Account is existing, trim the 'A' off the front of the CRM Id
            if(account_string != 'new') { account_id = account_string.removeStart('A'); }
            
            //Get API Key and createOFS endpoint url from custom metadata stored in SF
            OFS_API_Settings__mdt[] settings = [SELECT OFS_Create_OFS_URI__c FROM OFS_API_Settings__mdt WHERE DeveloperName='OFS_API'];
            for (OFS_API_Settings__mdt setting : settings) { //should only be one record
                OFS_URL = setting.OFS_Create_OFS_URI__c;
            }
            
            //Build Http Request, and build API Response record as we go > to be inserted later for logging purposes
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(OFS_URL);
            apiResp.Endpoint__c = 'OFS Create OFS'; //
            request.setMethod('POST');
            apiResp.Method__c = 'POST'; //
            Blob headerValue = Blob.valueOf(token  + ':');
            String authHeader = EncodingUtil.base64Encode(headerValue);
            request.setHeader('Authorization', 'Bearer ' + token);
            apiResp.Token__c = token; //
            
            //Hard-coded request body for testing purposes when needed...
            //request.setBody('customer_id=211432&account_id=new&opportunity_name=A New Opportunity'+ 
            //                '&order_type=new&sales_rep_id=1547713524197&retention_rep_id=1547713524197'+ 
            //                '&partner_id=1095&created_by_id=1547713524197&description=test');  
            
            request.setBody('customer_id=' + customer_id + '&account_id=' + account_id + '&opportunity_name=' + opportunity_name + 
                            '&order_type=' + order_type + '&sales_rep_id=' + sales_rep_id + '&retention_rep_id=' + retention_rep_id + 
                            '&partner_id=' + partner_id + '&created_by_id=' + created_by_id + '&description=' + descr); 
                        
            apiResp.Http_Request__c = request.getBody(); //
            
            HttpResponse resp = new HttpResponse();

			if(!Test.isRunningTest()) { //If Live mode - call actual API endpoint
                resp = http.send(request);
                statusCode = resp.getStatusCode();
                apiResp.Http_Response__c = resp.getBody(); //
                apiResp.Status_Code__c = String.valueOf(statusCode); //
                //if(statusCode != 200) {  //Error
                    //TODO: Process the response differently depending on status code
                    //if(statusCode == 500) { return '... Status Code 500 - UNKNOWN ERROR'; }
                    //if(statusCode == 422) { return '... Status Code 422 - VALIDATION ERROR'; }
                //} else { //Success - StatusCode 200
                //}                  
            } else { //If Test mode - build mock API response
               apiResp.Http_Response__c = '{"success":"true","message":"The Order for Service has been created.","code":"API_OFS_CREATED","data":{"token":"OFS!","order_for_service_id":12345,"description":"Just a description"}}';
               statusCode = 200;
               apiResp.Status_Code__c = String.valueOf(statusCode);
            }
            
            //Parse Response, regardless whether Live mode or Test mode
            //And build OFS record to be inserted as a related object to Opportunity
            JSONParser parser = JSON.createParser(apiResp.Http_Response__c);
            while (parser.nextToken() != null) {
                if (parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                    parser.nextValue();
                    if(parser.getCurrentName() == 'success') { apiResp.Success__c = parser.getText(); }
                    if(parser.getCurrentName() == 'message') { apiResp.Message__c = parser.getText(); }
                    if(parser.getCurrentName() == 'code') { apiResp.Code__c = parser.getText(); }
                    //Only do this part if StatusCode 200
                    if(statusCode == 200) {
                        if(parser.getCurrentName() == 'order_for_service_id') {
                            newOFS.Order_For_Service_ID__c = parser.getText();  
                            apiResp.OFS_Id__c = parser.getText();
                            System.debug('OFS Id: ' + apiResp.OFS_Id__c);
                        }
                    }
                    if(statusCode == 200) {
                        if(parser.getCurrentName() == 'description') {
                            if(parser.getText() == 'null') {
                                newOFS.Order_Description__c = ' ';
                            } else {
                                newOFS.Order_Description__c = parser.getText();
                            } 
                            System.debug('Desc: ' + newOFS.Order_Description__c);
                        }
                    }
                }
            }
            //Finish building OFS record and insert
            newOFS.Opportunity__c = opp_id;
            System.debug('Oppty Id: ' + newOFS.Opportunity__c);
            insert newOFS;
            //Return API Response which contains Response Code either way and OFS Id only if successful
            return apiResp;                                           
        } catch (Exception e) {
            System.debug('An exception occurred in createOFS(): ' + e.getMessage() + ' ... Line Number: ' + e.getLineNumber());
			return null;
        }
    }  
}