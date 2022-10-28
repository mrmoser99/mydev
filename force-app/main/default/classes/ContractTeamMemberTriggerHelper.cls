/*PBI:640594:Apex Sharing for Contracts using Contract Teams: DLL on Demand
*Ability to add a portal user to a contract team, so that the portal user can view the contract by APEX sharing.
*PBI:665016:Portfolio Team - End User Visibility Enable
*Extended the apex sharing functionality to share the EndUser account to Partner Admin
*version1: Geetha Bharadwaj
Commenting out the logic for Apex Sharing for DLL on Demand
*/
public class ContractTeamMemberTriggerHelper {
    
    /*public static void helpBeforeInsert(List<Contract_Team__c> contractTeamList, Map<Id,Contract_Team__c> oldMap){
        
        set<Id> contractId_set = new set <Id>();
        Map<String, string> contractEndUsermap = new  Map<String, string>();
        List<Contract__Share> contractTeamshareList = New List<Contract__Share>();
        Map<Id, Contract__Share> contractMap = new Map<Id, Contract__Share>();
        Set<Id> todeletelist = new Set<Id>();
        List<AccountShare> accountShareList = new List<AccountShare>();
        for(Contract_Team__c contTeam:contractTeamList ){
            contractId_set.add(contTeam.Contract__c );
        }
        List<Contract__c> contractlist= [Select Id, End_User__c from Contract__c where Id in: contractId_set];
        for(Contract__c cont: contractlist){
            contractEndUsermap.put(cont.Id,cont.End_user__c);
        }
        List<AccountShare> sharedAccountList = [SELECT id, AccountId, UserOrGroupId, AccountAccessLevel, 
                                                OpportunityAccessLevel, CaseAccessLevel, ContactAccessLevel, 
                                                RowCause from AccountShare where AccountId in: contractEndUsermap.values()];
        List<Contract__Share>  sharedcontractList =  [SELECT AccessLevel,Id,ParentId,RowCause,UserOrGroupId
                                                      FROM Contract__Share 
                                                      WHERE parentId in: contractId_set];
    map<Id, AccountShare> accountShareMap = new map<Id, AccountShare>();
        if(!sharedcontractList.isEmpty()){
            for(Contract__Share ctmshare:sharedcontractList){
                contractMap.put(ctmshare.UserOrGroupId, ctmshare);
            }
        }
        if(!sharedAccountList.isEmpty()){
            for(AccountShare actshare:sharedAccountList){
                accountShareMap.put(actshare.UserOrGroupId, actshare );
            }
        }
        for(Contract_Team__c ctm: contractTeamList){
            //if record is already shared with User
             if(contractMap.get(ctm.User__c) == null){
                If(oldMap != null){
                    todeletelist.add(oldMap.get(ctm.Id).User__c);
                } 
                Contract__Share ctshare = new Contract__Share();
                ctshare.AccessLevel = ctm.Contract_Access__c == 'Read / Write' ? 'edit':'read';
                ctshare.ParentId = ctm.Contract__c;
                ctshare.UserOrGroupId = ctm.User__c;
                contractTeamshareList.add(ctshare);
            }
              if(accountShareMap.get(ctm.User__c)== null){
                 if(contractEndUsermap.get(ctm.Contract__c) != null){
                     AccountShare actShare = new AccountShare();
                     actShare.AccountId = contractEndUsermap.get(ctm.Contract__c);
                     actShare.AccountAccessLevel = 'read';
                     actShare.OpportunityAccessLevel = 'read';
                     actShare.CaseAccessLevel = 'read';
                     actShare.UserOrGroupId = ctm.User__c;
                     accountShareList.add(actShare);
                 }
             }
        }
        //deleting the record for previous User and inserting record for updated User
        delete( [SELECT AccessLevel,Id,ParentId,RowCause,UserOrGroupId
                 FROM Contract__Share 
                 where parentId in: contractId_set and
                 UserOrGroupId in:todeletelist and RowCause = 'Manual']);
        
        
        if(!contractTeamshareList.isEmpty()){
            insert contractTeamshareList;
        }
        if(!accountShareList.isEmpty()){
          insert  accountShareList;
        }
        
    }
    
    public static void helpBeforeDelete(Map<Id,Contract_Team__c> oldMap){
        system.debug('oldMap=='+oldMap);
        Set<Id> userIdSet = new Set<Id>();
        Set<Id> contractIdSet = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        
        for(contract_Team__c ctm :oldMap.values()){
            userIdSet.add(oldMap.get(ctm.Id).user__c);
            contractIdSet.add(oldMap.get(ctm.id).contract__c);
        }
        
        List<Contract__c> convalue = [Select Id, End_User__c from Contract__c where Id in: contractIdSet];
        system.debug('oldMap=='+convalue);
        for(Contract__c ctm: convalue){
            if(ctm.end_user__c!=null){
                accountIdSet.add(ctm.end_user__c);
            }            
        }
        
        List<Contract__Share>  delContractShare =  [SELECT Id, parent.End_User__c FROM Contract__Share 
                                                    WHERE parentId in: contractIdSet
                                                    AND UserOrGroupId in: userIdSet];
        
         system.debug('delContractShare=='+delContractShare);
        
        List<AccountShare>  delAccountShare =  [SELECT Id FROM AccountShare 
                                                WHERE AccountId in: accountIdSet
                                                AND UserOrGroupId in: userIdSet];
         system.debug('delAccountShare=='+delAccountShare);
        List<OpportunityShare> oppShareList = [Select id from OpportunityShare where Opportunity.end_user__c in :accountIdSet and UserOrGroupId in :userIdSet];         
        
        
        system.debug('oppShareList=='+oppShareList);
        if(!delContractShare.isEmpty()){
            delete delContractShare;
        }
        system.debug('delContractShare=='+delContractShare);
        List<Contract__Share>  delContractAccountShare =  [SELECT Id, ParentId FROM Contract__Share 
                                                           WHERE parent.End_user__c in: accountIdSet
                                                           AND UserOrGroupId in: userIdSet];
        
        system.debug('delContractAccountShare=='+delContractAccountShare);
        If (delContractAccountShare.isEmpty() && oppShareList.isEmpty()){
            if(!delAccountShare.isEmpty()){
                delete delAccountShare;
            }
        }
        
    }*/
}