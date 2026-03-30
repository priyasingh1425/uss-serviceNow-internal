// SC-0000119
global class AddAccountTeamToAccountBatch implements Database.Batchable<sObject> {
	
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(
            // Type Customer, Partner, Account, Vendor 
            'SELECT OwnerId, Client_Development_Rep__c, Client_Development_Rep__r.IsActive FROM Account'
        );
    }
    
    // Add the Account Owner's default Account Team to their Accounts
    global void execute(Database.BatchableContext bc, List<Account> scope){
        List<AccountTeamMember> addAccountTeamMembersToAccounts = new List<AccountTeamMember>();
        Set<Id> accountOwnerIds = new Set<Id>();
        // The Client Development Rep assigned to an Account varies. For this reason, 
        // the CDR could not be added to the Default Account Teams. Instead, we grab 
        // the CDR on the Account record and establish them as a member on the Account Team.
        Map<Id, Id> accountIdToClientDevelopmentRep = new Map<Id, Id>();
        Map<Id, List<UserAccountTeamMember>> userIdToDefaultAccountTeam = new Map<Id, List<UserAccountTeamMember>>();
        System.debug('scope: ' + scope);
        System.debug('scope size: ' + scope.size());
        for(Account account : scope) {
            accountOwnerIds.add(account.OwnerId);
            if(account.Client_Development_Rep__c != null && account.Client_Development_Rep__r.IsActive == true) {
                accountIdToClientDevelopmentRep.put(account.Id, account.Client_Development_Rep__c);
            }
        }
        
        System.debug('accountOwnerIds: ' + accountOwnerIds);
        // UserAccountTeamMember represents a User on the default account team of another User.
        // Map the User to their default Account Team
        for(UserAccountTeamMember defaultAccountTeamMember : [SELECT UserId, OwnerId, AccountAccessLevel, CaseAccessLevel, ContactAccessLevel, 
                                                            OpportunityAccessLevel, TeamMemberRole FROM UserAccountTeamMember
                                                            WHERE OwnerId IN: accountOwnerIds]) {
            if(userIdToDefaultAccountTeam.containsKey(defaultAccountTeamMember.OwnerId)) {
                userIdToDefaultAccountTeam.get(defaultAccountTeamMember.OwnerId).add(defaultAccountTeamMember);
            } else {
                userIdToDefaultAccountTeam.put(defaultAccountTeamMember.OwnerId, new List<UserAccountTeamMember>{defaultAccountTeamMember});
            }                                                
        }
        System.debug('userIdToDefaultAccountTeam size: ' + userIdToDefaultAccountTeam.size());
        System.debug('userIdToDefaultAccountTeam keys: ' + userIdToDefaultAccountTeam.keySet());
        System.debug('userIdToDefaultAccountTeam values: ' + userIdToDefaultAccountTeam.values());
        for(Account account : scope) {
            // Check that the user has a Default Account Team...
            if(userIdToDefaultAccountTeam.containsKey(account.OwnerId)) {
                // Get the default Account Team for this Account Owner...
                for(UserAccountTeamMember defaultAccountTeamMember : userIdToDefaultAccountTeam.get(account.OwnerId)) {
                    // Add this default Account Team Member to the Account Team
                    AccountTeamMember member = new AccountTeamMember(
                        AccountId = account.Id,
                        UserId = defaultAccountTeamMember.UserId,
                        AccountAccessLevel = defaultAccountTeamMember.AccountAccessLevel,
                        CaseAccessLevel = defaultAccountTeamMember.CaseAccessLevel,
                        ContactAccessLevel = defaultAccountTeamMember.ContactAccessLevel,
                        OpportunityAccessLevel = defaultAccountTeamMember.OpportunityAccessLevel,
                        TeamMemberRole = defaultAccountTeamMember.TeamMemberRole
                    );
                    addAccountTeamMembersToAccounts.add(member);
                }
            }
            //Check if the Account has an assigned Client Development Rep...
            if(accountIdToClientDevelopmentRep.containsKey(account.Id)) {
                // Add this Client Development Rep to the Account Team
                AccountTeamMember member = new AccountTeamMember(
                    AccountId = account.Id,
                    UserId = accountIdToClientDevelopmentRep.get(account.Id),
                    AccountAccessLevel = 'Edit',
                    CaseAccessLevel = 'Edit',
                    ContactAccessLevel = 'Edit',
                    OpportunityAccessLevel = 'Edit',
                    TeamMemberRole = 'Client Development Rep'
                );
                addAccountTeamMembersToAccounts.add(member);
            }
        }

        System.debug('Add Account Team Members: ' + addAccountTeamMembersToAccounts);
        if(addAccountTeamMembersToAccounts.size() > 0) {
            // Add Account Owner's default Account Team to every Account they own
            insert addAccountTeamMembersToAccounts;
        }

    }
    
    global void finish(Database.BatchableContext bc) {
        //TODO: Implement send job status email if needed.  
    }
}