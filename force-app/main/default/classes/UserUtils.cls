/*****************************************************************************************************************
 * Dll on Demaind (DOD) USER UTILITY CLASS
 *
 * Change Log:
 *
 *  03/29/2023 - MRM Created class
 *******************************************************************************************************************/
public with sharing class UserUtils {



    @AuraEnabled  
    public static String setPartnerUser(ID contactId){

	    List<User> uList = [select id
                            FROM
                            User
                            where contactId = :contactId
                            and isActive = true
        ];

        if (uLIst.isEmpty()){
            throw new AuraHandledException('This contact is not have an active partner user.  This contact cannot be selected!');
        }

        List<Recent_Partner_User__c> rList = [
                Select Id
                ,current_user__c
                From Recent_Partner_User__c 
                where partner_user__c = :uLIst[0].id  //contact's user id
                and internal_user__c = :Userinfo.getUserId()
                and ownerid = :Userinfo.getUserId()
        ];

        if (!rList.isEmpty()){
            if (rList[0].current_user__c == true){
                return null;
            }
            else{
                 
                rList[0].current_user__c = true;
                update rList[0];
            }
        }
        else{
            Recent_Partner_User__c r = new Recent_Partner_User__c();
            r.internal_user__c = Userinfo.getUserId();
            r.partner_user__c = uList[0].id;    
            r.current_user__c = true;
            insert r;
        }
        

        return null;


    }
}