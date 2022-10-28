public class AccountTriggerHelper {
    
    public static void helperBeforeInsert(List<Account> newAccounts){
        Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'API Integration' LIMIT 1];
        if (UserInfo.getProfileId() != apiProfile.Id ){
            populateRegionRelationship(newAccounts);
            populateLegalEntityDescription(newAccounts);
        }
    }
    
    //Method to populate region relationship
    private static void populateRegionRelationship(List<Account> newAccounts){
        //Query all region associations for this user
        List<Region_Assignment__c> regionAssignments = [Select id,Region__c,Region__r.Name 
                                                        From Region_Assignment__c 
                                                        where user__c = :UserInfo.getUserId()];
        
        if(!regionAssignments.isEmpty()){
            //prepare a list of accs where Region_Override__c is false to set region relationship
            List<Account> accsToProcess = new List<Account>();
            for(Account objAccount : newAccounts){
                if(objAccount.Region_Override__c == false){
                    accsToProcess.add(objAccount);
                }
            }
            
            //update region relationship on accs
            for(Account objAccount : accsToProcess){
            	objAccount.Region_Relationship__c = regionAssignments[0].Region__c ;
                objAccount.Region_Description__c = regionAssignments[0].Region__r.Name;
            }
        }
    }
    
    //Method to populate Legal_Entity_Description__c 
    private static void populateLegalEntityDescription(List<Account> newAccounts){
        List<Business_Unit_Assignment__c> businessUnitAssignments = [SELECT Id, Business_Unit__r.Parent_Business_Unit__r.Name 
                         FROM Business_Unit_Assignment__c 
                         WHERE user__c = :UserInfo.getUserId()];
        if(!businessUnitAssignments.isEmpty()){
            for(Account objAccount : newAccounts){
                if(businessUnitAssignments[0].Business_Unit__r != null && businessUnitAssignments[0].Business_Unit__r.Parent_Business_Unit__r != null){
                    objAccount.Legal_Entity_Description__c  = businessUnitAssignments[0].Business_Unit__r.Parent_Business_Unit__r.Name ;
                }
            }
        }
    }
    
    //New logic PBI #327475,#327470,#327472 -- Added logic to add user to new account team 3-20-2020
    @TestVisible
    public static void helperAfterInsert(List<Account> newAccMap){
        RecordType prospectRecordType= [SELECT Name, Id FROM RecordType WHERE SobjectType='Account' AND Name='Prospect'];
        Profile apiProfile = [SELECT Id FROM Profile WHERE Name = 'API Integration' LIMIT 1];
        List<Account> prospectAccounts = new List<Account>();
        for(Account a : newAccMap){
            if(a.RecordTypeId == prospectRecordType.Id){
                prospectAccounts.add(a);
            }
        }
        if (UserInfo.getProfileId() != apiProfile.Id && !prospectAccounts.isEmpty()) {
            insertTeamMembersForProspect(prospectAccounts);
        }
        
    }
    @TestVisible
    public static void helpAfterUpdate(Map<Id, Account> oldAccMap, Map<Id, Account> newAccMap){
        
        List<Account> AccountTeamDelete = new List<Account>();
        
        
        for(Account oldAcc : oldAccMap.values()) {
            Account newAcc = newAccMap.get(oldAcc.Id);
            system.debug('in first for loop');
            if(oldAcc.Remove_Account_Team__c != newAcc.Remove_Account_Team__c && String.isNotBlank(newAcc.Remove_Account_Team__c)){
                system.debug('in first if');
                AccountTeamDelete.add(newAcc);
            }
        }
        deleteAccountTeamMember(AccountTeamDelete);
    }
    
    @TestVisible
    private static void deleteAccountTeamMember(List<Account> accts){
        
        AccountTeamMember deleteATM = new AccountTeamMember();
        List<AccountTeamMember> listATM = new List<AccountTeamMember>();
        List<Account> updateAcct = new List<Account>();
        
        for(Account acc : accts){
            system.debug('in for loop with accountID ' + acc.Id);
            if(acc.Remove_Account_Team__c != null){
                deleteATM = [Select ID from AccountTeamMember where ID=: acc.Remove_Account_Team__c];
                system.debug(deleteATM.ID);
                listATM.add(deleteATM);
                
            }
        }
        
        if(listATM.size() > 0){
            delete listATM;
            
        }
    }
    
    public static void helperAfterDelete(Map<Id, Account> oldAccMap, Map<Id, Account> newAccMap){
        Map<Id, String> accNewEntityUpdate = new Map<Id, String>();
        List<Id> accToQuery = new List<Id>();
        for(Account oldVal : oldAccMap.values()){
            if(String.isNotBlank(oldVal.MasterRecordId) && String.isNotBlank(oldVal.ATS_ID_s__c)){
                accNewEntityUpdate.put(oldVal.MasterRecordId, oldVal.ATS_ID_s__c);
                accToQuery.add(oldVal.MasterRecordId);
            }
        }
        
        
        if(!accToQuery.isEmpty()){
            mergeAccUpdate(accToQuery, accNewEntityUpdate);
            
        }
        
    }
    
    @future
    public static void mergeAccUpdate(List<Id> accounts , Map<Id, String> accNewEntity){
        List<Account> accountsToUpdate = [SELECT ATS_ID_s__c, Id FROM Account WHERE Id IN :accounts];
        List<Account> toUpdate = new List<Account>();
        for(Account acc : accountsToUpdate){
            if(String.isBlank(acc.ATS_ID_s__c)){
                acc.ATS_ID_s__c = accNewEntity.get(acc.Id);
                toUpdate.add(acc);
            }else{
                String toAdd = dupeCheck(accNewEntity.get(acc.Id), acc.ATS_ID_s__c);
                if(string.isNotBlank(toAdd)){
                    acc.ATS_ID_s__c = toAdd + ';' + acc.ATS_ID_s__c;
                    toUpdate.add(acc);
                }
            }
        }
        
        if(!toUpdate.isEmpty()){
            update toUpdate;
        }
    }
    
    @TestVisible
    private static String dupeCheck(String entityToCompare, String comparedEntity ){
        String toReturn;
        Integer currentSize = 0;
        List<String> comparedEntityList = comparedEntity.split('\\;');
        List<String> entityToCompareList = entityToCompare.split('\\;');
        for(String toCompare : entityToCompareList){
            Boolean found = false;
            for(String existingEntity : comparedEntityList){
                if(toCompare == existingEntity){
                    found = true;
                }
            }
            if(!found && (currentSize + comparedEntity.length() + toCompare.length() < 255)){
                if(toReturn != null){
                    toReturn = toCompare + ';' + toReturn;
                }else{
                    toReturn = toCompare;
                }
                currentSize = toReturn.length();
            }
        }
        return toReturn;
    }
    
    //New logic PBI #327475,#327470,#327472 -- Added logic to add user to new account team
    @TestVisible
    private static void insertTeamMembersForProspect(List<Account> accForTeamMembers){
        Id userId = UserInfo.getUserId();
        List<AccountTeamMember> atmsToInsert = new List<AccountTeamMember>();
        for (Account a : accForTeamMembers){
            String bu = 'Sales Rep - ' + a.Business_Unit__c;
            AccountTeamMember atmToInsert = new AccountTeamMember();
            atmToInsert.UserId = userId;
            atmToInsert.AccountId = a.Id;
            atmToInsert.TeamMemberRole = bu;
            atmsToInsert.add(atmToInsert);
        }
        
        if(!atmsToInsert.isEmpty()){
            insert atmsToInsert;
        }
    }
    
}