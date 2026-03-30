public class API_SellCPQ_GetQuotes_QRY {
    
    @Future(callout=true)
    public static void getQuoteLines(Id opportunityId, Id originalUser){
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
        Opportunity opp = [Select Id, Name, MA_External_Quote_ID__c, Pricebook2Id  from Opportunity where Id =: opportunityId].get(0);
        
        //this callout has an unknown number of pages that need to be fetched in the more efficiently than flow.  
        String externalQuoteID = opp.MA_External_Quote_ID__c;
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        HttpResponse res = new HttpResponse();
        
        List<APIResponse> allLines = new List<APIResponse>();
        List<APIResponse> apiresp = new List<APIResponse>();
        Integer pageCount = 1;
        Boolean continueLoop = true;
        
        List<API_Response__c> successes = new List<API_Response__c>();
        
        try{
            //get all quote lines from SellCPQ for the quote
            
            while(continueLoop){
                String endpoint = getEndpoint(externalQuoteId, 1000, pageCount);
                
                req.setEndpoint(endpoint);
                req.setMethod('GET');
                
                System.debug(req);
                System.debug(res);
                res = http.send(req);
                System.debug(res.getBody());
                apiresp = (List<APIResponse>) JSON.deserialize(res.getBody(), List<APIResponse>.class);
                system.debug(apiresp.get(0));
                
                API_Response__c ar = new API_Response__c();
                ar.Method__c = 'GET'; 
                ar.Success__c = 'true';
                if(a_ORG.isSandbox){
                    ar.Endpoint__c = 'https://sellapi.oneneck-sandbox.quosalsell.com/api/quoteItems'; 
                }else{
                    ar.Endpoint__c = 'https://sellapi.quosalsell.com/api/quoteItems';                    
                }
                ar.Http_Request__c = req.getBody().left(32765);
                ar.Http_Response__c = res.getBody().left(32765); 
                ar.Status_Code__c = res.getStatusCode().toString(); 
                ar.Message__c = 'Quotelines successfully retreived from SellCPQ';
                ar.Wrapper__c = 'API_SellCPQ_GetQuotes_QRY.APIResponse';
                successes.add(ar);                
                
                if(apiresp.size() < 1000){
                    System.debug(apiresp.size());
                    allLines.addAll(apiresp);
                    continueLoop = false;
                } else {
                    System.debug(apiresp.size());
                    allLines.addAll(apiresp);
                    pageCount = pageCount + 1;
                    apiresp.clear();
                }
            }
        }catch(Exception e){
            API_Response__c ar = new API_Response__c();
            ar.Method__c = 'GET';
            ar.Success__c = 'false'; 
            if(a_ORG.isSandbox){
                ar.Endpoint__c = 'https://sellapi.oneneck-sandbox.quosalsell.com/api/quoteItems'; 
            }else{
                ar.Endpoint__c = 'https://sellapi.quosalsell.com/api/quoteItems';                    
            }
            System.debug('selected endpoint: ' + ar.Endpoint__c);
            ar.Http_Request__c = req.getBody().left(32765);
            ar.Http_Response__c = res.getBody().left(32765); 
            ar.Status_Code__c = res.getStatusCode().toString(); 
            ar.Message__c = e.getMessage(); 
            ar.Wrapper__c = 'API_SellCPQ_GetQuotes_QRY type: ' + e.getTypeName() + ' line: ' + e.getLineNumber();
            insert ar;
        }
        
        insert successes;
        
        //get all pricebook entry and product information relevant for the looped responses
        List<PricebookEntry> pricebookEntries = [select Id, Product2Id, Product2.Product_Class__c from PricebookEntry where PricebookEntry.Product2.Product_Class__c != null and Pricebook2Id =: opp.Pricebook2Id];
        List<String> tabList = new List<String>();
        Set<String> missingManufacturerPartNumber = new Set<String>();
        Set<String> noProductClass = new Set<String>();
        Set<String> noProductFound = new Set<String>();
        Set<String> doNOTorder = new Set<String>();
        String postText='';
        String bodyText;
        Boolean userMsg = false;
        
        List<OpportunityLineItem> oppProducts = new List<OpportunityLineItem>();
        
        for(APIResponse r : allLines){
            //create temp sort order of tabs
            Integer tabIndex = 0;
            if(tabList.contains(r.quoteTab.Id)){
                tabIndex = tabList.indexOf(r.quoteTab.Id);
            } else {
                tabList.add(r.quoteTab.Id);
                tabIndex = tabList.indexOf(r.quoteTab.Id);
            }
            
            //determine if item has a Product class and create product accordingly (or list for user notification)
            if(r.productClass != null && r.productClass != ''){
                //find corresponding pricebook entry
                String pricebookEntry = '';
                String product = '';
                for(PricebookEntry pbe : pricebookEntries){
                    if(pbe.Product2.Product_Class__c == r.productClass){
                        pricebookEntry = pbe.Id;
                        product = pbe.Product2Id;
                    }
                }
                if(pricebookEntry != ''){
                    
                    if(r.productClass == 'Professional Services' || r.productClass == 'Advanced Services' || r.zCustomBool1){
                        doNOTorder.add('Manufacturer Part Number: ' + r.manufacturerPartNumber + ', Description: ' + r.longDescription);
                        System.debug('do NOT order: Manufacturer Part Number: ' + r.manufacturerPartNumber + ', Description: ' + r.longDescription );
                    } else {
                        if(r.zCustomDate1 == null && r.zCustomDate2 == null){
                            OpportunityLineItem op = new OpportunityLineItem(City__c = r.zCustomString4, Country__c = r.zCustomString2, Description = r.longDescription, Extended_Cost__c = r.extendedCost, Item_Notes__c = r.zCustomNotes3,Manual_Sort_Order__c = sortOrder((r.sortOrder).toString(), tabIndex.toString()),Manufacturer_Name__c = r.sourceManufacturerName,Manufacturer_Part_Number__c = r.manufacturerPartNumber,NRC_Price__c = r.extendedPrice,OpportunityId = opp.Id,Ordering_Source_ID__c = r.sourceVendorId,Ordering_Source_Name__c = r.zCustomString12,Original_Customer_Purhase_Order__c = r.zCustomString13,PricebookEntryId = pricebookEntry,Product_Subcategory__c = r.productSubCategory,Product2Id = product,Quantity = r.quantity,Quote_Item_Price__c = r.quoteItemPrice,Recurring_Cost_c__c = r.recurringCost,Recurring_Price_c__c = r.recurringPrice,Recurring_Suggested_Price__c = r.recurringSuggestedPrice,Recurring_Total_c__c = r.recurringTotal,Serial_Number__c = r.zCustomString14,Service_Duration__c = r.zCustomNotes2,Special_Pricing__c = r.zCustomString9,State__c = r.zCustomString5,Street__c = r.zCustomString3,Suggested_Price__c = r.suggestedPrice,Supported_Product_Manufacturer_Name__c = r.zCustomString1,Unit_Cost__c = r.cost,Vendor_Quote_ID_Line__c = r.configId,Zip__c = r.zCustomString6);
                            oppProducts.add(op);   
                            System.debug('OpportunityLineItem no dates: ' + op);
                        } else if(r.zCustomDate1 == null){
                            OpportunityLineItem op = new OpportunityLineItem(End_Date__c = (r.zCustomDate2).Date(), City__c = r.zCustomString4, Country__c = r.zCustomString2, Description = r.longDescription, Extended_Cost__c = r.extendedCost, Item_Notes__c = r.zCustomNotes3,Manual_Sort_Order__c = sortOrder((r.sortOrder).toString(), tabIndex.toString()),Manufacturer_Name__c = r.sourceManufacturerName,Manufacturer_Part_Number__c = r.manufacturerPartNumber,NRC_Price__c = r.extendedPrice,OpportunityId = opp.Id,Ordering_Source_ID__c = r.sourceVendorId,Ordering_Source_Name__c = r.zCustomString12,Original_Customer_Purhase_Order__c = r.zCustomString13,PricebookEntryId = pricebookEntry,Product_Subcategory__c = r.productSubCategory,Product2Id = product,Quantity = r.quantity,Quote_Item_Price__c = r.quoteItemPrice,Recurring_Cost_c__c = r.recurringCost,Recurring_Price_c__c = r.recurringPrice,Recurring_Suggested_Price__c = r.recurringSuggestedPrice,Recurring_Total_c__c = r.recurringTotal,Serial_Number__c = r.zCustomString14,Service_Duration__c = r.zCustomNotes2,Special_Pricing__c = r.zCustomString9,State__c = r.zCustomString5,Street__c = r.zCustomString3,Suggested_Price__c = r.suggestedPrice,Supported_Product_Manufacturer_Name__c = r.zCustomString1,Unit_Cost__c = r.cost,Vendor_Quote_ID_Line__c = r.configId,Zip__c = r.zCustomString6);
                            oppProducts.add(op);   
                            System.debug('OpportunityLineItem begin date: ' + op);
                        } else if(r.zCustomDate2 == null){
                            OpportunityLineItem op = new OpportunityLineItem(Begin_Date__c = (r.zCustomDate1).Date(), City__c = r.zCustomString4, Country__c = r.zCustomString2, Description = r.longDescription, Extended_Cost__c = r.extendedCost, Item_Notes__c = r.zCustomNotes3,Manual_Sort_Order__c = sortOrder((r.sortOrder).toString(), tabIndex.toString()),Manufacturer_Name__c = r.sourceManufacturerName,Manufacturer_Part_Number__c = r.manufacturerPartNumber,NRC_Price__c = r.extendedPrice,OpportunityId = opp.Id,Ordering_Source_ID__c = r.sourceVendorId,Ordering_Source_Name__c = r.zCustomString12,Original_Customer_Purhase_Order__c = r.zCustomString13,PricebookEntryId = pricebookEntry,Product_Subcategory__c = r.productSubCategory,Product2Id = product,Quantity = r.quantity,Quote_Item_Price__c = r.quoteItemPrice,Recurring_Cost_c__c = r.recurringCost,Recurring_Price_c__c = r.recurringPrice,Recurring_Suggested_Price__c = r.recurringSuggestedPrice,Recurring_Total_c__c = r.recurringTotal,Serial_Number__c = r.zCustomString14,Service_Duration__c = r.zCustomNotes2,Special_Pricing__c = r.zCustomString9,State__c = r.zCustomString5,Street__c = r.zCustomString3,Suggested_Price__c = r.suggestedPrice,Supported_Product_Manufacturer_Name__c = r.zCustomString1,Unit_Cost__c = r.cost,Vendor_Quote_ID_Line__c = r.configId,Zip__c = r.zCustomString6);
                            oppProducts.add(op);  
                            System.debug('OpportunityLineItem end date: ' + op);
                        } else {
                            OpportunityLineItem op = new OpportunityLineItem(Begin_Date__c = (r.zCustomDate1).Date(), City__c = r.zCustomString4, Country__c = r.zCustomString2, Description = r.longDescription, End_Date__c = (r.zCustomDate2).Date(), Extended_Cost__c = r.extendedCost, Item_Notes__c = r.zCustomNotes3,Manual_Sort_Order__c = sortOrder((r.sortOrder).toString(), tabIndex.toString()),Manufacturer_Name__c = r.sourceManufacturerName,Manufacturer_Part_Number__c = r.manufacturerPartNumber,NRC_Price__c = r.extendedPrice,OpportunityId = opp.Id,Ordering_Source_ID__c = r.sourceVendorId,Ordering_Source_Name__c = r.zCustomString12,Original_Customer_Purhase_Order__c = r.zCustomString13,PricebookEntryId = pricebookEntry,Product_Subcategory__c = r.productSubCategory,Product2Id = product,Quantity = r.quantity,Quote_Item_Price__c = r.quoteItemPrice,Recurring_Cost_c__c = r.recurringCost,Recurring_Price_c__c = r.recurringPrice,Recurring_Suggested_Price__c = r.recurringSuggestedPrice,Recurring_Total_c__c = r.recurringTotal,Serial_Number__c = r.zCustomString14,Service_Duration__c = r.zCustomNotes2,Special_Pricing__c = r.zCustomString9,State__c = r.zCustomString5,Street__c = r.zCustomString3,Suggested_Price__c = r.suggestedPrice,Supported_Product_Manufacturer_Name__c = r.zCustomString1,Unit_Cost__c = r.cost,Vendor_Quote_ID_Line__c = r.configId,Zip__c = r.zCustomString6);
                            oppProducts.add(op);
                            System.debug('OpportunityLineItem all dates: ' + op);
                        }  
                    }
                    
                } else {
                    noProductFound.add('No Product Found for Product Class: ' + r.productClass);
                    bodyText = bodyText + ' | No Product Found for Product Class: ' + r.productClass;
                    postText = postText + '\nNo Product Found for Product Class: ' + r.productClass;
                    userMsg = true;
                    System.debug('No Product Found for Product Class: ' + r.productClass);
                }
                
            } else if(r.manufacturerPartNumber != null && r.manufacturerPartNumber != ''){
                missingManufacturerPartNumber.add('Description: ' + r.longDescription);
                bodyText = bodyText + ' | Missing Manufacturer Part Number: Description' + r.longDescription;
                postText = postText + '\nMissing Manufacturer Part Number: Description' + r.longDescription;
                userMsg = true;
                System.debug('Missing Manufacturer Part Number: Description' + r.longDescription);
            } else {
                if(r.manufacturerPartNumber == null && r.longDescription == null){
                    //skip blank lines
                }else{
                    noProductClass.add('Manufacturer Part Number: ' + r.manufacturerPartNumber + ', Description: ' + r.longDescription);
                    bodyText = bodyText + ' | No Product Class Found: Manufacturer Part Number: ' + r.manufacturerPartNumber + ', Description: ' + r.longDescription;   
                    postText = postText + '\nNo Product Class Found: Manufacturer Part Number: ' + r.manufacturerPartNumber + ', Description: ' + r.longDescription; 
                    userMsg = true;
                    System.debug('No Product Class Found: Manufacturer Part Number: ' + r.manufacturerPartNumber + ', Description: ' + r.longDescription);
                }
            }
        }
        
        List<OpportunityLineItem> existingToDelete = [Select Id from OpportunityLineItem where OpportunityId =: opp.Id];
        
        try{
            delete existingToDelete;
        }  catch (Exception e) {
            HLP_Case_SFQueue_Ins.createSFQueueCase('API_SellCPQ_GetQuotes_QRY', 'Unable to delete existing opportunity products: ' + e.getMessage(), 'Medium');
            bodyText = bodyText + ' | Unable to delete existing opportunity products: ' + e.getMessage();
            postText = postText + ' \nUnable to delete existing opportunity products: ' + e.getMessage();
            userMsg = true;
        }
        
        try{
            insert oppProducts;
        }  catch (Exception e) {
            HLP_Case_SFQueue_Ins.createSFQueueCase('API_SellCPQ_GetQuotes_QRY', 'Unable to insert refreshed opportunity products: ' + e.getMessage(), 'Medium');
            bodyText = bodyText + ' | Unable to insert refreshed opportunity products: ' + e.getMessage();
            postText = postText + ' \nUnable to insert refreshed opportunity products: ' + e.getMessage();
            userMsg = true;
        }
        
        if(userMsg){
            
            postText = 'Refresh Products process for Opportunity ' + opp.Id + ' has completed WITH ERRORS.\n' + postText;
            HLP_UserNotifications_Ins.chatterPostToRecordWithMentionTruncated(opp.Id, originalUser, postText, 9000);
            
            bodyText = postText + bodyText;
            //send note to user about refresh products process
            String userEmailAddress = [select email from User where Id =: originalUser].get(0).Email;
            List<String> toAddresses = new List<String>();
            toAddresses.add(userEmailAddress);
            
            String subject = 'Refresh Product Process Complete for: ' + opp.Name;
            
            //System.debug('email: toAddresses: ' + toAddresses + 'subject: ' + subject + 'bodyText: ' + bodyText);
            HLP_UserNotifications_Ins.sendCustomSingleEmailNoCC(toAddresses, 'noreply@ussignal.com', 'Salesforce No Reply', subject, bodyText);
        } else {
            postText = 'Refresh Products process for Opportunity ' + opp.Id + ' has completed without errors.';
            HLP_UserNotifications_Ins.chatterPostToRecordWithMentionTruncated(opp.Id, originalUser, postText, 9000);
        }
        
        
    }
    
    public static String getEndpoint(String quoteId, Integer pageSize, Integer pageNum){
        String endpoint = 'callout:SellCPQ_BasicAuth_NamedCredential/quoteItems?pageSize=' + pageSize + '&page=' + pageNum + '&conditions=idQuote%3D%22' + quoteId + '%22';
        return endpoint;    
    }
    
    public static String sortOrder(String sortOrder, String tabSortOrder){
        String manualSortOrder = '0000' + sortOrder;
        manualSortOrder = manualSortOrder.right(5);
        String manualTabOrder = '000' + tabSortOrder;
        manualTabOrder = manualTabOrder.right(4);
        return manualTabOrder + '-' + manualSortOrder;
    }
    
    public class APIResponse{
        Decimal approvalMarginMinimum;
        Boolean approvalOnChange;
        Decimal approvalPriceMinimum;
        Decimal basePrice;
        String configId;
        Decimal configPosition;
        Decimal cost;
        Decimal defermentPeriods;
        Boolean disableRemaps;
        Decimal discount;
        Decimal discountAmount;
        Decimal discountAmountConverted;
        Boolean enforceItemModTags;
        Decimal etilizeProductId;
        Decimal extendedCost;
        Decimal extendedPrice;
        Decimal extendedPriceConverted;
        Decimal extendedSuggestedPrice;
        Decimal factorQtyFixed;
        Decimal factorQtyMultiplier;
        Decimal federalGovPrice;
        Decimal grossMargin;
        Decimal gsaPrice;
        Decimal gst;
        Decimal gstConverted;
        Decimal gstRate;
        String id;
        String idQuote;
        String idQuoteTabs;
        Decimal invoiceGroupingId;
        Boolean isBundleComponent;
        Boolean isBundleHeader;
        Boolean isDeferrable;
        Boolean isHiddenItem;
        Boolean isMetadataItem;
        Boolean isModTagModified;
        Boolean isOptional;
        Boolean isOverrideQty;
        Boolean isPhaseItem;
        Boolean isPrinted;
        Boolean isPromotion;
        Boolean isProtectedItem;
        Boolean isProtectedPrice;
        Boolean isRampable;
        Boolean isRebate;
        Boolean isRecurringTaxable;
        Boolean isSelected;
        Boolean isShowPrice;
        Boolean isSold;
        Boolean isTaxable;
        Boolean isTotalsIncluded;
        Decimal itemCube;
        Decimal itemHeight;
        Decimal itemLength;
        Decimal itemWidth;
        String longDescription;
        String manufacturerPartNumber;
        Decimal markup;
        Datetime modifyDate;
        Decimal netCost;
        Decimal onHand;
        Decimal onHandWarehouse1;
        Decimal onHandWarehouse2;
        Decimal onOrder;
        Boolean optionLocked;
        Boolean overridePackageDetails;
        Decimal overridePrice;
        String owner;
        Decimal packagePrice;
        Decimal packageQty;
        Decimal priceConverted;
        String priceModifier;
        String productCategory;
        String productClass;
        String productSubCategory;
        Decimal pst;
        Decimal pstConverted;
        Decimal pstRate;
        Decimal quantity;
        QuoteObj quote;
        Decimal quoteItemPrice;
        QuoteTab quoteTab;
        Decimal rampPeriods;
        Decimal recurringAmount;
        Decimal recurringBasePrice;
        String recurringCalculatedPriceModifier;
        Decimal recurringCost;
        Decimal recurringExtendedCost;
        Decimal recurringExtendedSuggestedPrice;
        Decimal recurringGst;
        Decimal recurringPrice;
        Decimal recurringPst;
        Decimal recurringSuggestedPrice;
        Decimal recurringTax;
        Decimal recurringTotal;
        String shortDescription;
        Decimal sortOrder;
        String source;
        String sourceManufacturerName;
        String sourceVendorId;
        String sourceVendorName;
        Decimal startingCost;
        Decimal stateGovPrice;
        Decimal suggestedPrice;
        Decimal svcSpread;
        Decimal tax;
        String taxCode;
        Decimal taxConverted;
        Decimal taxRate;
        Decimal totalWeight;
        Decimal uomFactor;
        Decimal uomWeight;
        Decimal uopFactor;
        String userId;
        String vendorPartNumber;
        Boolean zCustomBool1;
        Boolean zCustomBool10;
        Boolean zCustomBool2;
        Boolean zCustomBool3;
        Boolean zCustomBool4;
        Boolean zCustomBool5;
        Boolean zCustomBool6;
        Boolean zCustomBool7;
        Boolean zCustomBool8;
        Boolean zCustomBool9;
        Datetime zCustomDate1;
        Datetime zCustomDate2;
        Decimal zCustomDecimal1;
        Decimal zCustomDecimal10;
        Decimal zCustomDecimal2;
        Decimal zCustomDecimal3;
        Decimal zCustomDecimal4;
        Decimal zCustomDecimal5;
        Decimal zCustomDecimal6;
        Decimal zCustomDecimal7;
        Decimal zCustomDecimal8;
        Decimal zCustomDecimal9;
        String zCustomNotes2;
        String zCustomNotes3;
        String zCustomString1;
        String zCustomString12;
        String zCustomString13;
        String zCustomString14;
        String zCustomString2;
        String zCustomString3;
        String zCustomString4;
        String zCustomString5;
        String zCustomString6;
        String zCustomString9;
    }
    public class QuoteObj{
        String id;
    }
    public class QuoteTab{
        String id;
    }
    
}