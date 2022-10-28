/*****************************************************************************************
Name: PartnerAuthorization 
===============================================================================================
Purpose: To handle the logic for authorization of user in azure ad b2c and login to sfdc community
Author:
Jitendra Singh version 1.0 08-09-2021
******************************************************************************************/
global class PartnerAuthorization extends Auth.AuthProviderPluginClass {

    private String clientId = '';
    private String clientSecret = '';
    private String accessTokenUrl = '';
    private String authorizationUrl = '';
    private String scope = '';
    private String uilocale = '';
    private String forgorPasswordUrl = '';
    public string sfdcPartnerPortalUrl = '';
    @TestVisible private String redirectUri = '';
    private string userEmailid = '';
    public static final String CUSTOM_METADATA_TYPE = 'PartnerPortal__mdt';
    public static final String AUTH_PROVIDER_NAME = 'PartnerAuthorization';
    public static final string FORGOTPASSWORD_ERRORCODE = 'AADB2C90088';
    
   
    /*
     This method is responsible for returning the custom metadata storing the api credentials and other details
     */
    global String getCustomMetadataType() {
        return CUSTOM_METADATA_TYPE;
    }

    /*
    This method is responsible to initiate the authorization code flow
    */
    global PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
        system.debug('stateToPropagate=='+stateToPropagate);
        clientId = authProviderConfiguration.get('Client_Id__c');
        authorizationUrl = authProviderConfiguration.get('Authorization_URL__c');    
        scope = EncodingUtil.URLENCODE(authProviderConfiguration.get('Scope__c'), 'UTF-8');
        redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        uilocale = authProviderConfiguration.get('Locale__c');
        string url = authorizationUrl +'?client_id='+clientId+'&redirect_uri='+redirectUri+'&response_type=code'+'&scope='+scope+'&ui_locales='+uilocale+'&state='+stateToPropagate;
        system.debug('url==='+url );
        return new PageReference(url);
    }

    /*   
     This method is responsible to handle the callback from authorization code flow
     set the access token, refresh token and other parameters
    */   
    global Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {
       system.debug('state==='+ state);
       Auth.AuthProviderTokenResponse tokenResponse;
       clientId = authProviderConfiguration.get('Client_Id__c');
       clientSecret = authProviderConfiguration.get('Client_Secret__c');
       scope = EncodingUtil.URLENCODE(authProviderConfiguration.get('Scope__c'), 'UTF-8');
       redirectUri = authProviderConfiguration.get('Redirect_URI__c');
       accessTokenUrl = authProviderConfiguration.get('Access_Token_URL__c');
       
       Map<String,String> queryParams = state.queryParameters;
       String code = queryParams.get('code');
       String sfdcState = queryParams.get('state');
       
       try{
           HttpRequest req = new HttpRequest();
           req.setEndpoint(accessTokenURL);
           req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
           req.setMethod('POST');
           req.setBody('client_id='+clientId+'&client_secret='+clientSecret+'&code='+code+'&redirect_url='+redirectUri+'&grant_type=authorization_code'+'&state='+sfdcState);
           //req.setBody('client_id='+clientId+'&client_secret='+clientSecret+'&code='+code+'&redirect_uri='+redirectUri+'&state='+sfdcState);
    
           Http http = new Http();
           HTTPResponse res = http.send(req);
           system.debug('reqPOST==='+req);
           map<string,string> tokenMap = getTokenFromHttpResponse(res);
           
           string access_token = tokenMap.get('access_token');
           string refresh_token = tokenMap.get('refresh_token');
           userEmailid = findEmailFromAccessToken(access_token); //getting the email from access token
           
           tokenResponse = new Auth.AuthProviderTokenResponse(AUTH_PROVIDER_NAME, access_token, refresh_token, sfdcState );
       }catch(Exception e) {    
           System.debug('Exception caught:handleCallback ' + e.getMessage()); 
           PageReference newFPWDUrl = forgotPassword(authProviderConfiguration,sfdcState,e.getMessage() );  
            
       }  
       return tokenResponse;
    }

    /*
    This method is responsible to initiate the authorization code flow
    */
    public PageReference forgotPassword(Map<String, String> authProviderConfiguration, String stateToPropagate, String errormsg) {
        system.debug('****' + authProviderConfiguration + stateToPropagate);
        string url = '';
        if(errormsg.contains(FORGOTPASSWORD_ERRORCODE)){  
            sfdcPartnerPortalUrl = authProviderConfiguration.get('Partner_Portal_URL__c');  
            PageReference fpassUrl = new PageReference(sfdcPartnerPortalUrl);
            fpassUrl.setRedirect(true);
            return fpassUrl;
        }else{
            clientId = authProviderConfiguration.get('Client_Id__c');
            forgorPasswordUrl = authProviderConfiguration.get('Forgot_Password_URL__c');
            //String resetUrl = 'https://mscb2cparautprd.b2clogin.com/mscb2cparautprd.onmicrosoft.com/B2C_1A_DUPS_ResetPassword/oauth2/v2.0/authorize';
            scope = authProviderConfiguration.get('Scope__c');
            redirectUri = authProviderConfiguration.get('Redirect_URI__c');
            uilocale = authProviderConfiguration.get('Locale__c');
            url = forgorPasswordUrl +'?client_id='+clientId+'&redirect_uri='+forgorPasswordUrl+'&response_type=code'+'&scope='+scope+'&uilocale='+uilocale+'&state='+stateToPropagate;
            system.debug('url==='+url );
            PageReference fpassUrl = new PageReference(url);
            fpassUrl.setRedirect(true);
            return fpassUrl;
        }

    }
        
    /*
    *To find the email id from the payload in JWT Accesstoken
    */
    private string findEmailFromAccessToken(string access_Token){
        
        string emailId = '';
        
        try{
            if(String.isNotBlank(access_Token)){
                string pay_load = access_Token.substringBetween('.','.'); //take the payload part
                blob payload_blob = EncodingUtil.base64Decode(pay_load);
                string payload_string = payload_blob.ToString();
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload_string);
                system.debug('email=='+data.get('email'));
                emailId = (string)data.get('email');
            }
        }catch(Exception e) {
           system.debug('*****');
           System.debug('Exception caught:findEmailFromAccessToken ' + e.getMessage());    
        }
        return emailId;      
    }
    
    /*
    *Returns a new access token, which is used to update an expired access token.
    * Refresh is required by the parent class and it's used if the original Access Token has expired.
    */
    public override Auth.OAuthRefreshResult refresh(Map<String, String> authProviderConfiguration, String refreshToken) {
        
        Auth.OAuthRefreshResult refreshResult;
        clientId = authProviderConfiguration.get('Client_Id__c');
        clientSecret = authProviderConfiguration.get('Client_Secret__c');
        accessTokenUrl = authProviderConfiguration.get('Access_Token_URL__c');       
        String body = 'client_id='+clientId+'&client_secret='+clientSecret+'grant_type=refresh_token'+'refresh_token='+refreshToken;
        
        try{
            // setup request
            HttpRequest req = new HttpRequest();
            req.setEndpoint(accessTokenUrl);
            req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            req.setMethod('POST');
            req.setBody(body);
    
            // execute requets
            Http http = new Http();
            HttpResponse res = http.send(req);
            map<string,string> tokenMap = getTokenFromHttpResponse(res);
            string access_token = tokenMap.get('access_token');
            string refresh_token = tokenMap.get('refresh_token');
            
            refreshResult = new Auth.OAuthRefreshResult(access_token, refresh_token);
        }catch(Exception e) {
           system.debug('*****');
           System.debug('Exception caught:refresh ' + e.getMessage());    
        }
        return refreshResult;
    }
      
    /*
    *This method is responsible to get the user information used for authentication from the external api
    */
    global Auth.UserData getUserInfo(Map<String, String> authProviderConfiguration, Auth.AuthProviderTokenResponse response) {
    
      return new Auth.UserData(
            userEmailid,
            null,
            null,
            null,
            userEmailid,
            null,
            userEmailid,
            null,
            AUTH_PROVIDER_NAME,
            null,
            new Map<String, String>()
        );
    }
    
    /**
     * Get the access_token and refresh token from Http response.
    */
    private map<string,string> getTokenFromHttpResponse(HttpResponse res) {
        
        map<string,string> tokenMap = new map<string,string>();
        system.debug('resBody=='+res.getBody());
        
        final Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        final String errorCode = (String) data.get('error');
        if(String.isNotEmpty(errorCode)) {
            String errorDesc = (String) data.get('error_description');
            throw new Azure_AuthProvider_Exception(errorDesc)
                .setDetails(errorCode, (String) data.get('trace_id'), (String) data.get('correlation_id'));
        } else {
            tokenMap.put('access_token',(String) data.get('access_token'));
            tokenMap.put('refresh_token',(String) data.get('refresh_token'));
        }
       
        return tokenMap;
    }
    
    public class Azure_AuthProvider_Exception extends Exception {
        public String errorCode;
        public String traceId;
        public String correlationId;

        public Azure_AuthProvider_Exception setDetails(String error_code, String trace_id, String correlation_id) {
            this.traceId = trace_id;
            this.correlationId = correlation_id;
            this.errorCode = error_code;
            return this;
        }
    }

}