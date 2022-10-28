@isTest
public class PartnerForgotPasswordTest {
    
    @isTest
    public static void testError(){
        
        ApexPages.currentPage().getParameters().put('error', 'test');
        ApexPages.currentPage().getParameters().put('error_description', 'AADB2C90118');
        ApexPages.currentPage().getParameters().put('state', '');
        ApexPages.currentPage().getParameters().put('code', '');
        
        PartnerForgotPassword instance = new PartnerForgotPassword();
        
        Test.startTest();
        	instance.PartnerForgotPassword();
       	 	PageReference url = instance.redirectURL();
        Test.stopTest();
    }
    
    @isTest
    public static void testSuccess(){
        
        ApexPages.currentPage().getParameters().put('error', '');
        ApexPages.currentPage().getParameters().put('error_description', '');
        ApexPages.currentPage().getParameters().put('state', 'test');
        ApexPages.currentPage().getParameters().put('code', 'test');
        
        PartnerForgotPassword instance = new PartnerForgotPassword();
        
        Test.startTest();
        	instance.PartnerForgotPassword();
       	 	PageReference url = instance.redirectURL();
        Test.stopTest();
    }

}