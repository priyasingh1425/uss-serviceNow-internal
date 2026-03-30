/**
 * @author Ladd Partners
 * @date 4/21/2025
*/

@IsTest
private class lp_EcmsCertificateTest {

    @IsTest
    private static void getChangesSuccess() {
        lp_EcmsHttpCalloutMock mock = new lp_EcmsHttpCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        List<String> updatedAccountIds = new List<String>{'123456', '789065'};
        List<String> deletedAccountIds = new List<String>{'573296'};

        mock.addResponse(lp_EcmsSummaryMockImpl.createSummarySuccess(updatedAccountIds, deletedAccountIds));

        Test.startTest();

        lp_EcmsTypes.GetSummaryResponse summaryResponse = lp_EcmsService.getChangesSummary();

        Test.stopTest();

        System.debug('summaryResponse: ' + summaryResponse);
        Assert.areEqual(updatedAccountIds.size(), summaryResponse.updated.size(), 'unexpected number of updated accounts returned');
        Assert.areEqual(deletedAccountIds.size(), summaryResponse.deleted.size(), 'unexpected number of deleted accounts returned');
    }

    @IsTest
    private static void importByAccountIdSuccess() {
        lp_SetupTest setupTest = new lp_SetupTest();

        List<String> accountNumbers = new List<String>();
        List<String> designatorIds = new List<String>();

        List<String> updatedAccountIds = new List<String>{'123456', '789065', '1111', '2222', '3333'};
        List<String> deletedAccountIds = new List<String>{'573296'};

        Account account1 = setupTest.createAccount(false);
        account1.Customer_Number__c = '13579';
        accountNumbers.add(account1.Customer_Number__c);

        Account account2 = setupTest.createAccount(false);
        account2.Customer_Number__c = '24680';
        accountNumbers.add(account2.Customer_Number__c);

        List<Account> accounts = new List<Account>{account1, account2};
        insert accounts;

        laddafc__Tax_Type__c taxType1 = new laddafc__Tax_Type__c();
        taxType1.Name = 'Sales Tax';
        taxType1.laddafc__Category__c = 'Sales and Use Taxes';
        taxType1.laddafc__Description__c = 'This is a tax on the privilege of purchasing goods and services.';
        taxType1.laddafc__Tax_Type_Code__c = 1;
        designatorIds.add(String.valueOf(taxType1.laddafc__Tax_Type_Code__c));

        laddafc__Tax_Type__c taxType2 = new laddafc__Tax_Type__c();
        taxType2.Name = 'Special Tax';
        taxType2.laddafc__Category__c = 'Sales and Use Taxes';
        taxType2.laddafc__Description__c = 'Used to specify a tax that does not fit into a typical category.';
        taxType2.laddafc__Tax_Type_Code__c = 12;
        designatorIds.add(String.valueOf(taxType2.laddafc__Tax_Type_Code__c));

        insert new List<laddafc__Tax_Type__c>{taxType1, taxType2};

        lp_EcmsHttpCalloutMock mock = new lp_EcmsHttpCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        mock.addResponse(lp_EcmsSummaryMockImpl.createSummarySuccess(updatedAccountIds, deletedAccountIds));

        for (Integer i = 0; i < 2; i++) {
            String ecmsAcountId = updatedAccountIds.get(i);
            Account sfAccount = accounts.get(i);

            mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create(ecmsAcountId, sfAccount.Customer_Number__c, new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue(), taxType2.laddafc__Tax_Type_Code__c.intValue()}, false));
        }

        // these will fail
        // no accountNumber
        mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create('123456', null, new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue()}, false));
        // multiple account numbers
        mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create('123456', '123, 456, 789', new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue()}, false));
        // expired cert
        mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create('123456', '13579', new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue()}, true));

        Test.startTest();

        System.enqueueJob(new lp_EcmsImportQueueable());

        Test.stopTest();

        List<ECMS_Certificate__c> createdCertificates = [SELECT Id, Account__c, Tax_type__c, Account_Number__c, Effective_Date__c, Expiration_Date__c FROM ECMS_Certificate__c LIMIT 10];
        System.debug('createdCertificates: ' + createdCertificates);

        Assert.areEqual(4, createdCertificates.size(), 'unexpected number of ecms certificates created');

        for (ECMS_Certificate__c certificate : createdCertificates) {
            Assert.isNotNull(certificate.Account__c, 'not expecting account reference to be null');
            Assert.isNotNull(certificate.Tax_Type__c, 'not expecting tax type reference to be null');
        }
    }

    @IsTest
    private static void importByAccountIdResumeSuccess() {
        lp_SetupTest setupTest = new lp_SetupTest();

        List<String> accountNumbers = new List<String>();
        List<String> designatorIds = new List<String>();

        List<String> updatedAccountIds = new List<String>{'123456', '789065', '1111', '2222', '3333'};
        List<String> deletedAccountIds = new List<String>{'573296'};

        Account account1 = setupTest.createAccount(false);
        account1.Customer_Number__c = '13579';
        accountNumbers.add(account1.Customer_Number__c);

        Account account2 = setupTest.createAccount(false);
        account2.Customer_Number__c = '24680';
        accountNumbers.add(account2.Customer_Number__c);

        List<Account> accounts = new List<Account>{account1, account2};
        insert accounts;

        laddafc__Tax_Type__c taxType1 = new laddafc__Tax_Type__c();
        taxType1.Name = 'Sales Tax';
        taxType1.laddafc__Category__c = 'Sales and Use Taxes';
        taxType1.laddafc__Description__c = 'This is a tax on the privilege of purchasing goods and services.';
        taxType1.laddafc__Tax_Type_Code__c = 1;
        designatorIds.add(String.valueOf(taxType1.laddafc__Tax_Type_Code__c));

        laddafc__Tax_Type__c taxType2 = new laddafc__Tax_Type__c();
        taxType2.Name = 'Special Tax';
        taxType2.laddafc__Category__c = 'Sales and Use Taxes';
        taxType2.laddafc__Description__c = 'Used to specify a tax that does not fit into a typical category.';
        taxType2.laddafc__Tax_Type_Code__c = 12;
        designatorIds.add(String.valueOf(taxType2.laddafc__Tax_Type_Code__c));

        insert new List<laddafc__Tax_Type__c>{taxType1, taxType2};

        lp_EcmsHttpCalloutMock mock = new lp_EcmsHttpCalloutMock();
        Test.setMock(HttpCalloutMock.class, mock);

        //mock.addResponse(lp_EcmsSummaryMockImpl.createSummarySuccess(updatedAccountIds, deletedAccountIds));

        for (Integer i = 0; i < 2; i++) {
            String ecmsAcountId = updatedAccountIds.get(i);
            Account sfAccount = accounts.get(i);

            mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create(ecmsAcountId, sfAccount.Customer_Number__c, new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue(), taxType2.laddafc__Tax_Type_Code__c.intValue()}, false));
        }

        // these will fail
        // no accountNumber
        mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create('123456', null, new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue()}, false));
        // multiple account numbers
        mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create('123456', '123, 456, 789', new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue()}, false));
        // expired cert
        mock.addResponse(lp_EcmsGetByAccountIdMockImpl.create('123456', '13579', new List<Integer>{taxType1.laddafc__Tax_Type_Code__c.intValue()}, true));

        Test.startTest();

        lp_EcmsImportQueueable.ProcessingAccountInfo accountInfo = new lp_EcmsImportQueueable.ProcessingAccountInfo(
                '123456',
                100,
                new List<ECMS_Certificate__c>());

        lp_BatchNotify batchNotify = new lp_BatchNotify();
        updatedAccountIds.remove(0);

        System.enqueueJob(new lp_EcmsImportQueueable(batchNotify, accountInfo, updatedAccountIds, Datetime.now().addMonths(-1), Datetime.now()));

        Test.stopTest();

        List<ECMS_Certificate__c> createdCertificates = [SELECT Id, Account__c, Tax_type__c, Account_Number__c, Effective_Date__c, Expiration_Date__c FROM ECMS_Certificate__c LIMIT 10];
        System.debug('createdCertificates: ' + createdCertificates);

        Assert.areEqual(4, createdCertificates.size(), 'unexpected number of ecms certificates created');

        for (ECMS_Certificate__c certificate : createdCertificates) {
            Assert.isNotNull(certificate.Account__c, 'not expecting account reference to be null');
            Assert.isNotNull(certificate.Tax_Type__c, 'not expecting tax type reference to be null');
        }
    }

    @IsTest
    private static void exemptionCreateSuccess() {
        lp_SetupTest setupTest = new lp_SetupTest();

        createAdhocExemptionDefinitions();

        Account account1 = setupTest.createAccount(false);
        account1.Customer_Number__c = '13579';

        Account account2 = setupTest.createAccount(false);
        account2.Customer_Number__c = '24680';

        insert new List<Account>{account1, account2};

        laddafc__Tax_Type__c taxType1 = new laddafc__Tax_Type__c();
        taxType1.Name = 'Sales Tax';
        taxType1.laddafc__Category__c = 'Sales and Use Taxes';
        taxType1.laddafc__Description__c = 'This is a tax on the privilege of purchasing goods and services.';
        taxType1.laddafc__Tax_Type_Code__c = 1;

        laddafc__Tax_Type__c taxType2 = new laddafc__Tax_Type__c();
        taxType2.Name = 'Special Tax';
        taxType2.laddafc__Category__c = 'Sales and Use Taxes';
        taxType2.laddafc__Description__c = 'US';
        taxType2.laddafc__Tax_Type_Code__c = 18;

        laddafc__Tax_Type__c taxType3 = new laddafc__Tax_Type__c();
        taxType3.Name = 'Ad-hoc Tax';
        taxType3.laddafc__Category__c = 'Sales and Use Taxes';
        taxType3.laddafc__Description__c = 'AH';
        taxType3.laddafc__Tax_Type_Code__c = 74;

        laddafc__Tax_Type__c taxType4 = new laddafc__Tax_Type__c();
        taxType4.Name = 'Ad-hoc Tax 1';
        taxType4.laddafc__Category__c = 'Sales and Use Taxes';
        taxType4.laddafc__Description__c = 'AH1';
        taxType4.laddafc__Tax_Type_Code__c = 13;

        laddafc__Tax_Type__c taxType5 = new laddafc__Tax_Type__c();
        taxType5.Name = 'Ad-hoc Tax 2';
        taxType5.laddafc__Category__c = 'Sales and Use Taxes';
        taxType5.laddafc__Description__c = 'AH2';
        taxType5.laddafc__Tax_Type_Code__c = 48;

        laddafc__Tax_Type__c taxType6 = new laddafc__Tax_Type__c();
        taxType6.Name = 'Ad-hoc Tax 3';
        taxType6.laddafc__Category__c = 'Sales and Use Taxes';
        taxType6.laddafc__Description__c = 'AH3';
        taxType6.laddafc__Tax_Type_Code__c = 282;

        laddafc__Tax_Type__c taxType7 = new laddafc__Tax_Type__c();
        taxType7.Name = 'Ad-hoc Tax 4';
        taxType7.laddafc__Category__c = 'Sales and Use Taxes';
        taxType7.laddafc__Description__c = 'AH4';
        taxType7.laddafc__Tax_Type_Code__c = 164;

        laddafc__Tax_Type__c taxType8 = new laddafc__Tax_Type__c();
        taxType8.Name = 'Ad-hoc Tax 5';
        taxType8.laddafc__Category__c = 'Sales and Use Taxes';
        taxType8.laddafc__Description__c = 'AH5';
        taxType8.laddafc__Tax_Type_Code__c = 87;

        insert new List<laddafc__Tax_Type__c>{taxType1, taxType2, taxType3, taxType4, taxType5, taxType6, taxType7, taxType8};

        // should create
        ECMS_Certificate__c ecmsCertificate1 = new ECMS_Certificate__c();
        ecmsCertificate1.Name = 'A B C';
        ecmsCertificate1.ECMS_Account_Id__c = '1234';
        ecmsCertificate1.Account_Number__c = account1.Customer_Number__c;
        ecmsCertificate1.Certificate_Id__c = '9876543210';
        ecmsCertificate1.Effective_Date_Raw__c = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
        ecmsCertificate1.Expiration_Date_Raw__c = null;
        ecmsCertificate1.Scope__c = lp_Exemption.SCOPE_ALL;
        ecmsCertificate1.Domain__c = lp_Exemption.DOMAIN_STATE;
        ecmsCertificate1.Designator_Id__c = String.valueOf(taxType1.laddafc__Tax_Type_Code__c);
        ecmsCertificate1.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate1.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE;
        ecmsCertificate1.City__c = null;
        ecmsCertificate1.County__c = null;
        ecmsCertificate1.Country__c = 'US';
        ecmsCertificate1.State__c = 'CO';

        // should create
        ECMS_Certificate__c ecmsCertificate2 = new ECMS_Certificate__c();
        ecmsCertificate2.Name = 'D E F';
        ecmsCertificate2.ECMS_Account_Id__c = '1234';
        ecmsCertificate2.Account_Number__c = account2.Customer_Number__c;
        ecmsCertificate2.Certificate_Id__c = '9876543210';
        ecmsCertificate2.Effective_Date_Raw__c = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
        ecmsCertificate2.Expiration_Date_Raw__c = null;
        ecmsCertificate2.Scope__c = lp_Exemption.SCOPE_FEDERAL;
        ecmsCertificate2.Domain__c = lp_Exemption.DOMAIN_FEDERAL;
        ecmsCertificate2.Designator_Id__c = String.valueOf(taxType2.laddafc__Tax_Type_Code__c);
        ecmsCertificate2.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate2.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE;
        ecmsCertificate2.City__c = null;
        ecmsCertificate2.County__c = null;
        ecmsCertificate2.Country__c = 'US';
        ecmsCertificate2.State__c = null;

        // fails - no account
        ECMS_Certificate__c ecmsCertificate3 = new ECMS_Certificate__c();
        ecmsCertificate3.Name = 'G H I';
        ecmsCertificate3.ECMS_Account_Id__c = '1234';
        ecmsCertificate3.Account_Number__c = '000000000';
        ecmsCertificate3.Certificate_Id__c = '9876543210';
        ecmsCertificate3.Effective_Date_Raw__c = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
        ecmsCertificate3.Expiration_Date_Raw__c = null;
        ecmsCertificate3.Scope__c = lp_Exemption.SCOPE_ALL;
        ecmsCertificate3.Domain__c = 'State';
        ecmsCertificate3.Designator_Id__c = '12';
        ecmsCertificate3.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate3.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_CATEGORY;
        ecmsCertificate3.City__c = null;
        ecmsCertificate3.County__c = null;
        ecmsCertificate3.Country__c = 'US';
        ecmsCertificate3.State__c = 'CA';

        // fails - bad tax type
        ECMS_Certificate__c ecmsCertificate4 = new ECMS_Certificate__c();
        ecmsCertificate4.Name = 'J K L';
        ecmsCertificate4.ECMS_Account_Id__c = '1234';
        ecmsCertificate4.Account_Number__c = account2.Customer_Number__c;
        ecmsCertificate4.Certificate_Id__c = '9876543210';
        ecmsCertificate4.Effective_Date_Raw__c = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
        ecmsCertificate4.Expiration_Date_Raw__c = null;
        ecmsCertificate4.Scope__c = lp_Exemption.SCOPE_ALL;
        ecmsCertificate4.Domain__c = 'State';
        ecmsCertificate4.Designator_Id__c = '99';
        ecmsCertificate4.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate4.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE;
        ecmsCertificate4.City__c = null;
        ecmsCertificate4.County__c = null;
        ecmsCertificate4.Country__c = 'US';
        ecmsCertificate4.State__c = 'CA';

        // fails - bad effective date format
        ECMS_Certificate__c ecmsCertificate5 = new ECMS_Certificate__c();
        ecmsCertificate5.Name = 'M N O';
        ecmsCertificate5.ECMS_Account_Id__c = '1234';
        ecmsCertificate5.Account_Number__c = account2.Customer_Number__c;
        ecmsCertificate5.Certificate_Id__c = '9876543210';
        ecmsCertificate5.Effective_Date_Raw__c = '2025-74-23T00:00:00';
        ecmsCertificate5.Expiration_Date_Raw__c = null;
        ecmsCertificate5.Scope__c = lp_Exemption.SCOPE_ALL;
        ecmsCertificate5.Domain__c = 'State';
        ecmsCertificate5.Designator_Id__c = '12';
        ecmsCertificate5.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate5.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_CATEGORY;
        ecmsCertificate5.City__c = null;
        ecmsCertificate5.County__c = null;
        ecmsCertificate5.Country__c = 'US';
        ecmsCertificate5.State__c = 'CA';

        insert new List<ECMS_Certificate__c>{ecmsCertificate1, ecmsCertificate2, ecmsCertificate3, ecmsCertificate4, ecmsCertificate5};

        Test.startTest();

        lp_MessageWrapper message = lp_EcmsCertificateController.rerunAFCExemptionCreation();

        Test.stopTest();

        Assert.isTrue(message.isSuccessful, 'expecting controller to return success - ' + message.message);

        List<ECMS_Certificate__c> refreshedCertificates = [
                SELECT
                        Id,
                        Exemption__c,
                        Processing_Status__c,
                        Processing_Message__c
                FROM ECMS_Certificate__c
                LIMIT 25
        ];
        for (ECMS_Certificate__c refreshedCertificate : refreshedCertificates) {
            if (refreshedCertificate.Id == ecmsCertificate1.Id || refreshedCertificate.Id == ecmsCertificate2.Id) {
                Assert.isNull(refreshedCertificate.Processing_Message__c, 'unexpected processing error - ' + refreshedCertificate.Processing_Message__c);
                Assert.areEqual(lp_EcmsCertificate.PROCESSING_STATUS_PROCESSED, refreshedCertificate.Processing_Status__c, 'unexpected processing status - ' + refreshedCertificate.Processing_Message__c);
                Assert.isNotNull(refreshedCertificate.Exemption__c, 'expecting an AFC exemption reference');
            } else if (refreshedCertificate.Id == ecmsCertificate3.Id) {
                Assert.areEqual(lp_EcmsCertificate.PROCESSING_STATUS_ERROR, refreshedCertificate.Processing_Status__c, 'unexpected processing status');
                Assert.areEqual('No account found.', refreshedCertificate.Processing_Message__c, 'unexpected error message');
            } else if (refreshedCertificate.Id == ecmsCertificate4.Id) {
                Assert.areEqual(lp_EcmsCertificate.PROCESSING_STATUS_ERROR, refreshedCertificate.Processing_Status__c, 'unexpected processing status');
                Assert.areEqual('No tax type found.', refreshedCertificate.Processing_Message__c, 'unexpected error message');
            } else if (refreshedCertificate.Id == ecmsCertificate5.Id) {
                Assert.areEqual(lp_EcmsCertificate.PROCESSING_STATUS_ERROR, refreshedCertificate.Processing_Status__c, 'unexpected processing status');
                Assert.areEqual('Invalid effective date.', refreshedCertificate.Processing_Message__c, 'unexpected error message');
            }
        }

        List<laddafc__Exemption__c> createdExemptions = [
                SELECT
                        Id,
                        Name,
                        laddafc__Tax_Type__c,
                        laddafc__Account__c,
                        laddafc__Scope__c,
                        ECMS_Certificate__c,
                        laddafc__Region__c
                FROM laddafc__Exemption__c
                LIMIT 25
        ];
        System.debug('createdExemptions: ' + createdExemptions);
        Assert.areEqual(6, createdExemptions.size(), 'unexpected number of AFC exemptions created');

        String allScopeWithoutFederal = lp_Exemption.SCOPE_ALL_EXTENDED.replace(lp_Exemption.SCOPE_FEDERAL + ';', '');

        for (laddafc__Exemption__c afcExemption : createdExemptions) {
            if (afcExemption.ECMS_Certificate__c == ecmsCertificate1.Id) {
                if (afcExemption.laddafc__Tax_Type__c == taxType1.Id) {
                    Assert.areEqual(account1.Id, afcExemption.laddafc__Account__c, 'unexpected account');
                    Assert.areEqual(ecmsCertificate1.Name, afcExemption.Name, 'unexpected exemption name');
                    Assert.areEqual(lp_Exemption.SCOPE_ALL_EXTENDED, afcExemption.laddafc__Scope__c, 'unexpected scope');
                } else if (afcExemption.laddafc__Tax_Type__c == taxType3.Id) {
                    Assert.areEqual(account1.Id, afcExemption.laddafc__Account__c, 'unexpected account');
                    Assert.isTrue(afcExemption.Name.contains(taxType3.Name + ' State'), 'unexpected exemption name - ' + afcExemption.Name);
                    Assert.areEqual(allScopeWithoutFederal, afcExemption.laddafc__Scope__c, 'unexpected scope');
                } else if (afcExemption.laddafc__Tax_Type__c == taxType4.Id) {
                    Assert.areEqual(account1.Id, afcExemption.laddafc__Account__c, 'unexpected account');
                    Assert.isTrue(afcExemption.Name.contains(taxType4.Name + ' State'), 'unexpected exemption name - ' + afcExemption.Name);
                    Assert.areEqual(allScopeWithoutFederal, afcExemption.laddafc__Scope__c, 'unexpected scope');
                } else {
                    Assert.fail('unexpected tax type for exemption - ' + afcExemption);
                }
            } else if (afcExemption.ECMS_Certificate__c == ecmsCertificate2.Id) {
                // add federal types
                if (afcExemption.laddafc__Tax_Type__c == taxType2.Id) {
                    Assert.areEqual(account2.Id, afcExemption.laddafc__Account__c, 'unexpected account');
                    Assert.areEqual(ecmsCertificate2.Name, afcExemption.Name, 'unexpected exemption name');
                    Assert.areEqual(lp_Exemption.SCOPE_FEDERAL, afcExemption.laddafc__Scope__c, 'unexpected scope');
                } else if (afcExemption.laddafc__Tax_Type__c == taxType7.Id) {
                    Assert.areEqual(account2.Id, afcExemption.laddafc__Account__c, 'unexpected account');
                    Assert.isTrue(afcExemption.Name.contains(taxType7.Name), 'unexpected exemption name - ' + afcExemption.Name);
                    Assert.areEqual(lp_Exemption.SCOPE_ALL_EXTENDED, afcExemption.laddafc__Scope__c, 'unexpected scope');
                } else if (afcExemption.laddafc__Tax_Type__c == taxType8.Id) {
                    Assert.areEqual(account2.Id, afcExemption.laddafc__Account__c, 'unexpected account');
                    Assert.isTrue(afcExemption.Name.contains(taxType8.Name), 'unexpected exemption name - ' + afcExemption.Name);
                    Assert.areEqual(lp_Exemption.SCOPE_ALL_EXTENDED, afcExemption.laddafc__Scope__c, 'unexpected scope');
                } else {
                    Assert.fail('unexpected tax type for exemption - ' + afcExemption);
                }
            } else {
                Assert.fail('unexpected certificate - ' + afcExemption);
            }
        }
    }

    @IsTest
    private static void updateEcmsExemptionSuccess() {
        lp_SetupTest setupTest = new lp_SetupTest();

        Account account1 = setupTest.createAccount(false);
        account1.Customer_Number__c = '13579';

        Account account2 = setupTest.createAccount(false);
        account2.Customer_Number__c = '24680';

        insert new List<Account>{account1, account2};

        laddafc__Tax_Type__c taxType1 = new laddafc__Tax_Type__c();
        taxType1.Name = 'Sales Tax';
        taxType1.laddafc__Category__c = 'Sales and Use Taxes';
        taxType1.laddafc__Description__c = 'This is a tax on the privilege of purchasing goods and services.';
        taxType1.laddafc__Tax_Type_Code__c = 1;

        insert new List<laddafc__Tax_Type__c>{taxType1};

        // fails - no account
        ECMS_Certificate__c ecmsCertificate1 = new ECMS_Certificate__c();
        ecmsCertificate1.Name = 'G H I';
        ecmsCertificate1.ECMS_Account_Id__c = '1234';
        ecmsCertificate1.Account_Number__c = '000000000';
        ecmsCertificate1.Certificate_Id__c = '9876543210';
        ecmsCertificate1.Effective_Date_Raw__c = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
        ecmsCertificate1.Expiration_Date_Raw__c = null;
        ecmsCertificate1.Scope__c = lp_Exemption.SCOPE_ALL;
        ecmsCertificate1.Domain__c = 'State';
        ecmsCertificate1.Designator_Id__c = '1';
        ecmsCertificate1.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate1.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_CATEGORY;
        ecmsCertificate1.City__c = null;
        ecmsCertificate1.County__c = null;
        ecmsCertificate1.Country__c = 'US';
        ecmsCertificate1.State__c = 'CA';

        // fails - bad tax type
        ECMS_Certificate__c ecmsCertificate2 = new ECMS_Certificate__c();
        ecmsCertificate2.Name = 'J K L';
        ecmsCertificate2.ECMS_Account_Id__c = '1234';
        ecmsCertificate2.Account_Number__c = account2.Customer_Number__c;
        ecmsCertificate2.Certificate_Id__c = '9876543210';
        ecmsCertificate2.Effective_Date_Raw__c = Datetime.now().addDays(-7).format(lp_EcmsService.DATETIME_FORMAT);
        ecmsCertificate2.Expiration_Date_Raw__c = null;
        ecmsCertificate2.Scope__c = lp_Exemption.SCOPE_ALL;
        ecmsCertificate2.Domain__c = 'State';
        ecmsCertificate2.Designator_Id__c = '99';
        ecmsCertificate2.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate2.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_TYPE;
        ecmsCertificate2.City__c = null;
        ecmsCertificate2.County__c = null;
        ecmsCertificate2.Country__c = 'US';
        ecmsCertificate2.State__c = 'CA';

        // fails - bad expiration date format
        ECMS_Certificate__c ecmsCertificate3 = new ECMS_Certificate__c();
        ecmsCertificate3.Name = 'M N O';
        ecmsCertificate3.ECMS_Account_Id__c = '1234';
        ecmsCertificate3.Account_Number__c = account2.Customer_Number__c;
        ecmsCertificate3.Certificate_Id__c = '9876543210';
        ecmsCertificate3.Effective_Date_Raw__c = null;
        ecmsCertificate3.Expiration_Date_Raw__c = '2025-74-23T00:00:00';
        ecmsCertificate3.Scope__c = lp_Exemption.SCOPE_ALL;
        ecmsCertificate3.Domain__c = 'State';
        ecmsCertificate3.Designator_Id__c = '12';
        ecmsCertificate3.Designator_Name__c = 'Sales and Use Taxes';
        ecmsCertificate3.Designator_Type__c = lp_EcmsCertificate.DESIGNATOR_TYPE_TAX_CATEGORY;
        ecmsCertificate3.City__c = null;
        ecmsCertificate3.County__c = null;
        ecmsCertificate3.Country__c = 'US';
        ecmsCertificate3.State__c = 'CA';

        insert new List<ECMS_Certificate__c>{ecmsCertificate1, ecmsCertificate2, ecmsCertificate3};

        List<ECMS_Certificate__c> refreshedCertificates = [
                SELECT
                        Id,
                        Exemption__c,
                        Processing_Status__c,
                        Processing_Message__c,
                        Account__c,
                        Tax_Type__c,
                        Effective_Date__c
                FROM ECMS_Certificate__c
                LIMIT 5
        ];
        for (ECMS_Certificate__c refreshedCertificate : refreshedCertificates) {
            if (refreshedCertificate.Id == ecmsCertificate1.Id) {
                Assert.isNull(refreshedCertificate.Account__c, 'unexpected account reference - ' + refreshedCertificate.Account__c);
            } else if (refreshedCertificate.Id == ecmsCertificate2.Id) {
                Assert.isNull(refreshedCertificate.Tax_Type__c, 'unexpected tax type reference - ' + refreshedCertificate.Tax_Type__c);
            } else if (refreshedCertificate.Id == ecmsCertificate3.Id) {
                Assert.isNull(refreshedCertificate.Effective_Date__c, 'unexpected effective date - ' + refreshedCertificate.Effective_Date__c);
            }
        }

        Test.startTest();

        List<ECMS_Certificate__c> certsToUpdate = new List<ECMS_Certificate__c>();

        ECMS_Certificate__c cert1 = new ECMS_Certificate__c(Id = ecmsCertificate1.Id);
        cert1.Account_Number__c = account1.Customer_Number__c;
        certsToUpdate.add(cert1);

        ECMS_Certificate__c cert2 = new ECMS_Certificate__c(Id = ecmsCertificate2.Id);
        cert2.Designator_Id__c = String.valueOf(taxType1.laddafc__Tax_Type_Code__c);
        certsToUpdate.add(cert2);

        ECMS_Certificate__c cert3 = new ECMS_Certificate__c(Id = ecmsCertificate3.Id);
        cert3.Expiration_Date_Raw__c =  Datetime.now().addMonths(1).format(lp_EcmsService.DATETIME_FORMAT);
        certsToUpdate.add(cert3);

        update certsToUpdate;

        Test.stopTest();

        refreshedCertificates = [
                SELECT
                        Id,
                        Exemption__c,
                        Processing_Status__c,
                        Processing_Message__c,
                        Account__c,
                        Tax_Type__c,
                        Expiration_Date__c
                FROM ECMS_Certificate__c
                LIMIT 5
        ];
        for (ECMS_Certificate__c refreshedCertificate : refreshedCertificates) {
            if (refreshedCertificate.Id == ecmsCertificate1.Id) {
                Assert.isNotNull(refreshedCertificate.Account__c, 'unexpected account reference');
            } else if (refreshedCertificate.Id == ecmsCertificate2.Id) {
                Assert.isNotNull(refreshedCertificate.Tax_Type__c, 'unexpected tax type reference');
            } else if (refreshedCertificate.Id == ecmsCertificate3.Id) {
                Assert.isNotNull(refreshedCertificate.Expiration_Date__c, 'unexpected expiration date');
            }
        }
    }

    @IsTest
    static void testSchedulable() {
        Test.startTest();

        lp_EcmsImportQueueableSched job = new lp_EcmsImportQueueableSched();
        String chron = '0 0 23 * * ?';
        String jobId = System.schedule('Test lp_EcmsImportQueueableSched', chron, job);
        CronTrigger[] cts = [
                SELECT Id, CronExpression, TimesTriggered,
                        NextFireTime
                FROM CronTrigger
                WHERE Id = :jobId
        ];

        Test.stopTest();

        System.assertEquals(jobId, cts[0].Id, 'Job was not scheduled.');
    }

    private static void createAdhocExemptionDefinitions() {
        Map<String, lp_AdhocExemption.ExemptionDefinition> definitionsByKey = new Map<String, lp_AdhocExemption.ExemptionDefinition>();

        // force static method to run
        new lp_AdhocExemption.Key().getKey('abc', 'def', 'ghi');

        // US CO 1
        lp_AdhocExemption.ExemptionDefinition exDef = new lp_AdhocExemption.ExemptionDefinition();
        exDef.country = 'US';
        exDef.region = 'CO';
        exDef.triggeringType = '1';
        exDef.taxTypeCodes = new List<Integer>{13,74};

        String adhocKey = new lp_AdhocExemption.Key().getKey(exDef.country, exDef.region, exDef.triggeringType);

        definitionsByKey.put(adhocKey, exDef);

        //US 18
        lp_AdhocExemption.ExemptionDefinition exDef2 = new lp_AdhocExemption.ExemptionDefinition();
        exDef2.country = 'US';
        exDef2.region = null;
        exDef2.triggeringType = '18';
        exDef2.taxTypeCodes = new List<Integer>{87,164};

        String adhocKey2 = new lp_AdhocExemption.Key().getKey(exDef2.country, exDef2.region, exDef2.triggeringType);

        definitionsByKey.put(adhocKey2, exDef2);

        // replace queried list with test-specific one
        lp_AdhocExemption.definitionsByKey = definitionsByKey;

        System.debug('defs2: ' + lp_AdhocExemption.definitionsByKey);
    }

}