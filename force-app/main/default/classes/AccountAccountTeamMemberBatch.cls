/**
   *  @description A batch job that will insert the createdBy user into the account teams if the user
   *  is not a part of the account team
   *  @author      Newton Sun, Traction on Demand
   *  @date        2020-04-02
 */

global class AccountAccountTeamMemberBatch implements Database.Batchable<SObject>{
    global final String query;
    global AccountAccountTeamMemberBatch(String q) {
        this.query = q;
    }
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(this.query);

    }

    global void execute(Database.BatchableContext BC, List<Account> accs) {
        List<Id> usersToQuery = new List<Id>();
        Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'API Integration' LIMIT 1];
        List <User> apiUsers = [SELECT Id FROM User WHERE ProfileId =: apiProfile.Id];
        List<Account> accsToUse = new List<Account>();
        Set<Id> apiIds = new Set<Id>();
        for(User u : apiUsers){
            apiIds.add(u.Id);
        }
        for (Account acc : accs){
            if(acc.CreatedById != null && !apiIds.contains(acc.CreatedById)){
                accsToUse.add(acc);
                usersToQuery.add(acc.CreatedById);
            }
        }
        if(!usersToQuery.isEmpty()) {
            List<AccountTeamMember> atms = [
                    SELECT UserId, AccountId
                    FROM AccountTeamMember
                    WHERE AccountId IN :accs AND UserId IN :usersToQuery
            ];

            List<User> activeUsers = [
                    SELECT Id
                    FROM User
                    WHERE Id IN : usersToQuery
                    AND IsActive = TRUE
            ];
            List<Account> accToAddTeamMember = new List<Account>();
            for (Account acc : accsToUse) {
                Boolean found = false;
                for (AccountTeamMember atm : atms) {
                    if (acc.CreatedById == atm.UserId && acc.Id == atm.AccountId) {
                        found = true;
                        break;
                    }
                }
                if (!found) {
                    Boolean isActive = false;
                    for(User u : activeUsers){
                        if (acc.CreatedById == u.Id){
                            isActive = true;
                        }
                    }
                    if(isActive) {
                        accToAddTeamMember.add(acc);
                    }

                }
            }
            if (!accToAddTeamMember.isEmpty()) {
                List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
                for (Account a : accToAddTeamMember) {
                    String bu = a.Business_Unit__c == null ? 'Sales Rep' : 'Sales Rep - ' + a.Business_Unit__c;
                    AccountTeamMember atmToInsert = new AccountTeamMember();
                    atmToInsert.UserId = a.CreatedById;
                    atmToInsert.AccountId = a.Id;
                    atmToInsert.TeamMemberRole = bu;
                    atmsToInsert.add(atmToInsert);
                }
                if (!atmsToInsert.isEmpty()) {
                    insert atmsToInsert;
                }
            }
        }

    }

    global void finish(Database.BatchableContext BC) {
        System.debug('------------ ACCOUNT TEAMS UPDATED ------------');
    }
}