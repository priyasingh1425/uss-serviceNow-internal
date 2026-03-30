/**
 * Created by Ladd Partners on 6/1/2025.
 */

@isTest
private class lp_CompanySelectorTest {
    @TestSetup
    static void setupTestData() {
        // Create test company
        c2g__codaCompany__c company = new c2g__codaCompany__c(
            Name = lp_Company.NAME_US_SIGNAL
        );
        insert company;
    }

    @isTest
    static void testGetByNames() {
        // Test getting company by name
        Set<String> names = new Set<String>{ lp_Company.NAME_US_SIGNAL };
        List<c2g__codaCompany__c> companies = new lp_CompanySelector().getByNames(names);
        
        Assert.areEqual(1, companies.size(), 'Should return one company');
        Assert.areEqual(lp_Company.NAME_US_SIGNAL, companies[0].Name, 'Company name should match');
    }

    @isTest
    static void testGetByName() {
        // Test getting company by name
        c2g__codaCompany__c company = new lp_CompanySelector().getByName(lp_Company.NAME_US_SIGNAL);
        
        Assert.isNotNull(company, 'Company should be found');
        Assert.areEqual(lp_Company.NAME_US_SIGNAL, company.Name, 'Company name should match');
    }

    @isTest
    static void testGetByNameWithError() {
        // Test getting non-existent company with error
        try {
            new lp_CompanySelector().getByName('Non Existent Company');
            Assert.fail('Should throw exception for non-existent company');
        } catch (lp_Exception e) {
            Assert.isTrue(e.getMessage().contains('Company Non Existent Company not found'), 'Should throw correct error message');
        }
    }

    @isTest
    static void testGetByNameWithoutError() {
        // Test getting non-existent company without error
        c2g__codaCompany__c company = new lp_CompanySelector().getByName('Non Existent Company', false);
        Assert.isNull(company, 'Company should be null');
    }

    @isTest
    static void testGetUsSignal() {
        // Test getting US Signal company
        c2g__codaCompany__c company = new lp_CompanySelector().getUsSignal();
        
        Assert.isNotNull(company, 'US Signal company should be found');
        Assert.areEqual(lp_Company.NAME_US_SIGNAL, company.Name, 'Company name should match US Signal');
    }
}