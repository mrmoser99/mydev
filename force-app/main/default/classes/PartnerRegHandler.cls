global class PartnerRegHandler implements Auth.RegistrationHandler {
    private final string PARTNER_PROFILE = label.Partner_Portal_Profile;
    
    global boolean canCreateUser(Auth.UserData data) {
        return false;
    }
    
     /*
    This method is responsible to find the community user which is authenticated in Azure AD B2C.
    */
    global User createUser(Id portalId, Auth.UserData data){
        system.debug('email=='+data.email);
        User partnerPortalUser = new user();
        try{
            if(data.email != null){
                system.debug('inside query ' +data.email);
                // AND profile.name =: PARTNER_PROFILE LIMIT 1][0];
                partnerPortalUser = [
                    SELECT id,username,email,name,alias,languagelocalekey,localesidkey,emailEncodingKey,timeZoneSidKey,profileId 
                    FROM User 
                    WHERE email=: data.email
                    AND Profile.Name = 'Partner Admin'
                    AND isActive = true LIMIT 1
                ][0];
                
                system.debug('querypartner = ' +partnerPortalUser);
                                        
            }        
        }catch(QueryException qe) {
            System.debug('The following SOQL exception has occurred: ' + qe.getMessage());
        }catch(Exception e) {
            System.debug('Exception caught: ' + e.getMessage());    
        }   
        return partnerPortalUser ;
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        
    }
}