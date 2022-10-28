/**************************************************************************************************************
Name: PartnerAuthorizationTest 
===============================================================================================================
Purpose: Test class to handle the logic for authorization of user in azure ad b2c and login to sfdc community.
===============================================================================================================
 * Version 1.0 @author Ravisha Chugani @date 2021-06-01
 * Version 1.0 @author Neha Tyagi @date 2021-06-01
***************************************************************************************************************/

@IsTest
public class PartnerAuthorizationTest {
    
    private static final String clientId = '2d74e2b1-38d9-40d0-aa6e-2fdc6ca226b4';
    private static final String clientSecret = '44~NOyo.d6x8nj9d-EUiL2FJGS~Oxxp-qZ';
    private static final String accessTokenUrl = 'https://urldefense.proofpoint.com/v2/url?u=https-3A__mscb2cparautprd.b2clogin.com_mscb2cparautprd.onmicrosoft.com_B2C-5F1A-5FDUPS-5FSignIn_oauth2_v2.0_token&d=DwIGAg&c=YHcanBYpGrZxEbl-dEmkXYPwk0jOuY077yg_2uofQn0&r=_7vUT2W9lnHGYe9_jyGnztGRRTkq6IBj7MiQyu4f4HM&m=Eev0liBcFdAMK2x2SD6CauXXyHyOJaYmTnw0AsnhVNv7rrzt8WnHlkhaoekwb0F0&s=ux9TtXMXO4gVWdronKvP5d4nS9syr-nlvBAdgg0yBOg&e= ';
    private static final String authorizationUrl = 'https://urldefense.proofpoint.com/v2/url?u=https-3A__mscb2cparautprd.b2clogin.com_mscb2cparautprd.onmicrosoft.com_B2C-5F1A-5FDUPS-5FSignIn_oauth2_v2.0_authorize&d=DwIGAg&c=YHcanBYpGrZxEbl-dEmkXYPwk0jOuY077yg_2uofQn0&r=_7vUT2W9lnHGYe9_jyGnztGRRTkq6IBj7MiQyu4f4HM&m=Eev0liBcFdAMK2x2SD6CauXXyHyOJaYmTnw0AsnhVNv7rrzt8WnHlkhaoekwb0F0&s=uLk8eET-OcYRrQQsqAyHBbm01WJA3xPN2TM6aHjo5lw&e= ';
    private static final String scope = 'offline_access https://urldefense.proofpoint.com/v2/url?u=https-3A__mscb2cparautprd.onmicrosoft.com_digitalapis_view-5Fcontracts&d=DwIGAg&c=YHcanBYpGrZxEbl-dEmkXYPwk0jOuY077yg_2uofQn0&r=_7vUT2W9lnHGYe9_jyGnztGRRTkq6IBj7MiQyu4f4HM&m=Eev0liBcFdAMK2x2SD6CauXXyHyOJaYmTnw0AsnhVNv7rrzt8WnHlkhaoekwb0F0&s=Lp2u3xVHtPt_A1pzdAx0bKJ1Z6KyMvY1aDBNP4-THmU&e=  https://urldefense.proofpoint.com/v2/url?u=https-3A__mscb2cparautprd.onmicrosoft.com_digitalapis_view-5Ffinancial-5Fconfiguration&d=DwIGAg&c=YHcanBYpGrZxEbl-dEmkXYPwk0jOuY077yg_2uofQn0&r=_7vUT2W9lnHGYe9_jyGnztGRRTkq6IBj7MiQyu4f4HM&m=Eev0liBcFdAMK2x2SD6CauXXyHyOJaYmTnw0AsnhVNv7rrzt8WnHlkhaoekwb0F0&s=GGHlzrqKf7vDaIMz_BVcHutIBd3HGThLeYoRkb_8deA&e=  https://urldefense.proofpoint.com/v2/url?u=https-3A__mscb2cparautprd.onmicrosoft.com_digitalapis_view-5Fparties&d=DwIGAg&c=YHcanBYpGrZxEbl-dEmkXYPwk0jOuY077yg_2uofQn0&r=_7vUT2W9lnHGYe9_jyGnztGRRTkq6IBj7MiQyu4f4HM&m=Eev0liBcFdAMK2x2SD6CauXXyHyOJaYmTnw0AsnhVNv7rrzt8WnHlkhaoekwb0F0&s=1zqM4UH49zRgaubeggi1RAdrla0cOH9-tDeE3U6r57c&e=  https://urldefense.proofpoint.com/v2/url?u=https-3A__mscb2cparautprd.onmicrosoft.com_digitalapis_view-5Fyour-5Fprofile-5Finformation&d=DwIGAg&c=YHcanBYpGrZxEbl-dEmkXYPwk0jOuY077yg_2uofQn0&r=_7vUT2W9lnHGYe9_jyGnztGRRTkq6IBj7MiQyu4f4HM&m=Eev0liBcFdAMK2x2SD6CauXXyHyOJaYmTnw0AsnhVNv7rrzt8WnHlkhaoekwb0F0&s=sDGkFu1cc1y5qm44YPGoMA-ar_zfo2NElulM00NeUyA&e= ';
    private static final String uilocale = 'en-GB';
    private static final String redirectUri = 'https://urldefense.proofpoint.com/v2/url?u=https-3A__st02d01-2Dlife.cs195.force.com_partners_services_authcallback_Azure-5FAD-5FB2C&d=DwIGAg&c=YHcanBYpGrZxEbl-dEmkXYPwk0jOuY077yg_2uofQn0&r=_7vUT2W9lnHGYe9_jyGnztGRRTkq6IBj7MiQyu4f4HM&m=Eev0liBcFdAMK2x2SD6CauXXyHyOJaYmTnw0AsnhVNv7rrzt8WnHlkhaoekwb0F0&s=YiVEBzGi9rW469GUnyjrDQjK21U56cD72TDVkIggshU&e= ';
    private static final string userEmailid = 'Anujit.Das@cognizant.com';
    public static final String CUSTOM_METADATA_TYPE = 'Standard_Auth_Credentials__mdt';
    public static final String AUTH_PROVIDER_NAME = 'Azure_AD_B2C';
    private static final String stateToPropagate1  = 'testState';
    private static final String access_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IkJVOHlXamxhdFdiR2lldFFtU0wyUWE5NG03UVBibjRUcXhVOWgyVzNIMUEifQ.eyJpc3MiOiJodHRwczovL21zY2IyY3BhcmF1dHByZC5iMmNsb2dpbi5jb20vMDIwOGRlNjAtMWM3ZC00YjE1LTkzNjUtNGEzYTBlZDg0ZDFjL3YyLjAvIiwiZXhwIjoxNjIyMTk5MjExLCJuYmYiOjE2MjIxMTI4MTEsImF1ZCI6IjdkZmE5MDVkLWQ3NjktNGIzNC1hNDFlLWI5MTc4Zjg1M2Q1NSIsImVtYWlsIjoiQW51aml0LkRhc0Bjb2duaXphbnQuY29tIiwic3ViIjoiNDRmZjFhNWItNWY1NC00N2ZjLTljZjktMzAxNTIxODU0NjhkIiwibmFtZSI6IkFudWppdCBEYXMiLCJnaXZlbl9uYW1lIjoiQW51aml0IiwiZmFtaWx5X25hbWUiOiJEYXMiLCJsb2NhbGUiOiJlbi1HQiIsImxhc3RMb2dvbiI6MTYyMjEwNTY5NCwib3JnYW5pc2F0aW9uQ29udGV4dCI6IntcImlkZW50aWZpZXJzXCI6W119Iiwic2lnbkluTWV0aG9kIjoic2lnbi1pbiIsInRmcCI6IkIyQ18xQV9EVVBTX1NpZ25JbiIsInRpZCI6IjAyMDhkZTYwLTFjN2QtNGIxNS05MzY1LTRhM2EwZWQ4NGQxYyIsInNjcCI6InZpZXdfcGFydGllcyB2aWV3X2NvbnRyYWN0cyB2aWV3X3lvdXJfcHJvZmlsZV9pbmZvcm1hdGlvbiB2aWV3X2ZpbmFuY2lhbF9jb25maWd1cmF0aW9uIiwiYXpwIjoiMmQ3NGUyYjEtMzhkOS00MGQwLWFhNmUtMmZkYzZjYTIyNmI0IiwidmVyIjoiMS4wIiwiaWF0IjoxNjIyMTEyODExfQ.aO-AxDGad02kJ28JPmLzVX-O4IxHd5IoEroBVIyYMBUz0_BJJ6-7dI45UML0vvpSxeVXH8FCh2c9C9sIdCwH5gZmZl4RRzqpPUzouhVtFEbrRdG0yuhXPs-u0EmjaqO55wwNR4jy8l-dvhMd2X5YcGasgVQcY8DiEK56QxQy30nivrNKjDEDCZw5c_QEGcvfO3inNSijWETJwYKXkDtcVlOS5Dba9NdV4o2mGZMOonvSdtbiYmubfVCUlkW0fMtDRKRQEHBppA30mT4ZBk7ErSbKETx6Ux6V_YYaPcI6O2Fyno5FLQ_y95RSr84tMv3ZAr4K91rxe7HuDDq_6goY9A';
    private static final String STATE = 'mocktestState';
    private static final String refresh_token = 'refreshToken';
    private static final String partner_Portal_URL  = 'testPartnerPortalURL';
    private static final String VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.Vendor;
    private static final String END_USER_ACCOUNT_RECORDTYPE_DEVELOPER_NAME = System.Label.End_User;
    
   @testSetup static void setup(){
        
            TestAccountBuilder accountBuilder = new TestAccountBuilder();
            Account account = accountBuilder
                .withRecordType(VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
                .withName('Apple')
                .insertRecord(true)
                .build();
    
    }
    
    // in the real world scenario , the key and value would be read from the (custom fields in) custom metadata type record
    private static Map<String,String> setupAuthProviderConfig () {
        Map<String,String> authProviderConfiguration = new Map<String,String>();
        authProviderConfiguration.put('Authorization_URL__c', authorizationUrl);
        authProviderConfiguration.put('Access_Token_URL__c', accessTokenUrl);
        authProviderConfiguration.put('Client_Secret__c', clientSecret);
        authProviderConfiguration.put('Redirect_URI__c',redirectUri);
        authProviderConfiguration.put('Locale__c',uilocale);
        authProviderConfiguration.put('Client_Id__c',clientId);
        authProviderConfiguration.put('Scope__c',scope);
        authProviderConfiguration.put('Partner_Portal_URL__c',partner_Portal_URL);
        authProviderConfiguration.put('State_c',STATE);
        return authProviderConfiguration;
        
    }
    
     static testMethod void testGetCustomMetadataType() {
        
        PartnerAuthorization AzureCls = new PartnerAuthorization();
        string CUSTOM_METADATA_TYPE_test = AzureCls.getCustomMetadataType();
        
        //system.assertEquals(CUSTOM_METADATA_TYPE_test, CUSTOM_METADATA_TYPE);
        
    }
    
    static testMethod void testInitiateMethod() {
        String stateToPropogate = 'mocktestState';
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        PartnerAuthorization AzureCls = new PartnerAuthorization();
        AzureCls.redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        
        PageReference expectedUrl =  new PageReference(authProviderConfiguration.get('Authorization_URL__c') + '?client_id='+ 
                                            authProviderConfiguration.get('Client_Id__c') +'&redirect_uri='+ 
                                            authProviderConfiguration.get('Redirect_URI__c') + '&response_type=code'+'&scope='+
                                            authProviderConfiguration.get('Scope__c') +'&uilocale='+ authProviderConfiguration.get('Locale__c') +
                                            '&state='+ stateToPropagate1);
    
        Test.startTest();
        PageReference actualUrl = AzureCls.initiate(authProviderConfiguration, stateToPropagate1);
        Test.stopTest();
    
        //system.assertEquals(expectedUrl.getUrl(), actualUrl.getUrl());
       }
    
    static testMethod void testHandleCallback() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        PartnerAuthorization AzureCls = new PartnerAuthorization();
        AzureCls.redirectUri = authProviderConfiguration.get('Redirect_URI__c');

        Test.setMock(HttpCalloutMock.class, new AzureADB2CMockHTTPResponse());

        Map<String,String> queryParams = new Map<String,String>();
        queryParams.put('code','code');
        queryParams.put('state',authProviderConfiguration.get('State_c'));
        Auth.AuthProviderCallbackState cbState = new Auth.AuthProviderCallbackState(null,null,queryParams);
        test.startTest();
        Auth.AuthProviderTokenResponse actualAuthProvResponse = AzureCls.handleCallback(authProviderConfiguration, cbState);
        Auth.AuthProviderTokenResponse expectedAuthProvResponse = new Auth.AuthProviderTokenResponse('Azure_AD_B2C', access_token, refresh_token, null);
        //system.assertEquals(expectedAuthProvResponse.provider, actualAuthProvResponse.provider);
        test.stopTest();
    
        Auth.AuthProviderTokenResponse response = new Auth.AuthProviderTokenResponse(AUTH_PROVIDER_NAME, access_token ,'sampleOauthSecret', STATE);
        Auth.UserData actualUserData = AzureCls.getUserInfo(authProviderConfiguration, response) ;
        
        Map<String,String> provMap = new Map<String,String>();
                    
        Auth.UserData expectedUserData = new Auth.UserData(userEmailid, null, null, null, userEmailid,
                        null, userEmailid, null, AUTH_PROVIDER_NAME, null, provMap);
        
        //system.assertNotEquals(expectedUserData,null);
        //system.assertEquals(expectedUserData.email, actualUserData.email);
        //system.assertEquals(expectedUserData.provider, actualUserData.provider);
        

    }
   
     static testMethod void testRefresh() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        PartnerAuthorization AzureCls = new PartnerAuthorization();
        AzureCls.redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        Test.setMock(HttpCalloutMock.class, new AzureADB2CMockHTTPResponse());
        
        Test.startTest();
        Auth.OAuthRefreshResult actualRefreshResult = AzureCls.refresh(authProviderConfiguration, refresh_token);
        Auth.OAuthRefreshResult expectedRefreshResult = new Auth.OAuthRefreshResult(access_token, refresh_token);
        Test.stopTest();
        
        //system.assertEquals(expectedRefreshResult.refreshToken, actualRefreshResult.refreshToken);

    }
    
    static testMethod void testException() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        PartnerAuthorization AzureCls = new PartnerAuthorization();
        AzureCls.redirectUri = authProviderConfiguration.get('Redirect_URI__c');
        Test.setMock(HttpCalloutMock.class, new AzureADB2CMockHTTPResponseError());
        Test.startTest();
        try{
            Auth.OAuthRefreshResult actualRefreshResult = AzureCls.refresh(authProviderConfiguration, refresh_token);
            Auth.OAuthRefreshResult expectedRefreshResult = new Auth.OAuthRefreshResult(Null, Null);
        } catch(Exception e){}  
        Test.stopTest();
        
        ////system.assertEquals(1, [SELECT Id FROM Error_Log__c].size());
    }
    
    static testMethod void testForgotPassword() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        PartnerAuthorization AzureCls = new PartnerAuthorization();
        AzureCls.redirectUri = authProviderConfiguration.get('Redirect_URI__c'); 
        Test.startTest();
        try{
            PageReference result = AzureCls.forgotPassword(authProviderConfiguration,stateToPropagate1,'AADB2C90088');
            PageReference result1 = AzureCls.forgotPassword(authProviderConfiguration,stateToPropagate1,'AADB2');   
        } catch(Exception e){}  
        Test.stopTest();
        ////system.assertEquals(true, [SELECT Id FROM Error_Log__c].isEmpty());
    } 
    
    static testMethod void testGetUserInfo() {
        Map<String,String> authProviderConfiguration = setupAuthProviderConfig();
        PartnerAuthorization AzureCls = new PartnerAuthorization();
        String accessToken = access_token; 
        Auth.AuthProviderTokenResponse tokenResponse;
        Test.startTest();
        try{
           //AzureCls.findEmailFromAccessToken(accessToken);
           AzureCls.getUserInfo(authProviderConfiguration, tokenResponse);
        } catch(Exception e){}  
        Test.stopTest();
    } 
    
    static testMethod void testInMaintenanceController() {
        Account acc = [SELECT Id FROM account WHERE name = 'Apple'];
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        ApexPages.currentPage().getParameters().put('error','error');
        ApexPages.currentPage().getParameters().put('error_description','error_description_AADB2C90118');
        ApexPages.currentPage().getParameters().put('state','state');
        ApexPages.currentPage().getParameters().put('code','code');

        Test.startTest();
        //InMaintenanceController inMaintenanceControllerobj =new  InMaintenanceController();
        //inMaintenanceControllerobj.InMaintenanceController();   
        //inMaintenanceControllerobj.redirectURL();
        Test.stopTest();
       
    } 
    static testMethod void testInMaintenanceControllerNoError() {
        Account acc = [SELECT Id FROM account WHERE name = 'Apple'];
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        ApexPages.currentPage().getParameters().put('error','error');
        ApexPages.currentPage().getParameters().put('error_description',null);
        ApexPages.currentPage().getParameters().put('state','state');
        ApexPages.currentPage().getParameters().put('code','code');
        //InMaintenanceController inMaintenanceControllerobj =new  InMaintenanceController();
        
        Test.startTest();
        //inMaintenanceControllerobj.redirectURL();
        Test.stopTest();
       
    } 
    
    static testMethod void testAutocreatedRegHandler1622039605716() {
        Boolean isExcpetion = false;
        //AutocreatedRegHandler1622039605716 handler = new AutocreatedRegHandler1622039605716 ();
        Auth.UserData sampleData = new Auth.UserData('testId', 'testFirst', 'testLast',
                                                     'testFirst testLast', 'testuse8888r@example.org', null, 'testuserlong', 'en_US', 'facebook',
                                                     null, new Map<String, String>{'language' => 'en_US'});
        Test.startTest(); 
            //Boolean canCreateUser = handler.canCreateUser(sampleData);
            //user  u = handler.createUser(null, sampleData);
            //sampleData = new Auth.UserData('testNewId', 'testNewFirst', 'testNewLast',
            //                               'testNewFirst testNewLast', 'testnewuser@example.org', null, 'testnewuserlong', 'en_US', 'facebook',
            //                               null, new Map<String, String>{});
            //handler.updateUser(null, null, sampleData);
        Test.stopTest();
        
        ////system.assertEquals(false,canCreateUser);

    }

    public class AzureADB2CMockHTTPResponse implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
        // Create a fake response
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"EmailAddress":"Anujit.Das@cognizant.com","access_token":"eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImtpZCI6IkJVOHlXamxhdFdiR2lldFFtU0wyUWE5NG03UVBibjRUcXhVOWgyVzNIMUEifQ.eyJpc3MiOiJodHRwczovL21zY2IyY3BhcmF1dHByZC5iMmNsb2dpbi5jb20vMDIwOGRlNjAtMWM3ZC00YjE1LTkzNjUtNGEzYTBlZDg0ZDFjL3YyLjAvIiwiZXhwIjoxNjIyMTk5MjExLCJuYmYiOjE2MjIxMTI4MTEsImF1ZCI6IjdkZmE5MDVkLWQ3NjktNGIzNC1hNDFlLWI5MTc4Zjg1M2Q1NSIsImVtYWlsIjoiQW51aml0LkRhc0Bjb2duaXphbnQuY29tIiwic3ViIjoiNDRmZjFhNWItNWY1NC00N2ZjLTljZjktMzAxNTIxODU0NjhkIiwibmFtZSI6IkFudWppdCBEYXMiLCJnaXZlbl9uYW1lIjoiQW51aml0IiwiZmFtaWx5X25hbWUiOiJEYXMiLCJsb2NhbGUiOiJlbi1HQiIsImxhc3RMb2dvbiI6MTYyMjEwNTY5NCwib3JnYW5pc2F0aW9uQ29udGV4dCI6IntcImlkZW50aWZpZXJzXCI6W119Iiwic2lnbkluTWV0aG9kIjoic2lnbi1pbiIsInRmcCI6IkIyQ18xQV9EVVBTX1NpZ25JbiIsInRpZCI6IjAyMDhkZTYwLTFjN2QtNGIxNS05MzY1LTRhM2EwZWQ4NGQxYyIsInNjcCI6InZpZXdfcGFydGllcyB2aWV3X2NvbnRyYWN0cyB2aWV3X3lvdXJfcHJvZmlsZV9pbmZvcm1hdGlvbiB2aWV3X2ZpbmFuY2lhbF9jb25maWd1cmF0aW9uIiwiYXpwIjoiMmQ3NGUyYjEtMzhkOS00MGQwLWFhNmUtMmZkYzZjYTIyNmI0IiwidmVyIjoiMS4wIiwiaWF0IjoxNjIyMTEyODExfQ.aO-AxDGad02kJ28JPmLzVX-O4IxHd5IoEroBVIyYMBUz0_BJJ6-7dI45UML0vvpSxeVXH8FCh2c9C9sIdCwH5gZmZl4RRzqpPUzouhVtFEbrRdG0yuhXPs-u0EmjaqO55wwNR4jy8l-dvhMd2X5YcGasgVQcY8DiEK56QxQy30nivrNKjDEDCZw5c_QEGcvfO3inNSijWETJwYKXkDtcVlOS5Dba9NdV4o2mGZMOonvSdtbiYmubfVCUlkW0fMtDRKRQEHBppA30mT4ZBk7ErSbKETx6Ux6V_YYaPcI6O2Fyno5FLQ_y95RSr84tMv3ZAr4K91rxe7HuDDq_6goY9A","refresh_token":"refreshToken"}');
        res.setStatusCode(200);
        return res;
        }

    }
    
    public class AzureADB2CMockHTTPResponseError implements HttpCalloutMock{
        public HTTPResponse respond(HTTPRequest req){
        // Create a fake response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatus('Bad request');
            res.setBody('{"error":"error","error_description":"error_description","trace_id":"trace_id","correlation_id":"correlation_id"}');
            res.setStatusCode(400);
        
        return res;
        }

    }
}