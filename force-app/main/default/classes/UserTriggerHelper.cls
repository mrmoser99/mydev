/* Created by ilu on 2021-10-04.
New logic for experience cloud PBI #628135 -- Sync Partner account to external account hierarchy
   Class :  UserTriggerHelper
   Description : Helper Class for User
   Date/Sprint		PBI/Description
   PI-23-Q1-03	834525 - Partner Users: Automated Report Folder Sharing(Dibyendu)*/

public with sharing class UserTriggerHelper {
public static String DOD_PUBLIC_GROUP = 'DLL_on_Demand_Users';//Added as a part of change for PBI 834525
public static String DOD_Partner_Admin = 'Partner Admin';//Added as a part of change for PBI 834525
public static String DOD_Sales_Rep1 = 'DOD Partner Sales Rep 1';//Added as a part of change for PBI 834525

    public static void helperAfterInsert(List<User> newUsers){
        /*List<Id> newUserIds = new List<Id>();
        for(User u: newUsers){
            newUserIds.add(u.Id);
        }
        insertExternalAccountHierarchy(newUsers);*/
        addToPublicGroup(newUsers);
        
    }
    
    @TestVisible
   private static void addToPublicGroup(List<User> newListUsers){
       List<GroupMember> addMemeberToGroup = new List<GroupMember>();
       List<Group> pgList = [select Id,DeveloperName from Group where DeveloperName =: DOD_PUBLIC_GROUP];
       List<Profile> pList = [select Id,Name from Profile where name =:DOD_Partner_Admin   or name =:DOD_Sales_Rep1];
       Map<String,Profile> mapPIds = new Map<String,Profile>();
       for(Profile assingeP:pList){
           mapPIds.put(assingeP.id,assingeP);
       }
       for (User newUser : newListUsers){
           if(mapPIds.get(newUser.ProfileId)!=null){
               GroupMember addMemeber = new GroupMember();
               if(pgList.size()>0){
                   addMemeber.GroupId = pgList[0].id;
                   addMemeber.UserOrGroupId = newUser.id;
                   addMemeberToGroup.add(addMemeber);
               }
              // addMemeber.UserOrGroupId
           }
       }
       if(addMemeberToGroup.size()>0){
           insert addMemeberToGroup;
       }
       
   }
    
    
    public static void helpAfterUpdate(Map<Id, User> oldUserMap, Map<Id, User> newUserMap){
        /*List<Id> newUserIds = new List<Id>();
        for(User u: newUsers){
            newUserIds.add(u.Id);
        }
        insertExternalAccountHierarchy(newUsers);*/
        addToPublicGroupAfterUpdate(oldUserMap, newUserMap);
        
    }
    
   @TestVisible
   private static void addToPublicGroupAfterUpdate(Map<Id, User> oldUserMap, Map<Id, User> newUserMap){
       List<GroupMember> addMemeberToGroup = new List<GroupMember>();
       List<GroupMember> removeMemeberToGroup = new List<GroupMember>();
       List<Group> pgList = [select Id,DeveloperName from Group where DeveloperName =: DOD_PUBLIC_GROUP];
       List<Profile> pList = [select Id,Name from Profile where name =:DOD_Partner_Admin   or name =:DOD_Sales_Rep1];
       Map<String,Profile> mapPIds = new Map<String,Profile>();
       for(Profile assingeP:pList){
           mapPIds.put(assingeP.id,assingeP);
       }
       List<String> updatedIds = new List<String>();
       system.debug('DDT not test1');
       for (User newUser : newUserMap.values()) {
           updatedIds.add(newUser.id);
           system.debug('DDT not added'+newUser);
       }
       List<GroupMember> assignedPg = [select id,UserOrGroupId, Group.DeveloperName from GroupMember where UserOrGroupId IN:updatedIds and Group.DeveloperName =: DOD_PUBLIC_GROUP];
       Map<String,GroupMember> mapPGIds = new Map<String,GroupMember>();
       for(GroupMember assingedM:assignedPg){
           mapPGIds.put(assingedM.UserOrGroupId,assingedM);
       }
       
       for (User newUser : newUserMap.values()) {
           system.debug('DDT User'+mapPGIds.get(newUser.id)+mapPIds.get(newUser.ProfileId));
           if(mapPIds.get(newUser.ProfileId)!=null && mapPGIds.get(newUser.id)==null){
               system.debug('DDT userAssigned added'+mapPGIds.get(newUser.id));
               GroupMember addMemeber = new GroupMember();
               addMemeber.GroupId = pgList[0].id;
               addMemeber.UserOrGroupId = newUser.id;
               addMemeberToGroup.add(addMemeber);
           }
           else if(mapPIds.get(newUser.ProfileId)==null && mapPGIds.get(newUser.id)!=null)
           {
               system.debug('DDT userAssigned removed'+mapPGIds.get(newUser.id).id);
               GroupMember deleteMemeber = new GroupMember();
               deleteMemeber.id = mapPGIds.get(newUser.id).id;
               removeMemeberToGroup.add(deleteMemeber);
           }
       }
        if(addMemeberToGroup.size()>0){
               insert addMemeberToGroup;
           }
        if(removeMemeberToGroup.size()>0){
               delete removeMemeberToGroup;
           }
   }
    /*@future
    private static void insertExternalAccountHierarchy(List<Id> newUserIds){
        
        List<User> newUsers = [SELECT Id,ProfileId,ContactId from User WHERE Id IN:newUserIds];
        
        Map<Id,Profile> partnerProfileMap = new Map<Id,Profile>([SELECT Id,Name FROM Profile WHERE Name Like 'Partner%']);

        List<Id> partnerUserContactIds = new List<Id>();
        
        for(User pUser : newUsers){  
            if(partnerProfileMap.containsKey(pUser.ProfileId)){
                partnerUserContactIds.add(pUser.ContactId);
            }
        }
        
        List<ExternalAccountHierarchy> existingExternalAccountHierarchies = [SELECT Id, AccountId FROM ExternalAccountHierarchy WHERE IsActive = TRUE];
        
        Map<String,String> existingExternalAccountHierarchyMap = new Map<String,String>{};
        for(ExternalAccountHierarchy eah: existingExternalAccountHierarchies){
            existingExternalAccountHierarchyMap.put(eah.AccountId,eah.Id);
        }

        List<ExternalAccountHierarchy> newPartnerAccountHierarchies = new List<ExternalAccountHierarchy>();
        
        List<Contact> partnerContacts = [SELECT Id, Account.Id, Account.Name,Account.OwnerId,Account.ParentId,Account.IsPartner,Account.RecordTypeId FROM Contact WHERE Id = :partnerUserContactIds];
        
        List<RecordType> RecordTypes= [SELECT Name, Id FROM RecordType WHERE SobjectType='Account' AND
        (Name='Legal Entity' OR Name='Party' OR Name='Vendor')];

        Map<String,String> vendorRecordTypes = new Map<String,String>{};
        for(RecordType rt: RecordTypes){
            vendorRecordTypes.put(rt.Name,rt.Id);
        }
        
        for(Contact partnerContact:partnerContacts){            
            if(partnerContact.Account.RecordTypeId == vendorRecordTypes.get('Legal Entity') ||              
               partnerContact.Account.RecordTypeId == vendorRecordTypes.get('Party')  ||
               partnerContact.Account.RecordTypeId == vendorRecordTypes.get('Vendor')){
                   if(String.isBlank(existingExternalAccountHierarchyMap.get(partnerContact.Account.Id))){                       
                       ExternalAccountHierarchy newPartnerAccountHierarchy = new ExternalAccountHierarchy();
                       newPartnerAccountHierarchy.AccountId = partnerContact.Account.Id;
                       newPartnerAccountHierarchy.HierarchyType = 'Partner';
                       if(String.isNotBlank(partnerContact.Account.ParentId)){                          
                           newPartnerAccountHierarchy.IsAccessibleToParent = true;
                           ExternalAccountHierarchy parentExternalAccountHierarchy = new ExternalAccountHierarchy();
                           parentExternalAccountHierarchy.Id = existingExternalAccountHierarchyMap.get(partnerContact.Account.ParentId);
                           if(String.isBlank(parentExternalAccountHierarchy.Id)){                             
                               parentExternalAccountHierarchy.addError(partnerContact.Account.Id+'Parent external account hierarchy do not exist'); 
                           }
                           newPartnerAccountHierarchy.ParentId = parentExternalAccountHierarchy.Id;
                        }
                        else{
                            newPartnerAccountHierarchy.IsAccessibleToParent = false;
                        }
                        newPartnerAccountHierarchy.IsActive = true;
                        newPartnerAccountHierarchy.Name = partnerContact.Account.Name;
                        newPartnerAccountHierarchy.OwnerId = partnerContact.Account.OwnerId;
                        newPartnerAccountHierarchies.add(newPartnerAccountHierarchy);
                    }
            }
        }
        if(newPartnerAccountHierarchies.size()>0){
            try{
                insert newPartnerAccountHierarchies;
            } catch(DmlException e) {
                System.debug('The following exception has occurred: ' + e.getMessage());
            }
        }
	}*/
}