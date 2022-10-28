/**
 * @description       : Test class of Credit Application page container.
 * @author            : Surbhi Goyal (Traction on Demand)
 * @group             : 
 * @last modified on  : 23-03-2022
 * @last modified by  : Kritika Sharma
**/
@isTest
public class CreditApplicationHeaderControllerTest {
    @testSetup static void setup()
    {
        
        // New Account Record Created   
        Account a = new Account(name = 'Test');
        insert a;

        // New Contact Record Created
        Contact c = new Contact(firstName = 'Test', lastName = 'Last Name', accountId = a.id, role__c='Partner Sales Rep');
        insert c;

        // New Opportunity Record Created
        Opportunity o = new Opportunity( nickname__c = 'testNick', amount = 10000.00, Name='Test Opp', 
                						accountId = a.id, StageName = 'Quoting', CloseDate = date.today().addDays(30), Application_Number__c ='500-1234567',
                                        Sub_Stage__c='Application Submitted',Application_Date__c=date.today().addDays(30), Beneficial_Owner_Type__c='Owner(s)');
        insert o;

        // New Quote Record Created
        Quote q = new Quote (end_user__c = a.id, name = 'test Quote', opportunityId = o.id,
                lease_type__c = 'Fair Market Value (FMV)', term__c = '48', payment_frequency__c = 'monthly',
                payment_timing__c = 'in-arrears',Is_Primary__c=true);
        insert q;

        // New System Id object Record Created
        System_ID__c s = new System_Id__c(account__c = a.id, dll_external_key_source__c = 'ORACLE', dll_External_id__c = '12345', 
                dll_external_key_type__c = 'TCAPartyID');
        insert s;

        //New Quote Line Record in Account Object Created
        Quote_Line__c ql = new Quote_Line__c(quote__c = q.id);
        insert ql;
    }

    @isTest
    public static void CreditApplicationHeaderControllerMethod() {
        Opportunity opp = new Opportunity();
        Contact con = new Contact();
        Account acc = new Account();
        try{
            opp = [select Id,Application_Number__c,Sub_Stage__c,Application_Date__c,Beneficial_Owner_Type__c from Opportunity LIMIT 1];
        }catch(Exception e){
           // console.log('No record found for opportunity');
        }
        try{
            con = [select Id from Contact LIMIT 1];
        }catch(Exception e){
           // console.log('No record found for Contact');
        }
        try{
            acc = [select Id from Account LIMIT 1];
        }catch(Exception e){
           // console.log('No record found for Account');
        }

        CreditApplicationHeaderController.createPicklistValues('Contact','role__c');

        CreditApplicationHeaderController.picklistValues('Contact','role__c');

        CreditApplicationHeaderController.getQuoteLineData(opp.Id);

        CreditApplicationHeaderController.getQuoteLineAccessoryData(opp.Id);

        CreditApplicationHeaderController.getOpportunityData(opp.Id);
        
        CreditApplicationHeaderController.getContactField(opp.Id);

        List<Map<String,string>> listOfMap=new List<Map<String,string>>();

        Map<String,string> mapData=new Map<String,string>();

        mapData.put('uboID',con.Id);
        mapData.put('endUserAccount',acc.Id);
        mapData.put('firstName','firstName');
        mapData.put('middleName','middleName');
        mapData.put('lastName','lastName');
        mapData.put('titleValue','CEO');
        mapData.put('countryOfResidenceValue','United States');
        
        listOfMap.add(mapData);
        
        Map<String,string> mapData1=new Map<String,string>();

        mapData1.put('endUserAccount',acc.Id);
        mapData1.put('firstName','firstName');
        mapData1.put('middleName','middleName');
        mapData1.put('lastName','lastName');
        mapData1.put('titleValue','CEO');
        mapData1.put('countryOfResidenceValue','United States');
        
        listOfMap.add(mapData1);

        //Assert list is not empty
       // System.assert(listOfMap.isEmpty(),'List should not be empty');

        CreditApplicationHeaderController.UpdateBenefitOwnerData(listOfMap,opp.Id);

        Map<String,string> mapOfString=new Map<String,string>();
        mapOfString.put('customerStoryId',opp.Id);
        mapOfString.put('businessStructure','Test');
        mapOfString.put('yearsInBusiness','2020');
        mapOfString.put('story','Test story');
        //mapOfString.put('beneficialOwnerType','owner type');
        string appNo = opp.Application_Number__c;
        string appStatus = opp.Sub_Stage__c;
        Date todayDate = opp.Application_Date__c;
        string ownershipinfo = opp.Beneficial_Owner_Type__c;
        
         //Assert list is not empty
        //System.assert(mapOfString.isEmpty(),'List should not be empty');

        CreditApplicationHeaderController.UpdateQuoteData(mapOfString,ownershipinfo,appNo,appStatus,todayDate);

        CreditApplicationHeaderController.saveRelatedPartyForOpp(opp.Id, 'TestFirst', 'TestMiddle', 'TestLast', '123121234');
        CreditApplicationHeaderController.getRelatedPartyForOpp(opp.Id);
        CreditApplicationHeaderController.saveRelatedPartyForOpp(opp.Id, 'TestFirstTwo', 'TestMiddleTwo', 'TestLastTwo', '124121234');
        
    }
}