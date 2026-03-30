global with sharing class SCMImpToolsLoadPO implements Schedulable, Database.Batchable<SObject>{

	private ApexPages.StandardSetController setController;
    private Map<String, Schema.SObjectField> stagefs = Schema.SObjectType.SCMImpToolsPO_Stage__c.fields.getMap();
    private Map<String, Schema.SObjectField> headfs = Schema.SObjectType.SCMC__Purchase_Order__c.fields.getMap();
    private Map<String, Schema.SObjectField> linefs = Schema.SObjectType.SCMC__Purchase_Order_Line_Item__c.fields.getMap();
	
	global SCMImpToolsLoadPO() {
	}

    // this constructor is invoked from the multi select on the POStage object view
    public SCMImpToolsLoadPO(ApexPages.StandardSetController controller) {
    	this.setcontroller = controller;
	}
    
	public PageReference process() {
		Database.executeBatch(this, 100);
		// Get the sObject describe result for the Catalog Load object
		Schema.DescribeSObjectResult r = SCMC__Purchase_Order__c.sObjectType.getDescribe(); 
		String keyPrefix = r.getKeyPrefix();
		PageReference retPage = new PageReference('/' + keyPrefix + '/o');
		
		return retPage;
	}
	
	public PageReference goback() {
		PageReference retPage = setController.cancel();
		return retPage;
	}
    global void execute(SchedulableContext ctx)
    {       
        // Start Batch Apex job to pull requests and create requisitions
        Database.executeBatch(new SCMImpToolsLoadPO());              
    }
   	global Database.QueryLocator start(Database.BatchableContext ctx)
   	{
        // Select all requests that don't yet have purchase orders loaded
        String queryPO = 'select id';
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
                queryPO += ', ' + f.getName();
            }
        }
        queryPO += ' from SCMImpToolsPO_Stage__c where Loaded__c = false ';
        queryPO += ' order by Existing_PO_Number__c, Existing_PO_Line_No__c';
        System.debug('query stage for loadPO ' + queryPO);
        SCMC__Purchase_Order__c porder = null;
        return Database.getQueryLocator(queryPO);
    }
    
   
    global void execute(Database.BatchableContext ctx, List<SObject> records){
    	Map<String, SCMC__Purchase_Order__c>po = 
    		new Map<String, SCMC__Purchase_Order__c>();
    	Map<String, List<SCMC__Purchase_Order_Line_Item__c>> lines =
    		new Map<String, List<SCMC__Purchase_Order_Line_Item__c>>();
    	String currPO = '';
    	Map<String, SCMC__Purchase_Order__c>existPO = new Map<String, SCMC__Purchase_Order__c>();
    	Map<String, SCMC__Item__c>items = new Map<String, SCMC__Item__c>();
        Map<String, SCMC__Currency_Master__c>currs = new Map<String, SCMC__Currency_Master__c>();
    	Map<String, SCMC__Warehouse__c> houses =  new Map<String, SCMC__Warehouse__c>();
    	Map<String, SCMC__Ownership_Code__c>owns = new Map<String, SCMC__Ownership_Code__c>();
    	Map<String, SCMC__Supplier_Site__c>sites =
    		new Map<String, SCMC__Supplier_Site__c>();
    	Map<String, Account>accounts = new Map<String, Account>();
        Map<String, SCMC__PO_Payment_Terms__c> pTerms = new Map<String, SCMC__PO_Payment_Terms__c>();
        Map<String, SCMC__Condition_Code__c> cCodes = new Map<String, SCMC__Condition_Code__c>();
 
    	Map<String, RecordType>potypes = new Map<String, RecordType>();
    	RecordType[]typelist = [select id, name, DeveloperName
    			from RecordType
    			where sobjectType = 'SCMC__Purchase_Order__c'];
    	for (RecordType typel : typelist){
    		potypes.put(typel.name, typel);
    	}

        Map<String, RecordType>poltypes = new Map<String, RecordType>();
        RecordType[]polTypelist = [select id, name, DeveloperName
                from RecordType
                where sobjectType = 'SCMC__Purchase_Order_Line_Item__c'];
        for (RecordType typel : polTypelist){
            poltypes.put(typel.name, typel);
        }

    	for (SObject record : records){
    		SCMImpToolsPO_Stage__c stage = (SCMImpToolsPO_Stage__c)record;
            stage.Error__c = false;
            stage.Error_Message__c = '';
    		items.put(stage.Item__c, null);
    		houses.put(stage.Ship_To_Warehouse__c, null);
    		owns.put(stage.Ownership__c, null);
      		String supplier = stage.Supplier__c;
    		sites.put(supplier, null);
    		accounts.put(stage.Procured_For__c, null);
    		existPO.put(stage.Existing_PO_Number__c, null);
            pTerms.put(stage.Payment_Terms__c, null);
            cCodes.put(stage.Condition__c, null);
    	}
        //we need this because in a batch we cannot be guaranteed that we got all of the lines
        //also if we need to correct data and rerun, we want corrected line to be added to existing PO
   	    List<SCMC__Purchase_Order__c>exPOs = [select id, SCMC__Existing_PO_Number__c from SCMC__Purchase_Order__c
    			where SCMC__Existing_PO_Number__c in :existPO.Keyset()];
    	for (SCMC__Purchase_Order__c exPO : exPOs){
    		existPO.put(exPO.SCMC__Existing_PO_Number__c, exPO);
    	}
    	List<SCMC__Currency_Master__c>cmasters = [select id
    			,name
    		from SCMC__Currency_Master__c
    		limit 500];
    	currs = new Map<String, SCMC__Currency_Master__c>();
    	for (SCMC__Currency_Master__c cm : cmasters){
    		currs.put(cm.name, cm);
    	}
    	List<SCMC__Item__c>lItems = [select id, name 
    			from SCMC__Item__c
    			where name in :items.keySet()];
    	for (SCMC__Item__c item : lItems){
    		items.put(item.name, item);
    	}
    	List<SCMC__Warehouse__c>house = [select id, name 
    			from SCMC__Warehouse__c
    			where name in :houses.keySet()];
    	for (SCMC__warehouse__c whouse : house){
    		houses.put(whouse.name, whouse);
    	}
     	List<SCMC__Ownership_Code__c>lowns = [select id, name 
    			from SCMC__Ownership_Code__c
    			where name in :owns.keySet()];
    	for (SCMC__Ownership_Code__c own : lowns){
    		owns.put(own.name, own);
    	}
     	List<SCMC__Supplier_Site__c>lSites = [select id, name 
    			from SCMC__Supplier_Site__c
    			where name in :sites.keySet()];
    	for (SCMC__supplier_Site__c site : lSites){
    		sites.put(site.name, site);
    	}
    	List<account>laccounts = [select id, name 
    			from Account
    			where name in :accounts.keySet()];
    	for (Account account : laccounts){
    		accounts.put(account.name, account);
    	}
    	SCMC__PO_Payment_Terms__c[] poTerms = [select id, SCMC__Terms_Name__c
	    		from SCMC__PO_Payment_Terms__c
	    		where SCMC__Terms_Name__c in :pTerms.Keyset()];
        for (SCMC__PO_Payment_Terms__c poTerm : poTerms){
            pTerms.put(poTerm.SCMC__Terms_Name__c, poTerm);
        }
    	SCMC__Condition_Code__c[] codes = [select id, name from SCMC__Condition_Code__c
                where name in : cCodes.Keyset()];
    	for (SCMC__Condition_Code__c code : codes) {
            cCodes.put(code.name, code);
        }
     	

    	boolean headErr = false;
    	for (SObject record : records){
    		SCMImpToolsPO_Stage__c stage = (SCMImpToolsPO_Stage__c)record;
    		Integer lineNum = 0;
    		if (currPO != stage.Existing_PO_Number__c){
    			//we have the full PO start a new 
    			lineNum = 0;
    			currPO = stage.Existing_PO_Number__c;
    			headErr = false;
    			SCMC__Purchase_Order__c head = existPO.get(currPO);
    			if (head != null){
    				System.debug('PO already exists for ' + currPO);
    			} else {
    				System.debug('Creating new head for ' + currPO);
    				head = new SCMC__Purchase_Order__c();
                    Schema.SObjectField exist = headfs.get('SCMC__Existing_PO_Number__c');
                    if (exist != null){
                        head.put('SCMC__Existing_PO_Number__c', stage.Existing_PO_Number__c);
                    }
                    Schema.SObjectField exists = stagefs.get('Existing_SO_Number__c');
                    String so = '';
                    if (exists != null){
                        so = (String)stage.get('Existing_SO_Number__c');    
                        Schema.SObjectField existso = headfs.get('Existing_SO_Number__c');
                        if (existso != null){
                            head.put('Existing_SO_Number__c', so);
                        }  
                    }

	     			String supplier = stage.Supplier__c;
	    			SCMC__Supplier_Site__C site = sites.get(supplier);
	    			if (site == null){
	    				stage.Error__c = true;
	    				stage.Error_Message__c = 'Unknown supplier ' + supplier;
	    			}else {
	    				head.SCMC__Supplier_Site__c  = site.id;
	    			}
	    			SCMC__Warehouse__c thouse = houses.get(stage.Ship_to_Warehouse__c);
	    			if (thouse == null){
	    				stage.Error__c = true;
	    				stage.Error_Message__c = 'Unknown warehouse';
	    			}else {
	    				head.SCMC__Ship_To_Warehouse__c = thouse.id;
	    			}
	    			head.SCMC__Purchase_Order_Date__c = stage.PO_Date__c;
                    if (stage.Payment_Terms__c != null){
                        SCMC__PO_Payment_Terms__c term = pTerms.get(stage.Payment_Terms__c);
    	    			if (term == null){
    	    				stage.Error__c = true;
    	    				stage.Error_Message__c += stage.Payment_Terms__c + ' terms not defined';
    	    			} else {
    	    				head.SCMC__Payment_Terms__c = term.id;
    	    			}
                    }
                    if (stage.PO_Record_Type__c != null){
                        RecordType rtype = potypes.get(stage.PO_Record_Type__c);
                        if (rtype == null){
                            stage.Error__c = true;
                            stage.Error_Message__c += 'Unknown record type for header - ' + stage.PO_Record_Type__c;
                        } else {
                            head.RecordTypeId = rtype.id;
                            head.SCMC__Status__c = 'Open';
                            head.SCMC__Status_Change_Date__c = System.Today();
                            if (stage.PO_Record_Type__c.contains('Approved')){
                                head.SCMC__Status__c = 'Approved';
                            }
                        }
                    }
                    if (stage.Company__c != null){
					    head.put('SCMFFA__Company_Name__c', stage.Company__c);
                    }

	    			if (stage.ownership__c != null){
		    			SCMC__Ownership_Code__c owncode = owns.get(stage.ownership__c);
		    			if (owncode == null){
		    				stage.Error__c = true;
		    				stage.Error_Message__c += 'Unknown ownership ' + stage.ownership__c;
		    			} else {
		    				head.SCMC__Ownership__c = owncode.id;
		    			}
	    			}
                    if (stage.Procured_For__c != null) {
	    			    Account cust = accounts.get(stage.Procured_For__c);
	    			    if (cust == null){
                            stage.Error__c  = true;
                            stage.Error_Message__c += stage.Procured_For__c + ' unknown account';
                        } else {
	    				   head.SCMC__Procured_for__c = cust.id;
                        }
	    			}
	    			if (stage.Currency__c != null){
                        SCMC__Currency_Master__c curr = currs.get(stage.Currency__c);
                        if (curr == null){
                            stage.Error__c = true;
                            stage.Error_Message__c += 'Invalid currency ' + stage.Currency__c;
                        }else {
	    				   head.SCMC__Currency_Master__c = curr.id;	
                        }
	    			}
	    		}
	    		if (stage.Error__c){
	    			headErr = true;
	    		} else {
    				po.put(currPO, head);
	    			List<SCMC__Purchase_Order_Line_Item__c>poLines =
	    				new List<SCMC__Purchase_Order_Line_Item__c>();
	     			lines.put(currPO, poLines);	
	    		}
    		}
    		if (headErr){
    			stage.Error__c = true;
    		} else {
				List<SCMC__Purchase_Order_Line_Item__c>poLines =
					lines.get(currPO);
				//create line and add to list
				SCMC__Purchase_Order_Line_Item__c lItem =
					new SCMC__Purchase_Order_Line_Item__c();
				lItem.SCMC__Unit_Cost__c = stage.Unit_Cost__c;
				lItem.SCMC__Taxable__c = false;
				lItem.SCMC__Supplier_Current_Promise_Date__c = stage.Supplier_Commitment_Date__c;
				lItem.SCMC__Supplier_Commitment_Date__c = stage.Supplier_Commitment_Date__c;
				lItem.SCMC__Status__c = 'Open';
				lItem.SCMC__Status_Change_Date__c = System.Today();
				lItem.SCMC__Sales_Order_Line_Item__c = null;
				lItem.SCMC__Quantity__c = stage.Quantity__c;
				lItem.SCMC__Quantity_Received__c = 0;
				lItem.SCMC__Purchase_Order__c = null;
				lItem.SCMC__Line_Number__c = (++lineNum).format();
                Schema.SObjectField existl = stagefs.get('Existing_PO_Line_No__c');
                String lineno = '';
                if (existl != null){
                    lineno = String.valueOf(stage.get('Existing_PO_Line_No__c'));
                    Schema.SObjectField existline = linefs.get('Existing_PO_Line_No__c');
                    if (existline != null){
                        lItem.put('Existing_PO_Line_No__c', lineno);  
                    }  
                }

				SCMC__Item__c titem = items.get(stage.Item__c);
				if (tItem == null){
					stage.Error__c = true;
					stage.Error_Message__c = 'Unknown item ' + stage.Item__c;
				} else {
					lItem.SCMC__Item_Master__c = titem.id;
				}
                if (stage.Condition__c != null){
                    SCMC__Condition_Code__c ccode = cCodes.get(stage.Condition__c);
				    if (ccode == null){
					   stage.Error__c = true;
					   stage.Error_Message__c = 'Condition Code ' + stage.condition__c + ' is not known.';
				    } else {
					   lItem.SCMC__Condition_Code__c = ccode.id;
                    }
				}
                if (stage.PO_Line_Record_Type__c != null) {
                    RecordType rType = polTypes.get(stage.PO_Line_Record_Type__c);
                    if (rType == null) {
                        stage.Error__c = true;
                        stage.Error_Message__c = stage.PO_Line_Record_Type__c + ' unknown record type.';
                    } else {
				        lItem.RecordTypeId= rType.id;
                    }
                }
				if (!stage.Error__c){
					poLines.add(lItem);
				}
    		}
    			
       	}
       	Map<String,SCMC__Purchase_Order__c>insPO = new Map<String, SCMC__Purchase_Order__c>();
       	List<SCMC__Purchase_Order_Line_Item__c>inspolines = 
       		new List<SCMC__Purchase_Order_Line_Item__c>();
       	for (SObject record : records) {
    		SCMImpToolsPO_Stage__c stage = (SCMImpToolsPO_Stage__c)record;
    		if (stage.Error__c){
    			//skip past error lines
    			continue;
    		} else {
    			System.debug('Should not get here ' + stage.Existing_PO_Number__c);
    			insPO.put(stage.Existing_PO_Number__c,po.get(stage.Existing_PO_Number__c));
    		}
    		
       	}
       	System.debug('po to insert ' + insPO);
       	upsert insPO.values();
       	
       	for (String NSPO : lines.keyset()){
       		List<SCMC__Purchase_Order_Line_Item__c>nslines = 
       			lines.get(NSPO);
       		SCMC__Purchase_Order__c nsHead = po.get(NSPO);
       		for(SCMC__Purchase_Order_Line_Item__c nsline : nslines){
       			nsline.SCMC__Purchase_Order__c = nsHead.id;
       		}
       		inspolines.addall(nslines);
       	}
       	insert inspolines;
        for (SObject record : records){
    		SCMImpToolsPO_Stage__c stage = (SCMImpToolsPO_Stage__c)record;
    		if (stage.Error__c){
    			//skip past error lines
    			continue;
    		}
    		stage.Loaded__c = true;
        }
        update records;
    }
    
    global void finish(Database.BatchableContext ctx)
    {
    }

    private void setStageError(SCMImpToolsPO_Stage__c target, string message){
        target.Error__c = true;
        if(target.Error_Message__c != null){
            target.Error_Message__c += ', ' + message;
        }else{
            target.Error_Message__c = message;
        }
        system.debug('Stage error set: ' + message);
    }

   private Object getData(SCMImpToolsPO_Stage__c stage, String column) {
        Object retValue  = null;
        Schema.SObjectField sfield =  stagefs.get(column);  
        if (sfield !=  null){
            retValue = stage.get(column);
        }
        return retValue;
    }
    	
}