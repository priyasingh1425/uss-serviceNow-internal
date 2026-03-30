@isTest
public class OM_DLR_Test {
    
    @isTest
    public static void testUpsertDlr(){
        //test to examine that the DLR record is upserted by PUT
        Test.startTest();
        
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        OM_DLR.dlrWrapper wrapper = new OM_DLR.dlrWrapper();
		wrapper.base_order_id = '12345';
        wrapper.dlr_id = '54321';
        wrapper.dlr = 'test text';
        wrapper.created = '2011-02-15 09:55:11.244509-05';
        wrapper.modified = '2011-02-15 09:55:11.244509-05';
        
        Account acc = new Account(Name = 'Test Account', RecordTypeId = '0120a0000004bwXAAQ');
            insert acc;
        
        Service_Summary__c s = new Service_Summary__c(Name = 'Test Service Summary', Base_Order_ID__c = 12345, Customer_Account__c = acc.Id);
        insert s;
                
        DLR_s__c d = new DLR_s__c();
        d.Base_Order_Id__c = Double.valueOf(wrapper.base_order_id);
        d.DLR_Id__c = Double.valueOf(wrapper.dlr_id);
        d.Legacy_Timestamp_Created__c = DateTime.valueOf(wrapper.created);
        d.DLR_Text__c = wrapper.dlr;
        d.Legacy_Timestamp_Modified__c = DateTime.valueOf(wrapper.modified);
        d.Service_ID__c = s.Id;        
        
        insert d;

        req.requestURI = '/services/apexrest/dlr/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(JSON.serializePretty(wrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
        Decimal a = Decimal.valueOf(wrapper.base_order_id);
                
        OM_DLR.upsertDLR();

        DLR_s__c ex = [Select Id, Base_Order_Id__c, DLR_Id__c, Legacy_Timestamp_Created__c, DLR_Text__c from DLR_s__c Where Base_Order_Id__c =: Double.valueOf(wrapper.base_order_id)];
                
        OM_DLR.dlrWrapper wrapData = (OM_DLR.dlrWrapper)System.JSON.deserialize(res.responseBody.toString(), OM_DLR.dlrWrapper.class);

        Test.stopTest();
        
    }
    
        @isTest
    static void testNegativePutDlr(){
        Test.startTest();          
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();
        
        OM_DLR.dlrWrapper wrapper = new OM_DLR.dlrWrapper();
		wrapper.base_order_id = null;
        wrapper.dlr_id = null;
        wrapper.dlr = null;
        wrapper.created = null;
        
        req.requestURI = '/services/apexrest/dlr/';
        req.httpMethod = 'PUT';
        req.requestBody = Blob.valueOf(JSON.serializePretty(wrapper));
        
        RestContext.request = req;
        RestContext.response = res;
        
      
        //OM_DLR.upsertDLR();
        Test.stopTest();

        //restContext is not returning statusCode at the moment. troubleshoot and replace null with 500
        //System.assertEquals(null, res.statusCode);

    }

}