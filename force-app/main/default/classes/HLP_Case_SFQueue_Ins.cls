public class HLP_Case_SFQueue_Ins {
    public static Boolean isBulk = false;
    private static List<Case> cases = new List<Case>();

    public static void createSFQueueCase(String caseSubject, String caseDescription, String casePriority){
        Organization a_ORG = [Select Id, Name, IsSandbox from Organization];
 
            if(a_ORG.IsSandbox){
                System.debug('This is Sandbox.  Case would be created in Production: Subject: ' + caseSubject + ' Description: ' + caseDescription);
            }
            else{
                try{
                    Case c = new Case();
                    c.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Case' AND Name = 'Help'].get(0).Id;
                    c.Case_Type__c = 'Break/Fix';
                    c.Support_Queue__c = 'Salesforce Support';
                    c.Group__c = 'Salesforce';
                    c.Origin = 'Automated Alert';
                    c.Status = 'New';
                    c.OwnerId = [SELECT Queue.Id FROM queuesobject WHERE queue.name = 'Salesforce Queue'].get(0).Queue.Id;
                    c.Description = caseDescription;
                    c.Subject = caseSubject;
                    c.Priority = casePriority;
                    if(isBulk){
                        cases.add(c);
                    }else{
                        Insert c;
                    }
                }catch(Exception e){
                    CustomException ce = new CustomException();
                    ce.message = 'HLP_Case_SFQueue_Ins ::: INV_Case_SFQueue_Ins ::: ' + e.getLineNumber() + ' ::: ' + e.getMessage();
                    CustomException.sendErrorNotification(ce);
                }
            }

    }

    public static void saveCases(){
        try{
            if(cases.isEmpty() == false){
                insert cases;
            }
        }catch(Exception e){
            CustomException ce = new CustomException();
            ce.message = 'HLP_Case_SFQueue_Ins ::: INV_Case_SFQueue_Ins ::: ' + e.getLineNumber() + ' ::: ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
    }
}