public class HLP_QuoteLineTrigger_UTL {
    // Method to handle ICB product notifications
    public static void notifyICBProducts(Map<Id, SBQQ__QuoteLine__c> newQuoteLines) {
        try {
            List<SBQQ__QuoteLine__c> icbQuoteLines = [
                SELECT Id, SBQQ__Quote__r.Name, SBQQ__Product__r.ICB__c, SBQQ__Quote__c, CreatedById
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Product__r.ICB__c = true
                AND Id IN :newQuoteLines.keySet()
            ];
            
            if (!icbQuoteLines.isEmpty()) {
                CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
                Map<String, Map<String, String>> quoteToCreatedByMap = new Map<String, Map<String, String>>();
                
                for (SBQQ__QuoteLine__c ql : icbQuoteLines) {
                    if (!quoteToCreatedByMap.containsKey(ql.SBQQ__Quote__c)) {
                        quoteToCreatedByMap.put(ql.SBQQ__Quote__c, new Map<String, String>{ql.SBQQ__Quote__r.Name => ql.CreatedById});
                    }
                }
                
                for (String quoteId : quoteToCreatedByMap.keySet()) {
                    Map<String, String> quoteData = quoteToCreatedByMap.get(quoteId);
                    for (String quoteName : quoteData.keySet()) {
                        Messaging.CustomNotification notification = new Messaging.CustomNotification();
                        notification.setTitle('ICB products in quote');
                        notification.setBody('Quote ' + quoteName + ' has ICB products. Please click on this notification to be directed to it.');
                        notification.setNotificationTypeId(notificationType.Id);
                        notification.setTargetId(quoteId);
                        notification.send(new Set<String>{quoteData.get(quoteName)});
                    }
                }
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.notifyICBProducts at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            
            CustomException.sendErrorNotification(ce);
        }
        
    }
    
    public static void allowCarryoverAddressData(String quoteId) {
        try {
            SBQQ__Quote__c quote = [SELECT Id, Carry_Address_From_Group__c 
                                    FROM SBQQ__Quote__c
                                    WHERE Id =: quoteId LIMIT 1];
            quote.Carry_Address_From_Group__c = true;
            update quote;
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.allowCarryoverAddressData at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }        
    }
    
    // Method to update addresses for products
    public static void updateAddresses(Id quoteId) {
        try {
            List<SBQQ__QuoteLineGroup__c> qlgList = [SELECT Id, Name, Quote_Address__r.A_Address__c
                                                     FROM SBQQ__QuoteLineGroup__c
                                                     WHERE SBQQ__Quote__c = :quoteId
                                                     AND Quote_Address__r.A_Address__c = true];
            
            if (!qlgList.isEmpty()) {
                Set<Id> qlgIds = new Set<Id>();
                for (SBQQ__QuoteLineGroup__c qlg : qlgList) {
                    qlgIds.add(qlg.Id);
                }
                List<SBQQ__QuoteLine__c> qlUpdateStatus = [SELECT Id, SBQQ__Group__r.Network_Status__c, SBQQ__Group__r.Facility__c
                                                           FROM SBQQ__QuoteLine__c
                                                           WHERE SBQQ__Group__c IN :qlgIds
                                                           AND Send_To_Connectbase__c = true];
                for (SBQQ__QuoteLine__c ql : qlUpdateStatus) {
                    ql.Network_Status__c = ql.SBQQ__Group__r.Network_Status__c;
                    ql.Facility__c = ql.SBQQ__Group__r.Facility__c;
                }
                update qlUpdateStatus;
                
                // Further processing to update bundle and required quote lines
                List<SBQQ__QuoteLine__c> updatedQuoteLines = processBundleAndRequiredQuoteLines(qlgIds);
                if (!updatedQuoteLines.isEmpty()) {
                    update updatedQuoteLines;
                }
            }
            List<SBQQ__QuoteLineGroup__c> qlgList2 = [SELECT Id, Name, Quote_Address__r.A_Address__c
                                                      FROM SBQQ__QuoteLineGroup__c
                                                      WHERE SBQQ__Quote__c = :quoteId
                                                      AND Quote_Address__r.A_Address__c = false];
            
            if (!qlgList2.isEmpty()) {
                Set<Id> qlgIds2 = new Set<Id>();
                for (SBQQ__QuoteLineGroup__c qlg : qlgList2) {
                    qlgIds2.add(qlg.Id);
                }
                
                List<SBQQ__QuoteLine__c> qlUpdateStatus = [SELECT Id, Network_Status__c,
                                                           Facility__c, Street__c,
                                                           City__c, State__c,
                                                           Country__c, Zip__c,
                                                           SBQQ__Group__r.Network_Status__c, 
                                                           SBQQ__Group__r.Facility__c, 
                                                           SBQQ__Group__r.Street__c, 
                                                           SBQQ__Group__r.City__c, 
                                                           SBQQ__Group__r.State__c,
                                                           SBQQ__Group__r.Country__c,
                                                           SBQQ__Group__r.Zip__c
                                                           FROM SBQQ__QuoteLine__c
                                                           WHERE SBQQ__Group__c IN :qlgIds2
                                                           AND Send_To_Connectbase__c = true];
                List<SBQQ__QuoteLine__c> qlUpdateLst = new List<SBQQ__QuoteLine__c>();
                for (SBQQ__QuoteLine__c ql : qlUpdateStatus) {
                    if (ql.SBQQ__Group__r.Network_Status__c != null) {
                        ql.Network_Status__c = ql.SBQQ__Group__r.Network_Status__c;  
                    }
                    if (ql.SBQQ__Group__r.Facility__c != null) {
                        ql.Facility__c = ql.SBQQ__Group__r.Facility__c;  
                    }
                    if (ql.SBQQ__Group__r.Street__c != null) {
                        ql.Street__c = ql.SBQQ__Group__r.Street__c;
                    }
                    if (ql.SBQQ__Group__r.City__c != null) {
                        ql.City__c = ql.SBQQ__Group__r.City__c;  
                    }
                    if (ql.SBQQ__Group__r.State__c != null) {
                        ql.State__c = ql.SBQQ__Group__r.State__c;  
                    }
                    if (ql.SBQQ__Group__r.Country__c != null) {
                        ql.Country__c = ql.SBQQ__Group__r.Country__c;  
                    }
                    if (ql.SBQQ__Group__r.Zip__c != null) {
                        ql.Zip__c = ql.SBQQ__Group__r.Zip__c;  
                    }
                    qlUpdateLst.add(ql);
                }
                
                update qlUpdateLst;
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.updateAddresses at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
    
    // Helper method to process bundle and required quote lines
    private static List<SBQQ__QuoteLine__c> processBundleAndRequiredQuoteLines(Set<Id> qlgIds) {
        try {
            List<SBQQ__QuoteLine__c> updatedQuoteLines = new List<SBQQ__QuoteLine__c>();
            Map<Id, List<SBQQ__QuoteLine__c>> bundleIdToQuoteLinesMap = new Map<Id, List<SBQQ__QuoteLine__c>>();
            
            List<SBQQ__QuoteLine__c> bundleQuoteLines = [SELECT Id, SBQQ__Group__c, Send_To_Connectbase__c, SBQQ__Bundle__c, Network_Status__c,
                                                         SBQQ__Group__r.Quote_Address__r.Street__c,
                                                         SBQQ__Group__r.Quote_Address__r.City__c,
                                                         SBQQ__Group__r.Quote_Address__r.State__c,
                                                         SBQQ__Group__r.Quote_Address__r.Country__c,
                                                         SBQQ__Group__r.Quote_Address__r.Zip__c,
                                                         SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Street__c,
                                                         SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.City__c,
                                                         SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.State__c,
                                                         SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Country__c,
                                                         SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Zip__c
                                                         FROM SBQQ__QuoteLine__c
                                                         WHERE SBQQ__Group__c IN :qlgIds
                                                         AND SBQQ__Bundle__c = true];
            
            for (SBQQ__QuoteLine__c bundleQL : bundleQuoteLines) {
                if (!bundleIdToQuoteLinesMap.containsKey(bundleQL.Id)) {
                    bundleIdToQuoteLinesMap.put(bundleQL.Id, new List<SBQQ__QuoteLine__c>());
                }
                if (bundleQL.Send_To_Connectbase__c == true && bundleQL.Network_Status__c == 'Off Net') {
                    bundleIdToQuoteLinesMap.get(bundleQL.Id).add(bundleQL);
                }
            }
            
            List<SBQQ__QuoteLine__c> requiredQuoteLines = [SELECT Id, SBQQ__RequiredBy__c,
                                                           SBQQ__Group__r.Quote_Address__r.Network_Status__c,
                                                           SBQQ__Group__r.Quote_Address__r.Street__c,
                                                           SBQQ__Group__r.Quote_Address__r.City__c,
                                                           SBQQ__Group__r.Quote_Address__r.State__c,
                                                           SBQQ__Group__r.Quote_Address__r.Country__c,
                                                           SBQQ__Group__r.Quote_Address__r.Zip__c,
                                                           SBQQ__Group__r.Quote_Address__r.Facility__c,
                                                           SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Network_Status__c,
                                                           SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Street__c,
                                                           SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.City__c,
                                                           SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.State__c,
                                                           SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Country__c,
                                                           SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Zip__c,
                                                           SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Facility__c
                                                           FROM SBQQ__QuoteLine__c
                                                           WHERE Send_To_Connectbase__c = true
                                                           AND SBQQ__RequiredBy__c IN :bundleQuoteLines
                                                           AND Network_Status__c = 'Off Net'
                                                           ORDER BY SBQQ__Number__c];
            
            for (SBQQ__QuoteLine__c requiredQL : requiredQuoteLines) {
                bundleIdToQuoteLinesMap.get(requiredQL.SBQQ__RequiredBy__c).add(requiredQL);
            }
            
            for (Id bundleId : bundleIdToQuoteLinesMap.keySet()) {
                List<SBQQ__QuoteLine__c> quoteLines = bundleIdToQuoteLinesMap.get(bundleId);
                
                for (Integer i = 0; i < quoteLines.size(); i++) {
                    SBQQ__QuoteLine__c quoteLine = quoteLines[i].clone();
                    quoteLine.Id = quoteLines[i].Id;
                    if (Math.mod(i + 1, 2) == 1) {
                        quoteLine.Street__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.Street__c;
                        quoteLine.City__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.City__c;
                        quoteLine.State__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.State__c;
                        quoteLine.Country__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.Country__c;
                        quoteLine.Zip__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.Zip__c;
                    } else {
                        quoteLine.Street__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Street__c;
                        quoteLine.City__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.City__c;
                        quoteLine.State__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.State__c;
                        quoteLine.Country__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Country__c;
                        quoteLine.Zip__c = quoteLines[i].SBQQ__Group__r.Quote_Address__r.z_Quote_Address__r.Zip__c;
                    }
                    updatedQuoteLines.add(quoteLine);
                }
            }
            
            return updatedQuoteLines;
            
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.processBundleAndRequiredQuoteLines at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
    
    public static void nullCostingFields(List<SBQQ__QuoteLine__c> newQuoteLines, Map<Id, SBQQ__QuoteLine__c> oldQuoteLineMap) {
        try {
            Set<String> fieldsToTrack = new Set<String>();
            List<QuoteLineFieldTracker__mdt> fieldTrackers = 
                [SELECT Field_API_Name__c FROM QuoteLineFieldTracker__mdt];
            
            for (QuoteLineFieldTracker__mdt tracker : fieldTrackers) {
                fieldsToTrack.add(tracker.Field_API_Name__c);
            }
            
            for (SBQQ__QuoteLine__c newRecord : newQuoteLines) {
                SBQQ__QuoteLine__c oldRecord = oldQuoteLineMap.get(newRecord.Id);
                
                if (hasTrackedFieldChanged(newRecord, oldRecord, fieldsToTrack) && newRecord.Receive_From_Connectbase__c == true) {
                    newRecord.SBQQ__UnitCost__c = null;
                    newRecord.NRC_Unit_Cost__c = null;
                    newRecord.Provider__c = null;
                    newRecord.Media_Type__c = null;
                    newRecord.Received_Download_Speed__c = null;
                    newRecord.Received_Upload_Speed__c = null;
                    newRecord.Costing_Status__c = null;
                    newRecord.Access_Ordering_Instructions__c = null;
                    newRecord.SBQQ__ListPrice__c = null;
                    newRecord.NRC_List_Unit_Price__c = null;
                }
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.nullCostingFields at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
    
    // Helper method to check if any tracked field has changed
    private static Boolean hasTrackedFieldChanged(SBQQ__QuoteLine__c newRecord, SBQQ__QuoteLine__c oldRecord, Set<String> fieldsToTrack) {
        try {
            for (String fieldName : fieldsToTrack) {
                Object oldValue = oldRecord.get(fieldName);
                Object newValue = newRecord.get(fieldName);
                
                if (oldValue != newValue) {
                    return true;
                }
            }
            return false;
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.hasTrackedFieldChanged at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
        
    }
    
    public static void markAsChanged(List<SBQQ__QuoteLine__c> newQuoteLines, Map<Id, SBQQ__QuoteLine__c> oldQuoteLineMap) {
        try {
            Set<String> fieldsToTrack = new Set<String>();
            List<QuoteLineFieldTracker__mdt> fieldTrackers = 
                [SELECT Field_API_Name__c FROM QuoteLineFieldTracker__mdt];
            
            for (QuoteLineFieldTracker__mdt tracker : fieldTrackers) {
                fieldsToTrack.add(tracker.Field_API_Name__c);
            }
            fieldsToTrack.add('Street__c');
            fieldsToTrack.add('City__c');
            fieldsToTrack.add('State__c');
            fieldsToTrack.add('Country__c');
            fieldsToTrack.add('Zip__c');
            for (SBQQ__QuoteLine__c newRecord : newQuoteLines) {
                SBQQ__QuoteLine__c oldRecord = oldQuoteLineMap.get(newRecord.Id);
                
                if (hasTrackedFieldChanged(newRecord, oldRecord, fieldsToTrack) && newRecord.Receive_From_Connectbase__c == true) {
                    newRecord.Is_Amended_Line__c = true;
                }
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.markAsChanged at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
    
    // Method to add groups for amendments/renewals
    public static void createAmendGroups(String newQuoteId) {
        try {
            SBQQ__Quote__c quoteRecord = [
                SELECT 
                SBQQ__Type__c, 
                SBQQ__MasterContract__r.SBQQ__Quote__c, 
                SBQQ__MasterContract__r.SBQQ__Quote__r.SBQQ__Opportunity2__c,
                SBQQ__Opportunity2__c, Is_Costed__c,
                SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__c,
                SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r.SBQQ__Opportunity2__c
                FROM SBQQ__Quote__c
                WHERE Id =: newQuoteId
                LIMIT 1
            ];
            
            String previousQuote = '';
            String previousQuoteOpportunityId = '';
            String quoteOpportunityId = quoteRecord.SBQQ__Opportunity2__c;
            
            if (quoteRecord.SBQQ__Type__c == 'Amendment') {
                // Fetch previous quote from Master Contract
                if (quoteRecord.SBQQ__MasterContract__r != null && 
                    quoteRecord.SBQQ__MasterContract__r.SBQQ__Quote__r != null) {
                        
                        previousQuote = quoteRecord.SBQQ__MasterContract__r.SBQQ__Quote__c;
                        previousQuoteOpportunityId = quoteRecord.SBQQ__MasterContract__r.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                    }
            } else if (quoteRecord.SBQQ__Type__c == 'Renewal') {
                // Fetch previous quote from Renewed Contract
                if (quoteRecord.SBQQ__Opportunity2__r != null && 
                    quoteRecord.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r != null &&
                    quoteRecord.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r != null) {
                        
                        previousQuote = quoteRecord.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__c;
                        previousQuoteOpportunityId = quoteRecord.SBQQ__Opportunity2__r.SBQQ__RenewedContract__r.SBQQ__Quote__r.SBQQ__Opportunity2__c;
                    }
            }
            
            
            // Fetch Quote Lines associated with the new Quote
            List < SBQQ__QuoteLine__c > quoteLines = [
                SELECT Id, SBQQ__ComponentCost__c, SBQQ__PackageCost__c, SBQQ__ProductName__c,
                SBQQ__Quantity__c, SBQQ__ListPrice__c, Street__c, City__c, Site_Bandwidth_Mbps__c, SBQQ__UpgradedSubscription__r.SBQQ__OriginalQuoteLine__r.SBQQ__Group__c,SBQQ__RenewedSubscription__r.SBQQ__OriginalQuoteLine__r.SBQQ__Group__c
                FROM SBQQ__QuoteLine__c
                WHERE SBQQ__Quote__c =: newQuoteId
            ];
            
            // Fetch Quote Line Groups associated with the previous Quote
            List < SBQQ__QuoteLineGroup__c > quoteLineGroups = [
                SELECT Id, Name, SBQQ__Quote__c, Street__c, City__c, State__c, Country__c, Zip__c,
                Network_Status__c, Facility__c, Quote_Address__c,SBQQ__Quote__r.External_Connectbase_Id__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE SBQQ__Quote__c =: previousQuote
            ];
            
            System.debug('Mapping >>>> ' + quoteLineGroups);
            Map < String, String > groupIdVsKeyMap = new Map < String, String > ();
            
            for (SBQQ__QuoteLineGroup__c quotelinegroup: quoteLineGroups) {
                groupIdVsKeyMap.put(quotelinegroup.id, quotelinegroup.Name + quotelinegroup.Street__c + quotelinegroup.City__c + quotelinegroup.State__c + quotelinegroup.Country__c + quotelinegroup.Zip__c + quotelinegroup.Network_Status__c + quotelinegroup.Facility__c);
            }
            
            System.debug('groupIdVsKeyMap' + groupIdVsKeyMap);
            
            if (quoteOpportunityId == previousQuoteOpportunityId) {
                
                List < SBQQ__QuoteLineGroup__c > insertQuoteLineGroups = new List < SBQQ__QuoteLineGroup__c > ();
                
                for (SBQQ__QuoteLineGroup__c quotelineGroup: quoteLineGroups) {
                    SBQQ__QuoteLineGroup__c lineGroup = quotelineGroup.clone(false, false, false, false);
                    lineGroup.SBQQ__Quote__c = newQuoteId;
                    insertQuoteLineGroups.add(lineGroup);
                }                
                insert insertQuoteLineGroups;

              /* List < SBQQ__QuoteLineGroup__c > insertQuoteLineGroups = [SELECT Id,Name,Street__c,City__c,State__c,Country__c,Zip__c,Network_Status__c,Facility__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c =: newQuoteId  ];*/
                Map < String, String > oldgroupidVsNewgroupId = new Map < String, String > ();
                
                for (SBQQ__QuoteLineGroup__c newGroup: insertQuoteLineGroups) {
                    // Construct the key for the new group
                    String newKey = newGroup.Name + newGroup.Street__c + newGroup.City__c + newGroup.State__c + newGroup.Country__c + newGroup.Zip__c +
                        newGroup.Network_Status__c + newGroup.Facility__c;
                    
                    // Find the matching old ID from groupIdVsKeyMap
                    for (String oldId: groupIdVsKeyMap.keySet()) {
                        // If a match is found and oldgroupidVsNewgroupId does NOT already contain oldId, add it
                        if (groupIdVsKeyMap.get(oldId).contains(newKey) && !oldgroupidVsNewgroupId.containsKey(oldId)) {
                            oldgroupidVsNewgroupId.put(oldId, newGroup.Id);
                        }
                    }
                }
                
                System.debug('oldgroupidVsNewgroupId' + oldgroupidVsNewgroupId);
                System.debug('oldgroupidVsNewgroupId size' + oldgroupidVsNewgroupId.size());
                
                //System.debug('quoteLineGroupMap===>' + quoteLineGroupMap);
                
                // Update Quote Lines with new Quote Line Group IDs
                List < SBQQ__QuoteLine__c > updateQuoteLine = new List < SBQQ__QuoteLine__c > ();
                
                Set<Id> missingGroupQuoteLines = new Set<Id>();
                
                for (SBQQ__QuoteLine__c lineItem : quoteLines) {
                    lineItem.SBQQ__Group__c = (quoteRecord.SBQQ__Type__c == 'Renewal') 
                        ? oldgroupidVsNewgroupId.get(lineItem.SBQQ__RenewedSubscription__r.SBQQ__OriginalQuoteLine__r.SBQQ__Group__c) 
                        : oldgroupidVsNewgroupId.get(lineItem.SBQQ__UpgradedSubscription__r.SBQQ__OriginalQuoteLine__r.SBQQ__Group__c);
                    
                    if (lineItem.SBQQ__Group__c == null) missingGroupQuoteLines.add(lineItem.Id);
                    updateQuoteLine.add(lineItem);
                }
                
                if (!missingGroupQuoteLines.isEmpty()) {
                    SBQQ__QuoteLineGroup__c defaultGroup = new SBQQ__QuoteLineGroup__c(Name = 'Default Group', SBQQ__Quote__c = quoteRecord.Id, SBQQ__Number__c = 1);
                    insert defaultGroup;
                    for (SBQQ__QuoteLine__c lineItem : updateQuoteLine) 
                        if (missingGroupQuoteLines.contains(lineItem.Id)) lineItem.SBQQ__Group__c = defaultGroup.Id;
                }
                
                if (!updateQuoteLine.isEmpty()) update updateQuoteLine;
                
                //To populate Re-fetch button
                quoteRecord.Is_Costed__c = true;
                update quoteRecord;
                
            } else {
                
                List < Quote_Address__c > simpleQuoteAddresses = new List < Quote_Address__c > ();
                List < Quote_Address__c > zQuoteAddresses = new List < Quote_Address__c > ();
                List < Quote_Address__c > aQuoteAddresses = new List < Quote_Address__c > ();
                Map < String, String > aTOzMapping = new Map < String, String > ();
                
                List < Quote_Address__c > previousQuoteAddresses = [Select id, Street__c, City__c, State__c, Country__c, Zip__c, Network_Status__c, Facility__c, A_Address__c, Z_Address__c, z_Quote_Address__c, z_Quote_Address__r.Street__c, z_Quote_Address__r.City__c,
                                                                    z_Quote_Address__r.State__c, z_Quote_Address__r.Country__c,
                                                                    z_Quote_Address__r.Zip__c from Quote_Address__c where Opportunity__c =: previousQuoteOpportunityId
                                                                   ];
                List < Quote_Address__c > newQuoteAddresses = [Select id, Street__c, City__c, State__c, Country__c, Zip__c, Network_Status__c, Facility__c, A_Address__c, Z_Address__c, z_Quote_Address__c, z_Quote_Address__r.Street__c, z_Quote_Address__r.City__c,
                                                               z_Quote_Address__r.State__c, z_Quote_Address__r.Country__c,
                                                               z_Quote_Address__r.Zip__c from Quote_Address__c where Opportunity__c =: quoteOpportunityId
                                                              ];
                Set<String> existingAddresses = new Set<String>();
                
                // Store existing addresses in a Set for quick lookup
                for (Quote_Address__c newAddress : newQuoteAddresses) {
                    String key = newAddress.Street__c + '|' + newAddress.City__c + '|' + 
                        newAddress.State__c + '|' + newAddress.Country__c + '|' + 
                        newAddress.Zip__c + '|' + newAddress.Network_Status__c + '|' + 
                        newAddress.Facility__c + '|' + newAddress.A_Address__c + '|' + 
                        newAddress.Z_Address__c + '|' + newAddress.z_Quote_Address__c + '|' + 
                        newAddress.z_Quote_Address__r.Street__c + '|' + newAddress.z_Quote_Address__r.City__c + '|' + 
                        newAddress.z_Quote_Address__r.State__c + '|' + newAddress.z_Quote_Address__r.Country__c + '|' + 
                        newAddress.z_Quote_Address__r.Zip__c;
                    
                    existingAddresses.add(key);
                }
                
                for (Quote_Address__c quoteAddress: previousQuoteAddresses) {
                    String key = quoteAddress.Street__c + '|' + quoteAddress.City__c + '|' + 
                        quoteAddress.State__c + '|' + quoteAddress.Country__c + '|' + 
                        quoteAddress.Zip__c + '|' + quoteAddress.Network_Status__c + '|' + 
                        quoteAddress.Facility__c + '|' + quoteAddress.A_Address__c + '|' + 
                        quoteAddress.Z_Address__c + '|' + quoteAddress.z_Quote_Address__c + '|' + 
                        quoteAddress.z_Quote_Address__r.Street__c + '|' + quoteAddress.z_Quote_Address__r.City__c + '|' + 
                        quoteAddress.z_Quote_Address__r.State__c + '|' + quoteAddress.z_Quote_Address__r.Country__c + '|' + 
                        quoteAddress.z_Quote_Address__r.Zip__c;
                    
                    if (!existingAddresses.contains(key)) {
                        if (!quoteAddress.Z_Address__c && !quoteAddress.A_Address__c) {
                            Quote_Address__c newQuoteAddress = new Quote_Address__c();
                            newQuoteAddress.Street__c = quoteAddress.Street__c;
                            newQuoteAddress.City__c = quoteAddress.City__c;
                            newQuoteAddress.State__c = quoteAddress.State__c;
                            newQuoteAddress.Country__c = quoteAddress.Country__c;
                            newQuoteAddress.Zip__c = quoteAddress.Zip__c;
                            newQuoteAddress.Opportunity__c = quoteOpportunityId;
                            newQuoteAddress.Network_Status__c = quoteAddress.Network_Status__c;
                            newQuoteAddress.Facility__c = quoteAddress.Facility__c;
                            newQuoteAddress.Z_Address__c = false;
                            newQuoteAddress.A_Address__c = false;
                            newQuoteAddress.Bypass_Trigger__c = true;
                            simpleQuoteAddresses.add(newQuoteAddress);
                            
                        } else if (quoteAddress.Z_Address__c && !quoteAddress.A_Address__c) {
                            Quote_Address__c newQuoteAddress = new Quote_Address__c();
                            newQuoteAddress.Street__c = quoteAddress.Street__c;
                            newQuoteAddress.City__c = quoteAddress.City__c;
                            newQuoteAddress.State__c = quoteAddress.State__c;
                            newQuoteAddress.Country__c = quoteAddress.Country__c;
                            newQuoteAddress.Zip__c = quoteAddress.Zip__c;
                            newQuoteAddress.Opportunity__c = quoteOpportunityId;
                            newQuoteAddress.Network_Status__c = quoteAddress.Network_Status__c;
                            newQuoteAddress.Facility__c = quoteAddress.Facility__c;
                            newQuoteAddress.Z_Address__c = true;
                            newQuoteAddress.A_Address__c = false;
                            newQuoteAddress.Bypass_Trigger__c = true;
                            zQuoteAddresses.add(newQuoteAddress);
                            
                        } else if (!quoteAddress.Z_Address__c && quoteAddress.A_Address__c) {
                            
                            String addressKey = quoteAddress.Street__c + '-' + quoteAddress.City__c + '-' + quoteAddress.State__c + '-' + quoteAddress.Country__c + '-' + quoteAddress.Zip__c;
                            String zaddressKey = quoteAddress.z_Quote_Address__r.Street__c + '-' + quoteAddress.z_Quote_Address__r.City__c + '-' + quoteAddress.z_Quote_Address__r.State__c + '-' + quoteAddress.z_Quote_Address__r.Country__c + '-' + quoteAddress.z_Quote_Address__r.Zip__c; 
                            
                            aTOzMapping.put(zaddressKey, addressKey);
                            
                        }  
                    }
                    
                    
                    
                }
                System.debug('aTOzMapping'+aTOzMapping);
                
                if ((simpleQuoteAddresses.size() > 0)) {
                    
                    insert simpleQuoteAddresses;
                }
                if ((zQuoteAddresses.size() > 0)) {
                    
                    insert zQuoteAddresses;
                }
                
                if ((zQuoteAddresses.size() > 0)) {
                    List < Quote_Address__c > insertedAddresses = new List < Quote_Address__c > ();
                    
                    insertedAddresses = [SELECT Id, Street__c, City__c, State__c, Country__c, Zip__c
                                         FROM Quote_Address__c
                                         WHERE CreatedDate = TODAY AND Z_Address__c = true AND Opportunity__c =: quoteOpportunityId ORDER BY CreatedDate DESC LIMIT: zQuoteAddresses.size()
                                        ];
                    System.debug('Z addresses size'+insertedAddresses.size());
                    for (Quote_Address__c quoteAddress: insertedAddresses) {
                        String key = quoteAddress.Street__c + '-' + quoteAddress.City__c + '-' + quoteAddress.State__c + '-' + quoteAddress.Country__c + '-' + quoteAddress.Zip__c;
                        
                        String[] aAddressArray = aTOzMapping.get(key).split('-');
                        
                        Quote_Address__c newQuoteAddress = new Quote_Address__c();
                        newQuoteAddress.Street__c = aAddressArray[0];
                        newQuoteAddress.City__c = aAddressArray[1];
                        newQuoteAddress.State__c = aAddressArray[2];
                        
                        newQuoteAddress.Country__c = aAddressArray[3];
                        newQuoteAddress.Zip__c = aAddressArray[4];
                        newQuoteAddress.Opportunity__c = quoteOpportunityId;
                        newQuoteAddress.Network_Status__c = 'Off Net';
                        newQuoteAddress.z_Quote_Address__c = quoteAddress.Id;
                        newQuoteAddress.Z_Address__c = false;
                        newQuoteAddress.A_Address__c = true;
                        newQuoteAddress.Bypass_Trigger__c = true;
                        aQuoteAddresses.add(newQuoteAddress);
                        
                    }
                    
                    if ((aQuoteAddresses.size() > 0)) {
                        insert aQuoteAddresses;
                    }
                }
                
                // Insert new Quote Line Groups
                Map < String, Id > quoteLineGroupMap = new Map < String, Id > ();
                List < SBQQ__QuoteLineGroup__c > insertQuoteLineGroups = new List < SBQQ__QuoteLineGroup__c > ();

                Integer totalinsertedAddresses = aQuoteAddresses.size()+zQuoteAddresses.size()+simpleQuoteAddresses.size();
                
                List < Quote_Address__c > insertedAddressForNewOpp = [SELECT Id, Street__c, City__c, State__c, Country__c, Zip__c, Network_Status__c, Facility__c, Z_Address__c, A_address__c, z_Quote_Address__c,
                                                                      z_Quote_Address__r.Street__c, z_Quote_Address__r.City__c,
                                                                      z_Quote_Address__r.State__c, z_Quote_Address__r.Country__c,
                                                                      z_Quote_Address__r.Zip__c
                                                                      FROM Quote_Address__c WHERE Opportunity__c =: quoteOpportunityId 
                                                                     ];
                
                for (Quote_Address__c address: insertedAddressForNewOpp) {
                    String groupName = '';
                    if (address.Network_Status__c == 'Off Net') {
                        
                        groupName = address.Street__c + ', ' + address.City__c;
                        if (address.A_address__c == true) {
                            
                            groupName += ' | ';
                            groupName += address.z_Quote_Address__r.Street__c + ', ' + address.z_Quote_Address__r.City__c;
                            
                            if (groupName.length() > 80) {
                                groupName = address.Street__c + ' | ' + address.z_Quote_Address__r.Street__c;
                            }
                        }
                        
                    } else {
                        groupName = address.Facility__c;
                    }
                    
                    if (address.Z_Address__c == false) {
                        
                        SBQQ__QuoteLineGroup__c lineGroup = new SBQQ__QuoteLineGroup__c();
                        lineGroup.Name = groupName;
                        lineGroup.Street__c = address.Street__c;
                        lineGroup.City__c = address.City__c;
                        lineGroup.State__c = address.State__c;
                        lineGroup.Country__c = address.Country__c;
                        lineGroup.Zip__c = address.Zip__c;
                        lineGroup.Network_Status__c = address.Network_Status__c;
                        lineGroup.Facility__c = address.Facility__c;
                        lineGroup.SBQQ__Quote__c = newQuoteId;
                        lineGroup.Quote_Address__c = address.Id;
                        insertQuoteLineGroups.add(lineGroup);
                    }
                }
                
                if (insertQuoteLineGroups.size() > 0) {
                    insert insertQuoteLineGroups;
                }
                
                Map < String, String > oldgroupidVsNewgroupId = new Map < String, String > ();
                
                for (SBQQ__QuoteLineGroup__c newGroup: insertQuoteLineGroups) {
                    // Construct the key for the new group
                    String newKey = newGroup.Name + newGroup.Street__c + newGroup.City__c + newGroup.State__c + newGroup.Country__c + newGroup.Zip__c +
                        newGroup.Network_Status__c + newGroup.Facility__c;
                    
                    // Find the matching old ID from groupIdVsKeyMap
                    for (String oldId: groupIdVsKeyMap.keySet()) {
                        // If a match is found and oldgroupidVsNewgroupId does NOT already contain oldId, add it
                        if (groupIdVsKeyMap.get(oldId).contains(newKey) && !oldgroupidVsNewgroupId.containsKey(oldId)) {
                            oldgroupidVsNewgroupId.put(oldId, newGroup.Id);
                        }
                    }
                }
                
                System.debug('oldgroupidVsNewgroupId' + oldgroupidVsNewgroupId);
                System.debug('oldgroupidVsNewgroupId size' + oldgroupidVsNewgroupId.size());
                
                //System.debug('quoteLineGroupMap===>' + quoteLineGroupMap);
                
                // Update Quote Lines with new Quote Line Group IDs
                List < SBQQ__QuoteLine__c > updateQuoteLine = new List < SBQQ__QuoteLine__c > ();
                
                Set<Id> missingGroupQuoteLines = new Set<Id>();
                
                for (SBQQ__QuoteLine__c lineItem : quoteLines) {
                    lineItem.SBQQ__Group__c = (quoteRecord.SBQQ__Type__c == 'Renewal') 
                        ? oldgroupidVsNewgroupId.get(lineItem.SBQQ__RenewedSubscription__r.SBQQ__OriginalQuoteLine__r.SBQQ__Group__c) 
                        : oldgroupidVsNewgroupId.get(lineItem.SBQQ__UpgradedSubscription__r.SBQQ__OriginalQuoteLine__r.SBQQ__Group__c);
                    
                    if (lineItem.SBQQ__Group__c == null) missingGroupQuoteLines.add(lineItem.Id);
                    updateQuoteLine.add(lineItem);
                }
                
                if (!missingGroupQuoteLines.isEmpty()) {
                    SBQQ__QuoteLineGroup__c defaultGroup = new SBQQ__QuoteLineGroup__c(Name = 'Default Group', SBQQ__Quote__c = quoteRecord.Id, SBQQ__Number__c = 1);
                    insert defaultGroup;
                    for (SBQQ__QuoteLine__c lineItem : updateQuoteLine) 
                        if (missingGroupQuoteLines.contains(lineItem.Id)) lineItem.SBQQ__Group__c = defaultGroup.Id;
                }
                
                if (!updateQuoteLine.isEmpty()) update updateQuoteLine;

                //To populate Re-fetch button
                quoteRecord.Is_Costed__c = true;
                update quoteRecord;
            }
        }
        catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in HLP_QuoteLineTrigger_UTL.createAmendGroups at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
}