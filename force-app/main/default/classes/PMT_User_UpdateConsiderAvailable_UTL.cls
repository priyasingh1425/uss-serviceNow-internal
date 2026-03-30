global class PMT_User_UpdateConsiderAvailable_UTL Implements Schedulable{
    
    global void execute(SchedulableContext sc){

        CustomException ce = new CustomException();
        
        try{
            
			//list of PMT Permission Sets
            StaticResource sr = [SELECT Id, Body FROM StaticResource WHERE Name = 'PMT_PermissionSetNames' LIMIT 1];
            String body = sr.Body.toString();
            body = body.replace('"','');
            List<String> permissionSetNames = body.split(',');
            System.debug(permissionSetNames);
            System.debug(body);

            //list of Permission Set Ids
            List<Id> pids = new List<Id>();            
            for(String s : permissionSetNames){
                String query = 'SELECT Id FROM PermissionSet WHERE Name = '+ '\'' + s + '\'';
                System.debug(query);
                pids.add(Database.query(query).Id);
            }
            System.debug('pids: ' + pids);   
            
            //list of Permission Set groups that the Permission Set Ids are found in
            List<Id> psgIds = new List<Id>();
            for(PermissionSetGroupComponent psgc : [SELECT PermissionSetGroupId FROM PermissionSetGroupComponent WHERE PermissionSetId IN :pids]){
                psgIds.add(psgc.PermissionSetGroupId);
            }
            
            //List of user IDs that need to have Is_PMT_User_consider_for_Availability__c set to true
            List<PermissionSetAssignment> userIdsTrue = [SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSetId IN :pids or PermissionSetGroupId IN :psgIds];
            List<Id> userIdsUpdated = new List<Id>();
            for(PermissionSetAssignment p : userIdsTrue){
                userIdsUpdated.add(p.AssigneeId);
            }
            System.debug('userIdsTrue: ' + userIdsTrue);
            System.debug('userIdsUpdated: ' + userIdsUpdated);
            //Unique Set of user Ids that will be used to update Is_PMT_User_consider_for_Availability__c
            Set<User> idsUpdate = new Set<User>();
            
            //users that have the Is_PMT_User_consider_for_Availability__c already set to true
            for(User u : [SELECT Id FROM User WHERE Is_PMT_User_consider_for_Availability__c = TRUE]){
                if(!userIdsUpdated.contains(u.Id)){
                    User iduf = new User();
                    iduf.id = u.Id;
                    iduf.Is_PMT_User_consider_for_Availability__c = FALSE;
                    idsUpdate.add(iduf);
                }
                for(PermissionSetAssignment psa : userIdsTrue){
                    if(u.Id == psa.AssigneeId){
                       userIdsUpdated.remove(userIdsUpdated.indexOf(psa.AssigneeId));
                    }
                }
            }
            System.debug('userIdsUpdated: ' + userIdsUpdated);
            System.debug('idsUpdate: ' + idsUpdate);
            
            if(!userIdsUpdated.isEmpty()){
                for(Id idu : userIdsUpdated){
                    User iduc = new User();
                    iduc.id	= idu;
                    iduc.Is_PMT_User_consider_for_Availability__c = TRUE;
                    idsUpdate.add(iduc);
                }
            }
            System.debug('idsUpdate: ' + idsUpdate);
            List<User> updateThese = new List<User>(idsUpdate);
            update updateThese;
            
            
        }catch(Exception e){
            ce.message = 'Custom APEX Error ::: Scheduled class error ::: PMT_User_UpdateConsiderAvailable_UTL ::: line: ' + e.getLineNumber() + ' ::: ' + e.getMessage();
            CustomException.sendErrorNotification(ce);
        }
        
    }
}