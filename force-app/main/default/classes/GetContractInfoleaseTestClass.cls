@isTest(SeeAllData=True)
public class GetContractInfoleaseTestClass {
    
    @isTest static void contract_M1() {
        
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
        insert at;
        
        Contract__c cont=new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234';
        cont.UNQ_Contract__c='1234CONTRACT';
        cont.Name='test contract';
        cont.Amount__c=10;
        insert cont;   
        
        Case cs = new Case();
        cs.Type = 'Contract Activation & Changes';
        cs.Sub_Type__c = 'Contract Activation';
        cs.Department__c = 'Portfolio Services';
        cs.End_User_First_Name__c = 'Test First Name';
        cs.End_User_Last_Name__c = 'Test Last Name';
        cs.End_User_Email__c = 'test@test.com';
        cs.Contract_Relationship__c = cont.id;
        insert cs;
        
        
        // Insert Contract whse Parent is Case Id
        
      //  Test.setMock(HttpCalloutMock.class, new Infolease_AccessTokenMockCallout());
        Test.setMock(HttpCalloutMock.class, new GetContractGenerateResponseMockCallout());
        
        Test.startTest();
        GetContractInfolease.getContract(cs.Id);
        Test.stopTest();
    }
}