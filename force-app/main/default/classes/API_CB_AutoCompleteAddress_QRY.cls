// SC-0000100
// Class to create quote addresses
// and edit quote addresses and quote line groups
public class API_CB_AutoCompleteAddress_QRY {
    public String status;
    public String inputAddress;
    public cls_data[] data;
    public class cls_data {
        @AuraEnabled
        public String address;
        @AuraEnabled
        public String city;
        @AuraEnabled
        public String state;
        @AuraEnabled
        public String country;
        @AuraEnabled
        public String zipcode;
        
        public cls_data(String address, String city, String state, String country, String zipcode) {
            this.address = address;
            this.city = city;
            this.state = state;
            this.country = country;
            this.zipcode = zipcode;
        }
    }
    public class Bulk_data {
        @AuraEnabled
        public List < cls_data > parsedData {
            get;
            set;
        }
        @AuraEnabled
        public API_Response__c apiResponse {
            get;
            set;
        }
        
        public Bulk_data(List < cls_data > parsedData, API_Response__c apiResponse) {
            this.parsedData = parsedData;
            this.apiResponse = apiResponse;
        }
    }
    
    public static API_CB_AutoCompleteAddress_QRY parse(String json) {
        return (API_CB_AutoCompleteAddress_QRY) System.JSON.deserialize(json, API_CB_AutoCompleteAddress_QRY.class);
    }
    
    @AuraEnabled
    public static List < cls_data > autocompleteAddress(String search, String preferred_states, String preferred_cities) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String enteredAddress = search.replace(' ', '%20');
        String state = preferred_states.replace(' ', '%20');
        String city = preferred_cities.replace(' ', '%20');
        if ((state == '' || state == '%20') && (city == '' || city == '%20')) {
            request.setEndpoint('callout:Address_Autocomplete' + '/' + enteredAddress);
        } else {
            request.setEndpoint('callout:Address_Autocomplete' + '/' + enteredAddress + '?limit=10&preferred_states=' + state + '&preferred_cities=' + city);
        }
        
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse response = new HttpResponse();
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
        
        try {
            System.debug('Request' + request);
            response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('API Callout Success: ' + response.getBody());
                API_CB_AutoCompleteAddress_QRY parsedResponse = API_CB_AutoCompleteAddress_QRY.parse(response.getBody());
                System.debug('parsed response: ' + parsedResponse);
                
                //API Response 
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Address Autocomplete', 'true', String.valueOf(response.getStatusCode()), response.getStatus(), null, null, null);
                return parsedResponse.data;
            } else {
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Address Autocomplete', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, null, null);
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Error in Autocompleting Address');
                notification.setBody('There was an error in autocompleting addresses: ' +  response.getBody());
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId('000000000000000AAA');
                notification.send(new Set<String> { UserInfo.getUserId()});
                System.debug('Error response: ' + response.getStatusCode() + ' - ' + response.getBody());
                return null;
            }
        } catch (Exception e) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Error in Autocompleting Address');
            notification.setBody('There was an error in autocompleting addresses: ' +  e.getMessage());
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId('000000000000000AAA');
            notification.send(new Set<String> { UserInfo.getUserId()});            
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AutoCompleteAddress_QRY.autocompleteAddress at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return null;
        }
    }
    
    @AuraEnabled
    public static Bulk_data autocompleteAddressBulk(String search, String preferred_states, String preferred_cities) {
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        String enteredAddress = search.replace(' ', '%20');
        String state = preferred_states.replace(' ', '%20');
        String city = preferred_cities.replace(' ', '%20');
        if ((state == '' || state == '%20') && (city == '' || city == '%20')) {
            request.setEndpoint('callout:Address_Autocomplete' + '/' + enteredAddress);
        } else {
            request.setEndpoint('callout:Address_Autocomplete' + '/' + enteredAddress + '?limit=10&preferred_states=' + state + '&preferred_cities=' + city);
        }
        
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');
        HttpResponse response = new HttpResponse();
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
        
        try {
            System.debug('Request' + request);
            response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                System.debug('API Callout Success: ' + response.getBody());
                API_CB_AutoCompleteAddress_QRY parsedResponse = API_CB_AutoCompleteAddress_QRY.parse(response.getBody());
                System.debug('parsed response: ' + parsedResponse);
                
                //API Response 
                
                API_Response__c ar = API_APIResponse_INS.returnAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Address Autocomplete', 'true', String.valueOf(response.getStatusCode()), response.getStatus(), null, null, null);
                Bulk_data bulkdata = new Bulk_data(parsedResponse.data, ar);
                return bulkdata;
            } else {
                API_Response__c ar = API_APIResponse_INS.returnAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Address Autocomplete', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, null, null);
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Error in Autocompleting Address');
                notification.setBody('There was an error in autocompleting addresses: ' +  response.getBody());
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId('000000000000000AAA');
                notification.send(new Set<String> { UserInfo.getUserId()});
                System.debug('Error response: ' + response.getStatusCode() + ' - ' + response.getBody());
                return new Bulk_data(null, ar);
            }
        } catch (Exception e) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Error in Autocompleting Address');
            notification.setBody('There was an error in autocompleting addresses: ' +  e.getMessage());
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId('000000000000000AAA');
            notification.send(new Set<String> { UserInfo.getUserId()});            
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AutoCompleteAddress_QRY.autocompleteAddressBulk at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return new Bulk_data(null, null);
        }
    }
    
    @AuraEnabled
    public static Boolean bulkAddressInsert(List < String > addressList, String recordId) {
        
        try {
            List < Quote_Address__c > simpleQuoteAddressList = new List < Quote_Address__c > ();
            List < String > zAddressList = new List < String > ();
            List < String > aAddressList = new List < String > ();
            List < Quote_Address__c > zQuoteAddressList = new List < Quote_Address__c > ();
            List < Quote_Address__c > aQuoteAddressList = new List < Quote_Address__c > ();
            Map < String, String > AtoZAddressMap = new Map < String, String > ();
            Set<String> keySetFull = new Set<String>();
            List<Quote_Address__c> existingQAs = [SELECT Id, Street__c, City__c, State__c,
                                                  Country__c, Zip__c, A_Address__c, Z_Address__c,
                                                  z_Quote_Address__c, z_Quote_Address__r.Street__c, 
                                                  z_Quote_Address__r.City__c, z_Quote_Address__r.State__c, 
                                                  z_Quote_Address__r.Country__c, z_Quote_Address__r.Zip__c
                                                  FROM Quote_Address__c
                                                  WHERE Opportunity__c =: recordId
                                                  AND Network_Status__c = 'Off Net'];
            for (Quote_Address__c qa : existingQAs) {
                String key;
                if (qa.A_Address__c == false && qa.Z_Address__c == false) {
                    key = qa.Street__c + qa.City__c + qa.State__c + qa.Zip__c;
                }
                else if (qa.A_Address__c == true) {
                    key = qa.Street__c + qa.City__c + qa.State__c + qa.Zip__c + 'A';
                    key += qa.z_Quote_Address__r.Street__c + qa.z_Quote_Address__r.City__c +
                        qa.z_Quote_Address__r.State__c +
                        qa.z_Quote_Address__r.Zip__c;
                }
                else if (qa.Z_Address__c == true) {
                    key = qa.Street__c + qa.City__c + qa.State__c + qa.Zip__c + 'Z';
                    for (Quote_Address__c qaA : existingQAs)  {
                        if (qaA.A_Address__c == true && qaA.z_Quote_Address__c == qa.Id) {
                            key += qaA.Street__c + qaA.City__c + qaA.State__c + qaA.Zip__c;                       
                        }
                    }
                }
                keySetFull.add(key);
            }
            System.debug('keySetFull@@@1' + keySetFull);
            for (String address: addressList) {
                String[] addressArray = address.split(',');
                
                if (addressArray.size() == 5) {
                    String key = addressArray[0].trim() + addressArray[1].trim() + addressArray[2].trim() + addressArray[4].trim();
                    System.debug(key);
                    Quote_Address__c quoteAddress = new Quote_Address__c();
                    quoteAddress.Street__c = addressArray[0];
                    quoteAddress.City__c = addressArray[1];
                    quoteAddress.State__c = addressArray[2];
                    quoteAddress.Country__c = addressArray[3];
                    quoteAddress.Zip__c = addressArray[4];
                    quoteAddress.Network_Status__c = 'Off Net';
                    quoteAddress.Opportunity__c = recordId;
                    quoteAddress.A_Address__c = false;
                    quoteAddress.Z_Address__c = false;
                    if (!keySetFull.contains(key)) {
                        simpleQuoteAddressList.add(quoteAddress);
                        keySetFull.add(key);
                    }
                } else if (addressArray.size() == 6) {
                    String key = addressArray[0].trim() + addressArray[1].trim() + addressArray[2].trim() + addressArray[4].trim() + 'A';
                    String aNumber = addressArray[5].trim(); // Get the identifier (number) of A address
                    
                    // Nested loop to find matching Z address
                    for (String addressZ: addressList) {
                        String[] arrayZ = addressZ.split(',');
                        if (arrayZ.size() == 7 && arrayZ[arrayZ.size() - 1].trim() == aNumber ) { // identifier for same z address
                            key +=  arrayZ[0].trim() + arrayZ[1].trim() + arrayZ[2].trim() + arrayZ[4].trim();
                        }
                    }
                    System.debug(key);
                    System.debug('inside A address list');
                    if (!keySetFull.contains(key)) {
                        aAddressList.add(address);
                        keySetFull.add(key);
                    }
                    
                } else if (addressArray.size() == 7) {
                    String key = addressArray[0].trim() + addressArray[1].trim() + addressArray[2].trim() + addressArray[4].trim() + 'Z';
                    String zNumber = addressArray[6].trim(); // Get the identifier (number) of A address
                    for (String addressA: addressList) {
                        String[] arrayA = addressA.split(',');
                        if (arrayA.size() == 6 && arrayA[arrayA.size() - 1].trim() == zNumber ) { // identifier for same a address
                            key +=  arrayA[0].trim() + arrayA[1].trim() + arrayA[2].trim() + arrayA[4].trim();
                        }
                    } 
                    
                    System.debug(key);
                    System.debug('inside z address list');
                    if (!keySetFull.contains(key)) {
                        zAddressList.add(address);
                        keySetFull.add(key);
                    }
                }
            }
            
            system.debug(zAddressList.size() > 0 && aAddressList.size() > 0);
            if (zAddressList.size() > 0 && aAddressList.size() > 0) {
                
                for (String address: zAddressList) {
                    String[] addressArray = address.split(',');
                    Quote_Address__c quoteAddress = new Quote_Address__c();
                    quoteAddress.Street__c = addressArray[0];
                    quoteAddress.City__c = addressArray[1];
                    quoteAddress.State__c = addressArray[2];
                    quoteAddress.Country__c = addressArray[3];
                    quoteAddress.Zip__c = addressArray[4];
                    quoteAddress.Network_Status__c = 'Off Net';
                    quoteAddress.Opportunity__c = recordId;
                    quoteAddress.A_Address__c = false;
                    quoteAddress.Z_Address__c = true;
                    zQuoteAddressList.add(quoteAddress);
                }
                
                insert zQuoteAddressList;
                
                List < Quote_Address__c > insertedAddresses = new List < Quote_Address__c > ();
                
                do {
                    
                    insertedAddresses = [SELECT Id, Street__c, City__c, State__c, Country__c, Zip__c
                                         FROM Quote_Address__c
                                         WHERE CreatedDate = TODAY AND Z_Address__c = true ORDER BY CreatedDate DESC LIMIT: zQuoteAddressList.size()
                                        ];
                    
                    System.debug('Z address list after insert==>' + insertedAddresses);
                    Map < String, String > zAddressToId = new Map < String, String > ();
                    
                    for (Quote_Address__c quoteAddress: insertedAddresses) {
                        String zAddress = quoteAddress.Street__c + ',' + quoteAddress.City__c + ',' + quoteAddress.State__c + ',' + quoteAddress.Country__c + ',' + quoteAddress.Zip__c;
                        zAddressToId.put(zAddress, quoteAddress.Id);
                    }
                    System.debug('is mapped MAp==>' + zAddressToId);
                    
                    for (String aAddress: aAddressList) {
                        String[] aArray = aAddress.split(',');
                        String aNumber = aArray[aArray.size() - 1].trim(); // Get the identifier (number) of A address
                        System.debug('till HERE');
                        
                        // Nested loop to find matching Z address
                        for (String zAddress: zAddressList) {
                            String[] zArray = zAddress.split(',');
                            String zNumber = zArray[zArray.size() - 1].trim();
                            System.debug('mapping Numbers' + aNumber + zNumber); // Get the identifier (number) of Z address
                            
                            // Check if A and Z addresses have the same identifier
                            if (aNumber == zNumber) {
                                String key = '';
                                Integer lastIndex = zAddress.lastIndexOf(',,');
                                if (lastIndex != -1) {
                                    // Return the substring up to the lastIndex
                                    key = zAddress.substring(0, lastIndex).trim();
                                }
                                System.debug('KEY==>' + key);
                                String formattedKey = key.replaceAll(', ', ',');
                                String zAddressId = zAddressToId.get(formattedKey);
                                
                                Quote_Address__c quoteAddress = new Quote_Address__c();
                                quoteAddress.Street__c = aArray[0];
                                quoteAddress.City__c = aArray[1];
                                quoteAddress.State__c = aArray[2];
                                quoteAddress.Country__c = aArray[3];
                                quoteAddress.Zip__c = aArray[4];
                                quoteAddress.Network_Status__c = 'Off Net';
                                quoteAddress.Opportunity__c = recordId;
                                quoteAddress.A_Address__c = true;
                                quoteAddress.Z_Address__c = false;
                                quoteAddress.z_Quote_Address__c = zAddressId;
                                aQuoteAddressList.add(quoteAddress);
                                
                            }
                        }
                    }
                    
                } while (insertedAddresses.isEmpty());
                
            }
            
            if (simpleQuoteAddressList != null && !simpleQuoteAddressList.isEmpty()) {
                insert simpleQuoteAddressList;
            } else {
                System.debug('simpleQuoteAddressList is null or empty, no records to insert.');
            }
            
            // Check for null or empty before inserting aQuoteAddressList
            if (aQuoteAddressList != null && !aQuoteAddressList.isEmpty()) {
                insert aQuoteAddressList;
            } else {
                System.debug('aQuoteAddressList is null or empty, no records to insert.');
            }
            
            return true;
            
        } catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AutoCompleteAddress_QRY.bulkAddressInsert at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            
            return false;
        }
    }
    
    @InvocableMethod
    public static List < string > validateAddress(List < String > addrList) {
        List < string > strList = addrList[0].split(',');
        List < string > validList = new List < string > ();
        String street = strList[0];
        String city = strList[1];
        String state = strList[2];
        String country = strList[3];
        String zipcode = strList[4];
        Http http = new Http();
        
        HttpRequest request = new HttpRequest();
        HttpResponse response = new HttpResponse();
        CustomNotificationType notificationType = [SELECT Id FROM CustomNotificationType WHERE DeveloperName = 'Price_Fetch'];
        
        try {
            
            Boolean isValid = false;
            String address = addrList[0];
            
            String enteredAddress = address.replace(' ', '%20');
            
            request.setEndpoint('callout:Address_Validation' + '/?address=' + enteredAddress);
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            
            System.debug('Request' + request);
            response = http.send(request);
            
            System.debug('validation Status Code' + response.getStatusCode());
            
            //API Response 
            
            if (response.getStatusCode() == 200) {
                
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Address Autocomplete', 'true', String.valueOf(response.getStatusCode()), response.getStatus(), null, null, null);
                
                System.debug('API validation Success: ' + response.getBody());
                
                String responseBody = response.getBody();
                Map < String, Object > responseMap = (Map < String, Object > ) JSON.deserializeUntyped(responseBody);
                
                System.debug('responseMap' + responseMap);
                
                if (responseMap.get('status') == 'success' && responseMap.containsKey('data')) {
                    Map < String, object > dataList = (Map < String, object > ) responseMap.get('data');
                    
                    // Extract response address fields
                    String responseStreet = (String) dataList.get('address');
                    String responseCity = (String) dataList.get('city');
                    String responseZipcode = (String) dataList.get('zipcode');
                    String responseCountry = (String) dataList.get('country');
                    
                    // Validate input against the response
                    if (responseStreet.equalsIgnoreCase(street) &&
                        responseCity.equalsIgnoreCase(city) &&
                        responseZipcode.equalsIgnoreCase(zipcode) &&
                        responseCountry.equalsIgnoreCase(country)) {
                            
                            System.debug('Address Found');
                            isValid = true;
                            validList = addrList;
                            
                        }
                    
                }
            } else {
                Messaging.CustomNotification notification = new Messaging.CustomNotification();
                notification.setTitle('Error in Validating Address');
                notification.setBody('There was an error in validating addresses: ' +  response.getBody());
                notification.setNotificationTypeId(notificationType.Id);
                notification.setTargetId('000000000000000AAA');
                notification.send(new Set<String> { UserInfo.getUserId()});
                API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Address Autocomplete', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, null, null);
                
                isValid = false;
                
            }
            
            return validList;
        } catch (Exception e) {
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setTitle('Error in Validating Address');
            notification.setBody('There was an error in validating addresses: ' +  e.getMessage());
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId('000000000000000AAA');
            notification.send(new Set<String> { UserInfo.getUserId()});
            API_APIResponse_INS.createAPIResponse(request.getEndpoint(), request.getBody(), response.getBody(), true, request.getMethod(), 'Connectbase Address Autocomplete', 'false', String.valueOf(response.getStatusCode()), response.getStatus(), null, null, null);
            
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AutoCompleteAddress_QRY.validateAddress at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
            return validList;
        }
    }
    
    @AuraEnabled
    public static String editQuoteAddress(String recordId, String serach, String street, String city, String state, String country, String zipcode, String oldAddress) {
        
        String[] oldAddressArray = oldAddress.split(',');
        
        Quote_Address__c quoteAddress1 = [SELECT ID, Street__c, City__c, State__c, Country__c, Zip__c, A_address__c, Z_Address__c FROM Quote_Address__c WHERE Id =: recordId LIMIT 1];
        
        if (quoteAddress1.Z_Address__c) {
            Quote_Address__c AquoteAddress = [SELECT ID, Street__c, City__c, State__c, Country__c, Zip__c, A_address__c, Z_Address__c FROM Quote_Address__c WHERE z_Quote_Address__c =: recordId LIMIT 1];
            
            List < SBQQ__QuoteLineGroup__c > quoteLineGroups = [SELECT Id, Quote_Address__c, Quote_Address__r.A_address__c, Quote_Address__r.z_Quote_Address__r.Street__c, Quote_Address__r.z_Quote_Address__r.City__c FROM SBQQ__QuoteLineGroup__c WHERE Quote_Address__c =: AquoteAddress.Id];
            
            List < SBQQ__QuoteLineGroup__c > updateQuoteLineGroup = new List < SBQQ__QuoteLineGroup__c > ();
            List < SBQQ__QuoteLine__c > updateQuoteLine = new List < SBQQ__QuoteLine__c > ();
            
            String response = '';
            
            try {
                if (String.isBlank(serach)) {
                    List < string > strList = new List < string > ();
                    string addr = street + ',' + city + ',' + state + ',' + country + ',' + zipcode;
                    strList.add(addr);
                    List < string > isValList = validateAddress(strList);
                    Boolean isValid;
                    if (isValList.size() > 0) {
                        isValid = true;
                    } else {
                        isValid = false;
                    }
                    
                    if (isValid == true) {
                        
                        Quote_Address__c quoteAddress = new Quote_Address__c();
                        quoteAddress.id = recordId;
                        quoteAddress.Street__c = street;
                        quoteAddress.City__c = city;
                        quoteAddress.State__c = state;
                        quoteAddress.Country__c = country;
                        quoteAddress.Zip__c = zipcode;
                        
                        update quoteAddress;
                        
                        for (SBQQ__QuoteLineGroup__c quoteLineGroup: quoteLineGroups) {
                            String groupName = '';
                            groupName = AquoteAddress.Street__c + ', ' + AquoteAddress.City__c;
                            
                            groupName += ' | ';
                            groupName += street + ', ' + city;
                            
                            if (groupName.length() > 80) {
                                groupName = AquoteAddress.Street__c + ' | ' + street;
                            }
                            
                            SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c();
                            qlg.id = quoteLineGroup.Id;
                            qlg.name = groupName;
                            
                            updateQuoteLineGroup.add(qlg);
                            
                            List < SBQQ__QuoteLine__c > qls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                               WHERE Send_To_Connectbase__c = true
                                                               AND SBQQ__Group__c =: quoteLineGroup.Id AND Street__c =: oldAddressArray[0] AND City__c =: oldAddressArray[1] AND State__c =: oldAddressArray[2] AND Country__c =: oldAddressArray[3] AND Zip__c =: oldAddressArray[4]
                                                              ];
                            
                            Set<Id> qlIds = new Set<Id>();
                            for (SBQQ__QuoteLine__c ql: qls) {
                                qlIds.add(ql.Id);
                                ql.City__c = city;
                                ql.Country__c = country;
                                ql.State__c = state;
                                ql.Street__c = street;
                                ql.Zip__c = zipcode;
                                ql.SBQQ__UnitCost__c = null;
                                ql.NRC_Unit_Cost__c = null;
                                ql.Provider__c = null;
                                ql.Media_Type__c = null;
                                ql.Received_Download_Speed__c = null;
                                ql.Received_Upload_Speed__c = null;
                                ql.Costing_Status__c = null;
                                ql.Access_Ordering_Instructions__c = null;
                                ql.SBQQ__ListPrice__c = null;
                                ql.NRC_List_Unit_Price__c = null;
                                updateQuoteLine.add(ql);
                            }
                            List < SBQQ__QuoteLine__c > receivedQls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                                       WHERE Receive_From_Connectbase__c = true
                                                                       AND SBQQ__Group__c =: quoteLineGroup.Id
                                                                       AND Id NOT IN :qlIds 
                                                                      ];
                            for (SBQQ__QuoteLine__c ql: receivedQls) {
                                ql.SBQQ__UnitCost__c = null;
                                ql.NRC_Unit_Cost__c = null;
                                ql.Provider__c = null;
                                ql.Media_Type__c = null;
                                ql.Received_Download_Speed__c = null;
                                ql.Received_Upload_Speed__c = null;
                                ql.Costing_Status__c = null;
                                ql.Access_Ordering_Instructions__c = null;
                                ql.SBQQ__ListPrice__c = null;
                                ql.NRC_List_Unit_Price__c = null;
                                updateQuoteLine.add(ql);
                            }
                            
                        }
                        
                        if (!updateQuoteLineGroup.isEmpty()) {
                            update updateQuoteLineGroup;
                        }
                        
                        if (!updateQuoteLine.isEmpty()) {
                            update updateQuoteLine;
                        }
                        
                        response = 'Address updated successfully';
                        return response;
                        
                    } else {
                        
                        response = 'Address Validation Failed';
                        return response;
                    }
                    
                } else {
                    
                    Quote_Address__c quoteAddress = new Quote_Address__c();
                    quoteAddress.id = recordId;
                    quoteAddress.Street__c = street;
                    quoteAddress.City__c = city;
                    quoteAddress.State__c = state;
                    quoteAddress.Country__c = country;
                    quoteAddress.Zip__c = zipcode;
                    
                    update quoteAddress;
                    
                    for (SBQQ__QuoteLineGroup__c quoteLineGroup: quoteLineGroups) {
                        String groupName = '';
                        groupName = AquoteAddress.Street__c + ', ' + AquoteAddress.City__c;
                        
                        groupName += ' | ';
                        groupName += street + ', ' + city;
                        
                        if (groupName.length() > 80) {
                            groupName = AquoteAddress.Street__c + ' | ' + street;
                        }
                        
                        SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c();
                        qlg.id = quoteLineGroup.Id;
                        qlg.name = groupName;
                        
                        updateQuoteLineGroup.add(qlg);
                        
                        List < SBQQ__QuoteLine__c > qls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                           WHERE Send_To_Connectbase__c = true
                                                           AND SBQQ__Group__c =: quoteLineGroup.Id AND Street__c =: oldAddressArray[0] AND City__c =: oldAddressArray[1] AND State__c =: oldAddressArray[2] AND Country__c =: oldAddressArray[3] AND Zip__c =: oldAddressArray[4]
                                                          ];
                        
                        Set<Id> qlIds = new Set<Id>();
                        for (SBQQ__QuoteLine__c ql: qls) {
                            qlIds.add(ql.Id);
                            ql.City__c = city;
                            ql.Country__c = country;
                            ql.State__c = state;
                            ql.Street__c = street;
                            ql.Zip__c = zipcode;
                            ql.SBQQ__UnitCost__c = null;
                            ql.NRC_Unit_Cost__c = null;
                            ql.Provider__c = null;
                            ql.Media_Type__c = null;
                            ql.Received_Download_Speed__c = null;
                            ql.Received_Upload_Speed__c = null;
                            ql.Costing_Status__c = null;
                            ql.Access_Ordering_Instructions__c = null;
                            ql.SBQQ__ListPrice__c = null;
                            ql.NRC_List_Unit_Price__c = null;
                            updateQuoteLine.add(ql);
                        }
                        List < SBQQ__QuoteLine__c > receivedQls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                                   WHERE Receive_From_Connectbase__c = true
                                                                   AND SBQQ__Group__c =: quoteLineGroup.Id
                                                                   AND Id NOT IN :qlIds 
                                                                  ];
                        for (SBQQ__QuoteLine__c ql: receivedQls) {
                            ql.SBQQ__UnitCost__c = null;
                            ql.NRC_Unit_Cost__c = null;
                            ql.Provider__c = null;
                            ql.Media_Type__c = null;
                            ql.Received_Download_Speed__c = null;
                            ql.Received_Upload_Speed__c = null;
                            ql.Costing_Status__c = null;
                            ql.Access_Ordering_Instructions__c = null;                        
                            ql.SBQQ__ListPrice__c = null;
                            ql.NRC_List_Unit_Price__c = null;
                            updateQuoteLine.add(ql);
                        }
                        
                    }
                    
                    if (!updateQuoteLineGroup.isEmpty()) {
                        update updateQuoteLineGroup;
                    }
                    
                    if (!updateQuoteLine.isEmpty()) {
                        update updateQuoteLine;
                    }
                    
                    response = 'Address updated successfully';
                    return response;
                    
                }
                
            } catch (Exception e) {
                CustomException ce = new CustomException();
                ce.message = 'An error occurred in API_CB_AutoCompleteAddress_QRY.editQuoteAddress at line ' + e.getLineNumber() + ': ' + e.getMessage();
                CustomException.sendErrorNotification(ce);
                return 'Address Update Failed';
            }
            
        } else {
            
            List < SBQQ__QuoteLineGroup__c > quoteLineGroups = [SELECT Id, Quote_Address__c, Quote_Address__r.A_address__c, Quote_Address__r.z_Quote_Address__r.Street__c, Quote_Address__r.z_Quote_Address__r.City__c FROM SBQQ__QuoteLineGroup__c WHERE Quote_Address__c =: recordId];
            
            List < SBQQ__QuoteLineGroup__c > updateQuoteLineGroup = new List < SBQQ__QuoteLineGroup__c > ();
            List < SBQQ__QuoteLine__c > updateQuoteLine = new List < SBQQ__QuoteLine__c > ();
            
            String response = '';
            
            try {
                if (String.isBlank(serach)) {
                    List < string > strList = new List < string > ();
                    string addr = street + ',' + city + ',' + state + ',' + country + ',' + zipcode;
                    strList.add(addr);
                    List < string > isValList = validateAddress(strList);
                    Boolean isValid;
                    if (isValList.size() > 0) {
                        isValid = true;
                    } else {
                        isValid = false;
                    }
                    
                    if (isValid == true) {
                        
                        Quote_Address__c quoteAddress = new Quote_Address__c();
                        quoteAddress.id = recordId;
                        quoteAddress.Street__c = street;
                        quoteAddress.City__c = city;
                        quoteAddress.State__c = state;
                        quoteAddress.Country__c = country;
                        quoteAddress.Zip__c = zipcode;
                        
                        update quoteAddress;
                        
                        for (SBQQ__QuoteLineGroup__c quoteLineGroup: quoteLineGroups) {
                            String groupName = '';
                            groupName = street + ', ' + city;
                            
                            if (quoteLineGroup.Quote_Address__r.A_address__c == true) {
                                
                                groupName += ' | ';
                                groupName += quoteLineGroup.Quote_Address__r.z_Quote_Address__r.Street__c + ', ' + quoteLineGroup.Quote_Address__r.z_Quote_Address__r.City__c;
                                
                                if (groupName.length() > 80) {
                                    groupName = street + ' | ' + quoteLineGroup.Quote_Address__r.z_Quote_Address__r.Street__c;
                                }
                                
                            }
                            
                            SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c();
                            qlg.id = quoteLineGroup.Id;
                            qlg.name = groupName;
                            qlg.City__c = city;
                            qlg.Country__c = country;
                            qlg.State__c = state;
                            qlg.Street__c = street;
                            qlg.Zip__c = zipcode;
                            
                            updateQuoteLineGroup.add(qlg);
                            
                            List < SBQQ__QuoteLine__c > qls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                               WHERE Send_To_Connectbase__c = true
                                                               AND SBQQ__Group__c =: quoteLineGroup.Id AND Street__c =: oldAddressArray[0] AND City__c =: oldAddressArray[1] AND State__c =: oldAddressArray[2] AND Country__c =: oldAddressArray[3] AND Zip__c =: oldAddressArray[4]
                                                              ];
                            
                            Set<Id> qlIds = new Set<Id>();
                            for (SBQQ__QuoteLine__c ql: qls) {
                                qlIds.add(ql.Id);
                                ql.City__c = city;
                                ql.Country__c = country;
                                ql.State__c = state;
                                ql.Street__c = street;
                                ql.Zip__c = zipcode;
                                ql.SBQQ__UnitCost__c = null;
                                ql.NRC_Unit_Cost__c = null;
                                ql.Provider__c = null;
                                ql.Media_Type__c = null;
                                ql.Received_Download_Speed__c = null;
                                ql.Received_Upload_Speed__c = null;
                                ql.Costing_Status__c = null;
                                ql.Access_Ordering_Instructions__c = null;
                                ql.SBQQ__ListPrice__c = null;
                                ql.NRC_List_Unit_Price__c = null;
                                updateQuoteLine.add(ql);
                            }
                            List < SBQQ__QuoteLine__c > receivedQls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                                       WHERE Receive_From_Connectbase__c = true
                                                                       AND SBQQ__Group__c =: quoteLineGroup.Id
                                                                       AND Id NOT IN :qlIds 
                                                                      ];
                            for (SBQQ__QuoteLine__c ql: receivedQls) {
                                ql.SBQQ__UnitCost__c = null;
                                ql.NRC_Unit_Cost__c = null;
                                ql.Provider__c = null;
                                ql.Media_Type__c = null;
                                ql.Received_Download_Speed__c = null;
                                ql.Received_Upload_Speed__c = null;
                                ql.Costing_Status__c = null;
                                ql.Access_Ordering_Instructions__c = null;
                                ql.SBQQ__ListPrice__c = null;
                                ql.NRC_List_Unit_Price__c = null;
                                updateQuoteLine.add(ql);
                            }
                            
                        }
                        
                        if (!updateQuoteLineGroup.isEmpty()) {
                            update updateQuoteLineGroup;
                        }
                        
                        if (!updateQuoteLine.isEmpty()) {
                            update updateQuoteLine;
                        }
                        
                        response = 'Address updated successfully';
                        return response;
                        
                    } else {
                        
                        response = 'Address Validation Failed';
                        return response;
                    }
                    
                } else {
                    
                    Quote_Address__c quoteAddress = new Quote_Address__c();
                    quoteAddress.id = recordId;
                    quoteAddress.Street__c = street;
                    quoteAddress.City__c = city;
                    quoteAddress.State__c = state;
                    quoteAddress.Country__c = country;
                    quoteAddress.Zip__c = zipcode;
                    
                    update quoteAddress;
                    
                    for (SBQQ__QuoteLineGroup__c quoteLineGroup: quoteLineGroups) {
                        String groupName = '';
                        groupName = street + ', ' + city;
                        
                        if (quoteLineGroup.Quote_Address__r.A_address__c == true) {
                            
                            groupName += ' | ';
                            groupName += quoteLineGroup.Quote_Address__r.z_Quote_Address__r.Street__c + ', ' + quoteLineGroup.Quote_Address__r.z_Quote_Address__r.City__c;
                            
                            if (groupName.length() > 80) {
                                groupName = street + ' | ' + quoteLineGroup.Quote_Address__r.z_Quote_Address__r.Street__c;
                            }
                            
                        }
                        
                        SBQQ__QuoteLineGroup__c qlg = new SBQQ__QuoteLineGroup__c();
                        qlg.id = quoteLineGroup.Id;
                        qlg.name = groupName;
                        qlg.City__c = city;
                        qlg.Country__c = country;
                        qlg.State__c = state;
                        qlg.Street__c = street;
                        qlg.Zip__c = zipcode;
                        
                        updateQuoteLineGroup.add(qlg);
                        
                        List < SBQQ__QuoteLine__c > qls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                           WHERE Send_To_Connectbase__c = true
                                                           AND SBQQ__Group__c =: quoteLineGroup.Id AND Street__c =: oldAddressArray[0] AND City__c =: oldAddressArray[1] AND State__c =: oldAddressArray[2] AND Country__c =: oldAddressArray[3] AND Zip__c =: oldAddressArray[4]
                                                          ];
                        
                        Set<Id> qlIds = new Set<Id>();
                        for (SBQQ__QuoteLine__c ql: qls) {
                            qlIds.add(ql.Id);
                            ql.City__c = city;
                            ql.Country__c = country;
                            ql.State__c = state;
                            ql.Street__c = street;
                            ql.Zip__c = zipcode;
                            ql.SBQQ__UnitCost__c = null;
                            ql.NRC_Unit_Cost__c = null;
                            ql.Provider__c = null;
                            ql.Media_Type__c = null;
                            ql.Received_Download_Speed__c = null;
                            ql.Received_Upload_Speed__c = null;
                            ql.Costing_Status__c = null;
                            ql.Access_Ordering_Instructions__c = null;
                            ql.SBQQ__ListPrice__c = null;
                            ql.NRC_List_Unit_Price__c = null;
                            updateQuoteLine.add(ql);
                        }
                        List < SBQQ__QuoteLine__c > receivedQls = [SELECT Id, Name, Street__c, City__c, State__c FROM SBQQ__QuoteLine__c
                                                                   WHERE Receive_From_Connectbase__c = true
                                                                   AND SBQQ__Group__c =: quoteLineGroup.Id
                                                                   AND Id NOT IN :qlIds 
                                                                  ];
                        for (SBQQ__QuoteLine__c ql: receivedQls) {
                            ql.SBQQ__UnitCost__c = null;
                            ql.NRC_Unit_Cost__c = null;
                            ql.Provider__c = null;
                            ql.Media_Type__c = null;
                            ql.Received_Download_Speed__c = null;
                            ql.Received_Upload_Speed__c = null;
                            ql.Costing_Status__c = null;
                            ql.Access_Ordering_Instructions__c = null;
                            ql.SBQQ__ListPrice__c = null;
                            ql.NRC_List_Unit_Price__c = null;
                            updateQuoteLine.add(ql);
                        }
                        
                    }
                    
                    if (!updateQuoteLineGroup.isEmpty()) {
                        update updateQuoteLineGroup;
                    }
                    
                    if (!updateQuoteLine.isEmpty()) {
                        update updateQuoteLine;
                    }
                    
                    response = 'Address updated successfully';
                    return response;
                    
                }
                
            } catch (Exception e) {
                CustomException ce = new CustomException();
                ce.message = 'An error occurred in API_CB_AutoCompleteAddress_QRY.editQuoteAddress at line ' + e.getLineNumber() + ': ' + e.getMessage();
                CustomException.sendErrorNotification(ce);
                return 'Address Update Failed';
            }
        }
        
    }
    
    @AuraEnabled
    public static void insertAllAPIResponse(List < API_Response__c > apiResponses) {
        try {
            if (!apiResponses.isEmpty()) {
                insert apiResponses;
            }
        } catch (Exception e) {
            CustomException ce = new CustomException();
            ce.message = 'An error occurred in API_CB_AutoCompleteAddress_QRY.insertAllAPIResponse at line ' + e.getLineNumber() + ': ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
    
    //  @AuraEnabled
    /*public static String uploadFileToOpportunity(String fileName, String base64Data, Id opportunityId) {
        try {
            // Decode Base64
            Blob fileBlob = EncodingUtil.base64Decode(base64Data);

            // Create ContentVersion record (File Upload)
            ContentVersion cv = new ContentVersion();
            cv.Title = fileName;
            cv.PathOnClient = '/' + fileName;
            cv.VersionData = fileBlob;
            cv.FirstPublishLocationId = opportunityId; // Associate file with Opportunity
            insert cv;

            // Retrieve ContentDocument ID from inserted ContentVersion
            ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id LIMIT 1];

            // Create ContentDocumentLink to associate file with Opportunity
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cd.Id;
            cdl.LinkedEntityId = opportunityId;
            cdl.ShareType = 'V'; // Viewer permission
            insert cdl;

            return 'Success';
        } catch (Exception e) {
            return 'Error: ' + e.getMessage();
        } 
    } */
}