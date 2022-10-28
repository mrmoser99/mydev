@isTest
public class PartnerLogoutTest {
    
    @isTest
    public static void PartnerLogoutUrl(){
        PartnerLogout logout = new PartnerLogout(); 
        
        Test.startTest();
        logout.PartnerLogout();
        PageReference url = logout.redirectURL();
        Test.stopTest();
    }

	//test scenario for handleNordicsPortalLogout    
    @isTest
    public static void testHandleNordicsPortalLogout(){
        PartnerLogout logout = new PartnerLogout();
        
        Test.startTest();
        logout.PartnerLogout();
        PageReference url = logout.handleNordicsPortalLogout();
        Test.stopTest();
    }
}