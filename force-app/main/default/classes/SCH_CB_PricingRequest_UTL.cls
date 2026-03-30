// SC-0000100
// Scheduled class to check for quotes to fetch costs from,
// and save them in CPQ if they exist
public with sharing class SCH_CB_PricingRequest_UTL implements Schedulable {
    public void execute(SchedulableContext sc) {
        callFutureMethod();
       // deleteCurrentJob(sc);
    }
    
    @future(callout=true)
    public static void callFutureMethod() {
        try {
            Map<String, Map<String, String>> qlIdToDetailsMap = new Map<String, Map<String, String>>();
            List<API_Response__c> arLst = new List<API_Response__c>();
            Integer counter = 0;
            List<Get_Pricing_Request__c> pricingList =  [SELECT Id, Connectbase_Quote_Id__c, SF_Quote__c, User__c, SF_Quote_Line_Ids__c, Page_Number__c, Total_Pages__c, Connectbase_Product__c,
                                                         (SELECT Id, Quote_Line__c, Receiver_Quote_Line__c, Provider__c, NRC__c, MRC__c, Media_Type__c, Download_Speed__c, Upload_Speed__c
                                                          FROM Quote_Line_Requests__r)
                                                         FROM Get_Pricing_Request__c
                                                         ORDER BY CreatedDate];
            
            List<String> allSenderQLIds = new List<String>();
            Map<Get_Pricing_Request__c, List<SBQQ__QuoteLine__c>> gprToQLList = new Map<Get_Pricing_Request__c, List<SBQQ__QuoteLine__c>>();
            for (Get_Pricing_Request__c pricing : pricingList) {
                List<String> qlMap = pricing.SF_Quote_Line_Ids__c.split(',');
                for (String ql : qlMap) {
                    allSenderQLIds.add(ql.split('=')[0]);
                }
                for (String qlId : pricing.SF_Quote_Line_Ids__c.split(',')) {
                    qlIdToDetailsMap.put(qlId.split('=')[0], new Map<String, String>{'mrc'=> null, 'nrc'=> null, 'provider'=> null, 'mediaType'=> null, 'id'=> null, 'receiverId'=> qlId.split('=')[1], 'upload' => null, 'download' => null});
                }
                List<Quote_Line_Request__c> qlrList = pricing.Quote_Line_Requests__r;
                for (Quote_Line_Request__c qlr : qlrList) {
                    qlIdToDetailsMap.get(qlr.Quote_Line__c).put('mrc', String.valueOf(qlr.MRC__c));
                    qlIdToDetailsMap.get(qlr.Quote_Line__c).put('nrc', String.valueOf(qlr.NRC__c));
                    qlIdToDetailsMap.get(qlr.Quote_Line__c).put('provider', qlr.Provider__c);
                    qlIdToDetailsMap.get(qlr.Quote_Line__c).put('download', String.valueOf(qlr.Download_Speed__c));
                    qlIdToDetailsMap.get(qlr.Quote_Line__c).put('upload', String.valueOf(qlr.Upload_Speed__c));
                    qlIdToDetailsMap.get(qlr.Quote_Line__c).put('id', qlr.Id);
                    qlIdToDetailsMap.get(qlr.Quote_Line__c).put('mediaType', qlr.Media_Type__c);
                }
                gprToQLList.put(pricing, new List<SBQQ__QuoteLine__c>());
            }
            /*for (String qlId : qlIdToDetailsMap.keySet()) {
				System.debug(qlIdToDetailsMap.get(qlId));
			}*/
            List<SBQQ__QuoteLine__c> allSenderQLs = [SELECT Id, SBQQ__Quote__c, Street__c, City__c, State__c, Zip__c, Country__c, Site_Bandwidth_Mbps__c
                                                     FROM SBQQ__QuoteLine__c
                                                     WHERE Id IN :allSenderQLIds];
            
            Map<String, Get_Pricing_Request__c> prMap = new Map<String, Get_Pricing_Request__c>();
            Map<String, Quote_Line_Request__c> qlrMap = new Map<String, Quote_Line_Request__c> ();
            
            if (pricingList.size() > 0) {
                for (Get_Pricing_Request__c gpr : gprToQLList.keySet()) {
                    for (SBQQ__QuoteLine__c ql : allSenderQLs) {
                        if (gpr.SF_Quote_Line_Ids__c.contains(ql.Id)) {
                            gprToQLList.get(gpr).add(ql);
                        }
                    }
                }
                for (Get_Pricing_Request__c gpr : gprToQLList.keySet()) {
                    for (SBQQ__QuoteLine__c ql : gprToQLList.get(gpr)) {
                        System.debug('gpr@@' + gpr + ' ql@@@' + ql);
                    }
                }
                for (Get_Pricing_Request__c pricing : gprToQLList.keySet()) {
                    String[] sfQuotelines = pricing.SF_Quote_Line_Ids__c.split(',');
                    String[] receiverQLs = new List<String>();
                    for (String ql : sfQuotelines) {
                        receiverQLs.add(ql.split('=')[1]);
                    }
                    API_CB_PricingModel_QRY.ApiResultWrapper apiWrapper = API_CB_PricingModel_QRY.getPricing(pricing.Connectbase_Quote_Id__c, receiverQLs, (Integer)pricing.Page_Number__c + 1, pricing.User__c);
                    if (apiWrapper != null) {
                        API_CB_PricingModel_QRY parsedResponse = apiWrapper.parsedResponse;
                        arLst.add(apiWrapper.apiResponse);
                        counter++;              
                        String status = parsedResponse.data.pricingStatus.transactionStatus;
                        if (status == 'Success' || status == 'Failed' || status == 'Completed with Errors') {
                            Integer totalPages = parsedResponse.pagination.totalPages;
                            if (totalPages == 0) {
                                List<SBQQ__QuoteLine__c> qlList = gprToQLList.get(pricing);
                                for (SBQQ__QuoteLine__c ql : qlList) {
                                    Map<String,String> details = qlIdToDetailsMap.get(ql.Id);
                                    Quote_Line_Request__c qlr = new Quote_Line_Request__c(Id = qlIdToDetailsMap.get(ql.Id).get('id'),
                                                                                          Get_Pricing_Request__c = pricing.id,
                                                                                          MRC__c = null,
                                                                                          NRC__c = null,
                                                                                          Provider__c = null,
                                                                                          Quote_Line__c = ql.Id,
                                                                                          Media_Type__c = null,
                                                                                          Receiver_Quote_Line__c = qlIdToDetailsMap.get(ql.Id).get('receiverId'),
                                                                                          Download_Speed__c = null,
                                                                                          Upload_Speed__c = null);
                                    qlrMap.put(ql.Id, qlr);
                                    
                                    details.put('mrc', null);
                                    details.put('nrc', null);
                                    details.put('provider', null);
                                    details.put('id', qlIdToDetailsMap.get(ql.Id).get('id'));
                                    details.put('receiverId', qlIdToDetailsMap.get(ql.Id).get('receiverId'));
                                    details.put('mediaType', null);
                                    details.put('download', null);
                                    details.put('upload', null);
                                    qlIdToDetailsMap.put(ql.Id, details);
                                }
                                Get_Pricing_Request__c gpr = new Get_Pricing_Request__c(Id = pricing.Id,
                                                                                        Page_Number__c = (Integer)pricing.Page_Number__c,
                                                                                        Total_Pages__c = totalPages, 
                                                                                        SF_Quote__c = pricing.SF_Quote__c,
                                                                                        Connectbase_Quote_Id__c = pricing.Connectbase_Quote_Id__c,
                                                                                        User__c = pricing.User__c);
                                prMap.put(pricing.Id, gpr);
                                continue;
                                
                            }
                            List<SBQQ__QuoteLine__c> qlList = gprToQLList.get(pricing);
                            Map<SBQQ__QuoteLine__c, List<API_CB_PricingModel_QRY.cls_prices>> responseMap = new Map<SBQQ__QuoteLine__c, List<API_CB_PricingModel_QRY.cls_prices>>(); //sender
                            for (SBQQ__QuoteLine__c ql : qlList) {
                                responseMap.put(ql, new List<API_CB_PricingModel_QRY.cls_prices>());
                            }
                            for (SBQQ__QuoteLine__c ql : responseMap.keySet()) {
                                for (API_CB_PricingModel_QRY.cls_prices price : parsedResponse.data.pricingStatus.prices) {
                                    if (price.status != 'Location fallout: prices not found') {
                                        if (pricing.Connectbase_Product__c == 'Broadband') {
                                            if (price.address.equalsIgnoreCase(ql.Street__c) &&
                                                price.city.equalsIgnoreCase(ql.City__c) &&
                                                price.state.equalsIgnoreCase(ql.State__c) &&
                                                price.zip.equalsIgnoreCase(ql.Zip__c) &&
                                                price.downloadSpeed >= ql.Site_Bandwidth_Mbps__c) {
                                                    responseMap.get(ql).add(price); 
                                                }
                                        }
                                        else if (pricing.Connectbase_Product__c == 'Ethernet - Switched') {
                                            if (price.address.equalsIgnoreCase(ql.Street__c) &&
                                                price.city.equalsIgnoreCase(ql.City__c) &&
                                                price.state.equalsIgnoreCase(ql.State__c) &&
                                                price.zip.equalsIgnoreCase(ql.Zip__c) &&
                                                price.downloadSpeed >= ql.Site_Bandwidth_Mbps__c &&
                                                price.downloadSpeed <= ql.Site_Bandwidth_Mbps__c + 500) {
                                                    responseMap.get(ql).add(price); 
                                                }
                                        }
                                        else {
                                            if (price.address.equalsIgnoreCase(ql.Street__c) &&
                                                price.city.equalsIgnoreCase(ql.City__c) &&
                                                price.state.equalsIgnoreCase(ql.State__c) &&
                                                price.zip.equalsIgnoreCase(ql.Zip__c) &&
                                                price.downloadSpeed == ql.Site_Bandwidth_Mbps__c &&
                                                price.uploadSpeed == ql.Site_Bandwidth_Mbps__c) {
                                                    responseMap.get(ql).add(price); 
                                                }
                                        } 
                                    }
                                }
                            }
                            System.debug('responseMap@@@' + responseMap);
                            for (SBQQ__QuoteLine__c ql : responseMap.keySet()) {
                                Map<String,String> details = qlIdToDetailsMap.get(ql.Id);
                                List<API_CB_PricingModel_QRY.cls_prices> prices = responseMap.get(ql);
                                Decimal lowestMrc = details != null && details.get('mrc') != null ? Decimal.valueOf(details.get('mrc')) : null;
                                Decimal nrc = details != null && details.get('nrc') != null ? Decimal.valueOf(details.get('nrc')) : null;
                                Integer download = details != null && details.get('download') != null ? Integer.valueOf(details.get('download')) : null;
                                Integer upload = details != null && details.get('upload') != null ? Integer.valueOf(details.get('upload')) : null;
                                String provider = details != null && details.get('provider') != null ? details.get('provider') : null;
                                String mediaType = details != null && details.get('mediaType') != null ? details.get('mediaType') : null;
                                for (API_CB_PricingModel_QRY.cls_prices price : prices) {
                                    if (provider == 'US SIGNAL') {
                                        break;
                                    }
                                    if (lowestMrc == null || price.mrcTotalPrice < lowestMrc) {
                                        lowestMrc = price.mrcTotalPrice;
                                        nrc = price.nrcTotalPrice;
                                        provider = price.provider;
                                        mediaType = price.mediaType;
                                        download = price.downloadSpeed;
                                        upload = price.uploadSpeed;
                                        
                                    }
                                    if (price.provider == 'US SIGNAL') {
                                        lowestMrc = 0;
                                        nrc = 0;
                                        provider = price.provider;
                                        mediaType = price.mediaType;
                                        download = price.downloadSpeed;
                                        upload = price.uploadSpeed;
                                        break;
                                    }
                                }
                                Quote_Line_Request__c qlr = new Quote_Line_Request__c(Id = qlIdToDetailsMap.get(ql.Id).get('id'),
                                                                                      Get_Pricing_Request__c = Pricing.id,
                                                                                      MRC__c = lowestMrc,
                                                                                      NRC__c = nrc,
                                                                                      Provider__c = provider,
                                                                                      Quote_Line__c = ql.Id,
                                                                                      Media_Type__c = mediaType,
                                                                                      Receiver_Quote_Line__c = qlIdToDetailsMap.get(ql.Id).get('receiverId'),
                                                                                      Download_Speed__c = download,
                                                                                      Upload_Speed__c = upload);
                                
                                qlrMap.put(ql.Id, qlr);
                                details.put('mrc', String.valueOf(lowestMrc));
                                details.put('nrc', String.valueOf(nrc));
                                details.put('provider', provider);
                                details.put('id', qlIdToDetailsMap.get(ql.Id).get('id'));
                                details.put('receiverId', qlIdToDetailsMap.get(ql.Id).get('receiverId'));
                                details.put('mediaType', mediaType);
                                details.put('download', String.valueOf(download));
                                details.put('upload', String.valueOf(upload));
                                qlIdToDetailsMap.put(ql.Id, details);
                            }
                            System.debug('qlIdToDetailsMap@@@' + qlIdToDetailsMap);
                            
                            Get_Pricing_Request__c gpr = new Get_Pricing_Request__c(Id = pricing.Id,
                                                                                    Page_Number__c = (Integer)pricing.Page_Number__c + 1,
                                                                                    Total_Pages__c = totalPages, 
                                                                                    SF_Quote__c = pricing.SF_Quote__c,
                                                                                    Connectbase_Quote_Id__c = pricing.Connectbase_Quote_Id__c,
                                                                                    User__c = pricing.User__c);
                            prMap.put(pricing.Id, gpr);
                            System.debug('counter 0@@@' + counter);
                            if(counter >= 25) {
                                break;
                            }
                            
                            for (Integer i = (Integer)pricing.Page_Number__c + 2; i <= totalPages; i++) {
                                System.debug('inside for page number@@@' + i);
                                API_CB_PricingModel_QRY.ApiResultWrapper apiWrapperLoop = API_CB_PricingModel_QRY.getPricing(pricing.Connectbase_Quote_Id__c, receiverQLs, i, pricing.User__c);
                                if (apiWrapperLoop != null) {
                                    API_CB_PricingModel_QRY parsedRespo = apiWrapperLoop.parsedResponse;
                                    arLst.add(apiWrapperLoop.apiResponse);
                                    counter++;
                                    
                                    Map<SBQQ__QuoteLine__c, List<API_CB_PricingModel_QRY.cls_prices>> respoMap = new Map<SBQQ__QuoteLine__c, List<API_CB_PricingModel_QRY.cls_prices>>();
                                    for (SBQQ__QuoteLine__c ql : qlList) {
                                        respoMap.put(ql, new List<API_CB_PricingModel_QRY.cls_prices>());
                                    }
                                    for (SBQQ__QuoteLine__c ql : respoMap.keySet()) {
                                        for (API_CB_PricingModel_QRY.cls_prices price : parsedRespo.data.pricingStatus.prices) {
                                            if (price.status != 'Location fallout: prices not found') {
                                                if (pricing.Connectbase_Product__c == 'Broadband') {
                                                    if (price.address.equalsIgnoreCase(ql.Street__c) &&
                                                        price.city.equalsIgnoreCase(ql.City__c) &&
                                                        price.state.equalsIgnoreCase(ql.State__c) &&
                                                        price.zip.equalsIgnoreCase(ql.Zip__c) &&
                                                        price.downloadSpeed >= ql.Site_Bandwidth_Mbps__c) {
                                                            respoMap.get(ql).add(price); 
                                                        }
                                                }
                                                else if (pricing.Connectbase_Product__c == 'Ethernet - Switched') {
                                                    if (price.address.equalsIgnoreCase(ql.Street__c) &&
                                                        price.city.equalsIgnoreCase(ql.City__c) &&
                                                        price.state.equalsIgnoreCase(ql.State__c) &&
                                                        price.zip.equalsIgnoreCase(ql.Zip__c) &&
                                                        price.downloadSpeed >= ql.Site_Bandwidth_Mbps__c &&
                                                        price.downloadSpeed <= ql.Site_Bandwidth_Mbps__c + 500) {
                                                            respoMap.get(ql).add(price); 
                                                        }
                                                }
                                                else {
                                                    if (price.address.equalsIgnoreCase(ql.Street__c) &&
                                                        price.city.equalsIgnoreCase(ql.City__c) &&
                                                        price.state.equalsIgnoreCase(ql.State__c) &&
                                                        price.zip.equalsIgnoreCase(ql.Zip__c) &&
                                                        price.downloadSpeed == ql.Site_Bandwidth_Mbps__c &&
                                                        price.uploadSpeed == ql.Site_Bandwidth_Mbps__c) {
                                                            respoMap.get(ql).add(price); 
                                                        }
                                                } 
                                            }
                                        }
                                    }
                                    System.debug('respoMap@@@' + respoMap);
                                    for (SBQQ__QuoteLine__c ql : respoMap.keySet()) {
                                        Map<String,String> details = qlIdToDetailsMap.get(ql.Id);
                                        List<API_CB_PricingModel_QRY.cls_prices> prices = respoMap.get(ql);
                                        Decimal lowestMrc = details != null && details.get('mrc') != null ? Decimal.valueOf(details.get('mrc')) : null;
                                        Decimal nrc = details != null && details.get('nrc') != null ? Decimal.valueOf(details.get('nrc')) : null;
                                        Integer download = details != null && details.get('download') != null ? Integer.valueOf(details.get('download')) : null;
                                        Integer upload = details != null && details.get('upload') != null ? Integer.valueOf(details.get('upload')) : null;
                                        String provider = details != null && details.get('provider') != null ? details.get('provider') : null;
                                        String mediaType = details != null && details.get('mediaType') != null ? details.get('mediaType') : null;
                                        for (API_CB_PricingModel_QRY.cls_prices price  : prices) {
                                            if (provider == 'US SIGNAL') {
                                                break;
                                            }
                                            if (lowestMrc == null || price.mrcTotalPrice < lowestMrc) {
                                                lowestMrc = price.mrcTotalPrice;
                                                nrc = price.nrcTotalPrice;
                                                provider = price.provider;
                                                mediaType = price.mediaType;
                                                download = price.downloadSpeed;
                                                upload = price.uploadSpeed;
                                            }
                                            if (price.provider == 'US SIGNAL') {
                                                lowestMrc = 0;
                                                nrc = 0;
                                                provider = price.provider;
                                                mediaType = price.mediaType;
                                                download = price.downloadSpeed;
                                                upload = price.uploadSpeed;
                                                break;
                                            }
                                        }
                                        
                                        Quote_Line_Request__c qlr = new Quote_Line_Request__c(Id = qlIdToDetailsMap.get(ql.Id).get('id'),
                                                                                              Get_Pricing_Request__c = pricing.Id,
                                                                                              MRC__c=lowestMrc,
                                                                                              NRC__c=nrc,
                                                                                              Provider__c=provider,
                                                                                              Quote_Line__c=ql.Id,
                                                                                              Media_Type__c = mediaType,
                                                                                              Receiver_Quote_Line__c = qlIdToDetailsMap.get(ql.Id).get('receiverId'),
                                                                                              Download_Speed__c = download,
                                                                                              Upload_Speed__c = upload
                                                                                             );
                                        qlrMap.put(ql.Id,qlr);
                                        details.put('mrc', String.valueOf(lowestMrc));
                                        details.put('nrc', String.valueOf(nrc));
                                        details.put('provider', provider);
                                        details.put('id', qlIdToDetailsMap.get(ql.Id).get('id'));
                                        details.put('receiverId', qlIdToDetailsMap.get(ql.Id).get('receiverId'));
                                        details.put('mediaType', mediaType);
                                        details.put('download', String.valueOf(download));
                                        details.put('upload', String.valueOf(upload));
                                        qlIdToDetailsMap.put(ql.Id, details);
                                    }
                                    System.debug('qlIdToDetailsMap@@@' + qlIdToDetailsMap);
                                    
                                    Get_Pricing_Request__c gpr2 = new Get_Pricing_Request__c(Id = pricing.Id,
                                                                                             Page_Number__c = i,
                                                                                             Total_Pages__c = totalPages, 
                                                                                             SF_Quote__c = pricing.SF_Quote__c,
                                                                                             Connectbase_Quote_Id__c = pricing.Connectbase_Quote_Id__c,
                                                                                             User__c = pricing.User__c);
                                    prMap.put(pricing.Id, gpr2);
                                    if(counter>= 25){
                                        System.debug('counter 2@@@' + counter);
                                        break;
                                    }  
                                }
                                
                            }
                            if(counter>= 25){
                                System.debug('counter 2@@@' + counter);
                                break;
                            }
                            
                        }
                        else {
                            System.debug('counter 3@@@' + counter);
                            if (counter>= 25){
                                break;
                            }
                        }
                    }
                    
                }
            }
            System.debug('qlIdToDetailsMap@@@@' + qlIdToDetailsMap);
            System.debug('qlrMap@@@@' + qlrMap);
            System.debug('prMap@@@@' + prMap);
            Set<SBQQ__QuoteLine__c> qlUpdateLst = new Set<SBQQ__QuoteLine__c>();
            List<Get_Pricing_Request__c> prDeleteLst = new List<Get_Pricing_Request__c>();
            List<Get_Pricing_Request__c> prUpdateLst = new List<Get_Pricing_Request__c>();
            List<Quote_Line_Request__c> qlrUpsertLst = new List<Quote_Line_Request__c>();
            List<SBQQ__QuoteLineGroup__c> qlgUpdateLst = new List<SBQQ__QuoteLineGroup__c>();
            List<SBQQ__Quote__c> quoteUpdateLst = new List<SBQQ__Quote__c>();
            for (String pricingId : prMap.keySet()) {
                Get_Pricing_Request__c pricing = prMap.get(pricingId);
                for (String qlId : qlrMap.keySet()) {
                    Quote_Line_Request__c qlr = qlrMap.get(qlId);
                    if (qlr.Get_Pricing_Request__c == pricingId) {
                        if (pricing.Page_Number__c >= pricing.Total_Pages__c) {
                            String costingStatus = (qlr.MRC__c == null && qlr.NRC__c == null) ? 'No costing solutions found' : 'Cost found';
                            String positiveAOI = 'MRC: $' + (qlr.MRC__c == null ? '0' : String.valueOf(qlr.MRC__c)) + ', NRC: $' + (qlr.NRC__c == null ? '0' : String.valueOf(qlr.NRC__c)) + ', Provider: ' + qlr.Provider__c + ', Media Type: ' + qlr.Media_Type__c;
                            String accessOrderingInstructions = (qlr.MRC__c == null && qlr.NRC__c == null) ? 'No costing solutions found' : positiveAOI;
                            qlUpdateLst.add(new SBQQ__QuoteLine__c(Id = qlIdToDetailsMap.get(qlId).get('receiverId'), SBQQ__UnitCost__c = qlr.MRC__c, NRC_Unit_Cost__c = qlr.NRC__c,
                                                                   Costing_Status__c = costingStatus, Access_Ordering_Instructions__c = accessOrderingInstructions,
                                                                   Provider__c = qlr.Provider__c, Media_Type__c = qlr.Media_Type__c, Received_Download_Speed__c = qlr.Download_Speed__c,
                                                                   Received_Upload_Speed__c = qlr.Upload_Speed__c, SBQQ__ListPrice__c = qlr.MRC__c, NRC_List_Unit_Price__c = qlr.NRC__c));
                        }
                        else {
                            qlrUpsertLst.add(qlr);
                        }
                    }
                }
                if (pricing.Page_Number__c >= pricing.Total_Pages__c) {
                    prDeleteLst.add(pricing);
                }
                else {
                    prUpdateLst.add(pricing);
                }
            }
            System.debug('qlUpdateLst@@@' + qlUpdateLst);
            System.debug('prDeleteLst@@@' + prDeleteLst);
            System.debug('prUpdateLst@@@' + prUpdateLst);
            System.debug('qlrUpsertLst@@@' + qlrUpsertLst);
            System.debug('arLst@@@' + arLst);
            
            List<Get_Pricing_Request__c> prDeleteWithEmail = [
                SELECT Id, User__c, SF_Quote__c, SF_Quote__r.name
                FROM Get_Pricing_Request__c
                WHERE Id IN :prDeleteLst
            ];
            List<SBQQ__QuoteLineGroup__c> qlgLst = [
                SELECT Id, SBQQ__Quote__c
                FROM SBQQ__QuoteLineGroup__c
                WHERE SBQQ__Quote__c IN 
                (SELECT SF_Quote__c
                 FROM Get_Pricing_Request__c
                 WHERE Id IN :prDeleteLst)
            ];
            Map<String, List<SBQQ__QuoteLineGroup__c>> quoteIdToGroupLstMap = new Map<String, List<SBQQ__QuoteLineGroup__c>>();
            for (SBQQ__QuoteLineGroup__c qlg : qlgLst) {
                if (!quoteIdToGroupLstMap.containsKey(qlg.SBQQ__Quote__c)) {
                    quoteIdToGroupLstMap.put(qlg.SBQQ__Quote__c, new List<SBQQ__QuoteLineGroup__c>());
                }
                quoteIdToGroupLstMap.get(qlg.SBQQ__Quote__c).add(qlg);
            }
            
            Set<String> userQuoteCombinationsToCheck = new Set<String>();
            Set<String> quoteCombinationsToCheck = new Set<String>();
            for (Get_Pricing_Request__c pr : prDeleteWithEmail) {
                userQuoteCombinationsToCheck.add(pr.User__c + '|' + pr.SF_Quote__c);
                quoteCombinationsToCheck.add(pr.SF_Quote__c);
            }
            
            List<Get_Pricing_Request__c> existingRecords = [
                SELECT User__c, SF_Quote__c
                FROM Get_Pricing_Request__c
                WHERE Id NOT IN :prDeleteWithEmail
            ];
            
            Set<String> existingCombinations = new Set<String>();
            Set<String> existingCombinations2 = new Set<String>();
            for (Get_Pricing_Request__c record : existingRecords) {
                existingCombinations.add(record.User__c + '|' + record.SF_Quote__c);
                existingCombinations2.add(record.SF_Quote__c);
            }
            
            Set<String> uniqueCombinations = userQuoteCombinationsToCheck.clone();
            Set<String> uniqueCombinations2 = quoteCombinationsToCheck.clone();
            uniqueCombinations.removeAll(existingCombinations);
            uniqueCombinations2.removeAll(existingCombinations2);
            
            CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
            if (!uniqueCombinations.isEmpty()) {
                Set<String> processedCombinations = new Set<String>();
                
                for (Get_Pricing_Request__c pr : prDeleteWithEmail) {
                    String combination = pr.User__c + '|' + pr.SF_Quote__c;
                    if (uniqueCombinations.contains(combination)  && !processedCombinations.contains(combination)) {
                        // send custom notification here, for user id and add link to quote id
                        if (notificationType != null) {
                            try{
                                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                                notification.setTitle('Quote has been costed');
                                notification.setBody('Quote ' + pr.SF_Quote__r.Name + ' has been costed. Please click on this notification to be directed to it.');
                                notification.setNotificationTypeId(notificationType.Id);
                                notification.setTargetId( pr.SF_Quote__c);
                                notification.send(new Set<String> { pr.User__c });
                            }catch(Exception ex){
                                System.debug('Exception: '+ ex.getMessage());
                            }
                        }
                        processedCombinations.add(combination);
                    }
                }
                
            }
            
            if (!uniqueCombinations2.isEmpty()) {
                Set<String> processedCombinations = new Set<String>();
                
                for (Get_Pricing_Request__c pr : prDeleteWithEmail) {
                    String combination = pr.SF_Quote__c;
                    if (uniqueCombinations2.contains(combination)  && !processedCombinations.contains(combination)) {
                        SBQQ__Quote__c quote = new SBQQ__Quote__c(Id = pr.SF_Quote__c, Is_Costed__c = true);
                        quoteUpdateLst.add(quote);
                        List<SBQQ__QuoteLineGroup__c> qlgList = quoteIdToGroupLstMap.get(pr.SF_Quote__c);
                        if(qlgList != null && !qlgList.isEmpty()){
                        for (SBQQ__QuoteLineGroup__c qlg : qlgList) {
                            qlg.Costing_in_Progress__c = false;
                            qlgUpdateLst.add(qlg);
                        }
                    }
                        processedCombinations.add(combination);
                    }    
                }
                
            }

            List<SBQQ__QuoteLine__c> qlUpdateLstNew = new List<SBQQ__QuoteLine__c>(qlUpdateLst);
            update qlUpdateLstNew;
            delete prDeleteLst;
            upsert qlrUpsertLst Id;
            update prUpdateLst;
            insert arLst;
            update quoteUpdateLst;
            update qlgUpdateLst;
            
           /* Datetime now = Datetime.now();
            Datetime nextRun = now.addMinutes(1);
            nextRun = adjustToWorkingHours(nextRun);
            
            if (nextRun != null) {
                String cron = '0 ' + nextRun.minute() + ' ' + nextRun.hour() + ' ' + nextRun.day() + ' ' + nextRun.month() + ' ? ' + nextRun.year();
                System.schedule('SCH_CB_PricingRequest_UTL' + nextRun.getTime(), cron, new SCH_CB_PricingRequest_UTL());
            }*/
        }
        catch (Exception e) {
            System.debug('error' + e.getLineNumber() + ': ' + e.getMessage());
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in SCH_CB_PricingRequest_UTL.execute at line ' + e.getLineNumber() +
                ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
    
  /*  private static void deleteCurrentJob(SchedulableContext sc) {
        try {
            String jobId = sc.getTriggerId();
            System.abortJob(jobId);
        } catch (Exception e) {
            System.debug('Failed to delete job: ' + e.getMessage());
        }
    }
    
    private static Datetime adjustToWorkingHours(Datetime runTime) {
        String dayOfWeek = runTime.format('E');
        Integer hour = runTime.hour();
        
        if (dayOfWeek == 'Sat') {
            runTime = runTime.addDays(2);
        } else if (dayOfWeek == 'Sun') {
            runTime = runTime.addDays(1);
        }
        
        if (hour < 8) {
            runTime = Datetime.newInstance(runTime.date(), Time.newInstance(8, 0, 0, 0));
        } else if (hour >= 21) {
            runTime = runTime.addDays(1);
            runTime = Datetime.newInstance(runTime.date(), Time.newInstance(8, 0, 0, 0));
        }
        
        dayOfWeek = runTime.format('E');
        if (dayOfWeek == 'Sat' || dayOfWeek == 'Sun') {
            return adjustToWorkingHours(runTime);
        }
        
        return runTime;
    }*/
}