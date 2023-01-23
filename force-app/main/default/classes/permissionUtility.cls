/*****************************************************************************************************************
 * Dll on Demaind (DD) Permission Utility
 *
 * Change Log:
 *
 *  01/06/2023 - MRM Created class
 * 	01/10/2023 - Dibyendu Adding the logic in the method
 *******************************************************************************************************************/
public with sharing class permissionUtility {


    /************************************************************************************************************************************************
    * checkPermission for the current logged in user
    *
    *****************************************************************************************************************************************************/

    @AuraEnabled 
    public static Boolean check(String permissionName){
        try{
        //PermissionSetAssignment psAssignment = new PermissionSetAssignment();
        String currentUserID = UserInfo.getUserId();
        
        CustomPermission customPermissions = [SELECT Id, DeveloperName FROM CustomPermission WHERE DeveloperName = :permissionName];
        
        List<SetupEntityAccess> setupEntities =  [SELECT SetupEntityId FROM SetupEntityAccess WHERE SetupEntityId =:customPermissions.id AND  ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId())];
        system.debug('DDT1'+setupEntities);
        if(setupEntities!=null){
            system.debug('DDT1'+setupEntities[0]);
              return true;
        }
        /*psAssignment = Database.query('select id,AssigneeId, PermissionSet.Name,IsActive, PermissionSetGroup.DeveloperName,PermissionSetGroupId from PermissionSetAssignment where AssigneeId=:currentUserID and PermissionSet.Name=:permissionName');
        if(psAssignment!=null){
            system.debug('DDT1'+UserInfo.getUserId());
            return true;
        }else{
            List<PermissionSetAssignment> psAssignment1 = new List<PermissionSetAssignment>();
            psAssignment1 = [select id,AssigneeId, PermissionSet.Name,IsActive, PermissionSetGroup.DeveloperName,
                                                PermissionSetGroupId from PermissionSetAssignment where AssigneeId=:UserInfo.getUserId() and PermissionSetGroupId <> null];
            if(psAssignment!=null){
                List<String> psGroup = new List<String>();
                for(PermissionSetAssignment pg : psAssignment1){
                    psGroup.add(pg.PermissionSetGroupId);
                }
                List<PermissionSetGroupComponent> psGComponent = new List<PermissionSetGroupComponent>();
                psGComponent = [select id,PermissionSetId,PermissionSet.name,PermissionSetGroup.id from PermissionSetGroupComponent where PermissionSetGroup.id in:psGroup and PermissionSet.name=:permissionName];
                if(psGComponent!=null){
                    system.debug('DDT2'+UserInfo.getUserId());
                    return true;
                }
            }
            
        }*/    
        system.debug('DDT3'+UserInfo.getUserId());
            return false;
        }
        catch(Exception e)
        {
            return false;
        }
	      
    }

}