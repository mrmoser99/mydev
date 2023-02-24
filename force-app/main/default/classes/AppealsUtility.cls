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
        Boolean error=false;
        String ErrorMsg = null;
        HttpResponse response;
        String endpoint;
        try{
            PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();
            //endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/TestErrorHandler/globalcrmdata/Finance/financeapplication/1.NA.MOSAIC.' + applicationNumber;
            endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/Finance/financeapplication/1.NA.MOSAIC.' + applicationNumber;
            Http http = new Http();
            HttpRequest reqAPI = new HttpRequest();
            if (!Test.isRunningTest()){
                reqAPI = PricingUtils.buildHttpRequest(endpoint);
            }
            reqAPI.setTimeout(120000);
            response = http.send(reqAPI); 
            if (response.getStatusCode() != 200) {
                ErrorMsg = 'AppealsUtility getApplication: ' + response.getStatus()  + '  ' + response.getStatusCode() + response.getBody();
                error=true;
                throw new AuraHandledException(ErrorMsg);
              }      
        }catch (Exception e) {
            if (ErrorMsg == null) ErrorMsg = 'Exception in SearchContractDocs:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
            system.debug('ERROR AppealsUtility getApplication'+ErrorMsg);
            error=true;
            Error_Log__c el = new Error_Log__c();

            el.callout_name__c = 'AppealsUtility getApplication';
            el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
            el.Class_name__c = 'AppealsUtility';
            el.Request_body__c = endPoint;
            el.Method_Name__c = 'getApplication';
            if (response != null){
                el.Response_body__c = response.getBody();
                el.status_code__c = response.getStatusCode();
            }   
            el.stack_trace__c = e.getStackTraceString();
            el.exception_message__c = ErrorMsg;
            el.quote_id__c = null;
            PricingUtils.saveErrorLog(JSON.serialize(el));
        }

        if (error){
            return null;
        }
        else{
            System.debug('AppealsUtility getApplication response: '+response.getBody());
            return response.getBody();
        }  
    }   

    @AuraEnabled (Cacheable=true)
    public static string getAssets(String applicationNumber){
        Boolean error=false;
        String ErrorMsg = null;
        HttpResponse response;
        String endpoint;
        try{
            PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();
            endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/Finance/financeapplication/1.NA.MOSAIC.' + applicationNumber + '/proposals/1.NA.MOSAIC.' + applicationNumber + '.1/assets?feature=Credit-Application-Inquiry';
            Http http = new Http();
            HttpRequest reqAPI = new HttpRequest();
            if (!Test.isRunningTest()){
                reqAPI = PricingUtils.buildHttpRequest(endpoint);
            }
            reqAPI.setTimeout(120000);
            response = http.send(reqAPI); 
            if (response.getStatusCode() != 200) {
                ErrorMsg = 'AppealsUtility getAssets: ' + response.getStatus()  + '  ' + response.getStatusCode() + response.getBody();
                error=true;
                throw new AuraHandledException(ErrorMsg);
            }      
        }catch (Exception e) {
            if (ErrorMsg == null) ErrorMsg = 'Exception in SearchContractDocs:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
            system.debug('ERROR AppealsUtility getAssets'+ErrorMsg);
            error=true;
            Error_Log__c el = new Error_Log__c();

            el.callout_name__c = 'AppealsUtility getAssets';
            el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
            el.Class_name__c = 'AppealsUtility';
            el.Request_body__c = endPoint;
            el.Method_Name__c = 'getAssets';
            if (response != null){
                el.Response_body__c = response.getBody();
                el.status_code__c = response.getStatusCode();
            }   
            el.stack_trace__c = e.getStackTraceString();
            el.exception_message__c = ErrorMsg;
            el.quote_id__c = null;
            PricingUtils.saveErrorLog(JSON.serialize(el));
        }

        if (error){
            return null;
        }
        else{
            System.debug('AppealsUtility getAssets response: '+response.getBody());
            return response.getBody();
        }  


        /*
        PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();
        String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/Finance/financeapplication/1.NA.MOSAIC.' + applicationNumber + '/proposals/1.NA.MOSAIC.' + applicationNumber + '.1/assets?feature=Credit-Application-Inquiry';
        //String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/Finance/financeapplication/1.NA.MOSAIC.' + applicationNumber + '/proposals';
        Http http = new Http();
        HttpRequest reqAPI = new HttpRequest();
        if (!Test.isRunningTest()){
            reqAPI = PricingUtils.buildHttpRequest(endpoint);
        }
        reqAPI.setTimeout(120000);
        HttpResponse response = http.send(reqAPI); 
        System.debug('getAssets response: '+response.getBody());
        return response.getBody();*/
    }
 
}