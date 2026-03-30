@isTest
private class SCMImpToolsLoadSNTests {

    SCMC__Currency_Master__c currCode = createCurrency();


    static testMethod void loadSNControlItemTest() {
    	
		SCMC__Item__c item = createItem(true, false);
    	SCMC__Inventory_Position__c newIP = new SCMC__Inventory_Position__c();
    	newIP.SCMC__Item_Master__c = item.Id;
    	newIP.SCMC__Quantity__c = 1;
    	newIP.SCMC__Availability_Code__c = 'In Stock';
    	newIP.SCMC__Item_Serial_Number__c = 'ABC00100';
        newIP.SCMC__Acquisition_Currency__c = createCurrency().id;
    	upsert newIP;
    	
    	list<SCMC__Inventory_Position__c> theList = [select Id from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(0, theList.size(), 'Inventory Position Did Not Get Saved');

		list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(loadList);
		SCMImpToolsLoadSerialNumbers controller = new SCMImpToolsLoadSerialNumbers(stdSetController);
    	
    	test.startTest();
			controller.loadSNControlNumbers();
    	test.stopTest();

    	list<SCMC__Serial_Number__c> snList = [select Id from SCMC__Serial_Number__c where SCMC__Item__c = :item.Id];
    	system.assertNotEquals(0, snList.size(), 'Serial number did not get saved');

    	list<SCMC__Inventory_Position__c> updatedList = [select Id, SCMC__Serial_Number_Lookup__c from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(null, updatedList[0].SCMC__Serial_Number_Lookup__c, 'Serial number lookup did not get set on ip.');
    }

    static testMethod void cleanLoadIOSNControlItemTest() {
    	
		SCMC__Item__c item = createItem(false, true);
    	SCMC__Inventory_Position__c newIP = new SCMC__Inventory_Position__c();
    	newIP.SCMC__Item_Master__c = item.Id;
    	newIP.SCMC__Quantity__c = 5;
    	newIP.SCMC__Availability_Code__c = 'In Stock';
        newIP.SCMC__Acquisition_Currency__c = createCurrency().id;
    	upsert newIP;
    	
    	list<SCMC__Inventory_Position__c> theList = [select Id from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(0, theList.size(), 'Inventory Position Did Not Get Saved');

		list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
		SCMImpToolsLoad_Serial_Numbers__c newLSN = new SCMImpToolsLoad_Serial_Numbers__c();
		newLSN.Item__c = item.Name;
		newLSN.Serial_Number_List__c = 'SN00100;SN00200;SN00300;SN00400;SN00500;';
		newLSN.Serial_Number_Loaded__c = false;
		newLSN.Quantity__c = 5;
		upsert newLSN;
		
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(loadList);
		SCMImpToolsLoadSerialNumbers controller = new SCMImpToolsLoadSerialNumbers(stdSetController);
    	
    	test.startTest();
			controller.loadIOSerialNumbers();
    	test.stopTest();

    	list<SCMC__Serial_Number__c> snList = [select Id from SCMC__Serial_Number__c where SCMC__Item__c = :item.Id];
    	system.assertEquals(5, snList.size(), 'Serial numbers did not get added.');

    	list<SCMImpToolsLoad_Serial_Numbers__c> updatedList = [select Id, Serial_Number_Loaded__c from SCMImpToolsLoad_Serial_Numbers__c where Serial_Number_Loaded__c = true];
    	system.assertEquals(1, updatedList.size(), 'Load Serial Number did not get updated.');
    }

    static testMethod void cleanDataTest() {
    	
		SCMC__Item__c item = createItem(false, true);
    	SCMC__Inventory_Position__c newIP = new SCMC__Inventory_Position__c();
    	newIP.SCMC__Item_Master__c = item.Id;
    	newIP.SCMC__Quantity__c = 5;
    	newIP.SCMC__Availability_Code__c = 'In Stock';
        newIP.SCMC__Acquisition_Currency__c = createCurrency().id;
    	upsert newIP;
    	
    	list<SCMC__Inventory_Position__c> theList = [select Id from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(0, theList.size(), 'Inventory Position Did Not Get Saved');

		list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
		SCMImpToolsLoad_Serial_Numbers__c newLSN = new SCMImpToolsLoad_Serial_Numbers__c();
		newLSN.Item__c = item.Name;
		newLSN.Serial_Number_List__c = 'SN00100;SN00200;SN00300;SN00400;SN00500;';
		newLSN.Serial_Number_Loaded__c = true;
		newLSN.Quantity__c = 5;
		loadList.add(newLSN);

		SCMImpToolsLoad_Serial_Numbers__c newLSN1 = new SCMImpToolsLoad_Serial_Numbers__c();
		newLSN1.Item__c = item.Name;
		newLSN1.Serial_Number_List__c = 'SN00100;SN00200;SN00300;SN00400;SN00500;';
		newLSN1.Serial_Number_Loaded__c = true;
		newLSN1.Quantity__c = 5;
		loadList.add(newLSN1);
		upsert loadList;
		
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(loadList);
		SCMImpToolsLoadSerialNumbers controller = new SCMImpToolsLoadSerialNumbers(stdSetController);
    	
    	test.startTest();
			controller.clearLoadObject();
    	test.stopTest();

    	list<SCMImpToolsLoad_Serial_Numbers__c> updatedList = [select Id, Serial_Number_Loaded__c from SCMImpToolsLoad_Serial_Numbers__c];
    	system.assertEquals(0, updatedList.size(), 'Load Serial Number did not clear out.');
    	
    	system.assertNotEquals(null, controller.goBackList(), 'Back button is broken');
    }

    static testMethod void errorLoadIOSNControlItemNoItemTest() {
    	
		SCMC__Item__c item = createItem(false, true);
    	SCMC__Inventory_Position__c newIP = new SCMC__Inventory_Position__c();
    	newIP.SCMC__Item_Master__c = item.Id;
    	newIP.SCMC__Quantity__c = 5;
    	newIP.SCMC__Availability_Code__c = 'In Stock';
        newIP.SCMC__Acquisition_Currency__c = createCurrency().id;
        upsert newIP;
    	
    	list<SCMC__Inventory_Position__c> theList = [select Id from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(0, theList.size(), 'Inventory Position Did Not Get Saved');

		list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
		SCMImpToolsLoad_Serial_Numbers__c newLSN = new SCMImpToolsLoad_Serial_Numbers__c();
		newLSN.Item__c = 'Mikey Test';
		newLSN.Serial_Number_List__c = 'SN00100;SN00200;SN00300;SN00400;SN00500;';
		newLSN.Serial_Number_Loaded__c = false;
		newLSN.Quantity__c = 5;
		upsert newLSN;
		
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(loadList);
		SCMImpToolsLoadSerialNumbers controller = new SCMImpToolsLoadSerialNumbers(stdSetController);
    	
    	test.startTest();
			controller.loadIOSerialNumbers();
    	test.stopTest();

     	list<SCMImpToolsLoad_Serial_Numbers__c> updatedList = [select Id, Serial_Number_Loaded__c from SCMImpToolsLoad_Serial_Numbers__c where Has_Error__c = true];
    	system.assertEquals(1, updatedList.size(), 'An error should hav occur');
    }

    static testMethod void errorLoadIOSNControlItemNoSNTest() {
    	
		SCMC__Item__c item = createItem(false, true);
    	SCMC__Inventory_Position__c newIP = new SCMC__Inventory_Position__c();
    	newIP.SCMC__Item_Master__c = item.Id;
    	newIP.SCMC__Quantity__c = 5;
    	newIP.SCMC__Availability_Code__c = 'In Stock';
        newIP.SCMC__Acquisition_Currency__c = createCurrency().id;
    	upsert newIP;
    	
    	list<SCMC__Inventory_Position__c> theList = [select Id from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(0, theList.size(), 'Inventory Position Did Not Get Saved');

		list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
		SCMImpToolsLoad_Serial_Numbers__c newLSN = new SCMImpToolsLoad_Serial_Numbers__c();
		newLSN.Item__c = item.Name;
		newLSN.Serial_Number_List__c = '';
		newLSN.Serial_Number_Loaded__c = false;
		newLSN.Quantity__c = 5;
		upsert newLSN;
		
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(loadList);
		SCMImpToolsLoadSerialNumbers controller = new SCMImpToolsLoadSerialNumbers(stdSetController);
    	
    	test.startTest();
			controller.loadIOSerialNumbers();
    	test.stopTest();

     	list<SCMImpToolsLoad_Serial_Numbers__c> updatedList = [select Id, Serial_Number_Loaded__c from SCMImpToolsLoad_Serial_Numbers__c where Has_Error__c = true];
    	system.assertEquals(1, updatedList.size(), 'An error should hav occur');
    }

    static testMethod void errorLoadIOSNControlItemQtyNotRightTest() {
    	
		SCMC__Item__c item = createItem(false, true);
    	SCMC__Inventory_Position__c newIP = new SCMC__Inventory_Position__c();
    	newIP.SCMC__Item_Master__c = item.Id;
    	newIP.SCMC__Quantity__c = 5;
    	newIP.SCMC__Availability_Code__c = 'In Stock';
        newIP.SCMC__Acquisition_Currency__c = createCurrency().id;
    	upsert newIP;
    	
    	list<SCMC__Inventory_Position__c> theList = [select Id from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(0, theList.size(), 'Inventory Position Did Not Get Saved');

		list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
		SCMImpToolsLoad_Serial_Numbers__c newLSN = new SCMImpToolsLoad_Serial_Numbers__c();
		newLSN.Item__c = item.Name;
		newLSN.Serial_Number_List__c = 'SN00100;SN00200;';
		newLSN.Serial_Number_Loaded__c = false;
		newLSN.Quantity__c = 5;
		upsert newLSN;
		
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(loadList);
		SCMImpToolsLoadSerialNumbers controller = new SCMImpToolsLoadSerialNumbers(stdSetController);
    	
    	test.startTest();
			controller.loadIOSerialNumbers();
    	test.stopTest();

     	list<SCMImpToolsLoad_Serial_Numbers__c> updatedList = [select Id, Serial_Number_Loaded__c from SCMImpToolsLoad_Serial_Numbers__c where Has_Error__c = true];
    	system.assertEquals(1, updatedList.size(), 'An error should hav occur');
    }

    static testMethod void errorLoadIOSNControlItemSNLoadTest() {
    	
		SCMC__Item__c item = createItem(false, true);
    	SCMC__Inventory_Position__c newIP = new SCMC__Inventory_Position__c();
    	newIP.SCMC__Item_Master__c = item.Id;
    	newIP.SCMC__Quantity__c = 5;
    	newIP.SCMC__Availability_Code__c = 'In Stock';
        newIP.SCMC__Acquisition_Currency__c = createCurrency().id;
    	upsert newIP;
    	
    	SCMC__Serial_Number__c newSN = new SCMC__Serial_Number__c();
    	newSN.SCMC__Item__c = item.Id;
    	newSN.SCMC__Serial_Number__c = 'SN00100';
    	newSN.SCMC__InInventory__c = true;
    	upsert newSN;
    	
    	list<SCMC__Inventory_Position__c> theList = [select Id from SCMC__Inventory_Position__c where SCMC__Item_Master__c = :item.Id];
    	system.assertNotEquals(0, theList.size(), 'Inventory Position Did Not Get Saved');

		list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
		SCMImpToolsLoad_Serial_Numbers__c newLSN = new SCMImpToolsLoad_Serial_Numbers__c();
		newLSN.Item_Lookup__c = item.Id;
		newLSN.Serial_Number_List__c = 'SN00100;SN00200;SN00300;SN00400;SN00500;';
		newLSN.Serial_Number_Loaded__c = false;
		newLSN.Quantity__c = 5;
		upsert newLSN;
		
		ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(loadList);
		SCMImpToolsLoadSerialNumbers controller = new SCMImpToolsLoadSerialNumbers(stdSetController);
    	
    	test.startTest();
			controller.loadIOSerialNumbers();
    	test.stopTest();

     	list<SCMImpToolsLoad_Serial_Numbers__c> updatedList = [select Id, Serial_Number_Loaded__c from SCMImpToolsLoad_Serial_Numbers__c where Has_Error__c = true];
    	system.assertEquals(1, updatedList.size(), 'An error should hav occur');
    }

	private static SCMC__Item__c createItem(boolean serialized, boolean IOSerialized){
		SCMC__Unit_of_Measure__c uom = new SCMC__Unit_of_Measure__c();
		uom.Name = 'Each';
		uom.SCMC__ILS_Unit_of_Measure__c = 'EA';
		uom.SCMC__Valid_for_ILS__c = false;
		upsert uom;
				
		SCMC__Item__c newItem = new SCMC__Item__c();
		newItem.name = 'Test Item';
		newItem.SCMC__Item_Description__c = 'Test part for unit tests';
		newItem.SCMC__Inspection_Required__c  = false;
		newItem.SCMC__Inbound_Outbound_Serial_Number__c = IOSerialized;
		newItem.SCMC__Serial_Number_Control__c = serialized;
		newItem.SCMC__Lot_Number_Control__c = false;
		newItem.SCMC__Stocking_UOM__c = uom.id;
		insert newItem;
		return newItem;
	}

    private static SCMC__Currency_Master__c createCurrency(){
        SCMC__Currency_Master__c tCurrency = new SCMC__Currency_Master__c(
            name = 'USD',
            SCMC__Active__c = true,
            SCMC__Corporate_Currency__c = true
        );
        insert tCurrency;
        return tCurrency;
    }

}