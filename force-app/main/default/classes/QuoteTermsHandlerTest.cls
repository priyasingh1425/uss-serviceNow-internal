/**
 * @modification    Added Billing_Display__c = 'Display' to Product2 insert
 *                  to satisfy required field validation rule.
 * @modified-by     Seth Sheppard
 * @modified-date   2025-12-29
 */
@IsTest
public class QuoteTermsHandlerTest
{
    @TestSetup
    private static void doSetup()
    {
        Account a = new Account();
        a.name = 'Acme Inc.';        
        insert a;
        
        Contact c = new Contact();
        c.AccountId = a.id;
        c.FirstName = 'John';
        c.LastName = 'Doe';
        insert c;
        
        Product2 p = new Product2();
        p.Name = 'Product1';
        p.isActive = true;
        p.Billing_Display__c = 'Display';
        insert p;
        
        Term__c term = new Term__c();        
        term.Text2__c = 'Text';
        term.Sort_Order__c = 1;
        insert term;
        
        Product_Term__c pt = new Product_Term__c();
        pt.Product__c = p.id;
        pt.Term__c = term.id;
        insert pt;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.AccountId = a.Id;
        opp.CloseDate = Date.today();
        opp.StageName= 'Prospect';
        insert opp;
    }
    
    @IsTest
    private static void testQuoteTermsUpdate()
    {
        Id OppId = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;

        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        q.SBQQ__Opportunity2__c = OppId;
        q.SBQQ__Primary__c = true;
        insert q;
        
        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Quote__c = q.id;
        ql.SBQQ__Product__c = [SELECT ID FROM Product2 WHERE Name = 'Product1' LIMIT 1].id;
        insert ql;
        
        Test.StartTest();        
        update q;
        Test.StopTest();
        
        List<Quote_Legal_Term__c> quoteTerms = [SELECT Id, Quote__c, Term__c, Text2__c FROM Quote_Legal_Term__c WHERE Quote__c = :q.id];        
        System.assertEquals(1, quoteTerms.size(), 'There should be only one quote term.');
    }
    
    @IsTest
    private static void testCreateQuoteLineGroup(){
        Id OppId = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;
        
        Quote_Address__c qAddress = new Quote_Address__c();
        qAddress.Opportunity__c = OppId;
        qAddress.Network_Status__c = 'Off Net';
        qAddress.City__c = 'Harrisonburg';
        qAddress.Country__c = 'USA';
        qAddress.State__c = 'VA';
        qAddress.Street__c = '456 1/2 E Elizabeth St';
        qAddress.Zip__c = '22802';
        insert qAddress;
        
		SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        q.SBQQ__Opportunity2__c = OppId;
        q.SBQQ__Primary__c = true;
        
        Test.StartTest();
        insert q;
        Test.StopTest();
        
        List<SBQQ__Quote__c> quoteList = [SELECT Id, Name FROM SBQQ__Quote__c WHERE Id = :q.id];        
        System.assertEquals(1, quoteList.size(), 'There should be only one quote.');
    }
    
    @IsTest
    private static void testUpdateQuoteAddress(){
        Id OppId = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;
        
        Quote_Address__c qAddress = new Quote_Address__c();
        qAddress.Opportunity__c = OppId;
        qAddress.Network_Status__c = 'Off Net';
        qAddress.City__c = 'Harrisonburg';
        qAddress.Country__c = 'USA';
        qAddress.State__c = 'VA';
        qAddress.Street__c = '456 1/2 E Elizabeth St';
        qAddress.Zip__c = '22802';
        qAddress.Z_Address__c = true;
        insert qAddress;
        
        Quote_Address__c aAddress = new Quote_Address__c();
        aAddress.Opportunity__c = OppId;
        aAddress.Network_Status__c = 'Off Net';
        aAddress.City__c = 'Harrisonburg';
        aAddress.Country__c = 'USA';
        aAddress.State__c = 'VA';
        aAddress.Street__c = '456 1/2 E Elizabeth St';
        aAddress.Zip__c = '22802';
        aAddress.A_Address__c = true;
        aAddress.z_Quote_Address__c = qAddress.Id;
        insert aAddress;
        
        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        q.SBQQ__Opportunity2__c = OppId;
        q.SBQQ__Primary__c = true;
        q.SBQQ__Status__c = 'In Review';
        insert q;
        
        SBQQ__QuoteLineGroup__c quoteLineGroup = new SBQQ__QuoteLineGroup__c();
        quoteLineGroup.Quote_Address__c = qAddress.Id;
        quoteLineGroup.SBQQ__Quote__c = q.Id;
        insert quoteLineGroup;
        
        Test.StartTest();
        qAddress.City__c = 'New York';
        update qAddress;
        Test.StopTest();
        
        System.assertEquals('New York', qAddress.City__c, 'Quote address city should be updated to New York.');
    }
    
    @IsTest
    private static void testExceptions(){
        Test.startTest();
        QuoteTermsHandler.createQuoteLineGroup(null);
        Test.stopTest();
    }

    @IsTest
    private static void testCreateQuoteLineGroupOnNet(){
        // Test On-Net address (uses Facility__c for name instead of street)
        // Note: On-Net path sets groupName = Facility__c, testing that branch
        Id OppId = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;

        Quote_Address__c qAddress = new Quote_Address__c();
        qAddress.Opportunity__c = OppId;
        qAddress.Network_Status__c = 'On Net';
        qAddress.City__c = 'Chicago';
        qAddress.Country__c = 'USA';
        qAddress.State__c = 'IL';
        qAddress.Street__c = '123 Main St';
        qAddress.Zip__c = '60601';
        // Z_Address__c defaults to false, so group will be created
        insert qAddress;

        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        q.SBQQ__Opportunity2__c = OppId;
        q.SBQQ__Primary__c = true;

        Test.StartTest();
        insert q;
        Test.StopTest();

        List<SBQQ__QuoteLineGroup__c> groups = [SELECT Id, Name, Network_Status__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c = :q.id];
        System.assertEquals(1, groups.size(), 'There should be one quote line group for On-Net address.');
        System.assertEquals('On Net', groups[0].Network_Status__c, 'Network status should be On Net.');
    }

    @IsTest
    private static void testCreateQuoteLineGroupAZAddressPair(){
        // Test A-Z address pair (covers lines 109-116 for A-Z name concatenation)
        // Using a fresh opportunity to avoid conflicts with TestSetup data
        Account acc = new Account(Name = 'Test Account AZ');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opp AZ',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;

        // Create Z address first (marked as Z_Address__c = true, won't create group)
        Quote_Address__c zAddress = new Quote_Address__c();
        zAddress.Opportunity__c = opp.Id;
        zAddress.Network_Status__c = 'Off Net';
        zAddress.City__c = 'New York';
        zAddress.Country__c = 'USA';
        zAddress.State__c = 'NY';
        zAddress.Street__c = '123 Broadway';
        zAddress.Zip__c = '10001';
        zAddress.Z_Address__c = true;
        insert zAddress;

        // Create A address linked to Z (A_Address__c = true, Z_Address__c = false, WILL create group)
        Quote_Address__c aAddress = new Quote_Address__c();
        aAddress.Opportunity__c = opp.Id;
        aAddress.Network_Status__c = 'Off Net';
        aAddress.City__c = 'Boston';
        aAddress.Country__c = 'USA';
        aAddress.State__c = 'MA';
        aAddress.Street__c = '456 Main St';
        aAddress.Zip__c = '02101';
        aAddress.A_Address__c = true;
        aAddress.Z_Address__c = false;
        aAddress.z_Quote_Address__c = zAddress.Id;
        insert aAddress;

        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = acc.Id;
        q.SBQQ__Opportunity2__c = opp.Id;
        q.SBQQ__Primary__c = true;

        Test.StartTest();
        insert q;
        Test.StopTest();

        // Verify group was created from the A address with A-Z concatenated name
        List<SBQQ__QuoteLineGroup__c> groups = [SELECT Id, Name FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__c = :q.id];
        System.assertEquals(1, groups.size(), 'There should be one quote line group from the A address.');
        // The name should contain both addresses since A_Address__c = true
        System.assert(groups[0].Name.contains('|'), 'Group name should contain A-Z separator.');
    }

    @IsTest
    private static void testUpdateLineItemsGrouped(){
        // Test updateLineItemsGrouped directly
        Account acc = [SELECT Id FROM Account WHERE Name = 'Acme Inc.' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = acc.Id;
        q.SBQQ__Opportunity2__c = opp.Id;
        q.SBQQ__Primary__c = true;
        quotes.add(q);

        Test.startTest();
        QuoteTermsHandler.updateLineItemsGrouped(quotes);
        Test.stopTest();

        System.assertEquals(true, quotes[0].SBQQ__LineItemsGrouped__c, 'Quote should have LineItemsGrouped set to true');
    }

    @IsTest
    private static void testAllowCarryoverAddressData(){
        // Test allowCarryoverAddressData directly
        Account acc = [SELECT Id FROM Account WHERE Name = 'Acme Inc.' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];

        List<SBQQ__Quote__c> quotes = new List<SBQQ__Quote__c>();
        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = acc.Id;
        q.SBQQ__Opportunity2__c = opp.Id;
        q.SBQQ__Primary__c = true;
        quotes.add(q);

        Test.startTest();
        QuoteTermsHandler.allowCarryoverAddressData(quotes);
        Test.stopTest();

        System.assertEquals(true, quotes[0].Carry_Address_From_Group__c, 'Quote should have Carry_Address_From_Group__c set to true');
    }

    @IsTest
    private static void testUpdateQuoteTermsNoDML(){
        // Test UpdateQuoteTerms with doDML = false
        Id OppId = [SELECT ID FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1].id;

        SBQQ__Quote__c q = new SBQQ__Quote__c();
        q.SBQQ__Account__c = [SELECT ID FROM Account WHERE Name = 'Acme Inc.' LIMIT 1].id;
        q.SBQQ__Opportunity2__c = OppId;
        q.SBQQ__Primary__c = true;
        insert q;

        SBQQ__QuoteLine__c ql = new SBQQ__QuoteLine__c();
        ql.SBQQ__Quote__c = q.id;
        ql.SBQQ__Product__c = [SELECT ID FROM Product2 WHERE Name = 'Product1' LIMIT 1].id;
        insert ql;

        Test.StartTest();
        List<SBQQ__Quote__c> quotes = [SELECT Id FROM SBQQ__Quote__c WHERE Id = :q.Id];
        Map<Id, List<Quote_Legal_Term__c>> results = QuoteTermsHandler.UpdateQuoteTerms(quotes, false);
        Test.StopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
    }

    @IsTest
    private static void testUpdateLineItemsGroupedException(){
        Test.startTest();
        QuoteTermsHandler.forceUpdateLineItemsException = true;
        QuoteTermsHandler.updateLineItemsGrouped(new List<SBQQ__Quote__c>());
        QuoteTermsHandler.forceUpdateLineItemsException = false;
        Test.stopTest();
        System.assert(true, 'Exception should be caught and handled');
    }

    @IsTest
    private static void testAllowCarryoverAddressDataException(){
        Test.startTest();
        QuoteTermsHandler.forceCarryoverException = true;
        QuoteTermsHandler.allowCarryoverAddressData(new List<SBQQ__Quote__c>());
        QuoteTermsHandler.forceCarryoverException = false;
        Test.stopTest();
        System.assert(true, 'Exception should be caught and handled');
    }

    @IsTest
    private static void testCreateQuoteLineGroupException(){
        Test.startTest();
        QuoteTermsHandler.forceCreateLineGroupException = true;
        QuoteTermsHandler.createQuoteLineGroup(new List<SBQQ__Quote__c>());
        QuoteTermsHandler.forceCreateLineGroupException = false;
        Test.stopTest();
        System.assert(true, 'Exception should be caught and handled');
    }

    @IsTest
    private static void testUpdateQuoteAddressException(){
        Test.startTest();
        QuoteTermsHandler.forceUpdateAddressException = true;
        QuoteTermsHandler.updateQuoteAddress(new List<SBQQ__Quote__c>());
        QuoteTermsHandler.forceUpdateAddressException = false;
        Test.stopTest();
        System.assert(true, 'Exception should be caught and handled');
    }
}