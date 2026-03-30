/**
 * Created by Ladd Partners on 4/18/2025.
 */

public with sharing class lp_ProductTaxDetails {

    public static String getProductIdAndBillingTypeKey(Id productId, String billingType, Boolean isInterstate) {
        return String.format('{0}_{1}_{2}', new List<String> { productId, billingType, String.valueOf(isInterstate) });
    }
}