/*****************************************************************************************************************
 * Dll on Demaind (DD) Appeals Utility CLASS
 *
 * Change Log:
 *
 * 12/13/2022 - Class created by Lucas
 *******************************************************************************************************************/
public with sharing class AppealsUtility{

    @AuraEnabled (Cacheable=true)
    public static string getApplication(String applicationNumber){
        PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();
        String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/Finance/financeapplication/1.NA.MOSAIC.' + applicationNumber;
        Http http = new Http();
        HttpRequest reqAPI = new HttpRequest();
        if (!Test.isRunningTest()){
            reqAPI = PricingUtils.buildHttpRequest(endpoint);
        }
        reqAPI.setTimeout(120000);
        HttpResponse response = http.send(reqAPI); 
        System.debug('getApplication response: '+response.getBody());
        return response.getBody();
    }   

    @AuraEnabled (Cacheable=true)
    public static string getAssets(String applicationNumber){
        PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();
        String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/Finance/financeapplication/1.NA.MOSAIC.' + applicationNumber + '/proposals/1.NA.MOSAIC.' + applicationNumber + '.1/assets?feature=Credit-Application-Inquiry';
        Http http = new Http();
        HttpRequest reqAPI = new HttpRequest();
        if (!Test.isRunningTest()){
            reqAPI = PricingUtils.buildHttpRequest(endpoint);
        }
        reqAPI.setTimeout(120000);
        HttpResponse response = http.send(reqAPI); 
        System.debug('getAssets response: '+response.getBody());
        return response.getBody();
    }
 
}