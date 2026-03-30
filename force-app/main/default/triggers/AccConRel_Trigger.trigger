trigger AccConRel_Trigger on AccountContactRelation (before delete, after update, after insert) {
    if(Trigger.IsAfter && (Trigger.IsUpdate || Trigger.IsInsert)) {
        for(AccountContactRelation acr : trigger.new) {
            String aType = [Select Type from Account Where Id =: acr.AccountId].get(0).Type;
            if(aType == 'Account'){
                HLP_AcctContRel_GenericRoles_RLP.rollupRolesForCheckbox(acr.ContactId);
            }
        }
    }
    if(Trigger.IsBefore && Trigger.IsDelete) {
        for (AccountContactRelation acr : [SELECT Id FROM AccountContactRelation WHERE Id IN :Trigger.old]) {
            
            Boolean hasPermission = FeatureManagement.checkPermission('Remove_Account_Contact_Relationships');
            
            if(hasPermission){}else{
                Trigger.oldMap.get(acr.Id).addError('Relationships cannot be deleted.  Instead, set the Relationship to "Inactive".');
            }
            
        }
        
        if(Trigger.IsBefore && Trigger.IsDelete) {
            for(AccountContactRelation acrn : trigger.old) {
                System.debug('acrn ' + acrn);
                String aType = [Select Type from Account Where Id =: acrn.AccountId].get(0).Type;
                if(aType == 'Account'){
                    system.debug('contactId ' + acrn.ContactId);
                    
                    HLP_AcctContRel_GenericRoles_RLP.rollupForDelete(acrn.ContactId, acrn.Id);
                }
            }
        }
    }
    
    
}