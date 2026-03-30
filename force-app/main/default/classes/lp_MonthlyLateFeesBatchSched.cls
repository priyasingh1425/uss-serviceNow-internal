/**
 * @author Ladd Partners
 * @date 2/14/2025
*/

public with sharing class lp_MonthlyLateFeesBatchSched implements Schedulable {
    public void execute (SchedulableContext sc) {
        lp_MonthlyLateFeesBatch.runJob();
    }
}