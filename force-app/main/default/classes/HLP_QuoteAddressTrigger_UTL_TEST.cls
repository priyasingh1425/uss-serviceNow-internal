@IsTest
public class HLP_QuoteAddressTrigger_UTL_TEST {
    @IsTest
    static void testCreateQuoteLineGroup() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            AccountId = acc.Id,
            CloseDate = Date.today(),
            StageName = 'Prospect'
        );
        insert opp;
        Test.startTest();
        SBQQ__Quote__c testQuote = new SBQQ__Quote__c(
            SBQQ__Account__c = acc.Id,
            SBQQ__Opportunity2__c = opp.Id,
            SBQQ__Primary__c = true
        );
        insert testQuote;

        Quote_Address__c zAdd = new Quote_Address__c(
            Opportunity__c = opp.Id,
            Street__c = '123 Test St',
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
        Test.stopTest();
    }
}