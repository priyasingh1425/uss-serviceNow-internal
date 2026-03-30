global with sharing class SCMImpToolsLoadInventory implements Database.Batchable<SObject>{
   	global Database.QueryLocator start(Database.BatchableContext ctx) {
        // Select all requests that don't yet have requisition associated with them
        return Database.getQueryLocator([Select id
        		,name
        		,Warehouse__c
        		,WarehouseRef__c
        		,Unit_cost__c
        		,Quantity__c
        		,Ownership__c
        		,Ownership_Code__c
        		,Condition__c
        		,Condition_Code__c
				,Location__c
				,Item_Number__c
				,Item_Master__c
				,Inventory_Location__c
				,Error__c
				,Error_Message__c 
				,Loaded__c
				,Lot_Number__c
				,UOM__c
				,Unit_of_Measure__c
				,Reason__c
				,Reason_Code__c
				,Stocking_UOM__c
				,Serial_Number__c
			From SCMImpToolsLoad_Inventory__c 
			where Loaded__c = false and 
			Error__c = false]);
    }
   
    global void execute(Database.BatchableContext ctx, List<SObject> records) {
    	Map<String, SCMImpToolsLoad_Inventory__c>loads = new Map<String, SCMImpToolsLoad_Inventory__c>();
    	Map<String, SCMC__Item__c>items = new Map<String, SCMC__Item__c>();
    	Map<String, SCMC__Ownership_Code__c>owns = new Map<String, SCMC__Ownership_Code__c>();
    	Map<String, SCMC__Unit_Of_Measure__c>uoms = new Map<String, SCMC__Unit_Of_Measure__c>();
    	Map<String, SCMC__Reason_Code__c> reasons = new Map<String, SCMC__Reason_Code__c>();
    	//this is a map of locations associated with a warehouse
    	Map<String, Map<String,SCMC__Inventory_Location__c>>locns = new Map<String, Map<String,SCMC__Inventory_Location__c>>();
    	Map<String, SCMC__Condition_Code__c>conds = new Map<String, SCMC__Condition_Code__c>();
    	for (SObject record : records){
    		SCMImpToolsLoad_Inventory__c load = (SCMImpToolsLoad_Inventory__c)record;
    		loads.put(load.name, load);
    		items.put(load.Item_Number__c, null);
    		if (load.Ownership__c != null){
    			owns.put(load.Ownership__c, null);
    		}
    		uoms.put(load.UOM__C, null);
    		reasons.put(load.Reason__c, null);
    		if (load.Condition__c != null){
    			conds.put(load.Condition__c, null);
    		}
    	}
		//get all the items
		List<SCMC__Item__c>itemMasters = [select id, name
				,SCMC__Serial_Number_Control__c
				,SCMC__Lot_Number_Control__c
				 from SCMC__Item__c
				where name in :items.Keyset()];
		for (SCMC__Item__c master : itemMasters){
			items.put(master.name, master);
		}
   		List<SCMC__Ownership_Code__c>ownCodes = [select id, name from SCMC__Ownership_Code__c
				where name in :owns.Keyset()];
		for (SCMC__Ownership_Code__c ownCode : ownCodes){
			owns.put(ownCode.name, ownCode);
		}
		List<SCMC__Reason_Code__c>reas = [select id, name from SCMC__Reason_Code__c
				where name in :reasons.Keyset()];
		for (SCMC__Reason_Code__c reason : reas){
			reasons.put(reason.name, reason);	
		}
 	   	List<SCMC__Unit_Of_Measure__c>umeas= [select id, name from SCMC__Unit_Of_Measure__c
    			where name in :uoms.Keyset()];
    	for (SCMC__Unit_Of_Measure__c umea : umeas){
   			uoms.put(umea.name, umea);
   		}
   		List<SCMC__Condition_Code__c> ccodes = [select id, name from SCMC__Condition_Code__c
    			where name in :conds.Keyset()];
    	for (SCMC__Condition_Code__c ccode : ccodes){
    		conds.put(ccode.name, ccode);
    	}
   		
   		List<SCMC__Inventory_Location__c>locations = [select id
    			,name
    			,SCMC__Warehouse__c
    			,SCMC__Warehouse__r.name
    		from SCMC__Inventory_Location__c];
    			
		for (SCMC__Inventory_Location__c location : locations){
       		Map<String, SCMC__Inventory_Location__c>locn = locns.get(location.SCMC__Warehouse__r.name);
			System.debug('map of locations for warehouse ' + location.SCMC__Warehouse__r.name);
    		if (locn == null){
    			locn = new Map<String, SCMC__Inventory_Location__c>();
    			locns.put(location.SCMC__Warehouse__r.name, locn);
    		}
    		locn.put(location.name, location);
			
		}
 
    	//loop through the records, validate and load
    	
    	for (SObject record : records){
    		SCMImpToolsLoad_Inventory__c load = (SCMImpToolsLoad_Inventory__c)record;
    		SCMC__Item__c im = items.get(load.Item_Number__c);
    		load.error__c = false;
    		load.Error_Message__c = '';
    		if (im == null){
    			load.error__c = true;
    			load.Error_Message__c += '\nUnknow item number';
    		}else {
     			if (im.SCMC__Serial_Number_Control__c){
    				if (load.Quantity__c > 1){
    					load.error__c = true;
    					load.Error_Message__c = '\nSerialized items can only have a quantity of 1';
    				} else if (load.Serial_Number__c == null){
    					load.error__c = true;
    					load.Error_Message__c = '\nSerialized item must specify a serial number';
    				}
    			}
    			if (im.SCMC__Lot_Number_Control__c){
    				if (load.Lot_Number__c == null){
    					load.error__c = true;
    					load.Error_Message__c = '\nLot number controlled item must have a lot number specified';
    				}
    			}
    			load.Item_Master__c = im.id;
    		}
    		load.Ownership_Code__c = null;
    		if (load.Ownership__c != null){
   				SCMC__Ownership_Code__c lown = owns.get(load.Ownership__c);
   				if (lown == null){
   					load.error__c = true;
   					load.Error_Message__c += '\nInvalid Ownership specified';
   				} else {
   					load.Ownership_Code__c = lown.id;
   				}
    		}
    		load.Condition_Code__c = null;
    		if (load.Condition__c != null){
    			SCMC__Condition_Code__c lcode = conds.get(load.Condition__c);
    			if (lcode == null){
    				load.error__c = true;
    				load.Error_Message__c += '\nInvalid Condition specified';
    			} else {
    				load.Condition_Code__c = lcode.id;
    			}
    		}
			if (load.Reason__c != null){
   				SCMC__Reason_Code__c lreas = reasons.get(load.Reason__c);
   				if (lreas == null){
   					load.error__c = true;
   					load.Error_Message__c += '\nInvalid Reason specified';
   				} else {
   					load.Reason_Code__c = lreas.id;
   				}
    		}
    		if (load.Quantity__c == null){
    			load.error__c = true;
    			load.Error_Message__c += '\nInvalid Quantity Specified';
    		}
    		load.WarehouseRef__c = null;
    		Map<String, SCMC__Inventory_Location__c>locn = locns.get(load.Warehouse__c);
    		System.debug('get warehouse ' + load.Warehouse__c + locns);
    		if (locn == null){
    			load.error__c = true;
    			load.error_message__c += '\nUnknown warehouse specified';
    		}else {
    			SCMC__Inventory_Location__c wlocn = locn.get(load.Location__c);
    			if (wlocn == null){
    				load.Error__c = true;
    				load.Error_Message__c += '\nUnknown location specified';
    			}else {
    				load.WarehouseRef__c = wlocn.SCMC__Warehouse__c;
    				load.Inventory_Location__c = wlocn.id;
    			}
    		}
    	}
    	//now do miscellaneous receipt or issue
    	System.debug('items to load ' + records);
    	for (SObject record : records){
     		SCMImpToolsLoad_Inventory__c load = (SCMImpToolsLoad_Inventory__c)record;
    		if(load.Error__c){
    			//skip past records that have errors
    			continue;
    		}
      		Double quantity = Double.valueOf(load.Quantity__c);
     		Double value = 0;
     		System.debug('before receipt/issue ' + load);
	     	SCMC.InventoryAPI ip = new SCMC.InventoryAPI();
     		if (quantity < 0){
     			try{
     				List<SCMC__Inventory_Position__c> posns = findPosns(load.Item_Master__c, load.Ownership_Code__c, load.Condition_Code__c, load.WarehouseRef__c, quantity);
     				Double qtyToIssue = quantity;
     				for (SCMC__Inventory_Position__c posn : posns){
						//void miscellaneousIssue(ID inventoryPositionID, ID reasonId, Double quantity
						if (qtyToIssue >= 0){
							break;
						}
						Double issQuantity = posn.SCMC__Quantity__c; 
						if (issQuantity + qtyToIssue > 0){
							//this position completes the requirement
							issQuantity = qtyToIssue*-1;
						} 
     					ip.miscellaneousIssue(posn.id, load.Reason_Code__c, issQuantity);
     					qtyToIssue += issQuantity;
     				}
     				load.loaded__c = true;
     			} catch (Exception ex){
     				load.Error__c = true;
     				load.Error_Message__c += '\n '+ ex.getMessage();
     			}
     		} else {
	     		try {
	     			value = Double.valueOf(load.Unit_cost__c);
	    //SOBJECT:SCMC__Inventory_Position__c miscellaneousReceipt(Id warehouseId, Id itemId, Double Quantity, String lotNumber, String serialNumber, Datetime expirationDate, Id reasonId, Id conditionCodeId, Boolean inspectionRequired, Double value, Id ownerId, Id Ownership)			
	  	    		SCMC__Inventory_Position__c newposn = ip.miscellaneousReceipt(
		    			load.WarehouseRef__c
		    			, load.Item_Master__c
		    			, quantity
		    			, load.Lot_Number__c
		    			, load.Serial_Number__c
		            	, null
		            	, load.Reason_Code__c
		            	, load.Condition_Code__c
		            	, false 
		    			, value
		    			, null
						, load.Ownership_Code__c);
					load.Loaded__c = true;
					ip.locate(newposn, load.Location__c);
	     		} catch( Exception ex){
	     			load.Error__c = true;
	     			load.Error_Message__c += '\n '+ ex.getMessage();	
	     		}
     		}
    	}
    	update records;
    }
    
    global void finish(Database.BatchableContext ctx) {
    }
    
    private void notify(String message){
        System.debug('Error - request is ignored ' + message);
    }  
    
    private List<SCMC__Inventory_Position__c> findPosns(ID item, ID ownership, ID condition, ID warehouse, Double quantity){
    	system.debug('Item ' + item + ' Ownership ' + ownership + ' Condition ' + condition + ' warehouse ' + warehouse);
    	List<SCMC__Inventory_Position__c>issues = new List<SCMC__Inventory_Position__c>();
    	List<SCMC__Inventory_Position__c>possibles = [select id, name
                                ,SCMC__Acquisition_Cost__c
                                ,SCMC__Acquisition_Currency__c
                                ,SCMC__Availability__c
                                ,SCMC__Availability_Code__c
                                ,SCMC__Bin__c
                                ,SCMC__Bin__r.name
                                ,SCMC__Bin__r.SCMC__Warehouse__c
                                ,SCMC__Bin__r.SCMC__Warehouse__r.id
                                ,SCMC__Condition_Code__c
                                ,SCMC__CSN__c
                                ,SCMC__CSO__c
                                ,SCMC__CSR__c
                                ,SCMC__Current_Value__c
                                ,SCMC__ICP_Acquisition_Cost__c
                                ,SCMC__ICP_Currency__c
                                ,SCMC__Item_Master__c
                                ,SCMC__Last_Cycle_Count_Performed__c
                                ,SCMC__Listed_Date__c
                                ,SCMC__List_Type__c
                                ,SCMC__Lot_Number__c
                                ,SCMC__Manufacturer_CAGE__c
                                ,SCMC__Owned_By__c
                                ,SCMC__Ownership_Code__c
                                ,SCMC__Purchase_Order_Line_Item__c
                                ,SCMC__Quantity_Allocated__c
                                ,SCMC__Quantity__c
                                ,SCMC__Quantity_in_Transit__c
                                ,SCMC__Receipt_Line__c
                                ,SCMC__Receiving_Inspection__c
                                ,SCMC__Reserve_Price__c
                                ,SCMC__Revision_Level__c
                                ,SCMC__Sale_Price__c
                                ,SCMC__Sales_Order_Line_Item__c
                                ,SCMC__Item_Serial_Number__c
                                ,SCMC__Shelf_Life_Expiration__c
                                ,SCMC__TSN__c
                                ,SCMC__TSO__c
                                ,SCMC__TSR__c
			                    ,SCMC__Item_Master__r.name
			                    ,SCMC__Item_Master__r.SCMC__Item_Description__c
			                    ,Ownerid
                    from SCMC__Inventory_Position__c
                    where SCMC__Bin__r.SCMC__Warehouse__r.id = :warehouse and
                    	SCMC__Item_Master__c = :item and
                    	SCMC__Condition_Code__c = :condition and
                    	SCMC__Ownership_Code__c = :ownership and
                    	SCMC__Quantity_Allocated__c = 0 
                    order by CreatedDate];
    	if (possibles.size() == 0){
    		throw new SCMImpToolsException ('Unable to find inventory to issue');
    	}
    	System.debug('possible items ' + possibles);
    	Double totQuantity = 0;
    	for (SCMC__Inventory_Position__c posn : possibles){
    		totQuantity	-= posn.SCMC__Quantity__c;
    		issues.add(posn);
    		if (totQuantity < quantity){
    			break;
    		}
    	}
    	if (totQuantity > quantity){
    		throw new SCMImpToolsException('Unable to find full quantity of items to issue');
    	}
    	return issues;
    }

}