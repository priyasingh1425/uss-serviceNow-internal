/**
 * Created by Ladd Partners on 12/24/2025.
 */

@IsTest
private class lp_BillingContractLineTest {
 
    @IsTest
    static void testGetProrationFactor() {
        // Same Month
        // 15 days out of 30 = 0.5000
        Date start_SameMonth = Date.newInstance(2025, 6, 1);
        Date end_SameMonth = Date.newInstance(2025, 6, 15);
        Decimal result_SameMonth = lp_BillingContractLine.getProrationFactor(start_SameMonth, end_SameMonth);
        Assert.areEqual(0.5000, result_SameMonth, 'Same month proration failed');

        // Multi-Month with Leap Year (Jan 15th to March 10th, 2024)
        // Jan: 17/31 (0.5484) + Feb: 1.0 + March: 10/31 (0.3226) = 1.8710
        Date start_MultiMonth = Date.newInstance(2024, 1, 15);
        Date end_MultiMonth = Date.newInstance(2024, 3, 10);
        Decimal result_MultiMonth = lp_BillingContractLine.getProrationFactor(start_MultiMonth, end_MultiMonth);
        Assert.areEqual(1.8710, result_MultiMonth, 'Leap year multi-month proration failed');

        // Adjacent Months (March 20th to April 10th, 2025)
        // March: 12/31 (0.3871) + April: 10/30 (0.3333) = 0.7204
        Date start_Adjacent = Date.newInstance(2025, 3, 20);
        Date end_Adjacent = Date.newInstance(2025, 4, 10);
        Decimal result_Adjacent = lp_BillingContractLine.getProrationFactor(start_Adjacent, end_Adjacent);
        Assert.areEqual(0.7204, result_Adjacent, 'Adjacent month proration failed');

        // Bad Input
        Date start_BadInput = Date.newInstance(2025, 1, 1);
        Date end_BadInput = Date.newInstance(2024, 12, 31);
        Decimal result_BadInput = lp_BillingContractLine.getProrationFactor(start_BadInput, end_BadInput);
        Assert.areEqual(0.0, result_BadInput, 'Invalid date range should return 0');
    }
    
    @IsTest
    static void testGetProratedCreditUnitPrice() {
        Decimal unitPrice = 100.00;
        Decimal expected_SameMonth = (unitPrice * .5) * -1;
        Decimal expected_MultiMonth = (unitPrice * 1.8710) * -1;
                
        Date start_SameMonth = Date.newInstance(2025, 6, 1);
        Date end_SameMonth = Date.newInstance(2025, 6, 15);
        Decimal result_SameMonth = lp_BillingContractLine.getCreditUnitPrice(start_SameMonth, end_SameMonth, unitPrice);
        Assert.areEqual(expected_SameMonth, result_SameMonth, 'Same month proration failed');

        Date start_MultiMonth = Date.newInstance(2024, 1, 15);
        Date end_MultiMonth = Date.newInstance(2024, 3, 10);
        Decimal result_MultiMonth = lp_BillingContractLine.getCreditUnitPrice(start_MultiMonth, end_MultiMonth, unitPrice);
        Assert.areEqual(expected_MultiMonth, result_MultiMonth, 'Leap year multi-month proration failed');
    }
}