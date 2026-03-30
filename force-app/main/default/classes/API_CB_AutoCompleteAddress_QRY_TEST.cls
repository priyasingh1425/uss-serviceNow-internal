@IsTest
public class API_CB_AutoCompleteAddress_QRY_TEST {
    @IsTest
    static void testAutocompleteAddress() {
        // Mock HTTP Response
        
        Test.startTest();
         HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "inputAddress": "53 Sumner Street",\n' +
            '  "data": [\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Akron",\n' +
            '      "state": "OH",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Auburn",\n' +
            '      "state": "MA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Accord",\n' +
            '      "state": "MA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Allston",\n' +
            '      "state": "MA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 N Sumner St",\n' +
            '      "city": "Steptoe",\n' +
            '      "state": "WA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner Rd",\n' +
            '      "city": "Stamford",\n' +
            '      "state": "VT",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 W Sumner St",\n' +
            '      "city": "Ancona",\n' +
            '      "state": "IL",\n' +
            '      "country": "USA"\n' +
            '    }\n' +
            '  ]\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        List<API_CB_AutoCompleteAddress_QRY.cls_data> results = API_CB_AutoCompleteAddress_QRY.autocompleteAddress('53 Sumner Street', '', '');
        Test.stopTest();
    }
    
    @IsTest
    static void testAutocompleteAddressBulk() {
        // Mock HTTP Response
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "inputAddress": "53 Sumner Street",\n' +
            '  "data": [\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Akron",\n' +
            '      "state": "OH",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Auburn",\n' +
            '      "state": "MA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Accord",\n' +
            '      "state": "MA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner St",\n' +
            '      "city": "Allston",\n' +
            '      "state": "MA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 N Sumner St",\n' +
            '      "city": "Steptoe",\n' +
            '      "state": "WA",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 Sumner Rd",\n' +
            '      "city": "Stamford",\n' +
            '      "state": "VT",\n' +
            '      "country": "USA"\n' +
            '    },\n' +
            '    {\n' +
            '      "address": "53 W Sumner St",\n' +
            '      "city": "Ancona",\n' +
            '      "state": "IL",\n' +
            '      "country": "USA"\n' +
            '    }\n' +
            '  ]\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        
        Test.startTest();
        API_CB_AutoCompleteAddress_QRY.Bulk_data bulkData = API_CB_AutoCompleteAddress_QRY.autocompleteAddressBulk('53 Sumner Street', '', '');
        Test.stopTest();
        
    }
    
    @IsTest
    static void testBulkAddressInsert() {
        List<String> addresses = new List<String> {'123 Main St,Springfield,IL,USA,62704,1,','456 Elm St,Chicago,IL,USA,60601,,1','789 Elm St,Chicago,IL,USA,60601'};
        String accName = 'Test Company';
        Account acc =  new Account(Name = 'Test');
        insert acc;
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = acc.id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
        
        Test.startTest();
        Boolean result = API_CB_AutoCompleteAddress_QRY.bulkAddressInsert(addresses, opp.Id);
        Test.stopTest();
    }
    
    /*@IsTest
    static void testValidateAddress() {
        // Mock HTTP Response
        HttpCalloutMock mock = new MockHttpResponseGenerator(200, '{ "status": "success", "data": { "address": "123 Main St", "city": "Springfield", "state": "IL", "country": "USA", "zipcode": "62704" } }');
        Test.setMock(HttpCalloutMock.class, mock);
        
        List<String> address = new List<String> { '123 Main St,Springfield,IL,USA,62704'};
            
        Test.startTest();
        List<String> validList = API_CB_AutoCompleteAddress_QRY.validateAddress(address);
        Test.stopTest();
        
    }*/
    
    @IsTest
    static void testEditQuoteAddress1() {
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;
        Product2 testChildProduct2 = new Product2(Name = 'Test Child Product2', Receive_From_Connectbase__c = true);
        insert testChildProduct2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345'
        );
        qlInsert.add(testChildQuoteLine);
        SBQQ__QuoteLine__c testChildQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct2.Id
        );
        //qlInsert.add(testChildQuoteLine2);
        insert qlInsert;
        Test.startTest();
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "input_address": "134 Flanders Road, Westborough, MA, USA, 01581",\n' +
            '  "data": {\n' +
            '    "address_key": "134 FLANDERS RD|WESTBOROUGH|MA|USA",\n' +
            '    "address": "134 Flanders Rd",\n' +
            '    "city": "Westborough",\n' +
            '    "state": "Massachusetts",\n' +
            '    "zipcode": "01581",\n' +
            '    "country": "USA",\n' +
            '    "latitude": 42.276468,\n' +
            '    "longitude": -71.570728,\n' +
            '    "primary_number": "134",\n' +
            '    "street_name": "Flanders",\n' +
            '    "street_predirection": "",\n' +
            '    "street_postdirection": "",\n' +
            '    "street_suffix": "Rd",\n' +
            '    "secondary_designator": "Ste",\n' +
            '    "secondary_number": "375",\n' +
            '    "default_city_name": "Westborough",\n' +
            '    "county_name": "Worcester",\n' +
            '    "state_abbreviation": "MA",\n' +
            '    "plus4_code": "",\n' +
            '    "full_zipcode": "01581-1023",\n' +
            '    "glid": "US87JC7CGH+HPRPB",\n' +
            '    "rdi": "Commercial",\n' +
            '    "time_zone": "Eastern",\n' +
            '    "utc_offset": "-5"\n' +
            '  }\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        String response = API_CB_AutoCompleteAddress_QRY.editQuoteAddress(zAdd.Id, '', '134 Flanders Rd', 'Westborough', 'MA', 'USA', '01581', '456 Test St,Test City,Test State,Test Country,12345');
        Test.stopTest();
        
    }
    
     @IsTest
    static void testEditQuoteAddress1_1() {
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;
        Product2 testChildProduct2 = new Product2(Name = 'Test Child Product2', Receive_From_Connectbase__c = true);
        insert testChildProduct2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345'
        );
       // qlInsert.add(testChildQuoteLine);
        SBQQ__QuoteLine__c testChildQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct2.Id
        );
        qlInsert.add(testChildQuoteLine2);
        insert qlInsert;
        Test.startTest();
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "input_address": "134 Flanders Road, Westborough, MA, USA, 01581",\n' +
            '  "data": {\n' +
            '    "address_key": "134 FLANDERS RD|WESTBOROUGH|MA|USA",\n' +
            '    "address": "134 Flanders Rd",\n' +
            '    "city": "Westborough",\n' +
            '    "state": "Massachusetts",\n' +
            '    "zipcode": "01581",\n' +
            '    "country": "USA",\n' +
            '    "latitude": 42.276468,\n' +
            '    "longitude": -71.570728,\n' +
            '    "primary_number": "134",\n' +
            '    "street_name": "Flanders",\n' +
            '    "street_predirection": "",\n' +
            '    "street_postdirection": "",\n' +
            '    "street_suffix": "Rd",\n' +
            '    "secondary_designator": "Ste",\n' +
            '    "secondary_number": "375",\n' +
            '    "default_city_name": "Westborough",\n' +
            '    "county_name": "Worcester",\n' +
            '    "state_abbreviation": "MA",\n' +
            '    "plus4_code": "",\n' +
            '    "full_zipcode": "01581-1023",\n' +
            '    "glid": "US87JC7CGH+HPRPB",\n' +
            '    "rdi": "Commercial",\n' +
            '    "time_zone": "Eastern",\n' +
            '    "utc_offset": "-5"\n' +
            '  }\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        String response = API_CB_AutoCompleteAddress_QRY.editQuoteAddress(zAdd.Id, '', '134 Flanders Rd', 'Westborough', 'MA', 'USA', '01581', '456 Test St,Test City,Test State,Test Country,12345');
        Test.stopTest();
        
    }
    
    @IsTest
    static void testEditQuoteAddress2_1() {
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;
        Product2 testChildProduct2 = new Product2(Name = 'Test Child Product2', Receive_From_Connectbase__c = true);
        insert testChildProduct2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345'
        );
       // qlInsert.add(testChildQuoteLine);
        SBQQ__QuoteLine__c testChildQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct2.Id
        );
        qlInsert.add(testChildQuoteLine2);
        insert qlInsert;
        Test.startTest();
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "input_address": "134 Flanders Road, Westborough, MA, USA, 01581",\n' +
            '  "data": {\n' +
            '    "address_key": "134 FLANDERS RD|WESTBOROUGH|MA|USA",\n' +
            '    "address": "134 Flanders Rd",\n' +
            '    "city": "Westborough",\n' +
            '    "state": "Massachusetts",\n' +
            '    "zipcode": "01581",\n' +
            '    "country": "USA",\n' +
            '    "latitude": 42.276468,\n' +
            '    "longitude": -71.570728,\n' +
            '    "primary_number": "134",\n' +
            '    "street_name": "Flanders",\n' +
            '    "street_predirection": "",\n' +
            '    "street_postdirection": "",\n' +
            '    "street_suffix": "Rd",\n' +
            '    "secondary_designator": "Ste",\n' +
            '    "secondary_number": "375",\n' +
            '    "default_city_name": "Westborough",\n' +
            '    "county_name": "Worcester",\n' +
            '    "state_abbreviation": "MA",\n' +
            '    "plus4_code": "",\n' +
            '    "full_zipcode": "01581-1023",\n' +
            '    "glid": "US87JC7CGH+HPRPB",\n' +
            '    "rdi": "Commercial",\n' +
            '    "time_zone": "Eastern",\n' +
            '    "utc_offset": "-5"\n' +
            '  }\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        String response = API_CB_AutoCompleteAddress_QRY.editQuoteAddress(zAdd.Id, 'test', '134 Flanders Rd', 'Westborough', 'MA', 'USA', '01581', '456 Test St,Test City,Test State,Test Country,12345');
        Test.stopTest();
        
    }
    
    
    @IsTest
    static void testEditQuoteAddress3() {
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;
        Product2 testChildProduct2 = new Product2(Name = 'Test Child Product2', Receive_From_Connectbase__c = true);
        insert testChildProduct2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345'
        );
        qlInsert.add(testChildQuoteLine);
        SBQQ__QuoteLine__c testChildQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct2.Id
        );
        //qlInsert.add(testChildQuoteLine2);
        insert qlInsert;
        Test.startTest();
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "input_address": "134 Flanders Road, Westborough, MA, USA, 01581",\n' +
            '  "data": {\n' +
            '    "address_key": "134 FLANDERS RD|WESTBOROUGH|MA|USA",\n' +
            '    "address": "134 Flanders Rd",\n' +
            '    "city": "Westborough",\n' +
            '    "state": "Massachusetts",\n' +
            '    "zipcode": "01581",\n' +
            '    "country": "USA",\n' +
            '    "latitude": 42.276468,\n' +
            '    "longitude": -71.570728,\n' +
            '    "primary_number": "134",\n' +
            '    "street_name": "Flanders",\n' +
            '    "street_predirection": "",\n' +
            '    "street_postdirection": "",\n' +
            '    "street_suffix": "Rd",\n' +
            '    "secondary_designator": "Ste",\n' +
            '    "secondary_number": "375",\n' +
            '    "default_city_name": "Westborough",\n' +
            '    "county_name": "Worcester",\n' +
            '    "state_abbreviation": "MA",\n' +
            '    "plus4_code": "",\n' +
            '    "full_zipcode": "01581-1023",\n' +
            '    "glid": "US87JC7CGH+HPRPB",\n' +
            '    "rdi": "Commercial",\n' +
            '    "time_zone": "Eastern",\n' +
            '    "utc_offset": "-5"\n' +
            '  }\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        String response = API_CB_AutoCompleteAddress_QRY.editQuoteAddress(aAdd.Id, '', '134 Flanders Rd', 'Westborough', 'MA', 'USA', '01581', '456 Test St,Test City,Test State,Test Country,12345');
        Test.stopTest();
        
    }
    
     @IsTest
    static void testEditQuoteAddress3_1() {
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;
        Product2 testChildProduct2 = new Product2(Name = 'Test Child Product2', Receive_From_Connectbase__c = true);
        insert testChildProduct2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345'
        );
       // qlInsert.add(testChildQuoteLine);
        SBQQ__QuoteLine__c testChildQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct2.Id
        );
        qlInsert.add(testChildQuoteLine2);
        insert qlInsert;
        Test.startTest();
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "input_address": "134 Flanders Road, Westborough, MA, USA, 01581",\n' +
            '  "data": {\n' +
            '    "address_key": "134 FLANDERS RD|WESTBOROUGH|MA|USA",\n' +
            '    "address": "134 Flanders Rd",\n' +
            '    "city": "Westborough",\n' +
            '    "state": "Massachusetts",\n' +
            '    "zipcode": "01581",\n' +
            '    "country": "USA",\n' +
            '    "latitude": 42.276468,\n' +
            '    "longitude": -71.570728,\n' +
            '    "primary_number": "134",\n' +
            '    "street_name": "Flanders",\n' +
            '    "street_predirection": "",\n' +
            '    "street_postdirection": "",\n' +
            '    "street_suffix": "Rd",\n' +
            '    "secondary_designator": "Ste",\n' +
            '    "secondary_number": "375",\n' +
            '    "default_city_name": "Westborough",\n' +
            '    "county_name": "Worcester",\n' +
            '    "state_abbreviation": "MA",\n' +
            '    "plus4_code": "",\n' +
            '    "full_zipcode": "01581-1023",\n' +
            '    "glid": "US87JC7CGH+HPRPB",\n' +
            '    "rdi": "Commercial",\n' +
            '    "time_zone": "Eastern",\n' +
            '    "utc_offset": "-5"\n' +
            '  }\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        String response = API_CB_AutoCompleteAddress_QRY.editQuoteAddress(aAdd.Id, '', '134 Flanders Rd', 'Westborough', 'MA', 'USA', '01581', '456 Test St,Test City,Test State,Test Country,12345');
        Test.stopTest();
        
    }
    
    @IsTest
    static void testEditQuoteAddress4() {
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;
        Product2 testChildProduct2 = new Product2(Name = 'Test Child Product2', Receive_From_Connectbase__c = true);
        insert testChildProduct2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345'
        );
       // qlInsert.add(testChildQuoteLine);
        SBQQ__QuoteLine__c testChildQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct2.Id
        );
        qlInsert.add(testChildQuoteLine2);
        insert qlInsert;
        Test.startTest();
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "input_address": "134 Flanders Road, Westborough, MA, USA, 01581",\n' +
            '  "data": {\n' +
            '    "address_key": "134 FLANDERS RD|WESTBOROUGH|MA|USA",\n' +
            '    "address": "134 Flanders Rd",\n' +
            '    "city": "Westborough",\n' +
            '    "state": "Massachusetts",\n' +
            '    "zipcode": "01581",\n' +
            '    "country": "USA",\n' +
            '    "latitude": 42.276468,\n' +
            '    "longitude": -71.570728,\n' +
            '    "primary_number": "134",\n' +
            '    "street_name": "Flanders",\n' +
            '    "street_predirection": "",\n' +
            '    "street_postdirection": "",\n' +
            '    "street_suffix": "Rd",\n' +
            '    "secondary_designator": "Ste",\n' +
            '    "secondary_number": "375",\n' +
            '    "default_city_name": "Westborough",\n' +
            '    "county_name": "Worcester",\n' +
            '    "state_abbreviation": "MA",\n' +
            '    "plus4_code": "",\n' +
            '    "full_zipcode": "01581-1023",\n' +
            '    "glid": "US87JC7CGH+HPRPB",\n' +
            '    "rdi": "Commercial",\n' +
            '    "time_zone": "Eastern",\n' +
            '    "utc_offset": "-5"\n' +
            '  }\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        String response = API_CB_AutoCompleteAddress_QRY.editQuoteAddress(aAdd.Id, 'test', '134 Flanders Rd', 'Westborough', 'MA', 'USA', '01581', '456 Test St,Test City,Test State,Test Country,12345');
        Test.stopTest();
        
    }
    
     @IsTest
    static void testEditQuoteAddress4_1() {
        Product2 testChildProduct = new Product2(Name = 'Test Child Product', Send_To_Connectbase__c = true);
        insert testChildProduct;
        Product2 testChildProduct2 = new Product2(Name = 'Test Child Product2', Receive_From_Connectbase__c = true);
        insert testChildProduct2;

        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            Z_Address__c = true
        );
        insert zAdd;

        Quote_Address__c aAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345',
            Network_Status__c = 'Off Net',
            A_Address__c = true,
            z_Quote_Address__c = zAdd.Id
        );
        insert aAdd;

        SBQQ__QuoteLineGroup__c testGroup = new SBQQ__QuoteLineGroup__c(
            Name = 'Test Group',
            SBQQ__Quote__c = testQuote.Id,
            Quote_Address__c = aAdd.Id,
            Network_Status__c = 'Off Net'
        );
        insert testGroup;
        List<SBQQ__QuoteLine__c> qlInsert = new List<SBQQ__QuoteLine__c>();
        SBQQ__QuoteLine__c testChildQuoteLine = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct.Id,
            Street__c = '456 Test St',
            City__c = 'Test City',
            State__c = 'Test State',
            Country__c = 'Test Country',
            Zip__c = '12345'
        );
       // qlInsert.add(testChildQuoteLine);
        SBQQ__QuoteLine__c testChildQuoteLine2 = new SBQQ__QuoteLine__c(
            SBQQ__Quote__c = testQuote.Id,
            SBQQ__Group__c = testGroup.Id,
            SBQQ__Product__c = testChildProduct2.Id
        );
        qlInsert.add(testChildQuoteLine2);
        insert qlInsert;
        Test.startTest();
        HttpCalloutMock mock = new MockHttpResponseGenerator(
            200, 
            '{\n' +
            '  "status": "success",\n' +
            '  "input_address": "134 Flanders Road, Westborough, MA, USA, 01581",\n' +
            '  "data": {\n' +
            '    "address_key": "134 FLANDERS RD|WESTBOROUGH|MA|USA",\n' +
            '    "address": "134 Flanders Rd",\n' +
            '    "city": "Westborough",\n' +
            '    "state": "Massachusetts",\n' +
            '    "zipcode": "01581",\n' +
            '    "country": "USA",\n' +
            '    "latitude": 42.276468,\n' +
            '    "longitude": -71.570728,\n' +
            '    "primary_number": "134",\n' +
            '    "street_name": "Flanders",\n' +
            '    "street_predirection": "",\n' +
            '    "street_postdirection": "",\n' +
            '    "street_suffix": "Rd",\n' +
            '    "secondary_designator": "Ste",\n' +
            '    "secondary_number": "375",\n' +
            '    "default_city_name": "Westborough",\n' +
            '    "county_name": "Worcester",\n' +
            '    "state_abbreviation": "MA",\n' +
            '    "plus4_code": "",\n' +
            '    "full_zipcode": "01581-1023",\n' +
            '    "glid": "US87JC7CGH+HPRPB",\n' +
            '    "rdi": "Commercial",\n' +
            '    "time_zone": "Eastern",\n' +
            '    "utc_offset": "-5"\n' +
            '  }\n' +
            '}'
        );
        Test.setMock(HttpCalloutMock.class, mock);
        String response = API_CB_AutoCompleteAddress_QRY.editQuoteAddress(aAdd.Id, 'test', '134 Flanders Rd', 'Westborough', 'MA', 'USA', '01581', '456 Test St,Test City,Test State,Test Country,12345');
        Test.stopTest();
        
    }
    
    @IsTest
    static void testInsertAllAPIResponse() {
        // Create test data
        List<API_Response__c> responses = new List<API_Response__c>();
        
        Test.startTest();
        API_CB_AutoCompleteAddress_QRY.insertAllAPIResponse(responses);
        Test.stopTest();
        
        List<API_Response__c> insertedResponses = [SELECT Name FROM API_Response__c];
    }
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MockHttpResponseGenerator(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse response = new HttpResponse();
            response.setStatusCode(this.statusCode);
            response.setBody(this.responseBody);
            return response;
        }
    }
}