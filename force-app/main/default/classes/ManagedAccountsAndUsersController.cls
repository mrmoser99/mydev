/*****************************************************************************************
Name: ManagedAccountsAndUsersController
===============================================================================================
Purpose: It is used in Nordics_Internal_Deal_Flow to get managed Accounts and partners for 
these accounts (US-672464).
================================================================================================
================================================================================================
History
-------
VERSION        AUTHOR                  DATE              DETAIL
1.0            Elena Sokolova          04-01-2022        to get managed Accounts and partners for these accounts in flow
******************************************************************************************/
public with sharing class ManagedAccountsAndUsersController {

    /**
     * Name: getSObjectList
     * Purpose: method checks object id and search data accordingly
     */
    @InvocableMethod(label='Get Managed Accounts And Subordinates')
    public static List<String> getSObjectList(List<Id> ids) {
        return (String.valueOf(ids[0].getSobjectType()) == 'Account') 
            ? getSubordinatesByAccountId(ids)
            : getAccountManagersByUserId(ids);
    }

    /**
     * Name: getSubordinatesByAccountId
     * Purpose: method returns JSON string with partner users details for
     * particular account by account id
     */
    private static List<String> getSubordinatesByAccountId(List<Id> accountIds) {
        List<User> subordinates = new WoSSelector().getSubordinates(accountIds);
        return (subordinates.isEmpty()) ? null : new List<String>{JSON.serialize(subordinates)};
    }

    /**
     * Name: getAccountManagersByUserId
     * Purpose: method returns JSON string with account details for
     * particular user (internal user) by current user id
     */
    private static List<String> getAccountManagersByUserId(List<Id> userIds) {
        List<AccountTeamMember> accountManagers = new WoSSelector().getAccountManagers(userIds);
        return (accountManagers.isEmpty()) ? null : new List<String>{JSON.serialize(accountManagers)};
    }

    private without sharing class WoSSelector {

        private List<AccountTeamMember> getAccountManagers(List<Id> userIds) {
            return [
                SELECT      AccountId, Account.Name 
                FROM        AccountTeamMember 
                WHERE       UserId IN :userIds AND TeamMemberRole = 'Account Manager'
                ORDER BY    Account.Name ASC
            ];
        }

        private List<User> getSubordinates(List<Id> accountIds) {
            return [
                SELECT      Id, Full_Name__c
                FROM        User
                WHERE       Contact.AccountId IN :accountIds AND (UserRole.Name LIKE '%Partner User' OR UserRole.Name LIKE '%Partner Manager') 
                ORDER BY    Full_Name__c ASC
            ];
        }

    }
}