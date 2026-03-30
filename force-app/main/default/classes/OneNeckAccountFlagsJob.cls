public class OneNeckAccountFlagsJob {

    @InvocableMethod(
        label='Run OneNeck Account Flag Refresh'
        description='Starts a Batch Apex job that checks Certinia Billing Contract Line Items and sets OneNeck flags on Accounts.'
    )
    public static void runBatch(List<String> ignoredInput) {

        // Batch size controls chunk size per execute(), not total records
        Integer batchSize = 200;

        Database.executeBatch(
            new OneNeckAccountFlagsBatch(),
            batchSize
        );
    }
}