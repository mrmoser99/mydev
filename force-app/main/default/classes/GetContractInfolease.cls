/**
Info- This class is created to get the contract information from Infolease with OAuth Authentication.
PBI:475643,357157
Author - Geetha Bharadwaj
Date - 02/10/2021
**/

public class GetContractInfolease {
    
    private static String accessToken;
    private static final datetime expirationdate;
    public static Integer systemTime = (Integer) (System.now().getTime() / 1000);
    private static final String TOKEN_CACHE_KEY = 'authToken';
    
    @AuraEnabled(cacheable=true)
    
    public static List<getContractInfoleaseWrapper> getContract(string caseId){
        
        Map<String, Object> token = new Map<String, object>();
        Integer expirationDateTime = Integer.valueOf(CacheUtility.getCachedObject('expirationdate'));
        string subscriptionKey = System.label.Subscription_Key_for_Infolease;
        
        List<RESTRequestSetting__mdt> restsettings = [SELECT Body__c,DeveloperName,Endpoint__c,HeaderParameters__c,Id,Label,Language,MasterLabel,Method__c,
                                                      NamespacePrefix,QualifiedApiName,RequestBodyWrapperClassName__c,ResponseBodyWrapperClassName__c,
                                                      Timeout__c,URLParameters__c FROM RESTRequestSetting__mdt where DeveloperName in ('OAuth_Token_Infolease', 'Get_Contract_Infolease')];
        
        String contractNumber = [select id, Contract_Relationship__r.name from CASE where id =:caseId limit 1].Contract_Relationship__r.name;
        Case cs = [select id, Contract_Relationship__r.name, Department__c, Comments from CASE where id =:caseId limit 1]; 
        
        if(systemTime > expirationDateTime || expirationDateTime ==null) {
            HttpRequest req = new HttpRequest();
            for(RESTRequestSetting__mdt mtd: restsettings){
                List<String> headerlist = New List<String>();
                headerlist = mtd.HeaderParameters__c.split(',');
                
                if(mtd.DeveloperName =='OAuth_Token_Infolease'){
                    req.setMethod(mtd.Method__c);
                    req.setEndpoint(mtd.Endpoint__c);
                    req.setHeader(headerlist[0].split(':')[0].trim(), headerlist[0].split(':')[1].trim());
                    req.setHeader(headerlist[1].split(':')[0].trim(), headerlist[1].split(':')[1].trim());
                    req.setBody(mtd.Body__c);
                    req.setTimeout(integer.valueOf(mtd.Timeout__c));
                }
            }
            Http http = new Http();
            HTTPResponse res = http.send(req);
            token = (Map<String, Object>)JSON.deserializeUntyped(res.getbody());
            
            String tokenValue = (String)token.get('access_token');
            Integer tokenExpiration;
            if(token.get('expires_on') != null){
                tokenExpiration = Integer.valueOf((String)token.get('expires_on'));
            }
            CacheUtility.setCachedObject('TOKEN', tokenValue);
            CacheUtility.setCachedObject('expirationdate',tokenExpiration);
            
        }
        
        Object objt =    CacheUtility.getCachedObject('TOKEN');
        String accessToken = 'Bearer '+objt;
        Integer systemTime = (Integer) (System.now().getTime() / 1000);
        
        String  requestbodystatic = '';
        string obj='';
        string obj2 = '';
        string requestbody = '';
        Map<string, object> jsondata = new Map<string, object>();
        Map<string, object> jsondata2 = new Map<string, object>();
        
        HttpRequest reqforResponse = new HttpRequest();
        
        for(RESTRequestSetting__mdt mtd: restsettings){
            if(mtd.DeveloperName == 'Get_Contract_Infolease'){
                List<String> headerlist = new List<String>();
                headerlist = mtd.HeaderParameters__c.split(',');
                requestbodystatic =  mtd.Body__c;
                jsondata = new Map<string, object>{'contractID' => cs.Contract_Relationship__r.name};
                    obj = JSON.serialize(jsondata);   
                requestbody = requestbodystatic.replace('dynamicMatch', obj);
                
                if(requestbody.contains('departmentdynamic')){
                    requestbody = requestbody.replace('departmentdynamic', obj2);
                }
                reqforResponse.setMethod(mtd.Method__c);
                reqforResponse.setEndpoint(mtd.Endpoint__c);
                reqforResponse.setHeader(headerlist[0].split(':')[0].trim(), headerlist[0].split(':')[1].trim());
                reqforResponse.setHeader(headerlist[1].split(':')[0].trim(), headerlist[1].split(':')[1].trim());
                reqforResponse.setHeader('Authorization', accessToken);
                reqforResponse.setHeader('Ocp-Apim-Subscription-Key', subscriptionKey);
                reqforResponse.setHeader('X-ServiceUser', UserInfo.getUserEmail());
                reqforResponse.setTimeout(Integer.valueOf(mtd.Timeout__c));
                reqforResponse.setBody(requestbody);
            }
        }
        List<GetContractInfoleaseWrapper> wraplist = new List<GetContractInfoleaseWrapper>();
        GetContractInfoleaseWrapper wrap = new GetContractInfoleaseWrapper();
        
        Http http2 = new Http();
        HTTPResponse azureResponse = http2.send(reqforResponse);
        wrap.statusCode = azureResponse.getStatusCode();
        
        if(azureResponse.getStatusCode() == 200){
            wrap.statusMessage = 'Success';
            
            Map<String,Object> level1Details = (Map<String, Object>)JSON.deserializeUntyped(azureResponse.getbody());
            Map<String,Object> providerResponseDetails = (Map<string, Object>)level1Details.get('ProviderResponse');
            Map<String,Object> contractDetails = (Map<string, Object>)providerResponseDetails.get('Contract');
            Map<String,Object> accountValue = (Map<string, Object>)providerResponseDetails.get('Account');
            
            String customerName = (String)contractDetails.get('customerName');
            String contactName = '';
            String phoneNumber = '';
            String creditAccountNumber = (String)accountValue.get('sourceSystemId');
            List<Object> contactlist = (List<Object>)accountValue.get('Contact');
            
            Map<Integer, Map<String, Object>> contactMainMap = new Map<Integer, Map<String, Object>>();
            
            for(Integer i=0; i<contactlist.size(); i++){
                contactMainMap.put(i, (Map<String, object>)contactlist[i]);
            }
            for(Integer j: contactMainMap.keySet()){
                Map<string, Object> contactDetailmap = new Map<String, Object>();
                contactDetailmap = contactMainMap.get(j);
                
                contactName = string.valueof(contactDetailmap.get('contactName'));
                phoneNumber = string.valueof(contactDetailmap.get('contactdata'));
                break;
            }
            
            String applicationNumber = (String)contractDetails.get('opportunityId');
            String delinquencyStatus = (String)contractDetails.get('delinquencyStatus');
            String leadDays = (string)contractDetails.get('leadDays');
            Decimal paymentAmount = Decimal.valueOf((string)contractDetails.get('paymentAmount'));
            Integer renewalterminMonths = Integer.valueOf((string)contractDetails.get('renewalterminMonths'));
            Integer termInMonths = Integer.valueOf((string)contractDetails.get('termInMonths'));
            String terminationDate = (string)contractDetails.get('terminationDate');
            Integer timesDelinquent = Integer.valueOf((string)contractDetails.get('timesDelinquent'));
            Decimal totalDueAmount = Decimal.valueOf((string)contractDetails.get('totalDueAmount'));
            Decimal totalPastDueAmount = Decimal.valueOf((string)contractDetails.get('totalPastDueAmount'));
            
            Map<String, Object> months = (Map<string, Object>)contractDetails.get('billingCycle');
            
            Boolean jan = (Boolean)months.get('january');
            Boolean feb = (Boolean)months.get('february');
            Boolean mar = (Boolean)months.get('march');
            Boolean apr = (Boolean)months.get('april');
            Boolean may = (Boolean)months.get('may');
            Boolean jun = (Boolean)months.get('june');
            Boolean jul = (Boolean)months.get('july');
            Boolean aug = (Boolean)months.get('august');
            Boolean sep = (Boolean)months.get('september');
            Boolean oct = (Boolean)months.get('october');
            Boolean nov = (Boolean)months.get('november');
            Boolean dec = (Boolean)months.get('december');
            
            
            wrap.customerName = customerName;
            wrap.sourceSystemId = creditAccountNumber;
            wrap.applicationNumber = applicationNumber;
            wrap.delinquencyStatus = delinquencyStatus;
            wrap.leadDays = leadDays;
            wrap.paymentAmount = paymentAmount;
            wrap.renewalterminMonths = renewalterminMonths;
            wrap.termInMonths = termInMonths;
            wrap.terminationDate = terminationDate;
            wrap.timesDelinquent = timesDelinquent;
            wrap.totalDueAmount = totalDueAmount;
            wrap.totalPastDueAmount = totalPastDueAmount;
            wrap.contactName = contactName;
            wrap.phoneNumber = phoneNumber;
            wrap.jan = jan;
            wrap.feb = feb;
            wrap.mar = mar;
            wrap.apr = apr;
            wrap.may = may;
            wrap.jun = jun;
            wrap.jul = jul;
            wrap.aug = aug;
            wrap.sep = sep;
            wrap.oct = oct;
            wrap.nov = nov;
            wrap.dec = dec;
            
        }else if(string.valueOf(azureResponse.getStatusCode()).startswith('4')){
            wrap.statusMessage = 'Failure';
        }else if(string.valueOf(azureResponse.getStatusCode()).startswith('5')){
            wrap.statusMessage = 'ServerDown';
        }
        
        wraplist.add(wrap);
        return wraplist;
        
        
    }
}