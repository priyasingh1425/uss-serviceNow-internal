public with sharing class SCMImpToolsLoadIOSNBatch implements Database.Batchable<sObject>, Database.Stateful {

	public Database.QueryLocator start(Database.BatchableContext ctx){
		return Database.getQueryLocator([Select Id
											   ,Error_Message__c
											   ,Has_Error__c
											   ,Item__c
											   ,Item_Lookup__c
											   ,Item_Lookup__r.Name
											   ,Quantity__c
											   ,Serial_Number_List__c
											from SCMImpToolsLoad_Serial_Numbers__c
										   where Serial_Number_Loaded__c = false]);
	}
	
	public void execute(Database.BatchableContext ctx, List<SObject> records) {
		try {
			string splitSNBy = ';';
			map<string, Id> itemNameToIdMap = new map<string, Id>();
			set<string> itemNames = new set<string>();			
			set<string> serialNumberList = new set<string>();
			
			for(SObject line : records){
				SCMImpToolsLoad_Serial_Numbers__c record = (SCMImpToolsLoad_Serial_Numbers__c)line;
				//Get Item Master Record Id
				if(record.Item_Lookup__c != null){
					string itemName = record.Item_Lookup__r.Name.toUpperCase();
					itemNameToIdMap.put(itemName.trim(), record.Item_Lookup__c);
				} else {
					itemNames.add(record.Item__c.trim());
				}
				
				//Get all serial numbers for a quick check to see if they have already been loaded.
				string serialNumberBuckText = record.Serial_Number_List__c;
				if(serialNumberBuckText != null && serialNumberBuckText.length() > 0){
					string[] splitSNValue = record.Serial_Number_List__c.split(splitSNBy);
					for(string serial : splitSNValue){
						if(serial.trim() != null && serial.trim() != ''){
							serialNumberList.add(serial.trim());
						}
					}						
				}
										
			}

			//get item master ids from item name on record
			if(itemNames.size() > 0){
				for(SCMC__Item__c item : [select Id
											   , Name
											from SCMC__Item__c
										   where Name In :itemNames
										order By Name]){
					string itemName = item.Name.toUpperCase();
					itemNameToIdMap.put(itemName.trim(), item.Id);
				}
			}
			
			//Check Serial Number Object
			set<string> SerialNumberset = new set<string>();
			if(serialNumberList.size() > 0){
				for(SCMC__Serial_Number__c sn : [select Id
													   ,SCMC__Serial_Number__c
													   ,SCMC__Item__c
													from SCMC__Serial_Number__c
												   where SCMC__Serial_Number__c In :serialNumberList
												    and SCMC__InInventory__c = true]){
					string snValue = sn.SCMC__Serial_Number__c.toUpperCase();							    	
					string key = snValue.trim() + '{' + sn.SCMC__Item__c;
					SerialNumberset.add(key);
				}
			}		
			
			//Finally Create Serial Number Records For I/O Serial Number Control Items
			list<SCMC__Serial_Number__c> newSerialNumberList = new list<SCMC__Serial_Number__c>();
			list<SCMImpToolsLoad_Serial_Numbers__c> loadList = new list<SCMImpToolsLoad_Serial_Numbers__c>();
			for(SObject line : records){
				SCMImpToolsLoad_Serial_Numbers__c record = (SCMImpToolsLoad_Serial_Numbers__c)line;

				//Get Item Master Record Id
				Id itemId = record.Item_Lookup__c;
				if(itemId == null && record.Item__c != null && record.Item__c != ''){
					string itemName = record.Item__c.toUpperCase();
					if(itemNameToIdMap.containsKey(itemName.trim())){
						itemId = itemNameToIdMap.get(itemName.trim());
					}
				}

				if(itemId == null){
					record.Error_Message__c = 'Could not locate the item id, please check item master for this item.';
					record.Has_Error__c = true;
				} else {
					record.Item_Lookup__c = itemId;
				}
				
				if(!record.Has_Error__c){
					string serialNumberBuckText = record.Serial_Number_List__c;
					if(serialNumberBuckText != null && serialNumberBuckText.length() > 0){
						
						string[] splitSNValue = record.Serial_Number_List__c.split(splitSNBy);
						integer countSN = 0;

						//Create Record
						list<SCMC__Serial_Number__c> tempSNList = new list<SCMC__Serial_Number__c>();
						if(record.Quantity__c != null &&
						   record.Quantity__c > 0 &&
						   splitSNValue.size() == record.Quantity__c){
							for(string sn : splitSNValue){
								if(sn.trim() != null && sn.trim() != ''){
									string snValue = sn.toUpperCase();
									string key = snValue.trim() + '{' + itemId;
									if(!SerialNumberset.contains(key)){
										SCMC__Serial_Number__c newSerialNumber = new SCMC__Serial_Number__c();
										newSerialNumber.SCMC__InInventory__c = true;
										newSerialNumber.SCMC__Item__c = itemId; //Item Master Record
										newSerialNumber.SCMC__Serial_Number__c = sn.trim();
										tempSNList.add(newSerialNumber);

										SerialNumberset.add(key);
										countSN++;
									} else {
										record.Error_Message__c = sn.trim() + ' is already in the serial number object or is dup serial number.';
										record.Has_Error__c = true;
										break;
									}
								}			
							}
						}
						
						if(!record.Has_Error__c){
							if(countSN != record.Quantity__c){
								record.Error_Message__c = record.Quantity__c + ' are required and ' + countSN + ' have been entered.';
								record.Has_Error__c = true;
							} else {
								newSerialNumberList.addAll(tempSNList);
							}
						}						
					} else {
						record.Error_Message__c = 'Could not locate any serial numbers for this item, please check record.';
						record.Has_Error__c = true;
					}
				}
				
				if(!record.Has_Error__c){
					record.Serial_Number_Loaded__c = true;
				}
				
				loadList.add(record);
			}
			
			//Save New Serial Number records
			system.debug('+++++ newSerialNumberList: ' + newSerialNumberList.size());
			if(newSerialNumberList.size() > 0){
				upsert newSerialNumberList;
			}
			
			//Update Load Serial Number records
			system.debug('+++++ loadList: ' + loadList.size());
			if(loadList.size() > 0){
				update loadList;
			}
										
		} catch (Exception ex) {
			system.debug('+++++ error: ' + ex);
			SCMC.ErrorLog.log('LoadInventorySNBatch.execute', 'Error with loading the inventory serial number control numbers: ', ex);
			SCMC.ErrorLog.flush();
		}
	}
	
	public void finish(Database.BatchableContext ctx) {
	}
	
}