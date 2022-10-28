/* Created by ilu on 2021-10-04.
New logic for experience cloud PBI #628135 -- Sync Partner account to external account hierarchy*/

public with sharing class UserTriggerHelper {

    public static void helperAfterInsert(List<User> newUsers){
        List<Id> newUserIds = new List<Id>();
        for(User u: newUsers){
            newUserIds.add(u.Id);
        }
        insertExternalAccountHierarchy(newUserIds);
    }

    @future
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
	}
}