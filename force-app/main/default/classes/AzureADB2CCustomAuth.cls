/*****************************************************************************************
Name: AzureADB2CCustomAuth 
===============================================================================================
Purpose: To handle the logic for authorization of user in azure ad b2c and login to sfdc community
******************************************************************************************/
global class AzureADB2CCustomAuth extends Auth.AuthProviderPluginClass {

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
    
    /*
     This method is responsible for returning the custom metadata storing the api credentials and other details
     */
    global String getCustomMetadataType() {
        return Constants.CUSTOM_METADATA_TYPE;
    }

    /*
    This method is responsible to initiate the authorization code flow
    */
    global PageReference initiate(Map<String, String> authProviderConfiguration, String stateToPropagate) {
        clientId = authProviderConfiguration.get('Client_Id__c');
        authorizationUrl = authProviderConfiguration.get('Authorization_URL__c');    
        scope = authProviderConfiguration.get('Scope__c');
        redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        uilocale = authProviderConfiguration.get('Locale__c');
        string url = authorizationUrl +'?client_id='+clientId+'&redirect_uri='+redirectUri+'&response_type=code'+'&scope='+label.Scope+'&ui_locales='+uilocale+'&state='+stateToPropagate;
        return new PageReference(url);
    }

    /*   
     This method is responsible to handle the callback from authorization code flow
     set the access token, refresh token and other parameters
    */   
    global Auth.AuthProviderTokenResponse handleCallback(Map<String, String> authProviderConfiguration, Auth.AuthProviderCallbackState state) {
       
       Auth.AuthProviderTokenResponse tokenResponse;
       clientId = authProviderConfiguration.get('Client_Id__c');
       clientSecret = authProviderConfiguration.get('Client_Secret__c');
       scope = authProviderConfiguration.get('Scope__c');
       redirectUri = authProviderConfiguration.get('Redirect_URI__c');
       accessTokenUrl = authProviderConfiguration.get('Access_Token_URL__c');
       
       Map<String,String> queryParams = state.queryParameters;
       String code = queryParams.get('code');
       String sfdcState = queryParams.get('state');
       
       try{
           HttpRequest req = new HttpRequest();
           req.setEndpoint(accessTokenURL);
           req.setHeader('Content-Type',label.Content_type);
           req.setMethod('POST');
           req.setBody('client_id='+clientId+'&client_secret='+clientSecret+'&code='+code+'&redirect_url='+redirectUri+'&grant_type=authorization_code'+'&state='+sfdcState);
           
           Http http = new Http();
           HTTPResponse res = http.send(req);
           map<string,string> tokenMap = getTokenFromHttpResponse(res);
           
           string access_token = tokenMap.get('access_token');
           string refresh_token = tokenMap.get('refresh_token');
           userEmailid = findEmailFromAccessToken(access_token); //getting the email from access token
           
           tokenResponse = new Auth.AuthProviderTokenResponse(Constants.AUTH_PROVIDER_NAME, access_token, refresh_token, sfdcState );
        } catch(Exception e) {    
            PageReference newFPWDUrl = forgotPassword(authProviderConfiguration,sfdcState,e.getMessage() );    
        }  
       return tokenResponse;
    }

    /*
    This method is responsible to initiate the authorization code flow
    */
    public PageReference forgotPassword(Map<String, String> authProviderConfiguration, String stateToPropagate, String errormsg) {
        string url = '';
        if(errormsg.contains(Constants.FORGOTPASSWORD_ERRORCODE)){  
            sfdcPartnerPortalUrl = authProviderConfiguration.get('Partner_Portal_URL__c');  
            PageReference fpassUrl = new PageReference(sfdcPartnerPortalUrl);
            fpassUrl.setRedirect(true);
            return fpassUrl;
        }else{
            clientId = authProviderConfiguration.get('Client_Id__c');
            forgorPasswordUrl = authProviderConfiguration.get('Forgot_Password_URL__c');
            scope = authProviderConfiguration.get('Scope__c');
            redirectUri = authProviderConfiguration.get('Redirect_URI__c');
            uilocale = authProviderConfiguration.get('Locale__c');
            url = forgorPasswordUrl +'?client_id='+clientId+'&redirect_uri='+forgorPasswordUrl+'&response_type=code'+'&scope='+label.Scope+'&uilocale='+uilocale+'&state='+stateToPropagate;
            PageReference fpassUrl = new PageReference(url);
            fpassUrl.setRedirect(true);
            return fpassUrl;
        }

    }
        
    /*
    *To find the email id from the payload in JWT Accesstoken
    */
    @testVisible
    private string findEmailFromAccessToken(string access_Token){
        
        string emailId = '';
        
        try{
            if(String.isNotBlank(access_Token)){
                string pay_load = access_Token.substringBetween('.','.'); //take the payload part
                blob payload_blob = EncodingUtil.base64Decode(pay_load);
                string payload_string = payload_blob.ToString();
                Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(payload_string);
                emailId = (string)data.get('email');
            }
        } catch (Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, 'Integration', null, true);   
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
            req.setHeader('Content-Type', label.Content_type);
            req.setMethod('POST');
            req.setBody(body);
    
            // execute requets
            Http http = new Http();
            HttpResponse res = http.send(req);
            map<string,string> tokenMap = getTokenFromHttpResponse(res);
            string access_token = tokenMap.get('access_token');
            string refresh_token = tokenMap.get('refresh_token');
            
            refreshResult = new Auth.OAuthRefreshResult(access_token, refresh_token);
        } catch(Exception e) {
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, 'Integration', null, true); 
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
            Constants.AUTH_PROVIDER_NAME,
            null,
            new Map<String, String>()
        );
    }
    
    /**
     * Get the access_token and refresh token from Http response.
    */
    private map<string,string> getTokenFromHttpResponse(HttpResponse res) {
        
        map<string,string> tokenMap = new map<string,string>();
        
        final Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        final String errorCode = (String) data.get('error');
        if(String.isNotEmpty(errorCode)) {
            String errorDesc = (String) data.get('error_description');
            ErrorLogger.ErrorLoggerException errorLog = new ErrorLogger.ErrorLoggerException(
                'Error code:' + errorCode + '. Error description:' + errorDesc
                + '. Trace Id: ' + (String) data.get('trace_id') + '. Correlation Id: ' + (String) data.get('correlation_id')
            );
            throw errorLog;
        } else {
            tokenMap.put('access_token',(String) data.get('access_token'));
            tokenMap.put('refresh_token',(String) data.get('refresh_token'));
        }
       
        return tokenMap;
    }
}