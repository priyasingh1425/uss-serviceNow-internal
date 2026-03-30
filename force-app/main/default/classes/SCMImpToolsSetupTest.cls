@isTest
public with sharing class SCMImpToolsSetupTest {

	private static Integer suffix = 0;
	private SCMC__Currency_Master__c curr = this.createTestCurrency();
	private SCMC__Condition_Code__c cCode = this.createConditionCode('New');

	public Account createTestCustomerAccount(Boolean custActive, Boolean doInsert, Boolean onHold, id warehouseSpecific) {

        Account custSite = new Account();
        custSite.SCMC__Active__c = custActive;
 
        if (onHold){
            custSite.SCMC__Temporary_Hold__c = 'Finance';
        }else {
            custSite.SCMC__Temporary_Hold__c = null;
        }

        custSite.AnnualRevenue = null;
        custSite.SCMC__CAGE_Code__c = null;
        custSite.SCMC__Capability_Listing__c = null;
        custSite.SCMC__Certifications__c = null;
        custSite.SCMC__Credit_Card_Expiration_Date__c = null;
        custSite.SCMC__Credit_Card_Number__c = null;
        custSite.SCMC__Credit_Card_Type__c = null;
        custSite.SCMC__Credit_Card_Validation_Code__c = null;
        custSite.SCMC__Customer__c = true;
        custSite.SCMC__DUNS_Number__c = null;
        custSite.SCMC__Default_Payment_Type__c = null;
        custSite.SCMC__Corp_City__c = 'San Diego';
        custSite.SCMC__Corp_Country__c = 'United States';
        custSite.SCMC__Corp_State_Province__c = 'California';
        custSite.SCMC__Corp_Line1__c = '247 Ocean Blvd.';
        custSite.SCMC__Corp_Line2__c = null;
        custSite.SCMC__Corp_PostalCode__c = '92130';
        custSite.Description = 'Test customer site';
        custSite.FAX = '555-1234';
        custSite.SCMC__FOB__c = null;
        custSite.SCMC__Freight__c = null;
        custSite.Industry = null;
        custSite.SCMC__Language__c = null;
        custSite.Name = 'Test Customer' + string.valueOf(suffix++);
        custSite.NumberOfEmployees = null;
        custSite.Phone = null;
        custSite.Ownership = null;
        custSite.ParentId = null;
        custSite.SCMC__Preferred_Communication__c = 'Fax';
        custSite.SCMC__Provide_Advanced_Ship_Notice__c = false;
        custSite.SIC = null;
        custSite.SCMC__Sales_Rep__c = null;
        custSite.SCMC__Sales_Responsibility__c = null;
        custSite.SCMC__Ship_Via__c = null;
        custSite.SCMC__Small_Business_Designations__c = null;
        custSite.SCMC__Tax_Exemption_Group__c = null;
        custSite.SCMC__Terms__c = null;
        custSite.TickerSymbol = null;
        custSite.Type = null;
        custSite.Website = null;
        custSite.SCMC__warehouse__c = warehouseSpecific;

        custSite.BillingStreet = '123 Main St\nSuite 101\nc/0George';
        custSite.BillingCity = 'San Francisco';
        custSite.BillingState = 'California';
        custSite.BillingPostalCode = '12345';
        custSite.BillingCountry = 'United States';

        custSite.ShippingStreet = '123 Main St\nSuite 101\nc/0George';
        custSite.ShippingCity = 'San Francisco';
        custSite.ShippingState = 'California';
        custSite.ShippingPostalCode = '12345';
        custSite.ShippingCountry = 'United States';

        custSite.SCMC__Ship_Via__c = 'UPS Ground';
        custSite.SCMC__Shipping_Account__c = '123456789';
        //.Status__c = 'Active';

        if (doInsert){
            insert custSite;
        }
        return custSite;
    }
    
    public SCMC__Item__c createTestItem(boolean doInsert) {
        SCMC__Unit_of_Measure__c uom = createUnitofMeasure('Each');
        SCMC__Item__c im = new SCMC__Item__c();
        im.name = 'Test' + suffix++;
        im.SCMC__Item_Description__c = 'Test part for unit tests';
        im.SCMC__Inspection_Required__c  = false;
        im.SCMC__Serial_Number_Control__c = false;
        im.SCMC__Lot_Number_Control__c = false;
        im.SCMC__Stocking_UOM__c = uom.id;
        if (doInsert){
        	insert im;
        }
        return im;
    }
    
    public SCMC__Unit_of_Measure__c createUnitofMeasure(String name) {
        SCMC__Unit_of_Measure__c uom = new SCMC__Unit_of_Measure__c();
        try {
            uom = [select id
                    from SCMC__Unit_of_Measure__c
                    where name = :name];
        } catch(Exception ex) {
            uom.name = name;
            insert uom;
        }
        return uom;
	}
	
	public SCMC__Currency_Master__c createTestCurrency() {
        return createTestCurrency('USD', true);
	}

	public SCMC__Currency_Master__c createTestCurrency(String cname, Boolean corporate) {
        SCMC__Currency_Master__c currLocal = new SCMC__Currency_Master__c();
        try {
            currLocal = [select id, name
                    from SCMC__Currency_Master__c
                    where name = :cname];
        } catch (Exception ex) {
            currLocal.name = cname;
            currLocal.SCMC__Active__c = true;
            currLocal.SCMC__Corporate_Currency__c = corporate;
            insert currLocal;
        }
        
        return currLocal;
    }
    
    public SCMC__PO_Payment_Terms__c createPOPaymentTerms(string termName) {
    	SCMC__PO_Payment_Terms__c term = new SCMC__PO_Payment_Terms__c(
				SCMC__Terms_Name__c = termName
				,SCMC__Description__c = termName
				,SCMC__Number_of_Days__c = 60
				,SCMC__Discount_Percentage__c = 3
				,SCMC__Discount_Days__c = 30
				//,SCMC__Date_Due__c = ' '
				,SCMC__Basis_for_Due__c = 'Invoice Date'
			);
		insert term;
		return term;
    }
    
    public SCMC__Condition_Code__c createConditionCode(String code) {
        SCMC__Condition_Code__c condCode = new SCMC__Condition_Code__c();
        try {
            condCode = [select id
                       from SCMC__Condition_Code__c
                      where name = :code];
        } catch (Exception ex) {
            condCode.name = code;
            condCode.SCMC__description__c = 'Description for ' + code;
            condCode.SCMC__Disposal_Code__c = '1 -Excellent';
            condCode.SCMC__Supply_Code__c = 'A -Serviceable';
            insert condCode;
        }
        return condCode;
    }
    
    public SCMC__Reason_Code__c createTestReason(boolean doInsert) {
		SCMC__Reason_Code__c reason = new SCMC__Reason_Code__c();
		reason.Name = 'test reason';
		if (doInsert) { 
			insert reason;
		}
		return reason;
	}
	
	public SCMC__Ownership_Code__c createTestOwnership(String ownership, boolean doInsert) {
		SCMC__Ownership_Code__c code = new SCMC__Ownership_Code__c();
		code.name = ownership;
		if (doInsert) {
			insert code;
		}
		return code;
	}
	
	public SCMC__Warehouse__c setupWarehouse() {
        SCMC__Address__c address = createTestAddress();
        SCMC__ICP__c icp = createTestICP(address);
        return createTestWarehouse(icp, address);
    }

    public SCMC__Address__c createTestAddress() {
        SCMC__Address__c address = new SCMC__Address__c();
        address.name = 'Test Address';
        address.SCMC__City__c = 'A City';
        address.SCMC__Country__c = 'Country';
        address.SCMC__Line1__c = 'Address line 1';
        address.SCMC__PostalCode__c = 'Postcd';
        address.SCMC__State__c = 'State';
        insert address;
        return address;
    }

    public SCMC__ICP__c createTestICP(SCMC__Address__c address) {
    	List<SCMC__ICP__c>icps = [select id from SCMC__ICP__c];
    	
        SCMC__ICP__c icp = new SCMC__ICP__c();
        if (icps.Size() == 0){
        	icp.SCMC__Address__c = address.id;
        	icp.name = 'Test ICP';
        	icp.SCMC__Currency__c = curr.id;
        	insert icp;
        } else {
        	icp = icps[0];
        }
        return icp;
    }

    public SCMC__Warehouse__c createTestWarehouse(SCMC__ICP__c icp, SCMC__Address__c address){
        SCMC__Warehouse__c warehouse = new SCMC__Warehouse__c();
        warehouse.SCMC__ICP__c = icp.id;
        warehouse.SCMC__Address__c = address.id;
        warehouse.name = 'Test Warehouse';
        insert warehouse;
        return warehouse;
    }
    
    public SCMC__Inventory_Location__c createTestLocation(SCMC__Warehouse__c warehouse){
    	return createTestLocation(warehouse, true);
    }

    public SCMC__Inventory_Location__c createTestLocation(SCMC__Warehouse__c warehouse, boolean doInsert) {
        SCMC__Inventory_Location__c location = new SCMC__Inventory_Location__c();
        location.name = 'Level1';
        location.SCMC__Level1__c = 'Level1';
        location.SCMC__Warehouse__c = warehouse.id;
        if (doInsert){
        	insert location;
        }
        return location;
    }
    
    public SCMC__Supplier_Site__c createTestSupplier() {
    	SCMC__PO_Payment_Terms__c term = createPOPaymentTerms('Net 30');
        SCMC__Supplier_Site__c sc = new SCMC__Supplier_Site__c();
        sc.name = 'Test supplier for unit tests';
        sc.SCMC__Currency__c = curr.Id;
        sc.SCMC__Preferred_Communication_Sourcing__c = 'E-Mail';
        sc.SCMC__Preferred_Communication_Purchase_Order__c = 'E-Mail';
        sc.SCMC__E_Mail__c = 'test@test.com';
        sc.SCMC__PO_Payment_Terms__c = term.id;
        insert sc;
        return sc;
    }

}