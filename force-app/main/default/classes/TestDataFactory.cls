/**
 * Created by RyanO'Keefe on 11/8/2024.
 */

public with sharing class TestDataFactory {
    public static List<Account> accounts;
    public static List<SBQQ__Quote__c> quotes;
    public static List<SBQQ__QuoteLine__c> quoteLines;
    public static List<Opportunity> opportunities;
    public static List<Term__c> terms;
    public static List<Product_Term__c> productTerms;
    public static List<Product2> products;
    public static List<sbaa__Approval__c> approvals;
    public static List<sbaa__ApprovalRule__c> approvalRules;
    public static List<Contact> contacts;
    public static List<User> users;
    public static List<PermissionSet> permissionSets;
    public static List<AccountContactRelation> accountContactRelations;
    //  TODO: set a list of custom permissions for bypasses

    /**
     * @param useExisting
     * @param profileName
     * @param lstOfPermissionSets - leave null for all, or pass an empty list for none or pass in a list of permission set names
     *
     * @return
     */
    public static User createUser(Boolean useExisting, String profileName, List<String> lstOfPermissionSets) {
        if(users == null) {
            users = new List<User>();
        }
        if(permissionSets == null) {
            permissionSets = new List<PermissionSet>();
        }
        if(profileName == null) {
            profileName = 'System Administrator';
        }
        if(useExisting) {
            if(users.size() > 0) {
                return users[0];
            }
        }
        List<PermissionSetAssignment> lstOfPSA = new List<PermissionSetAssignment>();
        String userName = 'testUser';
        String userEmail = userName + Math.random() + '@test.com.invalid';
        User userRecord;
        Id profileId = [SELECT Id FROM Profile WHERE Name = :profileName limit 1].Id;
        userRecord = new User(
                ProfileId = profileId,
                LastName = 'last',
                Email = userEmail,
                Username = userName + '@testOrg.' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = userName,
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
        );
        insert userRecord;
        users.add(userRecord);
        List<PermissionSet> psList = null;

        if(lstOfPermissionSets == null){
            psList = [SELECT Id,Name FROM PermissionSet WHERE ProfileId = NULL AND LicenseId = NULL];
        } else{
            psList = [SELECT Id FROM PermissionSet WHERE Name IN :lstOfPermissionSets];
        }

        for (PermissionSet psRec : psList) {
            PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userRecord.Id, PermissionSetId = psRec.Id);
            lstOfPSA.add(psa);
        }
        insert lstOfPSA;
        permissionSets.addAll(psList);

        return userRecord;
    }

    /***
     * @description - always creates a list of new accounts. Should only be used when you want to create new accounts
     * will not return existing accounts *ever*
     *
     * @param count - number of accounts to create
     * @param name - name of the account
     * @param type - type of the account
     * @param recordTypeId - record type id of the account
     *
     * @return - list of newly created accounts
     */
    public static List<Account> createAccounts(Integer count, String name, String type, String recordTypeId) {
        if(accounts == null) {
            accounts = new List<Account>();
        }
        if(name == null) {
            name = 'Test Account';
        }
        if(type == null) {
            type = 'Customer';
        }
        if(recordTypeId == null) {
            recordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND Name = 'Customer' LIMIT 1].Id;
        }
        Integer currSize = accounts.size();
        List<Account> newAccounts = new List<Account>();
        for(Integer i = 0; i < count; i++) {
            Account newAcc = new Account(Name = name+(currSize+i+1), Type=type, RecordTypeId=recordTypeId);
            accounts.add(newAcc);
            newAccounts.add(newAcc);
        }

        insert newAccounts;
        return newAccounts;
    }

    /**
     * @param useExisting
     * @param count
     *
     * @return
     */
    public static List<Account> createAccounts(Boolean useExisting, Integer count) {
        if(accounts == null) {
            accounts = new List<Account>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any accounts
        if (useExisting) {
            if (accounts.size() >= count) {
                return accounts;
            }else{
                // if we need to create accounts, we need to know how many already exist
                countToCreate = count - accounts.size();
            }
        }

        List<Account> newlyCreated = createAccounts(countToCreate, null, null, null);

        if(useExisting) {
            return accounts;
        }

        return newlyCreated;
    }

    /**
     * @param count
     * @param name
     * @param accountId
     * @param opportunityId
     * @param primary - note only one primary quote per opportunity(?) or an erro will be thrown
     *
     * @return
     */
    public static List<SBQQ__Quote__c> createQuote(Integer count, Id accountId, Id opportunityId, Boolean primary) {
        if(quotes == null) {
            quotes = new List<SBQQ__Quote__c>();
        }

        if(accountId == null) {
            accountId = createAccounts(true,1)[0].Id;
        }
        if(opportunityId == null) {
            opportunityId = createOpportunity(true,1)[0].Id;
        }
        if(primary == null) {
            primary = true;
        }

        List<SBQQ__Quote__c> newQuotes = new List<SBQQ__Quote__c>();
        for(Integer i = 0; i < count; i++) {
            SBQQ__Quote__c newQuote = new SBQQ__Quote__c(SBQQ__Account__c = accountId, SBQQ__Opportunity2__c = opportunityId, SBQQ__Primary__c = primary);
            primary=false;
            quotes.add(newQuote);
            newQuotes.add(newQuote);
        }

        insert newQuotes;
        return newQuotes;

    }

    public static List<SBQQ__Quote__c> createQuotes(Boolean useExisting, Integer count) {
        if(quotes == null) {
            quotes = new List<SBQQ__Quote__c>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any accounts
        if (useExisting) {
            if (quotes.size() >= count) {
                return quotes;
            }else{
                // if we need to create accounts, we need to know how many already exist
                countToCreate = count - quotes.size();
            }
        }

        List<SBQQ__Quote__c> newlyCreated = createQuote(countToCreate, null, null, null);

        if(useExisting) {
            return quotes;
        }

        return newlyCreated;
    }

    public static List<Opportunity> createOpportunity(Integer count, String name, Id accountId, Date closeDate, String stageName) {
        if(opportunities == null) {
            opportunities = new List<Opportunity>();
        }
        if(name == null) {
            name = 'Test Opportunity';
        }
        if(accountId == null) {
            accountId = createAccounts(true,1)[0].Id;
        }
        if(closeDate == null) {
            closeDate = Date.today();
        }
        if(stageName == null) {
            stageName = 'Prospect';
        }
        Integer currSize = opportunities.size();

        List<Opportunity> newOpportunities = new List<Opportunity>();
        for(Integer i = 0; i < count; i++) {
            Opportunity newOpp = new Opportunity(Name = name+(currSize+i+1), AccountId = accountId, CloseDate = closeDate, StageName = stageName);
            opportunities.add(newOpp);
            newOpportunities.add(newOpp);
        }

        insert newOpportunities;
        return newOpportunities;
    }

    public static List<Opportunity> createOpportunity(Boolean useExisting, Integer count) {
        if(opportunities == null) {
            opportunities = new List<Opportunity>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any opportunities
        if (useExisting) {
            if (countToCreate <= opportunities.size()) {
                return opportunities;
            }
            countToCreate = count - opportunities.size();
        }

        List<Opportunity> newlyCreated = createOpportunity(countToCreate, null, null, null, null);

        if (useExisting) {
            return newlyCreated;
        }

        return opportunities;
    }

    public static List<Term__c> createTerms(Integer count, String text, Integer sortOrder) {
        if(terms == null) {
            terms = new List<Term__c>();
        }
        if(text == null) {
            text = 'Default Text';
        }
        if(sortOrder == null) {
            sortOrder = 1;
        }
        List<Term__c> newTerms = new List<Term__c>();
        for (Integer i = 0; i < count; i++) {
            Term__c term = new Term__c();
            term.Text2__c = text != null ? text : 'Default Text';
            term.Sort_Order__c = sortOrder != null ? sortOrder : i + 1;
            terms.add(term);
            newTerms.add(term);
        }
        insert newTerms;
        return newTerms;
    }

    public static List<Term__c> createTerms(Boolean useExisting, Integer count) {
        if(terms == null) {
            terms = new List<Term__c>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any terms
        if (useExisting) {
            if (countToCreate <= terms.size()) {
                return terms;
            }
            countToCreate = count - terms.size();
        }
        List<Term__c> newlyCreated = createTerms(countToCreate, null, null);

        if (useExisting) {
            // if we're using existing, we need to return all of them
            return terms;
        }

        // returns only the newly created terms, not the existing ones
        return newlyCreated;
    }

    public static List<Product_Term__c> createProductTerms(Integer count, Id productId, Id termId) {
        if(productTerms == null) {
            productTerms = new List<Product_Term__c>();
        }
        if(productId == null) {
            productId = createProducts(true,1)[0].Id;
        }
        if(termId == null) {
            termId = createTerms(true,1)[0].Id;
        }
        List<Product_Term__c> newProductTerms = new List<Product_Term__c>();
        for (Integer i = 0; i < count; i++) {
            Product_Term__c productTerm = new Product_Term__c();
            productTerm.Product__c = productId;
            productTerm.Term__c = termId;
            productTerms.add(productTerm);
            newProductTerms.add(productTerm);
        }
        insert newProductTerms;
        return newProductTerms;
    }

    public static List<Product_Term__c> createProductTerms(Boolean useExisting, Integer count) {
        if(productTerms == null) {
            productTerms = new List<Product_Term__c>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any product terms
        if (useExisting) {
            if (countToCreate <= productTerms.size()) {
                return productTerms;
            }
            countToCreate = count - productTerms.size();
        }
        List<Product_Term__c> newlyCreated = createProductTerms(countToCreate, null, null);

        if (useExisting) {
            // if we're using existing, we need to return all of them
            return productTerms;
        }

        // returns only the newly created product terms, not the existing ones
        return newlyCreated;
    }

    public static List<SBQQ__QuoteLine__c> createQuoteLines(Integer count, Id quoteId, Id productId) {
        if(quoteLines == null) {
            quoteLines = new List<SBQQ__QuoteLine__c>();
        }
        if (productId == null) {
            productId = createProducts(true,1)[0].Id;
        }
        if(quoteId == null) {
            quoteId = createQuotes(true,1)[0].Id;
        }
        List<SBQQ__QuoteLine__c> newQuoteLines = new List<SBQQ__QuoteLine__c>();
        for (Integer i = 0; i < count; i++) {
            SBQQ__QuoteLine__c quoteLine = new SBQQ__QuoteLine__c();
            quoteLine.SBQQ__Quote__c = quoteId;
            quoteLine.SBQQ__Product__c = productId;
            newQuoteLines.add(quoteLine);
            quoteLines.add(quoteLine);
        }

        insert newQuoteLines;
        return newQuoteLines;
    }

    public static List<SBQQ__QuoteLine__c> createQuoteLines(Boolean useExisting, Integer count) {
        if(quoteLines == null) {
            quoteLines = new List<SBQQ__QuoteLine__c>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any quote lines
        if (useExisting) {
            if (countToCreate <= quoteLines.size()) {
                return quoteLines;
            }
            countToCreate = count - quoteLines.size();
        }

        List<SBQQ__QuoteLine__c> newlyCreated = createQuoteLines(countToCreate, null, null);

        if (useExisting) {
            // if we're using existing, we need to return all of them
            return quoteLines;
        }

        // returns only the newly created quote lines, not the existing ones
        return newlyCreated;
    }

    public static List<Product2> createProducts(Integer count, String name, String productCode, Boolean isActive) {
        if(products == null) {
            products = new List<Product2>();
        }
        if(name == null) {
            name = 'Test Product';
        }
        if(productCode == null) {
            productCode = 'TP-00';
        }
        if(isActive == null) {
            isActive = true;
        }
        Integer currSize = products.size();

        List<Product2> newProducts = new List<Product2>();
        for(Integer i = 0; i < count; i++) {
            Product2 product = new Product2(Name = name+(currSize+i+1), ProductCode = productCode+(currSize+i+1), IsActive = isActive);
            products.add(product);
            newProducts.add(product);
        }

        insert newProducts;
        return newProducts;
    }

    public static List<Product2> createProducts(Boolean useExisting, Integer count) {
        if(products == null) {
            products = new List<Product2>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any products
        if (useExisting) {
            if (products.size() >= count) {
                return products;
            } else {
                // if we need to create products, we need to know how many already exist
                countToCreate = count - products.size();
            }
        }

        List<Product2> newlyCreated = createProducts(countToCreate, null, null, null);

        if(useExisting) {
            return products;
        }

        return newlyCreated;
    }

    /**
     * @param count - number of approvals to create. Submits to approval API once per. Not bulkified.
     * @param quoteId
     *
     * @return
     */
    public static List<sbaa__Approval__c> createApprovals(Integer count, Id quoteId) {
        if(approvals == null){
            approvals = new List<sbaa__Approval__c>();
        }
        if(quoteId == null) {
            quoteId = createQuotes(true,1)[0].Id;
        }

        List<Id> approvalIds = new List<Id>();
        for(sbaa__Approval__c approval : approvals) {
            approvalIds.add(approval.Id);
        }

        List<sbaa__Approval__c> newApprovals = new List<sbaa__Approval__c>();
        for(Integer i = 0; i < count; i++) {
            // submit not returning approvals
            sbaa__Approval__c newApproval = new sbaa__Approval__c();
            newApproval.Quote__c = quoteId;
            newApprovals.add(newApproval);
            approvals.addAll(newApprovals);
        }
        approvals.addAll(newApprovals);
        return newApprovals;
    }

    public static List<sbaa__Approval__c> createApprovals(Boolean useExisting, Integer count) {
        if(approvals == null){
            approvals = new List<sbaa__Approval__c>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any approvals
        if (useExisting) {
            if (approvals.size() >= count) {
                return approvals;
            } else {
                // if we need to create approvals, we need to know how many already exist
                countToCreate = count - approvals.size();
            }
        }

        List<sbaa__Approval__c> newlyCreated = createApprovals(countToCreate, null);

        if(useExisting) {
            return approvals;
        }

        return newlyCreated;
    }

    public static List<sbaa__ApprovalRule__c> createApprovalRules(Integer count, String name, String gearsetExternalId,String targetObject,Decimal approvalStep) {
        if(approvalRules == null) {
            approvalRules = new List<sbaa__ApprovalRule__c>();
        }
        if(name == null) {
            name = 'Test Approval Rule';
        }
        if(gearsetExternalId == null) {
            gearsetExternalId = 'GEARSET-00';
        }
        if(targetObject == null) {
            targetObject = 'SBQQ__Quote__c';
        }
        if(approvalStep == null) {
            approvalStep = 1;
        }
        Integer currSize = approvalRules.size();

        List<sbaa__ApprovalRule__c> newApprovalRules = new List<sbaa__ApprovalRule__c>();
        for(Integer i = 0; i < count; i++) {
            sbaa__ApprovalRule__c approvalRule = new sbaa__ApprovalRule__c(Name = name+(currSize+i+1), GearsetExternalId__c = gearsetExternalId+(currSize+i+1),sbaa__TargetObject__c = targetObject,sbaa__ApprovalStep__c=approvalStep+(currSize+i+1));
            approvalRules.add(approvalRule);
            newApprovalRules.add(approvalRule);
        }
        System.debug('newApprovalRules: ' + newApprovalRules);
        insert newApprovalRules;
        return newApprovalRules;
    }

    public static List<sbaa__ApprovalRule__c> createApprovalRules(Boolean useExisting, Integer count) {
        if(approvalRules == null) {
            approvalRules = new List<sbaa__ApprovalRule__c>();
        }
        Integer countToCreate = count;
        // early return if we don't need to create any approval rules
        if (useExisting) {
            if (approvalRules.size() >= count) {
                return approvalRules;
            } else {
                // if we need to create approval rules, we need to know how many already exist
                countToCreate = count - approvalRules.size();
            }
        }

        List<sbaa__ApprovalRule__c> newlyCreated = createApprovalRules(countToCreate, null, null,null,null);

        if(useExisting) {
            return approvalRules;
        }

        return newlyCreated;
    }

    public static List<Contact> createContacts(Integer count, String firstName, String lastName, Id accountId) {
        if (contacts == null) {
            contacts = new List<Contact>();
        }
        if (firstName == null) {
            firstName = 'First Name';
        }
        if (lastName == null) {
            lastName = 'Test Contact';
        }
        if (accountId == null) {
            accountId = createAccounts(true, 1)[0].Id;
        }
        Integer currSize = contacts.size();

        List<Contact> newContacts = new List<Contact>();
        for (Integer i = 0; i < count; i++) {
            Contact newContact = new Contact(FirstName = firstName+(currSize+i+1), LastName = lastName+(currSize+i+1), AccountId = accountId);
            contacts.add(newContact);
            newContacts.add(newContact);
        }

        insert newContacts;
        return newContacts;
    }

    public static List<Contact> createContacts(Boolean useExisting, Integer count) {
        if (contacts == null) {
            contacts = new List<Contact>();
        }
        Integer countToCreate = count;
        if (useExisting) {
            if (contacts.size() >= count) {
                return contacts;
            } else {
                countToCreate = count - contacts.size();
            }
        }

        List<Contact> newlyCreated = createContacts(countToCreate, null, null, null);

        if (useExisting) {
            return contacts;
        }

        return newlyCreated;
    }

    public static List<AccountContactRelation> createAccountContactRelations(Integer count, Id contactId, Id accountId, Boolean IsActive, String Roles) {
        if (accountContactRelations == null) {
            accountContactRelations = new List<AccountContactRelation>();
        }
        if(contactId == null) {
            contactId = createContacts(count, 'firstName',  'lastName', accountId)[0].Id;
        }
        if(accountId == null) {
            accountId = createAccounts(false,1)[0].Id;
        }
        if(IsActive == null) {
            IsActive = true;
        }
        if(Roles == null) {
            Roles = 'C1';
        }
        List<AccountContactRelation> newAccountContactRelations = new List<AccountContactRelation>();
        for (Integer i = 0; i < count; i++) {
            AccountContactRelation newAccountContactRelation = new AccountContactRelation(ContactId = contactId, AccountId = accountId, IsActive = IsActive, Roles = Roles);
            newAccountContactRelations.add(newAccountContactRelation);
            accountContactRelations.add(newAccountContactRelation);
        }
        System.debug('newAccountContactRelations: ' + newAccountContactRelations);
        insert newAccountContactRelations;
        return newAccountContactRelations;

    }

    public static List<AccountContactRelation> createAccountContactRelations(Boolean useExisting, Integer count) {
        if (accountContactRelations == null) {
            accountContactRelations = new List<AccountContactRelation>();
        }
        Integer countToCreate = count;
        if (useExisting) {
            if (accountContactRelations.size() >= count) {
                return accountContactRelations;
            } else {
                countToCreate = count - accountContactRelations.size();
            }
        }

        List<AccountContactRelation> newlyCreated = createAccountContactRelations(countToCreate, null, null,null,null);

        if (useExisting) {
            return accountContactRelations;
        }

        return newlyCreated;
    }

    public class TestException extends Exception {

    }
}