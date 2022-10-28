/*
* Integrates with DUPS to ensure a logout.
* hvedo@tractionondemand.com
* updated by @Author: Anujit Das 19-11-2021. to handle nordics portal logout
*/

public class PartnerLogout {
    
    public void PartnerLogout() {
       
        ApexPages.currentPage().getParameters().get('id');      
    }
    
    /*
    This method is responsible to initiate the forgot password flow whenver encountered an error
    */
    public PageReference redirectURL() {
        
        PageReference fpassUrl; 
        //To check if the logged in user is Nordics community user
        id profileId = userinfo.getProfileId();
        String profileName = [select Name from profile where id = :profileId LIMIT 1].Name;     
        if(profileName == Constants.LIFE_PROFILE ){
            fpassUrl = handleNordicsPortalLogout();
        }else{
    
            //get the details from custom meta data type
            Map<String, PartnerPortal__mdt> standardAuthCreds = PartnerPortal__mdt.getAll();
            string LogoutUrl = standardAuthCreds.get('PartnerAuthorization').Logout_URL__c;
            string clientId = standardAuthCreds.get('PartnerAuthorization').Client_Id__c;
            string redirect_url = EncodingUtil.urlEncode(standardAuthCreds.get('PartnerAuthorization').Partner_Portal_URL__c, 'UTF-8'); 
            string scope = EncodingUtil.urlEncode(standardAuthCreds.get('PartnerAuthorization').Scope__c, 'UTF-8');     
            
            String url = LogoutUrl +'?client_id='+clientId+'&redirect_uri='+redirect_url+'&response_type=code&scope=' + scope + '&uilocale=en-GB';
            fpassUrl = new PageReference(url);         
            
            
        }
        fpassUrl.setRedirect(true);
        return fpassUrl;
    }
    
    /*
    This method is responsible to initiate the forgot password flow for Nordics community
    */
    public PageReference handleNordicsPortalLogout() {
       
        //get the details from custom meta data type
        Map<String, Standard_Auth_Credentials__mdt> standardAuthCreds = Standard_Auth_Credentials__mdt.getAll();
        string LogoutUrl = standardAuthCreds.get('Azure_AD_B2C').Logout_URL__c;
        string clientId = standardAuthCreds.get('Azure_AD_B2C').Client_Id__c;
        string redirect_url = EncodingUtil.urlEncode(standardAuthCreds.get('Azure_AD_B2C').Partner_Portal_URL__c, 'UTF-8'); 
        string scope = EncodingUtil.urlEncode(standardAuthCreds.get('Azure_AD_B2C').Scope__c, 'UTF-8');     
        String url = LogoutUrl +'?client_id='+clientId+'&redirect_uri='+redirect_url+'&response_type=code&scope=' + scope + '&uilocale=en-GB';
        
        PageReference fpassUrl = new PageReference(url);    
        
        return fpassUrl;
    }
    
}