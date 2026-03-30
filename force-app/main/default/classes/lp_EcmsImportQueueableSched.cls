/**
 * @author Ladd Partners
 * @date 4/28/2025
*/

public with sharing class lp_EcmsImportQueueableSched implements Schedulable {

    public void execute (SchedulableContext sc){
        System.enqueueJob(new lp_EcmsImportQueueable());
    }

}