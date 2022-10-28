@isTest(SeeAllData=True)
public class GetAddressValidationTestClass {
    
    @isTest static void method_M1() {
        system.debug('inside testclass');
        //creating account
        
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId(); 
        
        Account acc =new Account();
        acc.Name='test';
        acc.Technology_Solutions__c=false;
        insert acc;       
        
        system.assertNotEquals(null, acc.id);
        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        insert parentEnduser;
        system.assertNotEquals(null, parentEnduser.id);
        
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        at.BillingStreet = '1041 penn cir';
        at.BillingCity = 'King of Prussia';
        at.BillingCounty__c = 'Montgomery';
        at.BillingState = 'PA';
        at.BillingCountry = 'US';
        at.BillingPostalCode = '19406';
        insert at;
        
        Account at1 =new Account();
        at1.Name='Service1';
        at1.RecordTypeId=RecordTypeIdAccountEndUser;
        at1.ParentId=parentEnduser.Id;
        at1.Technology_Solutions__c=false;
        at1.BillingStreet = '1041 penn cir';
        at1.BillingCity = 'King of Prussia';
        at1.BillingCounty__c = 'Montgomery';
        at1.BillingState = 'PA';
        at1.BillingCountry = 'US';
        at1.BillingPostalCode = '19406';
        
        Account at2 =new Account();
        at2.Name='';
        at2.RecordTypeId=RecordTypeIdAccountEndUser;
        at2.ParentId=parentEnduser.Id;
        at2.Technology_Solutions__c=false;
        at2.BillingStreet = '1041 penn cir';
        at2.BillingCity = 'King of Prussia';
        at2.BillingCounty__c = 'Montgomery';
        at2.BillingState = 'PA';
        at2.BillingCountry = 'US';
        at2.BillingPostalCode = '19406';
      
        Test.setMock(HttpCalloutMock.class, new GetAddressValidationResponseMockCallout());
        
        Test.startTest();
        try{
        GetAddressValidation.getAddValidation(at,'f203');
        GetAddressValidation.insertAccount(at1);
        GetAddressValidation.getAddValidation(null,'f203');
        GetAddressValidation.insertAccount(at2);
       
        }catch(Exception e){
            system.debug('error');
        }
        Test.stopTest();
        
    }
    
    @isTest static void method_M2() {
         GetAddressValidation.getAllstates();
    }
    
    
}