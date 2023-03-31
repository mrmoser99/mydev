/*******************************************************************************************************************************
 * 
 * Change Log:
 * 
 * 03/28/2023 - MRM - Created trigger; This trigger makes sure only one user is set to current
 * 
 *******************************************************************************************************************************/

public class RecentPartnerUserTriggerHelper {

    public Static Boolean RecentPartnerUserHelperRunning = false;  //initialize static to false and set to true when running
    
    
    /***********************************************************************************************************************
     * @description helpAfterInsert description
     * @author Mark R. Moser
     * @param  recentPartnerUsers recentPartnerUsers description
     */ 
    public static void helpAfterInsert(List<Recent_Partner_User__c> recentPartnerUsers){
        
        RecentPartnerUserHelperRunning = true;

        List<Recent_Partner_User__c> otherRecentPartnerUsers = new List<Recent_Partner_User__c>();

        Map<ID,Recent_Partner_User__c> idMap = new Map<ID,Recent_Partner_User__c>();
        for (Recent_Partner_User__c rpu:recentPartnerUsers){
            if (rpu.current_user__c == true){
                idMap.put(rpu.id,rpu);
            }
        }

        //Makes sure only 1 current on insert batch

        if (idMap.size() > 1){
            Integer i=0;
            for (ID rId:idMap.keySet() ){
                i++;
                if (i > 1){
                    idMap.get(rId).addError('Only 1 user can be the current user!');
                }
            }  
        }     
    
        if (!idMap.isEmpty()){
            markOthersAsFalse(idMap);
        }
    
    }

    /**********************************************************************************************************************************************
     * @description 
     * 
     * @author Mark R. Moser
     * @param  oldRecentPartnerUserMap oldRecentPartnerUserMap description
     * @param  newRecentPartnerUserMap newRecentPartnerUserMap description
     */ 
    public static void helpAfterUpdate(Map<Id, Recent_Partner_User__c> oldRecentPartnerUserMap, Map<Id, Recent_Partner_User__c> newRecentPartnerUserMap){

        RecentPartnerUserHelperRunning = true;

        Integer i=0;
        Map<ID,Recent_Partner_User__c> idMap = new Map<ID,Recent_Partner_User__c>();
        for(ID rId:newRecentPartnerUserMap.keySet()){
            if (newRecentPartnerUserMap.get(rId).current_user__c == true){
                idMap.put(rId,newRecentPartnerUserMap.get(rId));
                i++;
                //Makes sure only 1 current on udpate batch
                if (i > 1){
                    newRecentPartnerUserMap.get(rId).addError('Only 1 user can be the current user!');
                }
            }
        }

        if (!idMap.isEmpty()){
            markOthersAsFalse(idMap);
        }
     
    }

    /****************************************************************************************************************************************
     * @description markOthersAsFalse description
     * @author Mark R. Moser
     * @param  currentMap currentMap description
     */ 

    static void markOthersAsFalse(Map<ID,Recent_Partner_User__c> currentMap){

        List<Recent_Partner_User__c> rList = new List<Recent_Partner_User__c>();
        rList = [
                select id 
                from 
                Recent_Partner_User__c 
                where id not in :currentMap.keySet() 
                and internal_user__c = :UserInfo.getUserId()
                ];
        for (Recent_Partner_User__c r:rList){
            r.current_user__c = false;
        }

        if (!rList.isEmpty()){
            update rList;
        }        

    }
}