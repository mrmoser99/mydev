/**
  *  @description A batch job that processes opportunities that have not assigned the
  *  owner of the opportunity to the account teams of the vendor and end user accounts
  *  associated with the opportunity.
  *  @author      Newton Sun, Traction on Demand
  *  @date        2020-04-02
 **/

global class OpportunityAccountTeamMemberBatch  implements Database.Batchable<SObject> {
    global final String query;
    global OpportunityAccountTeamMemberBatch(String q) {
        this.query = q;
    }
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(this.query);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> opps) {
        Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'API Integration' LIMIT 1];
        Set<Id> accountsToQuery = new Set<Id>();
        Set<Id> usersToQuery = new Set<Id>();
        List<Opportunity> oppsToCheck = new List<Opportunity>();
        List<Id> userIds = new List<Id>();
        for (Opportunity o : opps) {
            userIds.add(o.OwnerId);
        }
        Map<Id, User> users = new Map<Id, User>([
                SELECT Id
                FROM User
                WHERE Profile.Name = 'API Integration'
        ]);
        List<User> activeUsers = [SELECT Id FROM User WHERE Id IN :userIds AND IsActive = TRUE];
        Set<Id> activeUsersId = new Set<Id>();
        for (User u : activeUsers) {
            activeUsersId.add(u.Id);
        }
        List<Opportunity> oppsToParse = new List<Opportunity>();
        for (Opportunity o : opps) {
            if (o.OwnerId != null && activeUsersId.contains(o.OwnerId) && users.get(o.OwnerId) == null) {
                oppsToParse.add(o);
            }
        }
        for (Opportunity o : oppsToParse) {
            Boolean existsAccount = false;
            if (o.End_User__c != null) {
                accountsToQuery.add(o.End_User__c);
                existsAccount = true;
            }
            if (o.AccountId != null) {
                accountsToQuery.add(o.AccountId);
                existsAccount = true;
            }
            if (existsAccount) {
                oppsToCheck.add(o);
                usersToQuery.add(o.OwnerId);
            }

        }

        if (accountsToQuery != null && !accountsToQuery.isEmpty()) {
            //List of account team members based off of the given accounts
            List<AccountTeamMember> actTeamMems = [
                    SELECT UserId, AccountId
                    FROM AccountTeamMember
                    WHERE AccountId IN :accountsToQuery
                    AND UserId IN :usersToQuery
            ];

            List<Opportunity> verifiedOpps = new List<Opportunity>();
            Map<Id, String> verifiedOppsWhichTeam = new Map<Id, String>();

            for (Opportunity o : oppsToCheck) {
                Boolean doesntExistVendor = o.AccountId == null ? false : true;
                Boolean doesntExistEndUser = o.End_User__c == null ? false : true;
                if (!actTeamMems.isEmpty()) {
                    for (AccountTeamMember atm : actTeamMems) {
                        if (atm.UserId == o.OwnerId && atm.AccountId == o.AccountId) {
                            doesntExistVendor = false;
                        }
                        if (atm.UserId == o.OwnerId && atm.AccountId == o.End_User__c) {
                            doesntExistEndUser = false;
                        }
                    }
                }
                if (doesntExistVendor || doesntExistEndUser) {
                    if (doesntExistVendor && doesntExistEndUser) {
                        verifiedOppsWhichTeam.put(o.Id, 'Both');
                    } else if (doesntExistVendor) {
                        verifiedOppsWhichTeam.put(o.Id, 'Vendor');
                    } else if (doesntExistEndUser) {
                        verifiedOppsWhichTeam.put(o.Id, 'End User');
                    }
                    verifiedOpps.add(o);
                }
            }
            List<AccountTeamMember> atmToInsert = new List<AccountTeamMember>();
            if (!verifiedOpps.isEmpty()) {
                for (Opportunity o : verifiedOpps) {
                    String memRole = 'Sales Rep';
                    if (o.Business_Unit1__c != null) {
                        memRole = memRole + ' - ' + o.Business_Unit1__c;
                    }
                    if (verifiedOppsWhichTeam.get(o.Id) == 'Both') {
                        AccountTeamMember atmVendor = new AccountTeamMember();
                        atmVendor.UserId = o.OwnerId;
                        atmVendor.AccountId = o.AccountId;
                        atmVendor.TeamMemberRole = memRole;
                        atmToInsert.add(atmVendor);
                        AccountTeamMember atmEndUser = new AccountTeamMember();
                        atmEndUser.UserId = o.OwnerId;
                        atmEndUser.AccountId = o.End_User__c;
                        atmEndUser.TeamMemberRole = memRole;
                        atmToInsert.add(atmEndUser);
                    } else {
                        AccountTeamMember atm = new AccountTeamMember();
                        atm.UserId = o.OwnerId;
                        if (verifiedOppsWhichTeam.get(o.Id) == 'Vendor') {
                            atm.AccountId = o.AccountId;
                        } else if (verifiedOppsWhichTeam.get(o.Id) == 'End User') {
                            atm.AccountId = o.End_User__c;
                        }
                        atm.TeamMemberRole = memRole;
                        atmToInsert.add(atm);
                    }
                }
            }

            if (!atmToInsert.isEmpty()) {
                insert atmToInsert;
            }
        }
    }
    global void finish(Database.BatchableContext BC) {
        System.debug('------------ ACCOUNT TEAMS UPDATED FROM OPPORTUNITY ------------');
    }
}