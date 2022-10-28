/**
 * Created by samuelmeyers on 3/20/19.
 */

public class RoleUtility {
    public static Set<Id> getAllSubRoleIds(Set<Id> roleIds) {
        Set<Id> currentRoleIds = new Set<Id>();

        for(UserRole userRole :[SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds AND ParentRoleId != null]) {
            currentRoleIds.add(userRole.Id);
        }

        if(currentRoleIds.size() > 0) {
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
        return currentRoleIds;
    }
}