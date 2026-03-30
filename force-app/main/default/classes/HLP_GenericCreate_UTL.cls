public class HLP_GenericCreate_UTL {
    
    //Create a generic case with parameters defined by the function calling it.
	public static void createGenericCase(String caseSubject, 
                                         String caseDescription,
                                         String supportQueue,
                                         String caseGroup,
                                         String ownerID,
                                         Boolean isBulk){
                                             
		 try
		 {
			 Case c = new Case();
			 c.RecordTypeId = [SELECT Id FROM RecordType WHERE sobjecttype = 'Case' AND Name = 'Help'].get(0).Id;
			 c.Case_Type__c = 'Break/Fix';
			 c.Support_Queue__c = supportQueue;
			 c.Group__c = caseGroup;
			 c.Origin = 'Automated Alert';
			 c.Status = 'New';
			 c.OwnerId = ownerID;
			 c.Description = caseDescription;
			 c.Subject = caseSubject;
			 
			 //Handle bulk cases when applicable
			 if(isBulk)
			 {
				 List<Case> cases = new List<Case>();
				 
				 cases.add(c);
				 
				 //If there are cases to insert, insert them
				 if(!cases.isEmpty())
				 {
					 Insert cases;
				 }
			 }
			 else
			 {
				 Insert c;
			 }
		 }
		 catch(Exception e)
		 {
			 HLP_Case_SFQueue_Ins.createSFQueueCase(caseSubject, caseDescription, 'Medium');
		 }
	}
}