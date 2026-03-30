/*
* FinancialForce.com, inc. claims copyright in this software, its screen
* display designs and supporting documentation. FinancialForce and
* FinancialForce.com are trademarks of FinancialForce.com, inc. Any
* unauthorized use, copying or sale of the above may constitute an
* infringement of copyright and may result in criminal or other legal
* proceedings.
*
* Copyright (c) 2015 FinancialForce.com, inc. All rights reserved.
*/
global with sharing class SCMImpToolsLoadSO implements Schedulable, Database.Batchable<SObject>{
	private ApexPages.StandardSetController setController;
	private Map<String, Schema.SObjectField> stagefs = Schema.SObjectType.SCMImpToolsSO_Stage__c.fields.getMap();

	global SCMImpToolsLoadSO() {
	}

	// this constructor is invoked from the multi select on the SOStage object view
	public SCMImpToolsLoadSO(ApexPages.StandardSetController controller) {
		this.setController = controller;
	}

	public PageReference process() {
		Database.executeBatch(this, 30);
		Schema.DescribeSObjectResult r = SCMC__Sales_Order__c.SObjectType.getDescribe();
		String keyPrefix = r.getKeyPrefix();
		PageReference retPage = new PageReference('/' + keyPrefix + '/o');

		return retPage;
	}

	public PageReference goback() {
		PageReference retPage = setController.cancel();
		return retPage;
	}

	global void execute(SchedulableContext ctx) {
		// Start Batch Apex job to pull requests and create requisitions
		Database.executeBatch(new SCMImpToolsLoadSO(),30);
	}

	global Database.QueryLocator start(Database.BatchableContext ctx) {

		// Select all requests that are not already loaded

		String querySO = 'SELECT id';
		for(SObjectField field : stagefs.values()){
			Schema.DescribeFieldResult f = field.getDescribe();
			if(f.isAutoNumber()){
				//skip autonumber fields
				continue;
			} else if (f.isCalculated()){
				//skip calculated fields
				continue;
			} else if (!f.isCreateable()){
				//skip this field if the user cannot create the field
				continue;
			} else {
				querySO += ', ' + f.getName();
			}
		}
		querySO += ' FROM SCMImpToolsSO_Stage__c WHERE Loaded__c = false ';
		querySO += ' order by Existing_SO_Number__c, Existing_SO_Line_No__c';
		System.debug('query stage for loadSO ' + querySO);
		return Database.getQueryLocator(querySO);
	}

	global void execute(Database.BatchableContext ctx, List<SObject> records){
		Map<String, SCMC__Sales_Order__c>so =
				new Map<String, SCMC__Sales_Order__c>();
		Map<String, List<SCMC__Sales_Order_Line_Item__c>> lines =
				new Map<String, List<SCMC__Sales_Order_Line_Item__c>>();
		String currSO = '';
		Map<String, SCMC__Sales_Order__c>existSO = new Map<String, SCMC__Sales_Order__c>();
		Map<Id, Account>accounts = new Map<Id, Account>();
		Map<String, RecordType>headType = new Map<String, RecordType>();
		Map<String, RecordType>lineType = new Map<String, RecordType>();
		Map<String,Map<String,SObject>>validLookup = new Map<String,Map<String, SObject>>();
		Map<String,Set<String>>objToName = new Map<String,Set<String>>();


		lp_analyzeFields analyze = new lp_analyzeFields(Schema.SObjectType.SCMC__Sales_Order__c.fields.getMap()
				, Schema.SObjectType.SCMC__Sales_Order_Line_Item__c.fields.getMap());

		analyze.stagefs = stagefs;
		//setup keys for lookup fields
		objToName = analyze.mapreferenceToData(records);

		//get lookup data
		System.debug('objToName ' + objToName);
		for (String objectName : objToName.keySet()){
			Set<String>keys = objToName.get(objectName);
			System.debug('keys ' + keys);
			String query = 'Select Id, Name FROM ';
			query += objectName;
			query += ' WHERE (Name in :keys';
			query += ' OR Id IN :keys)'; // allow lookup fields to be added to stage object
            if (objectName == 'Account') {
                query += ' AND SCMC__Active__c = true';
                query += ' AND SCMC__Customer__c = true';
            }
            if (objectName == 'User'){
                query += ' AND IsActive = true';
            }
			System.debug('Reference query ' + query);
			SObject[] keyData = Database.query(query);
			Map<String,SObject> mapData = new Map<String, SObject>();
			for (SObject data : keyData){
				// allow lookup fields to be added to stage object
				String recordName = (String)data.get('Name');
				if (keys.contains(recordName)) {
					mapData.put((String)data.get('Name'), data);
				} else {
					mapData.put((String)data.get('Id'), data);
				}
			}
			validLookup.put(objectName, mapData);
			System.debug('key data ' + objectName + ' ' +mapData);
		}

        for (SObject record : records){
            //setup existing so numbers
            existSO.put((String)record.get('Existing_SO_Number__c'), null );
        }


		//see if SO is already loaded
		List<SCMC__Sales_Order__c>exSOs = [SELECT Id, SCMC__Existing_SO_Number__c FROM SCMC__Sales_Order__c
		WHERE SCMC__Existing_SO_Number__c IN :existSO.keySet()];
		for (SCMC__Sales_Order__c exSO : exSOs){
			existSO.put(exSO.SCMC__Existing_SO_Number__c, exSO);
		}


		List<Account>ISites = [SELECT Id, Name
				,SCMC__Active__c
				,SCMC__Temporary_Hold__c
				,SCMC__Customer__c
		FROM Account
		WHERE Id in :accounts.keySet() AND
		SCMC__Active__c = TRUE ];
		for (Account site : ISites){
			accounts.put(site.Id, site);
		}



		List<RecordType>rhtypes = [SELECT Id, Name
		FROM RecordType
		WHERE SobjectType = 'SCMC__Sales_Order__c'];

		for (RecordType rhtype : rhtypes){
			headType.put(rhtype.Name, rhtype);
		}

		List<RecordType>rltypes = [SELECT Id, Name
		FROM RecordType
		WHERE SobjectType = 'SCMC__Sales_Order_Line_Item__c'];

		for (RecordType rltype : rltypes){
			lineType.put(rltype.Name, rltype);
		}

		Boolean headErr = false;
		for (SObject record : records){
			SCMImpToolsSO_Stage__c stage = (SCMImpToolsSO_Stage__c)record;
			stage.Error__c = false;
			stage.Error_Message__c = '';
			Integer lineNum = 0;
			if (currSO != stage.Existing_SO_Number__c){
				//we have the full SO start a new
				lineNum = 0;
				currSO = stage.Existing_SO_Number__c;
				headErr = false;
				SCMC__Sales_Order__c head = existSO.get(currSO);
				if (head != null){
					System.debug('SO already exists for ' + currSO);
				} else {
					System.debug('Creating new head for ' + currSO);
					head = new SCMC__Sales_Order__c();
					head.SCMC__Existing_SO_Number__c = stage.Existing_SO_Number__c;


					RecordType rtypeID = null;
					if (stage.SO_Record_Type__c != null){
						//get record type
						rtypeID = headType.get(stage.SO_Record_Type__c);
					}
					if (rtypeID != null){
						head.RecordTypeId = rtypeID.Id;
					}
					for(String hdfield  : analyze.headAttrs.keySet()) {
						lp_analyzeFields.fieldAttributes attrs = analyze.headAttrs.get(hdfield);
						if (!attrs.isSetable || hdfield == 'createdbyid' || hdfield == 'lastmodifiedbyid') {
							continue;
						}
						System.debug('head field ' + hdfield + ' ' + attrs);
						String headFieldName = attrs.fieldName;
						if (stagefs.containsKey(hdfield)){
							//set this field
							//for reference fields - set field to id of sobject
							String stageFieldName = hdfield;
							if (attrs.fieldType == Schema.DisplayType.REFERENCE) {
								String lookupObject = attrs.lookupName;
								Map<String, SObject> orgData = validLookup.get(lookupObject);
								System.debug('lookupobject: ' + lookupObject);
								System.debug('validLookup ' + validLookup);
								System.debug('orgData ' + orgData);
								if (orgdata == null) {
									lp_toolsUtility.setStageError(stage, 'Invalid data for ' + hdfield);
								} else {
									String dataLookup = (String) lp_toolsUtility.getData(stagefs, stage, stageFieldName);
									System.debug('dataLookup ' + dataLookup);
									if (dataLookup != null) {
										SObject orgRecord = orgdata.get(dataLookup);
										if (orgRecord == null) {
											lp_toolsUtility.setStageError(stage, 'Invalid value for ' + hdfield);
										} else {
											head.put(headFieldName, orgRecord.Id);
										}
									}
								}
							} else if (attrs.fieldType == Schema.DisplayType.PICKLIST) {
								String stageData = (String)lp_toolsUtility.getData(stagefs,stage, stageFieldName);
								if (stageData != null) {
									if (attrs.validPicks.contains(stageData)) {
										head.put(headFieldName, stageData);
									} else {
										lp_toolsUtility.setStageError(stage, 'Invalid picklist value ' + stageData + ' for ' + hdfield);
									}
								}
                            }else if (attrs.fieldType == Schema.DisplayType.BOOLEAN){
                                Object tcont = head.get(headFieldName);
                                //only over write field if it is currently empty
                                if (tcont == Null &&
                                        stage.get(hdfield) != 'NULL' &&
                                        stage.get(hdfield) != null) {

                                    head.put(headFieldName, stage.get(hdfield));
                                }

							} else {
								Object tcont = head.get(headFieldName);
								//only over write field if it is currently empty
								if (tcont == Null &&
										stage.get(hdfield) != 'NULL') {

									head.put(headFieldName, stage.get(hdfield));
								}
							}
						}
					}
				}
				System.debug('so head ' + head);
				if (stage.Error__c){
					headErr = true;
				} else {
					so.put(currSO, head);
					List<SCMC__Sales_Order_Line_Item__c>soLines =
							new List<SCMC__Sales_Order_Line_Item__c>();
					lines.put(currSO, soLines);
				}
			}
			if (headErr){
				stage.Error__c = true;
				System.debug ('Error message for stage record ' + stage.Error_Message__c);
				stage.Error_Message__c = stage.Error_Message__c.abbreviate(254);
			} else {
				List<SCMC__Sales_Order_Line_Item__c>soLines =
						lines.get(currSO);
				//create line and add to list
				SCMC__Sales_Order_Line_Item__c lItem =
						new SCMC__Sales_Order_Line_Item__c();
				for(String lnfield  : analyze.detailAttrs.keySet()) {
					if (!stagefs.containsKey(lnfield)) {
						continue;
					}
					lp_analyzeFields.fieldAttributes lineAttrs = analyze.detailAttrs.get(lnfield);
					if (!lineAttrs.isSetable || lnfield == 'createdbyid' || lnfield == 'lastmodifiedbyid') {
						continue;
					}
					System.debug('line field ' + lnfield + ' ' + lineAttrs);
					String lineFieldName = lineAttrs.fieldName;
					if (stagefs.containsKey(lnfield)) {
						//set this field
						//for reference fields - set field to id of sobject
						String stageFieldName = lnfield;
						if (lineAttrs.fieldType == Schema.DisplayType.REFERENCE) {
							String lookupObject = lineAttrs.lookupName;
							Map<String, SObject> orgData = validLookup.get(lookupObject);
							System.debug('validLookup ' + validLookup);
							System.debug('orgData ' + orgData);
							if (orgdata == null) {
								lp_toolsUtility.setStageError(stage, 'Invalid data for ' + lnfield);
							} else {
								String dataLookup = (String) lp_toolsUtility.getData(stagefs,stage, lnfield);
								System.debug('dataLookup ' + dataLookup);
								if (dataLookup != null) {
									SObject orgRecord = orgdata.get(dataLookup);
									if (orgRecord == null) {
										lp_toolsUtility.setStageError(stage, 'Invalid value for ' + lnfield);
									} else {
										lItem.put(lineFieldName, orgRecord.Id);
										System.debug('after set reference ' + lItem.get(lineFieldName));
									}
								}
							}
						} else if (lineAttrs.fieldType == Schema.DisplayType.PICKLIST) {
							String stageData = (String) lp_toolsUtility.getData(stagefs,stage, lnfield);
							if (stageData != null) {
								if (lineAttrs.validPicks.contains(stageData)) {
									lItem.put(lineFieldName, stageData);
								} else {
									lp_toolsUtility.setStageError(stage, 'Invalid picklist value ' + stageData + ' for ' + lnfield);
								}
							}
                        }else if (lineAttrs.fieldType == Schema.DisplayType.BOOLEAN){
                            Object tcont = lItem.get(lineFieldName);
                            //only over write field if it is currently empty
                            if (tcont == Null &&
                                    stage.get(lnfield) != 'NULL' &&
                                    stage.get(lnfield) != null) {

                                litem.put(lineFieldName, stage.get(lnfield));
                            }

						} else {
							Object tcont = lItem.get(lineFieldName);
							//only over write field if it is currently empty
							if (tcont == Null &&
									stage.get(lnfield) != 'NULL') {
								lItem.put(lineFieldName, stage.get(lnfield));
							}
						}

					}
				}
				lItem.SCMC__Line_Number__c = (++lineNum);
				RecordType rTypeId = null;
				if (stage.SO_Line_Record_Type__c != null){
					//get record type
					rTypeId = lineType.get(stage.SO_Line_Record_Type__c);
				}
				if (rTypeId != null){
					lItem.RecordTypeId = rtypeID.Id;
				}
				if (!stage.Error__c){
					soLines.add(lItem);
				}
			}
		}
		Map<String,SCMC__Sales_Order__c>insSO = new Map<String, SCMC__Sales_Order__c>();
		List<SCMC__Sales_Order_Line_Item__c>inssolines =
				new List<SCMC__Sales_Order_Line_Item__c>();
		for (SObject record : records){
			SCMImpToolsSO_Stage__c stage = (SCMImpToolsSO_Stage__c)record;
			if (stage.Error__c){
				//skip past error lines
				continue;
			} else {
				insSO.put(stage.Existing_SO_Number__c,so.get(stage.Existing_SO_Number__c));
			}

		}
		System.debug('so to insert ' + insSO);
		if (insSO.values().size() > 0){
			upsert insSO.values();
		}

		for (String NSSO : lines.keyset()){
			List<SCMC__Sales_Order_Line_Item__c>nslines =
					lines.get(NSSO);
			SCMC__Sales_Order__c nsHead = so.get(NSSO);
			for(SCMC__Sales_Order_Line_Item__c nsline : nslines){
				nsline.SCMC__Sales_Order__c = nsHead.Id;
			}
			inssolines.addAll(nslines);
		}
		System.debug('inssolines ' + inssolines);
		insert inssolines;
		for (SObject record : records){
			SCMImpToolsSO_Stage__c stage = (SCMImpToolsSO_Stage__c)record;
			if (stage.Error__c){
				//skip past error lines
				continue;
			}
			stage.Loaded__c = true;
		}
		update records;
	}

	global void finish(Database.BatchableContext ctx) {
	}


}