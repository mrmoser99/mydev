/********
* This is a wrapper class built and used in GetAddressValidation class.
* Used in Customer creation process in DLL on Demand
* Author:Geetha Bharadwaj
*/

public virtual class GetAddressValidationExtention {
    
    public class GetAddressValidationWrapper{
        @AuraEnabled public String country{get;set;}
        @AuraEnabled public String addressLine1{get;set;}
        @AuraEnabled public String state{get;set;}
        @AuraEnabled public String city{get;set;}
        @AuraEnabled public String postalCode{get;set;}
      //  @AuraEnabled public String residenceNumber{get;set;}
      //  @AuraEnabled public String streetName{get;set;}
        @AuraEnabled public String county{get;set;}
        @AuraEnabled public String returnCode{get;set;}
        @AuraEnabled public String responseMessage{get;set;}
        @AuraEnabled public boolean isSuccess{get;set;}
  }  

}