/*****************************************************************************************
Name: PartnerForgotPassword
===============================================================================================
Purpose: To handle the logic when user clicks on forgot password link in the azure ad b2c login page
created for DLL on Demand
******************************************************************************************/

public class PartnerForgotPassword {
    
    public void PartnerForgotPassword() {
        system.debug('PartnerForgotPassword');
        ApexPages.currentPage().getParameters().get('id');
    }
    
    /*
    This method is responsible to initiate the forgot password flow whenver encountered an error
    */
    public PageReference redirectURL() {
        String error = ApexPages.currentPage().getParameters().get('error');
        String error_desc = ApexPages.currentPage().getParameters().get('error_description');
        String state = ApexPages.currentPage().getParameters().get('state');
        String code = ApexPages.currentPage().getParameters().get('code');
               
        //get the details from custom meta data type
        Map<String, PartnerPortal__mdt> standardAuthCreds = PartnerPortal__mdt.getAll();
        string forgotPasswordUrl = standardAuthCreds.get('PartnerAuthorization').Forgot_Password_URL__c;
        string clientId = standardAuthCreds.get('PartnerAuthorization').Client_Id__c;
        string redirect_url = EncodingUtil.urlEncode(standardAuthCreds.get('PartnerAuthorization').Redirect_URI__c, 'UTF-8'); 
        string scope = EncodingUtil.urlEncode(standardAuthCreds.get('PartnerAuthorization').Scope__c, 'UTF-8');     
        
        if(error_desc!= null && error_desc.contains('AADB2C90118')){
            //String url = 'https://mscb2cparautprd.b2clogin.com/mscb2cparautprd.onmicrosoft.com/B2C_1A_DUPS_ResetPassword/oauth2/v2.0/authorize?client_id=2d74e2b1-38d9-40d0-aa6e-2fdc6ca226b4&redirect_uri=https%3A%2F%2Fst02d01-life.cs195.force.com%2Fpartners%2Fservices%2Fauthcallback%2FAzure_AD_B2C&response_type=code&scope=offline_access+https%3A%2F%2Fmscb2cparautprd.onmicrosoft.com%2Fdigitalapis%2Fview_contracts+https%3A%2F%2Fmscb2cparautprd.onmicrosoft.com%2Fdigitalapis%2Fview_financial_configuration+https%3A%2F%2Fmscb2cparautprd.onmicrosoft.com%2Fdigitalapis%2Fview_parties+https%3A%2F%2Fmscb2cparautprd.onmicrosoft.com%2Fdigitalapis%2Fview_your_profile_information&state=' + state + '&uilocale=en-GB';
            String url = forgotPasswordUrl +'?client_id='+clientId+'&redirect_uri='+redirect_url+'&response_type=code&scope='+ scope +'&state=' +state + '&uilocale=en-US';
            PageReference fpassUrl = new PageReference(url);         
            fpassUrl.setRedirect(true);
            system.debug('***Inside 1st if' + url);
            return fpassUrl;
        }
        if(state != null && code != null && (error_desc == null || error_desc == '')){
            String url = standardAuthCreds.get('PartnerAuthorization').Partner_Portal_URL__c;
            PageReference loginUrl = new PageReference(url);         
            loginUrl.setRedirect(true);
            return loginUrl;
        }           

        return null;
    }
    
}