/**
 * @author Ladd Partners
 * @date 8/02/2017
 * @group
*/

public with sharing class lp_Utility {

    /**
     * @description Map of object type to Map of developer names to record type
     */
    public static Map<String,Map<String, RecordType>> rTypes = new Map<String, Map<String, RecordType>>();

    public static Id getRecordType(SObjectType objectType, String recordTypeDeveloperName) {
        return objectType.getDescribe().getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
    }

    /**
     * @description Determine the record type id for a specific record type
     * for a specific object using the developerName.
     * @param name The name of the record type you want.
     * @param userObject An object of the type associated with the record type you want.
     * @return The id of the requested record type.
     */
    public static Id getRecordType(String name, SObject userObject) {
        return getRecordType(userObject.getSObjectType(), name);
    }

    public static boolean isRunningBatch() {
        return (System.isBatch() || System.isFuture());
    }
  
    public static Approval.ProcessResult submitForApproval(Id recordId, string comments, Id submitterId) {
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(comments);
        req1.setObjectId(recordId);

        if (submitterId != null) {
            req1.setSubmitterId(submitterId);
        }
		
		if (System.Test.isRunningTest()){
			return null;
		}

        return Approval.process(req1);
    }

    /**
     * @description Retrieve order processing queue id.
     * @return Id.
     */
    public static Id getOrderProcessQueueId(){
        if(lp_Constants.ORDER_PROCESSING_QUEUE_ID == null){
            List<Group> groups = [select Id from Group where DeveloperName = :lp_Constants.ORDER_PROCESSING_QUEUE_NAME];
            if(!groups.isEmpty()){
                lp_Constants.ORDER_PROCESSING_QUEUE_ID = groups[0].Id;
            }
        }
        return lp_Constants.ORDER_PROCESSING_QUEUE_ID;
    }

    /**
     * @description Log Exception details
     * 
     * @param ex Exception to log
     *
     */
    public static void logException(Exception ex){
        System.debug(LoggingLevel.DEBUG, 'Exception Thrown');
        System.debug(LoggingLevel.DEBUG, 'Error Message: ' + ex.getMessage());
        System.debug(LoggingLevel.DEBUG, 'Line number: ' + ex.getLineNumber());
        System.debug(LoggingLevel.DEBUG, 'Stack trace: ' + ex.getStackTraceString());
    }
    
    /**
     * @description The AuraHandledException constructor only exposes the error message to the client. 
     * This method enables testing of the proper error message by setting the message before throwing the AuraHandledException.
     * 
     * @param errorMessage error message to display to the User
     */
    public static AuraHandledException createAuraHandledException(String errorMessage){
        AuraHandledException ex = new AuraHandledException(errorMessage);
        ex.setMessage(errorMessage);
        return ex;
    }

    public static String convertSetIdsToString(Set<Id> setIds){
        String idsString = '';
        for(Id setId : setIds){
            idsString += (idsString==''?'':',') + '\'' + setId + '\'';
        }
        return idsString;
    }

    public static boolean jobIsRunning(String className, Id jobId){
        ApexClass[] apexClasses = [select Id
                                            ,Name
                                    from ApexClass
                                    where NamespacePrefix = null
                                    and name = :className];

        if(apexClasses.isEmpty()){
            throw new lp_Exception(String.Format('Batch class not found [{0}]', new List<String>{className}));
        }

        Id classId = apexClasses[0].Id;
        AsyncApexJob[] apexJobs = [select ApexClassId
                                         ,CompletedDate
                                         ,CreatedById
                                         ,CreatedDate
                                         ,ExtendedStatus
                                         ,Id
                                         ,JobType
                                         ,LastProcessed
                                         ,LastProcessedOffset
                                         ,NumberOfErrors
                                         ,Status
                                     from AsyncApexJob
                                    where ApexClassId = :classId
                                      and Id != :jobId
                                      and Status != 'Completed'
                                      and Status != 'Aborted'
                                      and JobType = 'BatchApex'];

        Set<string> runningStatus = new Set<string>{ 'Queued', 'Holding', 'Preparing', 'Processing' };
        for(AsyncApexJob asyncApexJob : apexJobs) {
            if(runningStatus.contains(asyncApexJob.Status)){
                return true;
            }
        }
        return false;
    }
}