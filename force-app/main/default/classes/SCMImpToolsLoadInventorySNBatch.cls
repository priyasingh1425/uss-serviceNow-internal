public with sharing class SCMImpToolsLoadInventorySNBatch implements Database.Batchable<sObject>, Database.Stateful {
	public Database.QueryLocator start(Database.BatchableContext ctx){
		return Database.getQueryLocator([Select Id
											   ,SCMC__Item_Master__c
											   ,SCMC__Ownership_Code__c
											   ,SCMC__Purchase_Order_Line_Item__c
											   ,SCMC__Production_Order_Line__c
											   ,SCMC__Production_Order__c
											   ,SCMC__Receipt_Line__c
											   ,SCMC__Receiving_Inspection__c
											   ,SCMC__Sales_Order_Line_Item__c
											   ,SCMC__Serial_Number_Lookup__c
											   ,SCMC__Item_Serial_Number__c
											   ,SCMC__Availability_Code__c
											from SCMC__Inventory_Position__c
										   where SCMC__Item_Master__r.SCMC__Serial_Number_Control__c = true
										     and SCMC__Serial_Number_Lookup__c = null]);
	}
	
	public void execute(Database.BatchableContext ctx, List<SObject> records) {
		try {
			
   			map<Id, SCMC__Serial_Number__c> ipToSNMap = new map<Id, SCMC__Serial_Number__c>();
			for(SObject record : records){
				
				SCMC__Inventory_Position__c ip = (SCMC__Inventory_Position__c)record;
				
				boolean onHold = false;
				if(ip.SCMC__Availability_Code__c == 'On Hold'){
					onHold = true;
				}
				
				boolean inInventory = true;
				if(ip.SCMC__Purchase_Order_Line_Item__c != null){
					inInventory = false;
				}

				SCMC__Serial_Number__c sn             		  = new SCMC__Serial_Number__c();
				sn.SCMC__Serial_Number__c             		  = ip.SCMC__Item_Serial_Number__c.trim();
				sn.SCMC__Item__c 					          = ip.SCMC__Item_Master__c;
				sn.SCMC__Receipt_Line__c              		  = ip.SCMC__Receipt_Line__c;
				sn.SCMC__Service_Purchase_Order_Line_Item__c  = ip.SCMC__Purchase_Order_Line_Item__c;
				sn.SCMC__Sales_Order_Line_Item__c     		  = ip.SCMC__Sales_Order_Line_Item__c;
				sn.SCMC__AP_Voucher_Line__c           		  = null;
				sn.SCMC__Receiving_Inspection__c			  = ip.SCMC__Receiving_Inspection__c;
				sn.SCMC__Ownership_Code__c            		  = ip.SCMC__Ownership_Code__c;
				sn.SCMC__Production_Order__c 				  = ip.SCMC__Production_Order__c;
				sn.SCMC__Production_Order_Line__c			  = ip.SCMC__Production_Order_Line__c;
				sn.SCMC__On_Hold__c                   		  = onHold;
				sn.SCMC__InInventory__c                       = inInventory;
				sn.SCMC__Type_Of_Serial_Number__c	  		  = 'Inventory Position';

				ipToSNMap.put(ip.id, sn);
				
			}

			system.debug('+++++ ipToSNMap: ' + ipToSNMap.size());
			if(ipToSNMap.size() > 0){
				upsert ipToSNMap.Values();
				list<SCMC__Inventory_Position__c> ipList = new list<SCMC__Inventory_Position__c>();
				for(SObject record : records){
					SCMC__Inventory_Position__c ip = (SCMC__Inventory_Position__c)record;
					if(ipToSNMap.containsKey(ip.Id)){
						ip.SCMC__Serial_Number_Lookup__c = ipToSNMap.get(ip.Id).Id;
						ipList.add(ip);
					}
				}
				if(ipList.size() > 0){
					update ipList;
				}
			}
			
		} catch (Exception ex) {
			system.debug('+++++ error: ' + ex);
			SCMC.ErrorLog.log('SCMImpToolsLoadInventorySNBatch.execute', 'Error with loading the inventory serial number control numbers: ', ex);
			SCMC.ErrorLog.flush();
		}
	}
	
	public void finish(Database.BatchableContext ctx) {
	}

}