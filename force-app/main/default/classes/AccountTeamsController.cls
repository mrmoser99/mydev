public class AccountTeamsController {
        
    @AuraEnabled
    public static List<AccountTeamMember> getAccountTeamsList(ID accountId) {
        // Getting the list of Account Team Members from where Id is in accountIds
                String acctId = accountId;
                return [SELECT Id, UserId, User.Name, AccountId, Title, TeamMemberRole FROM AccountTeamMember where accountid=:acctId ];
        
    }

 
    @AuraEnabled
    public static Map<String,String> deleteTeamList(String memberId, ID acctId) {
        
        String del = memberId; 
        ID updateAcct = acctId;
        Account acctUpdate = new Account(Id = acctId);
        acctUpdate.Remove_Account_Team__c = del;
        
        Map<String,String> resultMap = new Map<String,String>();
        // Adding try catch for exception handling
        try {
            // Updating Account leading to delete of Account Team Member
            update acctUpdate;
            // Setting the success status and message in resultMap
            resultMap.put('status', 'success');
                resultMap.put('message', 'Team Members Deleted Successfully');        
        }
        catch(Exception e) {
            // Setting the error status and message in resultMap
            resultMap.put('status', 'error');
                        resultMap.put('message',e.getMessage());
        }
        // Returning the result string map
        return resultMap;                
    }
}