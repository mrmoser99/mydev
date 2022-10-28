/********
* This class is built to call the Address Doctor API using REST Integration.
* The API callout information is stored in REST Setting Metadata
* Used in Customer creation process in DLL on Demand
* Author:Geetha Bharadwaj
*/

public class GetAddressValidation extends GetAddressValidationExtention{
    @AuraEnabled
    public static GetAddressValidationWrapper getAddValidation(Account act, string billingAddressLine2){
        if(act == null){
            return null;
        }
        string street = act.BillingStreet;
        string city=act.BillingCity;
        string state=act.BillingState.trim();
        string postalcode=act.BillingPostalCode;
        string country =act.BillingCountry;
        string county = act.BillingCounty__c;
        String tokenValue;
        
        List<RESTRequestSetting__mdt> restSettings = [SELECT Body__c,DeveloperName,Endpoint__c,HeaderParameters__c,Id,Label,Language,MasterLabel,Method__c,
                                                      NamespacePrefix,QualifiedApiName,RequestBodyWrapperClassName__c,ResponseBodyWrapperClassName__c,
                                                      Timeout__c,URLParameters__c,Subscription_Key__c FROM RESTRequestSetting__mdt where DeveloperName in ('Address_Validation_Token', 'Address_Validation_Callout')];
        HttpRequest req = new HttpRequest();
        for(RESTRequestSetting__mdt mtd: restSettings){
            
            List<String> headerlist = New List<String>();
            headerlist = mtd.HeaderParameters__c.split(',');
            
            if(mtd.DeveloperName =='Address_Validation_Token'){
                req.setMethod(mtd.Method__c);
                req.setEndpoint(mtd.Endpoint__c);
                req.setHeader(headerlist[0].split(':')[0].trim(), headerlist[0].split(':')[1].trim());
                req.setHeader(headerlist[1].split(':')[0].trim(), headerlist[1].split(':')[1].trim());
                req.setBody(mtd.Body__c);
                req.setTimeout(Integer.valueOf(mtd.Timeout__c));
            }
        }
        Map<String, Object> token = new Map<String, object>();
        Http http = new Http();
        try{
            HTTPResponse res = http.send(req);
            token = (Map<String, Object>)JSON.deserializeUntyped(res.getbody());
            tokenValue = (String)token.get('access_token');
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, act.id, true); 
            throw new ErrorLogger.ErrorLoggerException(e.getDmlMessage(0));
        }
        HttpRequest reqforResponse = new HttpRequest();
        
        for(RESTRequestSetting__mdt mtd: restsettings){
            if(mtd.DeveloperName == 'Address_Validation_Callout'){
                List<String> headerlist = new List<String>();
                headerlist = mtd.HeaderParameters__c.split(',');
                
                reqforResponse.setMethod(mtd.Method__c);
                reqforResponse.setEndpoint(mtd.Endpoint__c);
                reqforResponse.setHeader(headerlist[0].split(':')[0].trim(), headerlist[0].split(':')[1].trim());
                reqforResponse.setHeader(headerlist[1].split(':')[0].trim(), headerlist[1].split(':')[1].trim());
                reqforResponse.setHeader('Ocp-Apim-Subscription-Key', mtd.Subscription_Key__c);
                reqforResponse.setHeader('Authorization', tokenValue);
                reqforResponse.setTimeout(Integer.valueOf(mtd.Timeout__c));
                
                Map<string, Object> addressmap = new Map<String, Object>{'country'=> country,
                    'addressLine1' => street,
                    'addressLine2' => billingAddressLine2 != null?billingAddressLine2:'' ,
                        'addressLine3' =>'',
                        'city' => city,
                        'stateProvince'=> state,
                        'postalCode' => postalcode};
                            string addressjson=   JSON.serialize(addressmap);
                string requestBody = '{"requestControl": {"transactionID": "123456789","userLanguage": "ENG","userCountry": "US","userId": "Sample","userCurrency": "EUR","sourceSystemTimestamp": 1},"validateAddressInformation": {"address":'+ addressjson+'}}';
                reqforResponse.setBody(requestBody);
            }
        }
        Http http2 = new Http();
        try{
            HTTPResponse azureResponse = http2.send(reqforResponse);
            Integer statusCode = azureResponse.getStatusCode();
            GetAddressValidationWrapper wrap = new GetAddressValidationWrapper();
            if(string.valueOf(azureResponse.getStatusCode()).startswith('2')){
                Map<String,Object> level1Details = (Map<String, Object>)JSON.deserializeUntyped(azureResponse.getbody());
                Map<String,Object> validateAddressInformation = (Map<string, Object>)level1Details.get('validateAddressInformation');
                Map<String,Object> serviceConfirmation = (Map<string, Object>)level1Details.get('serviceConfirmation');
                Map<String,Object> address = (Map<string, Object>)validateAddressInformation.get('address');
                
                if(statusCode == 200 || statusCode == 202){
                    wrap.country = (String)address.get('country');
                    
                    wrap.city = (String)address.get('city');
                    wrap.addressLine1 = (String)address.get('addressLine1');
                    wrap.state = (String)address.get('stateProvince');
                    wrap.postalcode = (String)address.get('postalCode');
                    wrap.county = (String)address.get('countyName');
                    
                    wrap.returnCode = (String)serviceConfirmation.get('returnCode');
                    system.debug('Success');
                    wrap.isSuccess = true;
                }
            }
            if(string.valueOf(statusCode).startswith('4')){
                
                wrap.responseMessage = 'Failure';
            }else if(string.valueOf(statusCode).startswith('5')){
                
                wrap.responseMessage = 'ServerDown';
            }
            
            return wrap;
            
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, act.id, true); 
            throw new ErrorLogger.ErrorLoggerException(e.getDmlMessage(0));
        }
    }
    
    @AuraEnabled
    public static account insertAccount(Account customer){
        if(customer != null){
            customer.recordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
            customer.BillingCounty__c = customer.BillingCounty__c !=null ? customer.BillingCounty__c :'';
            customer.Phone = (customer.Phone!=null && customer.Phone!='')?'(+1)'+customer.Phone:'';
            try{
                customer.type = 'End User';
                system.debug('customer:'  + customer);
                insert customer;
            }catch(Exception e){
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, customer.id, true); 
                throw new ErrorLogger.ErrorLoggerException(e.getMessage());
            }
        }
        return customer;
    }
    
    
    @AuraEnabled
    public static List<String> getAllstates(){
        List<String > allstates = system.label.stateList.split(','); 
        return allstates;
    }
}