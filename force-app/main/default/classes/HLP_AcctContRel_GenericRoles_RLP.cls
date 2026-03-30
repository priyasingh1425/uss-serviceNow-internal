public class HLP_AcctContRel_GenericRoles_RLP {
    // generic version of HLP_AcctConRel_restrictedRoles_RLP
    
    public static void rollupRolesForCheckbox(Id contactId){
        List<AccountContactRelation> acctConRel = [Select Roles, Id, IsActive From AccountContactRelation Where ContactId =: contactId and Account.type = 'Account'];
        
        
        for(Generic_Role_Rollup__mdt metadataRecord : [Select CheckboxAPIName__c, RestrictedRoles__c from Generic_Role_Rollup__mdt]){
            Boolean setCheckbox = false;
            Set<String> uniqueRoles = new Set<String>();
            List<String> listOfRolesToCompare = metadataRecord.RestrictedRoles__c.split(',');
            System.debug('generic role metadata: ' + metadataRecord.CheckboxAPIName__c + ' ' + metadataRecord.RestrictedRoles__c);
            for(AccountContactRelation rel : acctConRel){
                if(rel.IsActive){
                    uniqueRoles.addAll(rel.Roles.split(';'));                    
                }
            }
            
            List<String> uniqueIterableRoles = new List<String>();
            uniqueIterableRoles.addAll(uniqueRoles);
            
            for(String iter : uniqueIterableRoles){
                if(listOfRolesToCompare.contains(iter)){
                    setCheckbox = true;
                }
            }
            
            Contact con = new Contact(Id = contactId);
            con.put(metadataRecord.CheckboxAPIName__c, setCheckbox);
            System.debug('con: ' + con);
            update con;
            
        }        
    }
    
    public static void rollupForDelete(Id contactId, Id deletedId){
        List<AccountContactRelation> acctConRel = [Select Roles, Id, IsActive From AccountContactRelation Where ContactId =: contactId and Account.type = 'Account'];
        
        for(Generic_Role_Rollup__mdt metadataRecord : [Select CheckboxAPIName__c, RestrictedRoles__c from Generic_Role_Rollup__mdt]){
            List<String> listOfRolesToCompare = metadataRecord.RestrictedRoles__c.split(',');
            Boolean setCheckbox = false;
            Set<String> uniqueRoles = new Set<String>();
            for(AccountContactRelation rel : acctConRel){
                if(rel.Id == deletedId){} else {
                    if(rel.IsActive){
                        uniqueRoles.addAll(rel.Roles.split(';'));                    
                    }
                }
            }
            
            List<String> uniqueIterableRoles = new List<String>();
            uniqueIterableRoles.addAll(uniqueRoles);
            
            for(String iter : uniqueIterableRoles){
                if(listOfRolesToCompare.contains(iter)){
                    setCheckbox = true;
                }
            }
            
            Contact con = new Contact(Id = contactId);
            con.put(metadataRecord.CheckboxAPIName__c, setCheckbox);
            update con;
            
        }
    }
    
}