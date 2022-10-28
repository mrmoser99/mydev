/*PBI:665017:Opportunity Team - End User Visibility Enable: DLL on Demand
* Opportunity access automaticall shared. Enduser account is apex shared.
* version1: Geetha Bharadwaj
Commenting out the logic for Apex Sharing for DLL on Demand
*/
public class OpportunityTeamMemberTriggerHelper {
    
    /*public static void processEndUserAccShare(Map<Id,OpportunityTeamMember > newMap) {
        List<OpportunityTeamMember> oppTeamMemberList =  [SELECT Id, TeamMemberRole, OpportunityId, 
                                                          Opportunity.End_User__c, User.Contact.ReportsToId, UserId 
                                                          FROM OpportunityTeamMember 
                                                          WHERE Id IN: 
                                                          newMap.keySet()  ];
        
        Set<Id> act_Idset = new set<Id>();
        Set<Id> user_IdSet = new Set<Id>();
        List<User> reportToUserList = new  List<User>();
        Map<Id, Set<Id>> userOppMap = new Map<Id, Set<Id>>();
        for(OpportunityTeamMember oppTeamMember: oppTeamMemberList) {
            if(oppTeamMember.Opportunity.End_User__c != null){
                act_Idset.add(oppTeamMember.Opportunity.End_User__c);
                user_IdSet.add(oppTeamMember.User.Id);
            }
        }
        
        if(user_IdSet.size() > 0) {
            reportToUserList = [SELECT Id, ContactId FROM User WHERE Id IN: user_IdSet];
        }
       
        if(!act_Idset.isEmpty() && !reportToUserList.isEmpty()){
            shareEndUserAccount(reportToUserList, act_Idset);
        }
    }
    public static void shareEndUserAccount(List<User> uslist, Set<Id> accIds){
        
        String partnerAdmin = System.label.ddPartnerAdminProfile;
        Set<Id> accountIdset = new Set<Id>();
        List<AccountShare> accountShareList = new List<AccountShare>();
        
        List<Account> accList = [select id from Account where id in :accIds];
        
        for(Account acc:accList){
            for(User us: uslist){
                AccountShare actShare = new AccountShare();
                actShare.AccountId = acc.Id;
                actShare.AccountAccessLevel = 'read';
                actShare.OpportunityAccessLevel = 'read';
                actShare.CaseAccessLevel = 'read';
                // actShare.ContactAccessLevel = 'read';
                actShare.UserOrGroupId = us.Id;
                accountShareList.add(actShare);
            }   
        }
        
        if(!accountShareList.isEmpty()){  
            insert accountShareList;
        }
        
    }
    public static void removeEndUserAccShare(Map<id, OpportunityTeamMember> oldMap){
        List<opportunityTeamMember>  oppTeamMemberList = [SELECT Id, TeamMemberRole, OpportunityId, 
                                                          Opportunity.End_User__c,  User.Contact.ReportsToId, UserId, 
                                                          User.Id 
                                                          FROM OpportunityTeamMember 
                                                          WHERE Id IN: oldMap.keySet()];
        set<Id> act_Idset = new set<Id>();
        Set<Id> user_IdSet = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        List<AccountShare> sharelist = new  List<AccountShare>();
        for(OpportunityTeamMember oppTeamMember: oppTeamMemberList) {
            if(oppTeamMember.Opportunity.End_User__c != null){
                act_Idset.add(oppTeamMember.Opportunity.End_User__c);
                user_IdSet.add(oppTeamMember.User.Id);
                oppIds.add(oppTeamMember.OpportunityId);
            }
        }
        sharelist =  [Select Id from AccountShare where UserOrGroupId in:user_IdSet AND AccountId in:act_Idset and OpportunityAccessLevel = 'read'];
        
        List<OpportunityShare> oppShareList = [Select id  from OpportunityShare where Opportunity.end_user__c in :act_Idset and UserOrGroupId in :user_IdSet];         
        //Acc share - userid and account id
        List<Contract__Share> conShareList = [Select id from Contract__Share where (ParentId in (Select id from contract__c where End_User__c in :act_Idset)) AND UserOrGroupId in :user_IdSet];
                
        if(conShareList.isEmpty() && oppShareList.isEmpty()){
            if(!sharelist.isEmpty()){
                delete sharelist;
            }
        }
    }*/ 
}