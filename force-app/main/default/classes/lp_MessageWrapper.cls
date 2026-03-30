/**
 * @author Ladd Partners
 * @date 4/17/2025
*/

 public with sharing class lp_MessageWrapper {
    @AuraEnabled public Boolean isSuccessful { get; set; }
    @AuraEnabled public String message { get; set; }
    @AuraEnabled public Id newRecordId { get; set; }
    @AuraEnabled public String urlLink { get; set; }
}