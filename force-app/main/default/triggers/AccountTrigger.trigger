/*Modifying this trigger based on the Nordics requirement.
 * Profile check condition is temporary fix, the final solution need to be discussed
 * and fixed soon - Geetha PBI 927369
 */

trigger AccountTrigger on Account (before insert, after insert, after update, after delete) {
    
    //Not to execute the below code for Nordics Profiles
    Id profileId = userinfo.getProfileId();
    String profileName = [select Name from profile where id = :profileId LIMIT 1].Name;
    if(profileName != Constants.NORDICS_PROFILE_NAME && profileName != Constants.NORDICS_INTERNAL_DLL_MEMBER && profileName != Constants.GLOBAL_BUSINESS_ADMINISTRATION){
    	
        system.debug('Account trigger executed for profile = ' +profileName);
        if(Trigger.isInsert && Trigger.isBefore){
            AccountTriggerHelper.helperBeforeInsert(Trigger.new);
        }
        if(Trigger.isInsert && Trigger.isAfter){
            AccountTriggerHelper.helperAfterInsert(Trigger.newMap.values());
        }
        if(Trigger.isUpdate) {
            AccountTriggerHelper.helpAfterUpdate((Map<Id, Account>) Trigger.oldMap, (Map<Id, Account>) Trigger.newMap);
        }      
        if(Trigger.isDelete) {
            AccountTriggerHelper.helperAfterDelete((Map<Id, Account>) Trigger.oldMap, (Map<Id, Account>) Trigger.newMap);
        }
    }
}