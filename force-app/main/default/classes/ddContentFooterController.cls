/**
 * @description       : Apex class controller LWC (ddContentFooter) for get contact support in footer.
 * @author            : Vinicio Ramos
 * @group             : DLL On demand
 * @last modified on  : 12/15/2022
 * @Changes Log        :
 * Date       - BUG/PBI    - Author           - Description
 * 12/15/2022 - PBI 779222 - Vinicio Ramos    - As a portal user I need to know how I can contact DLL for support.

**/
public with sharing class ddContentFooterController {
    
    @AuraEnabled( cacheable=true )  
    public static List<Contact_Support__mdt> getContactList(String userId) {
        
        User us = [SELECT Id,Contact.Business_Unit__c FROM User WHERE Id =: userId];
        Contact_Support__mdt contactMdt = [SELECT Email__c,Id,Label,Language,MasterLabel,NamespacePrefix,Phone__c FROM Contact_Support__mdt Where Business_Unit__c =: us.Contact.Business_Unit__c];
        return [ SELECT Email__c,Id,Label,Language,MasterLabel,NamespacePrefix,Phone__c,Business_Unit__c FROM Contact_Support__mdt Where Business_Unit__c =: us.Contact.Business_Unit__c];
    }
}