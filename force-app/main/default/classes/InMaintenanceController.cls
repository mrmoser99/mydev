/*****************************************************************************************
Name: InMaintenanceController
===============================================================================================
Purpose: To handle the backend logic to handle the forgot password error in Azure ad b2c
================================================================================================
================================================================================================
History
-------
VERSION        AUTHOR                  DATE              DETAIL
1.0                Anujit Das          14-06-2021        handles the forgot password error in Azure ad b2c
******************************************************************************************/
public class InMaintenanceController {
    
    public void InMaintenanceController() {
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
        Map<String, Standard_Auth_Credentials__mdt> standradAuthCreds = Standard_Auth_Credentials__mdt.getAll();
        string forgotPasswordUrl = standradAuthCreds.get('Azure_AD_B2C').Forgot_Password_URL__c;
        string clientId = standradAuthCreds.get('Azure_AD_B2C').Client_Id__c;
        string uilocale = standradAuthCreds.get('Azure_AD_B2C').Locale__c;
        string redirect_url = EncodingUtil.urlEncode(standradAuthCreds.get('Azure_AD_B2C').Redirect_URI__c, 'UTF-8');      
        
        if(error_desc!= null && error_desc.contains('AADB2C90118')){
            String url = forgotPasswordUrl +'?client_id='+clientId+'&redirect_uri='+redirect_url+'&response_type=code&scope='+label.scope +'&state=' +state + '&ui_locales='+uilocale;
            PageReference fpassUrl = new PageReference(url);         
            fpassUrl.setRedirect(true);
            return fpassUrl;
        }
        if(state != null && code != null && (error_desc == null || error_desc == '')){
            String url = standradAuthCreds.get('Azure_AD_B2C').Partner_Portal_URL__c;
            PageReference loginUrl = new PageReference(url);         
            loginUrl.setRedirect(true);
            return loginUrl;
        }            
        return null;
    }
    
}