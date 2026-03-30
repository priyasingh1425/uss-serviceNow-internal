/*************************************************
* Name: API_OPSramp_GetDevicesForTenant_QRY_Test
* Description: Test class for API_OPSramp_GetDevicesForTenant_QRY
* ***********************************************/
@isTest
public class API_OPSramp_GetDevicesForTenant_QRY_Test {
    
    @isTest
    static void testGetDevicesForTenantSuccess() {
        // Set up mock HTTP response for success
        Test.setMock(HttpCalloutMock.class, new HLP_OpsRamp_MockHttpResponse_TST());
        
        Test.startTest();
        List<API_OPSramp_GetDevicesForTenant_QRY.Device> devices = 
            API_OPSramp_GetDevicesForTenant_QRY.getDevicesForTenantFromOpsRamp('client-456');
        Test.stopTest();
        
        // Verify devices were returned
        System.assert(devices != null, 'Devices list should not be null');
        System.assert(devices.size() > 0, 'Devices list should contain at least one device');
        System.assertEquals('device-123', devices[0].uniqueId, 'Device unique ID should match mock response');
        System.assertEquals('TestHost1', devices[0].hostName, 'Device host name should match mock response');
    }
    
    @isTest
    static void testGetDevicesForTenantException() {
        // Set up mock HTTP response that throws exception
        Test.setMock(HttpCalloutMock.class, new HLP_MockHttpCalloutEx_Test());
        
        Test.startTest();
        List<API_OPSramp_GetDevicesForTenant_QRY.Device> devices = 
            API_OPSramp_GetDevicesForTenant_QRY.getDevicesForTenantFromOpsRamp('client-456');
        Test.stopTest();
        
        // Should return empty list on exception
        System.assert(devices != null, 'Devices list should not be null even on exception');
        System.assertEquals(0, devices.size(), 'Devices list should be empty on exception');
    }
    
    @isTest
    static void testGetDevicesForTenantHttpError() {
        // Set up mock HTTP response for HTTP error
        Test.setMock(HttpCalloutMock.class, new HLP_MockHttpFailureResponseGenerator_TST());
        
        Test.startTest();
        List<API_OPSramp_GetDevicesForTenant_QRY.Device> devices = 
            API_OPSramp_GetDevicesForTenant_QRY.getDevicesForTenantFromOpsRamp('client-456');
        Test.stopTest();
        
        // Should handle HTTP error gracefully
        System.assert(devices != null, 'Devices list should not be null on HTTP error');
    }
    
    @isTest
    static void testDeviceClassInstantiation() {
        // Test Device class can be instantiated and properties set
        API_OPSramp_GetDevicesForTenant_QRY.Device device = new API_OPSramp_GetDevicesForTenant_QRY.Device();
        device.uniqueId = 'test-unique-id';
        device.hostName = 'test-hostname';
        device.ipAddress = '192.168.1.1';
        device.aliasName = 'test-alias';
        device.resourceName = 'test-resource';
        device.resourceType = 'Server';
        
        System.assertEquals('test-unique-id', device.uniqueId, 'Unique ID should be set correctly');
        System.assertEquals('test-hostname', device.hostName, 'Host name should be set correctly');
        System.assertEquals('192.168.1.1', device.ipAddress, 'IP address should be set correctly');
        System.assertEquals('test-alias', device.aliasName, 'Alias name should be set correctly');
        System.assertEquals('test-resource', device.resourceName, 'Resource name should be set correctly');
        System.assertEquals('Server', device.resourceType, 'Resource type should be set correctly');
    }
}