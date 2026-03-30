/*************************************************
* Name: API_OPSramp_WrapperClasses_Test
* Description: Test class for wrapper classes in API_OPSramp_GenMaintWin_QUE_CallOut
* ***********************************************/
@isTest
public class API_OPSramp_WrapperClasses_Test {
    
    @isTest
    static void testSendEventWrapperClass() {
        // Test SendEventWrapper class instantiation and property setting
        API_OPSramp_GenMaintWin_QUE_CallOut.SendEventWrapper wrapper = new API_OPSramp_GenMaintWin_QUE_CallOut.SendEventWrapper();
        
        wrapper.name = 'Test Maintenance Window';
        wrapper.description = 'Test Description';
        
        // Create test devices
        List<API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice> devices = new List<API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice>();
        API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice device = new API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice();
        device.uniqueId = 'device-123';
        devices.add(device);
        wrapper.devices = devices;
        
        // Create test schedule
        API_OPSramp_GenMaintWin_QUE_CallOut.SendSchedule schedule = new API_OPSramp_GenMaintWin_QUE_CallOut.SendSchedule();
        schedule.type = 'One-Time';
        schedule.startTime = '2024-01-01T10:00:00';
        schedule.endTime = '2024-01-01T12:00:00';
        schedule.timezone = 'GMT';
        wrapper.schedule = schedule;
        
        System.assertEquals('Test Maintenance Window', wrapper.name, 'Name should be set correctly');
        System.assertEquals('Test Description', wrapper.description, 'Description should be set correctly');
        System.assertEquals(1, wrapper.devices.size(), 'Should have one device');
        System.assertEquals('device-123', wrapper.devices[0].uniqueId, 'Device unique ID should match');
        System.assertEquals('One-Time', wrapper.schedule.type, 'Schedule type should be set correctly');
    }
    
    @isTest
    static void testSendDeviceClass() {
        // Test SendDevice class instantiation and property setting
        API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice device = new API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice();
        device.uniqueId = 'unique-device-id-123';
        
        System.assertEquals('unique-device-id-123', device.uniqueId, 'Unique ID should be set correctly');
    }
    
    @isTest
    static void testSendScheduleClass() {
        // Test SendSchedule class instantiation and property setting
        API_OPSramp_GenMaintWin_QUE_CallOut.SendSchedule schedule = new API_OPSramp_GenMaintWin_QUE_CallOut.SendSchedule();
        
        schedule.type = 'Recurring';
        schedule.startTime = '2024-01-01T09:00:00';
        schedule.endTime = '2024-01-01T17:00:00';
        schedule.timezone = 'America/New_York';
        
        System.assertEquals('Recurring', schedule.type, 'Type should be set correctly');
        System.assertEquals('2024-01-01T09:00:00', schedule.startTime, 'Start time should be set correctly');
        System.assertEquals('2024-01-01T17:00:00', schedule.endTime, 'End time should be set correctly');
        System.assertEquals('America/New_York', schedule.timezone, 'Timezone should be set correctly');
    }
    
    @isTest
    static void testDeviceGroupClass() {
        // Test DeviceGroup class instantiation and property setting
        API_OPSramp_GenMaintWin_QUE_CallOut.DeviceGroup deviceGroup = new API_OPSramp_GenMaintWin_QUE_CallOut.DeviceGroup();
        
        deviceGroup.name = 'Test Device Group';
        deviceGroup.id = 'group-123';
        
        System.assertEquals('Test Device Group', deviceGroup.name, 'Name should be set correctly');
        System.assertEquals('group-123', deviceGroup.id, 'ID should be set correctly');
    }
    
    @isTest
    static void testDeviceLocationsClass() {
        // Test DeviceLocations class instantiation and property setting
        API_OPSramp_GenMaintWin_QUE_CallOut.DeviceLocations location = new API_OPSramp_GenMaintWin_QUE_CallOut.DeviceLocations();
        
        location.name = 'Test Location';
        location.id = 'location-123';
        
        System.assertEquals('Test Location', location.name, 'Name should be set correctly');
        System.assertEquals('location-123', location.id, 'ID should be set correctly');
    }
    
    @isTest
    static void testPatternClass() {
        // Test Pattern class instantiation and property setting
        API_OPSramp_GenMaintWin_QUE_CallOut.Pattern pattern = new API_OPSramp_GenMaintWin_QUE_CallOut.Pattern();
        
        pattern.type = 'Weekly';
        pattern.weekDays = 'Monday,Tuesday,Wednesday,Thursday,Friday';
        
        System.assertEquals('Weekly', pattern.type, 'Type should be set correctly');
        System.assertEquals('Monday,Tuesday,Wednesday,Thursday,Friday', pattern.weekDays, 'Week days should be set correctly');
    }
    
    @isTest
    static void testMaintenanceWindowHolderClass() {
        // Test MaintenanceWindowHolder class instantiation and property setting
        API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder holder = new API_OPSramp_GenMaintWin_QUE.MaintenanceWindowHolder();
        
        holder.clientId = 'client-789';
        holder.startDate = '2024-01-01T08:00:00';
        holder.endDate = '2024-01-01T18:00:00';
        holder.caseNumber = 'CR-999';
        holder.maintWindowIndex = 5;
        
        // Create test devices
        List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice> devices = new List<API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice>();
        API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice device = new API_OPSramp_GenMaintWin_QUE_CallOut.sendDevice();
        device.uniqueId = 'device-456';
        devices.add(device);
        holder.sendDevices = devices;
        
        System.assertEquals('client-789', holder.clientId, 'Client ID should be set correctly');
        System.assertEquals('2024-01-01T08:00:00', holder.startDate, 'Start date should be set correctly');
        System.assertEquals('2024-01-01T18:00:00', holder.endDate, 'End date should be set correctly');
        System.assertEquals('CR-999', holder.caseNumber, 'Case number should be set correctly');
        System.assertEquals(5, holder.maintWindowIndex, 'Maintenance window index should be set correctly');
        System.assertEquals(1, holder.sendDevices.size(), 'Should have one device');
        System.assertEquals('device-456', holder.sendDevices[0].uniqueId, 'Device unique ID should match');
    }
    
    @isTest
    static void testCompleteWrapperSerialization() {
        // Test that wrapper classes can be serialized to JSON
        API_OPSramp_GenMaintWin_QUE_CallOut.SendEventWrapper wrapper = new API_OPSramp_GenMaintWin_QUE_CallOut.SendEventWrapper();
        wrapper.name = 'Serialization Test';
        wrapper.description = 'Testing JSON serialization';
        
        // Create devices
        List<API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice> devices = new List<API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice>();
        API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice device = new API_OPSramp_GenMaintWin_QUE_CallOut.SendDevice();
        device.uniqueId = 'serialization-device-123';
        devices.add(device);
        wrapper.devices = devices;
        
        // Create schedule
        API_OPSramp_GenMaintWin_QUE_CallOut.SendSchedule schedule = new API_OPSramp_GenMaintWin_QUE_CallOut.SendSchedule();
        schedule.type = 'One-Time';
        schedule.startTime = '2024-01-01T10:00:00';
        schedule.endTime = '2024-01-01T12:00:00';
        schedule.timezone = 'GMT';
        wrapper.schedule = schedule;
        
        Test.startTest();
        String jsonString = JSON.serialize(wrapper);
        Test.stopTest();
        
        System.assert(jsonString.contains('Serialization Test'), 'JSON should contain the wrapper name');
        System.assert(jsonString.contains('serialization-device-123'), 'JSON should contain the device unique ID');
        System.assert(jsonString.contains('One-Time'), 'JSON should contain the schedule type');
        System.assertNotEquals(null, jsonString, 'JSON string should not be null');
        System.assert(jsonString.length() > 0, 'JSON string should not be empty');
    }
}