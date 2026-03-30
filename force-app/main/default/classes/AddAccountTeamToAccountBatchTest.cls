@isTest
private class AddAccountTeamToAccountBatchTest {

    @testSetup
    public static void initDataSetup() {
        // Remember: When two "Customer" Accounts are created, two Accounts of Type "Account" will also be created.
        Id customerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();

        // Important! UserAccountTeamMember doesn't support DML operations. 

        User user1 = [SELECT Id FROM User WHERE LastName = 'Voigt' LIMIT 1];
        User user2 = [SELECT Id FROM User WHERE LastName = 'Ouvry' LIMIT 1];
        User clientDevelopmentRep = [SELECT Id FROM User WHERE LastName = 'Brown' LIMIT 1];

        // Create Accounts...
        List<Account> user1CustomerAccounts = new List<Account>();
        for(Integer i = 0; i < 2; i++) {
            user1CustomerAccounts.add(
                new Account(
                        Name = 'Wayne Water Systems ' + i,
                        RecordTypeId = customerRecordTypeId,
                        BillingStreet = '145' + i + ' East Market Street',
                        BillingCity = 'Jeffersonville',
                        BillingState = 'Indiana',
                        BillingPostalCode = '47130',
                        BillingCountry = 'United States',
                        Phone = '8004953500',
                        CRM_ID__c = '145' + i,
                        Client_Development_Rep__c = clientDevelopmentRep.Id
                )
            );
        }

        System.runAs(user1) {
            insert user1CustomerAccounts;
        }

        List<Account> user2CustomerAccounts = new List<Account>();
        for(Integer i = 0; i < 2; i++) {
            user2CustomerAccounts.add(
                new Account(
                        Name = 'Wayne Water Systems '+ i,
                        RecordTypeId = customerRecordTypeId,
                        BillingStreet = '102' + i + 'East Market Street',
                        BillingCity = 'Jeffersonville',
                        BillingState = 'Indiana',
                        BillingPostalCode = '47130',
                        BillingCountry = 'United States',
                        Phone = '8004953500',
                        CRM_ID__c = '102' + i,
                        Client_Development_Rep__c = clientDevelopmentRep.Id
                )
            );
        }

        System.runAs(user2) {
            insert user2CustomerAccounts;
        }
    }

    @isTest
    static void addAccountTeamToAccountTest() {
        Test.StartTest();
            AddAccountTeamToAccountBatch addAccountTeam = new AddAccountTeamToAccountBatch();
            Id batchprocessid = Database.executeBatch(addAccountTeam);
        Test.StopTest();

        System.assert([SELECT COUNT() FROM AccountTeamMember WHERE TeamMemberRole != 'Client Development Rep'] > 0 , 'Account Team Members were not created.');
        System.assert([SELECT COUNT() FROM AccountTeamMember WHERE TeamMemberRole = 'Client Development Rep'] > 0 , 'The Client Development Rep was not added to the Account Team.');
    }
}