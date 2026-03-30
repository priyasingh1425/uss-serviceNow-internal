@IsTest
public with sharing class TestDataFactoryTest {

    @IsTest
    static void testCreateAccount() {
        //Test.startTest();
        List<Account> accounts = TestDataFactory.createAccounts(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, accounts, 'Accounts list should not be null');
        System.assertEquals(1, accounts.size(), 'Accounts list should contain exactly one account, actual size: ' + accounts.size());
        System.assertEquals('Test Account1', accounts[0].Name, 'Account name should be "Test Account1"');
    }

    @IsTest
    static void testCreateQuote() {
        //Test.startTest();
        List<SBQQ__Quote__c> quotes = TestDataFactory.createQuotes(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, quotes, 'Quotes list should not be null');
        System.assertEquals(1, quotes.size(), 'Quotes list should contain exactly one quote, actual size: ' + quotes.size());
        System.assertEquals(TestDataFactory.accounts[0].Id, quotes[0].SBQQ__Account__c, 'Related Account Id should be the same as the Account Id from the TestDataFactory');
        System.assertEquals(TestDataFactory.opportunities[0].Id, quotes[0].SBQQ__Opportunity2__c, 'Related Opportunity Id should be the same as the Opportunity Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateOpportunity() {
        //Test.startTest();
        List<Opportunity> opportunities = TestDataFactory.createOpportunity(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, opportunities, 'Opportunities list should not be null');
        System.assertEquals(1, opportunities.size(), 'Opportunities list should contain exactly one opportunity, actual size: ' + opportunities.size());
        System.assertEquals('Test Opportunity1', opportunities[0].Name, 'Opportunity name should be "Test Opportunity1"');
        System.assertEquals(TestDataFactory.accounts[0].Id, opportunities[0].AccountId, 'Related Account Id should be the same as the Account Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateTerms() {
        //Test.startTest();
        List<Term__c> terms = TestDataFactory.createTerms(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, terms, 'Terms list should not be null');
        System.assertEquals(1, terms.size(), 'Terms list should contain exactly one term, actual size: ' + terms.size());
        System.assertEquals('Default Text', terms[0].Text2__c, 'Term text should be "Default Text"');
    }

    @IsTest
    static void testCreateProductTerms() {
        //Test.startTest();
        List<Product_Term__c> productTerms = TestDataFactory.createProductTerms(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, productTerms, 'Product Terms list should not be null');
        System.assertEquals(1, productTerms.size(), 'Product Terms list should contain exactly one product term, actual size: ' + productTerms.size());
        System.assertEquals(TestDataFactory.terms[0].Id, productTerms[0].Term__c, 'Related Term Id should be the same as the Term Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateQuoteLines() {
        //Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLines = TestDataFactory.createQuoteLines(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, quoteLines, 'Quote Lines list should not be null');
        System.assertEquals(1, quoteLines.size(), 'Quote Lines list should contain exactly one quote line, actual size: ' + quoteLines.size());
        System.assertEquals(TestDataFactory.quotes[0].Id, quoteLines[0].SBQQ__Quote__c, 'Related Quote Id should be the same as the Quote Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateProducts(){
        //Test.startTest();
        List<Product2> products = TestDataFactory.createProducts(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, products, 'Products list should not be null');
        System.assertEquals(1, products.size(), 'Products list should contain exactly one product, actual size: ' + products.size());
        System.assertEquals('Test Product1', products[0].Name, 'Product name should be "Test Product1"');
    }

    @IsTest
    static void testCreateApproval(){
        //Test.startTest();
        List<sbaa__Approval__c> approvals = TestDataFactory.createApprovals(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, approvals, 'Approvals list should not be null');
        System.assertEquals(1, approvals.size(), 'Approvals list should contain exactly one approval, actual size: ' + approvals.size());
        System.assertEquals(TestDataFactory.quotes[0].Id, approvals[0].Quote__c, 'Approval related Quote Id should be the same as the Quote Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateApprovalRules(){
        //Test.startTest();
        List<sbaa__ApprovalRule__c> approvalRules = TestDataFactory.createApprovalRules(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, approvalRules, 'Approval Rules list should not be null');
        System.assertEquals(1, approvalRules.size(), 'Approval Rules list should contain exactly one approval rule, actual size: ' + approvalRules.size());
        System.assertEquals('Test Approval Rule1', approvalRules[0].Name, 'Approval Rule name should be "Test Approval Rule1"');
    }

    @IsTest
    static void testCreateContacts(){
        //Test.startTest();
        List<Contact> contacts = TestDataFactory.createContacts(false, 1);
        //Test.stopTest();
        System.assertNotEquals(null, contacts, 'Contacts list should not be null');
        System.assertEquals(1, contacts.size(), 'Contacts list should contain exactly one contact, actual size: ' + contacts.size());
        System.assertEquals('Test Contact1', contacts[0].LastName, 'Contact name should be "Test Contact1"');
    }

    @IsTest
    static void testCreateAccountMultiple() {
        //Test.startTest();
        List<Account> accounts = TestDataFactory.createAccounts(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, accounts, 'Accounts list should not be null');
        System.assertEquals(2, accounts.size(), 'Accounts list should contain exactly one account, actual size: ' + accounts.size());
        System.assertEquals('Test Account1', accounts[0].Name, 'Account name should be "Test Account1"');
        System.assertEquals('Test Account2', accounts[1].Name, 'Account name should be "Test Account2"');
    }

    @IsTest
    static void testCreateQuoteMultiple() {
        //Test.startTest();
        List<SBQQ__Quote__c> quotes = TestDataFactory.createQuotes(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, quotes, 'Quotes list should not be null');
        System.assertEquals(2, quotes.size(), 'Quotes list should contain exactly one quote, actual size: ' + quotes.size());
        System.assertEquals(TestDataFactory.accounts[0].Id, quotes[0].SBQQ__Account__c, 'Related Account name should be "Test Account"');
        System.assertEquals(TestDataFactory.opportunities[0].Id, quotes[0].SBQQ__Opportunity2__c, 'Related Opportunity name should be "Test Opportunity"');
        System.assertEquals(TestDataFactory.accounts[0].Id, quotes[1].SBQQ__Account__c, 'Related Account name should be "Test Account"');
        System.assertEquals(TestDataFactory.opportunities[0].Id, quotes[1].SBQQ__Opportunity2__c, 'Related Opportunity name should be "Test Opportunity"');
    }

    @IsTest
    static void testCreateOpportunityMultiple() {
        //Test.startTest();
        List<Opportunity> opportunities = TestDataFactory.createOpportunity(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, opportunities, 'Opportunities list should not be null');
        System.assertEquals(2, opportunities.size(), 'Opportunities list should contain exactly one opportunity, actual size: ' + opportunities.size());
        System.assertEquals('Test Opportunity1', opportunities[0].Name, 'Opportunity name should be "Test Opportunity1"');
        System.assertEquals(TestDataFactory.accounts[0].Id, opportunities[0].AccountId, 'Related Account Id should be the same as the Account Id from the TestDataFactory');
        System.assertEquals('Test Opportunity2', opportunities[1].Name, 'Opportunity name should be "Test Opportunity2"');
    }

    @IsTest
    static void testCreateTermsMultiple() {
        //Test.startTest();
        List<Term__c> terms = TestDataFactory.createTerms(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, terms, 'Terms list should not be null');
        System.assertEquals(2, terms.size(), 'Terms list should contain exactly one term, actual size: ' + terms.size());
        System.assertEquals('Default Text', terms[0].Text2__c, 'Term text should be "Default Text"');
        System.assertEquals('Default Text', terms[1].Text2__c, 'Term text should be "Default Text"');
    }

    @IsTest
    static void testCreateProductTermsMultiple() {
        //Test.startTest();
        List<Product_Term__c> productTerms = TestDataFactory.createProductTerms(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, productTerms, 'Product Terms list should not be null');
        System.assertEquals(2, productTerms.size(), 'Product Terms list should contain exactly one product term, actual size: ' + productTerms.size());
        System.assertEquals(TestDataFactory.terms[0].Id, productTerms[0].Term__c, 'Related Term Id should be the same as the Term Id from the TestDataFactory');
        System.assertEquals(TestDataFactory.terms[0].Id, productTerms[1].Term__c, 'Related Term Id should be the same as the Term Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateQuoteLinesMultiple() {
        //Test.startTest();
        List<SBQQ__QuoteLine__c> quoteLines = TestDataFactory.createQuoteLines(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, quoteLines, 'Quote Lines list should not be null');
        System.assertEquals(2, quoteLines.size(), 'Quote Lines list should contain exactly one quote line, actual size: ' + quoteLines.size());
        System.assertEquals(TestDataFactory.quotes[0].Id, quoteLines[0].SBQQ__Quote__c, 'Related Quote Id should be the same as the Quote Id from the TestDataFactory');
        System.assertEquals(TestDataFactory.quotes[0].Id, quoteLines[1].SBQQ__Quote__c, 'Related Quote Id should be the same as the Quote Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateProductsMultiple(){
        //Test.startTest();
        List<Product2> products = TestDataFactory.createProducts(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, products, 'Products list should not be null');
        System.assertEquals(2, products.size(), 'Products list should contain exactly one product, actual size: ' + products.size());
        System.assertEquals('Test Product1', products[0].Name, 'Product name should be "Test Product1"');
        System.assertEquals('Test Product2', products[1].Name, 'Product name should be "Test Product2"');
    }

    @IsTest
    static void testCreateApprovalMultiple(){
        //Test.startTest();
        List<sbaa__Approval__c> approvals = TestDataFactory.createApprovals(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, approvals, 'Approvals list should not be null');
        System.assertEquals(2, approvals.size(), 'Approvals list should contain exactly one approval, actual size: ' + approvals.size());
        System.assertEquals(TestDataFactory.quotes[0].Id, approvals[0].Quote__c, 'Approval related Quote Id should be the same as the Quote Id from the TestDataFactory');
        System.assertEquals(TestDataFactory.quotes[0].Id, approvals[1].Quote__c, 'Approval related Quote Id should be the same as the Quote Id from the TestDataFactory');
    }

    @IsTest
    static void testCreateApprovalRulesMultiple(){
        //Test.startTest();
        List<sbaa__ApprovalRule__c> approvalRules = TestDataFactory.createApprovalRules(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, approvalRules, 'Approval Rules list should not be null');
        System.assertEquals(2, approvalRules.size(), 'Approval Rules list should contain exactly one approval rule, actual size: ' + approvalRules.size());
        System.assertEquals('Test Approval Rule1', approvalRules[0].Name, 'Approval Rule name should be "Test Approval Rule1"');
        System.assertEquals('Test Approval Rule2', approvalRules[1].Name, 'Approval Rule name should be "Test Approval Rule2"');
    }

    @IsTest
    static void testCreateContactsMultiple(){
        //Test.startTest();
        List<Contact> contacts = TestDataFactory.createContacts(false, 2);
        //Test.stopTest();
        System.assertNotEquals(null, contacts, 'Contacts list should not be null');
        System.assertEquals(2, contacts.size(), 'Contacts list should contain exactly one contact, actual size: ' + contacts.size());
        System.assertEquals('Test Contact1', contacts[0].LastName, 'Contact name should be "Test Contact1"');
        System.assertEquals('Test Contact2', contacts[1].LastName, 'Contact name should be "Test Contact2"');
    }

    @IsTest
    static void testCreateAccountContactRelationship(){
        System.runAs(TestDataFactory.createUser(true, null,null)) {
            List<AccountContactRelation> accountContactRelations = TestDataFactory.createAccountContactRelations(false, 1);

            System.assertNotEquals(null, accountContactRelations, 'Account Contact Relations list should not be null');
            System.assertEquals(1, accountContactRelations.size(), 'Account Contact Relations list should contain exactly one account contact relation, actual size: ' + accountContactRelations.size());
            Boolean found = false;
            for(Account acc : TestDataFactory.accounts){
                if(acc.Id == accountContactRelations[0].AccountId){
                    found = true;
                    break;
                }
            }
            System.assert(found, 'Related Account Id should be the same as the Account Id from the TestDataFactory');
            System.assertEquals(TestDataFactory.contacts[0].Id, accountContactRelations[0].ContactId, 'Related Contact Id should be the same as the Contact Id from the TestDataFactory');
        }
    }

    @IsTest
    static void testCreateAccountContactRelationshipExplicit(){

        System.runAs(TestDataFactory.createUser(true, null,null)) {
            List<Account> accList = TestDataFactory.createAccounts(1,'Explicit Account','Customer',null);
            List<Contact> conList = TestDataFactory.createContacts(1,'Explicit Contact','Customer',accList[0].Id);

            Id accountId = TestDataFactory.createAccounts(1,'Explicit Account','Customer',null)[0].Id;
            List<AccountContactRelation> accountContactRelations = TestDataFactory.createAccountContactRelations(1,
                    conList[0].Id,
                    accountId,
                    true,
                    '');

            System.assertNotEquals(null, accountContactRelations, 'Account Contact Relations list should not be null');
            System.assertEquals(1, accountContactRelations.size(), 'Account Contact Relations list should contain exactly one account contact relation, actual size: ' + accountContactRelations.size());
//            System.assertEquals(TestDataFactory.accounts[2].Id, accountContactRelations[0].AccountId, 'Related Account Id should be the same as the Account Id from the TestDataFactory');
            System.assertEquals(TestDataFactory.contacts[0].Id, accountContactRelations[0].ContactId, 'Related Contact Id should be the same as the Contact Id from the TestDataFactory');
        }
    }

    @IsTest
    static void testCreateUser(){

    }

    //TODO: Test for static lists clearing after Test.stopTest()
}