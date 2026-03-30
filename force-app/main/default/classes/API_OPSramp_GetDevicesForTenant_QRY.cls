/*************************************************
* Name: API_OPSramp_GetDevicesForTenant_QRY
* Description: Synchronous Callout to OpsRamp to get all devices for a specific client.
* Related Classes: 
	- INV_API_OPSramp_GenMaintWin_INS
	- API_OPSramp_GenMaintWin_HLP
	- API_OPSramp_GenMaintWin_FUT
	- API_OPSramp_GenMaintWin_INS
	- HLP_Case_SFQueue_Ins
	- HLP_GenericCreate_UTL
* Test class: API_OPSramp_GetDevicesForTenant_QRY_Test
* ***********************************************/

public class API_OPSramp_GetDevicesForTenant_QRY {
  
/*************************************************
* Method Name: getDevicesForTenantFromOpsRamp
* Description: Method that performs a Synchronous Callout to the 3rd party app OpsRamp to get all devices for a specific client.
* ***********************************************/
    public static List<Device> getDevicesForTenantFromOpsRamp(String clientId){
        
        //this callout gets all devices for OpsRamp tenant by client/tenant Id
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        
        List<Device> allDevices = new List<Device>();        
        try{
            req.setEndpoint('callout:OpsRamp_Oauth' +'/api/v2/tenants/' + clientId +'/devices/minimal');
            req.setMethod('GET');
            
            res = http.send(req);
            
            system.debug(res.getBody());
            API_Response__c ar = new API_Response__c();
            ar.Method__c = 'GET'; 
            ar.Success__c = 'true';
            ar.Endpoint__c = 'https://oneneck.api.opsramp.com/api/v2/tenants/%7BTenantID%7D/devices/minimal'; 
            ar.Http_Request__c = req.getBody().left(32765);
            ar.Http_Response__c = res.getBody().left(32765); 
            ar.Status_Code__c = res.getStatusCode().toString(); 
            ar.Message__c = 'OpsRamp Query for All Devices Succeeded for Client: ' + clientId;
            ar.Wrapper__c = 'API_OPSramp_GetDevicesForTenant_QRY.Device';
            ar.Code__c = 'OpsRamp_QueryAllDevices_SUCCESS';
            //insert ar;
            
            allDevices = (List<Device>) JSON.deserialize(res.getBody(), List<Device>.class);
            System.debug('alldevices: ' + allDevices);
        } catch (Exception e){
            HLP_Case_SFQueue_Ins.createSFQueueCase('API_OPSramp_GenMaintWin process failed with errors.  !!! Callout Failed!!!', 'Callout to generate Maintenance Windows failed. Error: ' + e.getMessage(), 'Medium');
            
            API_Response__c ar = new API_Response__c();
            ar.Method__c = 'GET'; 
            ar.Success__c = 'false';
            ar.Endpoint__c = 'https://oneneck.api.opsramp.com/api/v2/tenants/%7BTenantID%7D/devices/minimal'; 
            ar.Http_Request__c = req.getBody().left(32765);
            ar.Http_Response__c = res.getBody().left(32765); 
            ar.Status_Code__c = res.getStatusCode().toString(); 
            ar.Message__c = 'OpsRamp Query for All Devices FAILED for Client: ' + clientId;
            ar.Wrapper__c = 'API_OPSramp_GetDevicesForTenant_QRY.Device';
            ar.Code__c = 'OpsRamp_QueryAllDevices_FAILED';
            //insert ar;
        }
        return allDevices;
    }
        
/*************************************************
* Name: Device
* Description: Apex class for holding device information retrieved from the OpsRamp Query callout for all devices.  Structure based on OpsRamp API resource documentation.
* Used by classes: 
	- API_OPSramp_GetDevicesForTenant_QRY
	- API_OPSramp_GenMaintWin_FUT
* ***********************************************/   
    public class Device{
        public String uniqueId;
        public String hostName;
        public String ipAddress;
        public String aliasName;
        public String resourceName;
        public String resourceType;
    }
    
    
}