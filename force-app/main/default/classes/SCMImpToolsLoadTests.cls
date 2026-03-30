@isTest
private class SCMImpToolsLoadTests {

	private static SCMImpToolsSetupTest st = new SCMImpToolsSetupTest();

	/* ===================================================================== */
	/* Inventory Loads */
	static Testmethod void testLoadInventoryAllFail() {
		
		SCMC__Reason_Code__c rc = st.createTestReason(true);
		SCMC__Ownership_Code__c oc = st.createTestOwnership('Apple', true);
		
        List<SCMImpToolsLoad_Inventory__c>testLoad = new List<SCMImpToolsLoad_Inventory__c>();
        SCMImpToolsLoad_Inventory__c ink = new SCMImpToolsLoad_Inventory__c();
        ink.Warehouse__c = 'San Jose Warehouse';
        ink.UOM__c = 'Each';
        ink.Unit_Cost__c = 55.23;
        ink.Quantity__c = 100;
        ink.Ownership__c = 'Apple';
        ink.Location__c = 'Receiving';
        ink.Item_Number__c = '043-990145-01.P';
        testLoad.add(ink);
        SCMImpToolsLoad_Inventory__c ink2 = new SCMImpToolsLoad_Inventory__c();
        ink2.Warehouse__c = 'Main1';
        ink2.UOM__c = 'xxx';
        ink2.Condition__c = 'xxx';
        ink2.Reason__c = 'xxx';
        ink2.Unit_Cost__c = 55.23;
        ink2.Quantity__c = 100;
        ink2.Location__c = 'xxx';
        ink2.Item_Number__c = 'xxx';
        testLoad.add(ink2);
        SCMImpToolsLoad_Inventory__c ink3 = new SCMImpToolsLoad_Inventory__c();
        ink3.Warehouse__c = 'San Jose Warehouse';
        ink3.UOM__c = 'Each';
        ink3.Unit_Cost__c = 55.23;
        ink3.Quantity__c = -50;
        ink3.Lot_Number__c = 'Lot';
        ink3.Ownership__c = 'Apple';
        ink3.Location__c = 'Receiving';
        ink3.Item_Number__c = '043-990145-01.P';
        testLoad.add(ink3);
        insert testLoad;
        
        Test.startTest();
        ApexPages.StandardSetController setController =
            new ApexPages.StandardSetController(testLoad);
        SCMImpToolsLoadInventoryExtension extension = new SCMImpToolsLoadInventoryExtension(setController);
        
        System.assertNotEquals(null, extension.goback(), 'unexpected goBack return');
        
        extension.process();
        Test.stopTest();
        
        List<SCMImpToolsLoad_Inventory__c> testInv = [Select id
                , name
                , Warehouse__c
                , WarehouseRef__c
                , Unit_of_Measure__c
                , Unit_cost__c
                , Stocking_UOM__c
                , Quantity__c
                , Ownership__c
                , Ownership_Code__c
                , Condition__c
                , Condition_Code__c
                , Location__c
                , Loaded__c
                , Lot_Number__c
                , Item_Number__c
                , Item_Master__c
                , Inventory_Location__c
                , Error__c
                , Error_Message__c
             From SCMImpToolsLoad_Inventory__c];
        System.assert(testInv.Size() > 0);
        
        SCMC__Inventory_Position__c[] ips = [select Id from SCMC__Inventory_Position__c];
        system.assertEquals(0, ips.size(), 'unexpected number of IPs created');
    }
    
    static Testmethod void testLoadInventoryAllFail2() {
		
		SCMC__Reason_Code__c rc = st.createTestReason(true);
		SCMC__Ownership_Code__c oc = st.createTestOwnership('Apple', true);
		SCMC__Item__c i1 = st.createTestItem(false);
		i1.SCMC__Serial_Number_Control__c = true;
		insert i1;
		SCMC__Item__c i2 = st.createTestItem(false);
		i2.SCMC__Serial_Number_Control__c = true;
		insert i2;
		SCMC__Item__c i3 = st.createTestItem(false);
		i3.SCMC__Lot_Number_Control__c = true;
		insert i3;
		
		SCMC__Warehouse__c wh1 = st.setupWarehouse();
		SCMC__Unit_of_Measure__c uom = st.createUnitofMeasure('EA');
		SCMC__Inventory_Location__c loc1 = st.createTestLocation(wh1);
		SCMC__Condition_Code__c condCode = st.createConditionCode('Condition');
		
        List<SCMImpToolsLoad_Inventory__c>testLoad = new List<SCMImpToolsLoad_Inventory__c>();
        SCMImpToolsLoad_Inventory__c ink = new SCMImpToolsLoad_Inventory__c();
        ink.Warehouse__c = wh1.name;
        ink.UOM__c = uom.name;
        ink.Unit_Cost__c = 55.23;
        ink.Quantity__c = 100;
        ink.Ownership__c = oc.Name;
        ink.Location__c = loc1.name;
        ink.Item_Number__c = i1.name;
        testLoad.add(ink);
        SCMImpToolsLoad_Inventory__c ink2 = new SCMImpToolsLoad_Inventory__c();
        ink2.Warehouse__c = wh1.name;
        ink2.UOM__c = uom.name;
        ink2.Condition__c = condCode.name;
        ink2.Reason__c = rc.name;
        ink2.Unit_Cost__c = 55.23;
        ink2.Quantity__c = 2;
        ink2.Location__c = loc1.name;
        ink2.Item_Number__c = i2.name;
        ink2.Serial_Number__c = 'SN1234';
        testLoad.add(ink2);
        SCMImpToolsLoad_Inventory__c ink3 = new SCMImpToolsLoad_Inventory__c();
        ink3.Warehouse__c = wh1.name;
        ink3.UOM__c = uom.name;
        ink3.Unit_Cost__c = 55.23;
        ink3.Quantity__c = 50;
        ink3.Lot_Number__c = null;
        ink3.Ownership__c = oc.name;
        ink3.Location__c = loc1.name;
        ink3.Item_Number__c = i3.name;
        testLoad.add(ink3);
        insert testLoad;
        
        Test.startTest();
        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(testLoad);
        SCMImpToolsLoadInventoryExtension extension = new SCMImpToolsLoadInventoryExtension(setController);
        extension.process();
        Test.stopTest();
        
        List<SCMImpToolsLoad_Inventory__c> testInv = [Select id
                , name
                , Warehouse__c
                , WarehouseRef__c
                , Unit_of_Measure__c
                , Unit_cost__c
                , Stocking_UOM__c
                , Quantity__c
                , Ownership__c
                , Ownership_Code__c
                , Condition__c
                , Condition_Code__c
                , Location__c
                , Loaded__c
                , Lot_Number__c
                , Item_Number__c
                , Item_Master__c
                , Inventory_Location__c
                , Error__c
                , Error_Message__c
             From SCMImpToolsLoad_Inventory__c];
        System.assert(testInv.Size() > 0);
        
        SCMC__Inventory_Position__c[] ips = [select Id from SCMC__Inventory_Position__c];
        system.assertEquals(0, ips.size(), 'unexpected number of IPs created');
    }
    
    static Testmethod void testLoadInventorySuccess() {
		
		SCMC__Reason_Code__c rc = st.createTestReason(true);
		SCMC__Ownership_Code__c oc = st.createTestOwnership('Apple', true);
		SCMC__Item__c i1 = st.createTestItem(true);
		SCMC__Item__c i2 = st.createTestItem(false);
		i2.SCMC__Serial_Number_Control__c = true;
		insert i2;
		SCMC__Item__c i3 = st.createTestItem(false);
		i3.SCMC__Lot_Number_Control__c = true;
		insert i3;
		
		SCMC__Warehouse__c wh1 = st.setupWarehouse();
		SCMC__Unit_of_Measure__c uom = st.createUnitofMeasure('EA');
		SCMC__Inventory_Location__c loc1 = st.createTestLocation(wh1);
		SCMC__Condition_Code__c condCode = st.createConditionCode('Condition');
		
        List<SCMImpToolsLoad_Inventory__c>testLoad = new List<SCMImpToolsLoad_Inventory__c>();
        SCMImpToolsLoad_Inventory__c ink = new SCMImpToolsLoad_Inventory__c();
        ink.Warehouse__c = wh1.name;
        ink.UOM__c = uom.name;
        ink.Unit_Cost__c = 55.23;
        ink.Quantity__c = 100;
        ink.Ownership__c = oc.Name;
        ink.Location__c = loc1.name;
        ink.Item_Number__c = i1.name;
        testLoad.add(ink);
        SCMImpToolsLoad_Inventory__c ink2 = new SCMImpToolsLoad_Inventory__c();
        ink2.Warehouse__c = wh1.name;
        ink2.UOM__c = uom.name;
        ink2.Condition__c = condCode.name;
        ink2.Reason__c = rc.name;
        ink2.Unit_Cost__c = 55.23;
        ink2.Quantity__c = 1;
        ink2.Location__c = loc1.name;
        ink2.Item_Number__c = i2.name;
        ink2.Serial_Number__c = 'SN1234';
        testLoad.add(ink2);
        SCMImpToolsLoad_Inventory__c ink3 = new SCMImpToolsLoad_Inventory__c();
        ink3.Warehouse__c = wh1.name;
        ink3.UOM__c = uom.name;
        ink3.Unit_Cost__c = 55.23;
        ink3.Quantity__c = 50;
        ink3.Lot_Number__c = 'Lot';
        ink3.Ownership__c = oc.name;
        ink3.Location__c = loc1.name;
        ink3.Item_Number__c = i3.name;
        testLoad.add(ink3);
        insert testLoad;
        
        Test.startTest();
        ApexPages.StandardSetController setController = new ApexPages.StandardSetController(testLoad);
        SCMImpToolsLoadInventoryExtension extension = new SCMImpToolsLoadInventoryExtension(setController);
        extension.process();
        Test.stopTest();
        
        List<SCMImpToolsLoad_Inventory__c> testInv = [Select id
                , name
                , Warehouse__c
                , WarehouseRef__c
                , Unit_of_Measure__c
                , Unit_cost__c
                , Stocking_UOM__c
                , Quantity__c
                , Ownership__c
                , Ownership_Code__c
                , Condition__c
                , Condition_Code__c
                , Location__c
                , Loaded__c
                , Lot_Number__c
                , Item_Number__c
                , Item_Master__c
                , Inventory_Location__c
                , Error__c
                , Error_Message__c
             From SCMImpToolsLoad_Inventory__c];
        System.assert(testInv.Size() > 0);

        SCMC__Error_Log__c[] errorLogs = [select Id, SCMC__Message__c, SCMC__Trace__c from SCMC__Error_Log__c];

        for(SCMImpToolsLoad_Inventory__c test_line : testInv){
            system.assert(String.isEmpty(test_line.Error_Message__c), 'err: ' + test_line.Error_Message__c + '::' + errorLogs);
        }
        
        SCMC__Inventory_Position__c[] ips = [select Id from SCMC__Inventory_Position__c];
        system.assertEquals(3, ips.size(), 'unexpected number of IPs created');
    }
    
    static Testmethod void testLoadInventory2() {
    	List<SCMImpToolsLoad_Inventory__c>testLoad = new List<SCMImpToolsLoad_Inventory__c>();
    	SCMImpToolsLoad_Inventory__c ink = new SCMImpToolsLoad_Inventory__c();
    	ink.Warehouse__c = 'SCMTest Warehouse';
    	ink.UOM__c = 'SCMTestuom';
    	ink.Unit_Cost__c = 55.23;
    	ink.Quantity__c = 100;
    	ink.Location__c = 'SCMTestLocation';
    	ink.Item_Number__c = 'SCMTestItem';
    	testLoad.add(ink);
     	SCMImpToolsLoad_Inventory__c ink2 = new SCMImpToolsLoad_Inventory__c();
    	ink2.Warehouse__c = 'SCMTest Warehouse';
    	ink2.UOM__c = 'xxx';
    	ink2.Condition__c = 'xxx';
    	ink2.Reason__c = 'xxx';
    	ink2.Unit_Cost__c = 55.23;
    	ink2.Quantity__c = 100;
    	//ink.Ownership__c = 'Apple';
    	ink2.Location__c = 'SCMTestLocation';
    	ink2.Item_Number__c = 'xxx';
    	testLoad.add(ink2);
    	SCMImpToolsLoad_Inventory__c ink3 = new SCMImpToolsLoad_Inventory__c();
    	ink3.Warehouse__c = 'SCMTest Warehouse';
    	ink3.UOM__c = 'SCMTestuom';
    	ink3.Unit_Cost__c = 55.23;
    	ink3.Quantity__c = -50;
    	//ink3.Lot_Number__c = 'Lot';
    	//ink3.Ownership__c = 'Apple';
    	ink3.Location__c = 'SCMTestLocation';
    	ink3.Item_Number__c = 'SCMTestItem';
    	testLoad.add(ink3);
    	insert testLoad;
    	//Create warehouse, location, Reason, UOM and item.
    	//create address, ICP and warehouse
    	SCMC__Address__c address = new SCMC__Address__c();
        address.name = 'Test Address';
        address.SCMC__City__c = 'A City';
        address.SCMC__Country__c = 'Country';
        address.SCMC__Line1__c = 'Address line 1';
        address.SCMC__PostalCode__c = 'Postcd';
        address.SCMC__State__c = 'State';
        insert address;
       	SCMC__ICP__c icp = new SCMC__ICP__c();
        icp.SCMC__Address__c = address.Id;
        icp.name = 'SCMTest ICP';
        icp.SCMC__Currency__c = [SELECT Id FROM SCMC__Currency_Master__c
        	Where SCMC__Corporate_Currency__c = true].Id;
        insert icp;
		SCMC__Warehouse__c warehouse = new SCMC__Warehouse__c();
        warehouse.SCMC__ICP__c = icp.id;
        warehouse.SCMC__Address__c = address.id;
        warehouse.name = 'SCMTest Warehouse';
        insert warehouse;
        SCMC__Inventory_Location__c location = new SCMC__Inventory_Location__c();
        location.name = 'SCMTestLocation';
        location.SCMC__Level1__c = 'SCMTestLocation';
        location.SCMC__Warehouse__c = warehouse.id;
        insert location;
        SCMC__Unit_of_Measure__c uom = new SCMC__Unit_of_Measure__c();
        uom.name = 'SCMTestuom';
        insert uom;
        SCMC__Item__c im = new SCMC__Item__c();
        im.name = 'SCMTestItem';
        im.SCMC__Item_Description__c = 'Test part for unit tests';
        im.SCMC__Inspection_Required__c  = false;
        im.SCMC__Serial_Number_Control__c = false;
        im.SCMC__Lot_Number_Control__c = false;
        im.SCMC__Stocking_UOM__c = uom.id;
        insert im;
    	
    	Test.startTest();
    	ApexPages.StandardSetController setController =
    		new ApexPages.StandardSetController(testLoad);
    	SCMImpToolsLoadInventoryExtension extension = new SCMImpToolsLoadInventoryExtension(setController);
    	extension.process();
    	Test.stopTest();
    	
    	List<SCMImpToolsLoad_Inventory__c> testInv = [Select id
    			, name
    			, Warehouse__c
    			, WarehouseRef__c
    			, Unit_of_Measure__c
    			, Unit_cost__c
    			, Stocking_UOM__c
    			, Quantity__c
    			, Ownership__c
    			, Ownership_Code__c
    			, Condition__c
    			, Condition_Code__c
    			, Location__c
    			, Loaded__c
    			, Lot_Number__c
    			, Item_Number__c
    			, Item_Master__c
				, Inventory_Location__c
				, Error__c
				, Error_Message__c
			 From SCMImpToolsLoad_Inventory__c];
		System.assert(testInv.Size() > 0);
    }

	/* ===================================================================== */
	/* PO Loads */
	static Testmethod void testLoadPOFail() {
    	SCMC__PO_Payment_Terms__c pt1 = st.createPOPaymentTerms('Net 30');

    	List<SCMImpToolsPO_Stage__c>testLoad = new List<SCMImpToolsPO_Stage__c>();
    	SCMImpToolsPO_Stage__c ink = new SCMImpToolsPO_Stage__c();
    	ink.Unit_Cost__C = 5.50;
    	ink.Supplier__c = 'Vend111 Synnex';
    	ink.Supplier_Commitment_Date__c = System.today();
    	ink.Ship_to_Warehouse__c = 'San Jose Warehouse';
    	ink.Quantity__c = 10;
    	ink.Procured_For__c = 'Apple Inc. Retail';
    	ink.PO_Date__c = System.today();
    	ink.Ownership__c = 'Apple';
    	ink.Item__c = '043-990145-01.P';
    	ink.Existing_SO_Number__c = 'SOxxx';
    	ink.Existing_PO_Number__c = 'POyyy';
    	testLoad.add(ink);
    	insert testLoad;
    	
    	Test.startTest();
    	Database.executeBatch(new SCMImpToolsLoadPO());
    	Test.stopTest();
    	
    	SCMC__Purchase_Order__c[] pos = [select Id from SCMC__Purchase_Order__c];
    	system.assertEquals(0, pos.size(), 'unexpected number of POs created');
	}
	
	static Testmethod void testLoadPOSuccess() {
    	//SCMC__PO_Payment_Terms__c pt1 = st.createPOPaymentTerms('Net 30');
    	
    	SCMC__Reason_Code__c rc = st.createTestReason(true);
		SCMC__Ownership_Code__c oc = st.createTestOwnership('Apple', true);
		SCMC__Item__c i1 = st.createTestItem(true);
		SCMC__Item__c i2 = st.createTestItem(false);
		i2.SCMC__Serial_Number_Control__c = true;
		insert i2;
		SCMC__Item__c i3 = st.createTestItem(false);
		i3.SCMC__Lot_Number_Control__c = true;
		insert i3;
		
		SCMC__Warehouse__c wh1 = st.setupWarehouse();
		SCMC__Unit_of_Measure__c uom = st.createUnitofMeasure('EA');
		SCMC__Inventory_Location__c loc1 = st.createTestLocation(wh1);
		SCMC__Condition_Code__c condCode = st.createConditionCode('Condition'); 
		Account acct = st.createTestCustomerAccount(true, true, false, null);  	
    	SCMC__Supplier_Site__c ss = st.createTestSupplier();
    	
    	List<SCMImpToolsPO_Stage__c>testLoad = new List<SCMImpToolsPO_Stage__c>();
    	SCMImpToolsPO_Stage__c ink = new SCMImpToolsPO_Stage__c();
    	ink.Unit_Cost__C = 5.50;
    	ink.Supplier__c = ss.name;
    	ink.Supplier_Commitment_Date__c = System.today();
    	ink.Ship_to_Warehouse__c = wh1.name;
    	ink.Quantity__c = 10;
    	ink.Procured_For__c = acct.name;
    	ink.PO_Date__c = System.today();
    	ink.Ownership__c = oc.name;
    	ink.Item__c = i1.name;
    	ink.Existing_SO_Number__c = 'SOxxx';
    	ink.Existing_PO_Number__c = 'POyyy';
    	testLoad.add(ink);
    	insert testLoad;
    	
    	Test.startTest();
    	Database.executeBatch(new SCMImpToolsLoadPO());
    	Test.stopTest();
    	
    	SCMC__Purchase_Order__c[] pos = [select Id from SCMC__Purchase_Order__c];
    	system.assertEquals(1, pos.size(), 'unexpected number of POs created');
	}

	/* ===================================================================== */
	/* SO Loads */
	static Testmethod void testLoadSO() {
   		
   		Account testAcct = st.createTestCustomerAccount(true, true, false, null);
   		SCMC__Item__c testItem = st.createTestItem(true);
        SCMC__Warehouse__c warehouse = st.setupWarehouse();

        List<SCMImpToolsSO_Stage__c>testLoad = new List<SCMImpToolsSO_Stage__c>();
    	SCMImpToolsSO_Stage__c ink = new SCMImpToolsSO_Stage__c();
        ink.Currency__c = 'USD';
    	ink.Price__C = 5.50;
    	ink.Customer_Account__c= testAcct.Id;
    	ink.Quantity__c = 10;
        ink.Item_Master__c = testItem.name;
    	ink.Existing_SO_Number__c = 'SOxxx';
    	ink.Customer_Purchase_Order__c = '55555';
        ink.Warehouse__c = warehouse.Name;
		ink.Sales_Order_Date__c = System.today();
		ink.Quantity_Shipped__c = 0;
    	testLoad.add(ink);
    	SCMImpToolsSO_Stage__c ink2 = new SCMImpToolsSO_Stage__c();
        ink2.Currency__c = 'USD';
    	ink2.Price__C = 5.50;
    	ink2.Customer_Account__c= testAcct.Id;
    	ink2.Quantity__c = 10;
    	ink2.Item_Master__c = testItem.name;
    	ink2.Existing_SO_Number__c = 'SOyyy';
    	ink2.Customer_Purchase_Order__c = '55555';
		ink2.Quantity_Shipped__c = 0;
    	testLoad.add(ink2);
    	insert testLoad;
    	
    	Test.startTest();
    	Database.executeBatch(new SCMImpToolsLoadSO());
    	Test.stopTest();
    	
    	SCMC__Sales_Order__c[] sos = [select id, (select id from SCMC__Line_Items__r) from SCMC__Sales_Order__c
    			where SCMC__Customer_Purchase_Order__c = '55555'];
    	system.assertEquals(2, sos.size(), 'unexpected number of SOs created');
        System.assertEquals(1, sos[0].SCMC__Line_Items__r.Size(), 'Wrong number of sales order lines');
     }
     
     /* ===================================================================== */

}