/**
 * Created by Ladd Partners on 6/1/2025.
 */

@isTest
private class lp_CompanyTest {
    @isTest
    static void testConstants() {
        // Test US Signal name constant
        Assert.areEqual('US Signal', lp_Company.NAME_US_SIGNAL, 'US Signal name constant should be correct');
        
        // Test error message constant
        String expectedError = 'Company {0} not found';
        Assert.areEqual(expectedError, lp_Company.ERROR_COMPANY_NOT_FOUND, 'Error message constant should be correct');
        
        // Test error message formatting
        String formattedError = String.format(lp_Company.ERROR_COMPANY_NOT_FOUND, new List<String>{ 'Test Company' });
        Assert.areEqual('Company Test Company not found', formattedError, 'Error message should format correctly');
    }
}