/**
Info- This class is created to send the comments from Case to Infolease source system through Azure
All inputs are received from FLOW
PBI - 477398
Author - Geetha Bharadwaj 
Date - 02/17/2021
**/

global class PushCommentsInfolease {
    
    public static Integer systemTime = (Integer) (System.now().getTime() / 1000);
    
    global class pushcommentsWrapper{
        @invocableVariable
        global string commentbody;
        
        @invocableVariable
        global string  contractId;
        
        @invocableVariable
        global string departmentName;
        
        @invocableVariable
        global string emailId;
        
    }
    
    //Receiving inputs from FLOW
    @invocableMethod
    public static void sendComments(List<pushcommentswrapper> pushwraplist){
        
        string commentbody = '';
        string contractId = '';
        string departmentName = '';
        string emailId = '';
        for(pushcommentswrapper wrap : pushwraplist ){
            commentbody= wrap.commentbody;
            contractId = wrap.contractId;
            departmentName = wrap.departmentName;
            emailId = wrap.emailId;
        }
        
        //callout using @future
        doCallout(commentbody, contractId, departmentName, emailId);
        
    }
    @future(callout=true)
    public static void doCallout (string commentBody, string contractId, string departmentName, string emailId){
        Map<String, Object> token = new Map<String, object>();
        Integer expirationDateTime = Integer.valueOf(CacheUtility.getCachedObject('expirationdate'));  
        string subscriptionKey = System.label.Subscription_Key_for_Infolease;
        
        List<RESTRequestSetting__mdt> restsettings = [SELECT Body__c,DeveloperName,Endpoint__c,HeaderParameters__c,Id,Label,Language,MasterLabel,Method__c,
                                                      NamespacePrefix,QualifiedApiName,RequestBodyWrapperClassName__c,ResponseBodyWrapperClassName__c,
                                                      Timeout__c,URLParameters__c FROM RESTRequestSetting__mdt where DeveloperName in ('OAuth_Token_Infolease', 'Push_Comments_Infolease')];
        
        if(systemTime > expirationDateTime || expirationDateTime ==null) {
            HttpRequest req = new HttpRequest();
            for(RESTRequestSetting__mdt mtd: restsettings){
                List<String> headerlist = New List<String>();
                headerlist = mtd.HeaderParameters__c.split(',');
                
                if(mtd.DeveloperName =='OAuth_Token_Infolease'){
                    req.setMethod(mtd.Method__c);
                    req.setEndpoint(mtd.Endpoint__c);
                    req.setHeader(headerlist[0].split(':')[0], headerlist[0].split(':')[1]);
                    req.setHeader(headerlist[1].split(':')[0], headerlist[1].split(':')[1]);
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
        
        //requestbodystatic =  '{"Identifier": "CREATEMESSAGE","RequestBody": {"ContractRequestBody": dynamicMatch,"OtherRequestBody": {"otherField": [departmentdynamic]}}}';
        jsondata = new Map<string, object>{'contractID' => contractId, 'contractNote' =>commentbody};
            jsondata2 = new Map<string, object>{'departmentName'=>departmentName};
                
                obj = JSON.serialize(jsondata);
        obj2 = JSON.serialize(jsondata2);
        system.debug('contractNote ==>' +commentbody);
        system.debug('departmentCode=>' +departmentName);
        system.debug('contractId=>' +contractId);
        system.debug('emailId=>' +emailId);

        HttpRequest reqforResponse = new HttpRequest();
        
        for(RESTRequestSetting__mdt mtd: restsettings){
            if(mtd.DeveloperName == 'Push_Comments_Infolease'){
                List<String> headerlist = new List<String>();
                headerlist = mtd.HeaderParameters__c.split(',');
                requestbodystatic =  mtd.Body__c;
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
                reqforResponse.setHeader('X-ServiceUser', emailId);
                reqforResponse.setTimeout(Integer.valueOf(mtd.Timeout__c));
                reqforResponse.setBody(requestbody);
            }
        }   
        Http http2 = new Http();
        HTTPResponse azureResponse = http2.send(reqforResponse);
        if(azureResponse.getStatusCode() == 200 || azureResponse.getStatusCode() == 201){ 
            system.debug('Message sent Successfully');
        }
        else{
            system.debug('Message not sent');
        }
    }
    
}