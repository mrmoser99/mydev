/*PBI:640594:Apex Sharing for Contracts using Contract Teams: DLL on Demand
 *Ability to add a portal user to a contract team, so that the portal user can view the contract by APEX sharing.
 *version1: Geetha Bharadwaj
 *commenting the login for Apex sharing - Geetha
 */
@isTest
public class ContractTeamMemberTest {
    
    /*@testSetup static void setup() {
        List<User> usList = new List<User>();
        User u = new User( ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,LastName = 'Testlast',
                          Email = 'testadmin.last@test.com',Username = 'testadmin.last@test.com' + System.currentTimeMillis(),
                          CompanyName = 'TEST',Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles', Legal_Entity_Description__c = 'DLL', 
                          EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_US',Business_Unit__c = 'Commercial Finance'
                         );
        usList.add(u);
        
        User w = new User( ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,LastName = 'TestUser1last',
                          Email = 'testuser1.last@test.com',Username = 'testuser1.last@test.com' + System.currentTimeMillis(),
                          CompanyName = 'TEST',Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles', Legal_Entity_Description__c = 'DLL',
                          EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_US',Business_Unit__c = 'Commercial Finance'
                         );
        usList.add(w);
        
        User x = new User( ProfileId = [SELECT Id FROM Profile WHERE Name = 'API Integration'].Id,LastName = 'TestUser2last',
                          Email = 'testuser2.last@test.com',Username = 'testuser2.last@test.com' + System.currentTimeMillis(),
                          CompanyName = 'TEST',Title = 'title', Alias = 'alias', TimeZoneSidKey = 'America/Los_Angeles',Legal_Entity_Description__c = 'DLL',
                          EmailEncodingKey = 'UTF-8',LanguageLocaleKey = 'en_US',LocaleSidKey = 'en_US',Business_Unit__c = 'Commercial Finance'
                         );
        usList.add(x);
        insert usList;
        
        system.debug('usList==>'+usList);
        
        Id RecordTypeIdAccountEndUser = Schema.SObjectType.Account.getRecordTypeInfosByName().get('End User').getRecordTypeId(); 
        Id RecordTypeIdAccountVendor = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId(); 
        Id RecordTypeIdAccountProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId(); 
        
        
        Account parentEnduser =new Account();
        parentEnduser.Name='testparent end user';
        parentEnduser.RecordTypeId=RecordTypeIdAccountEndUser;
        insert parentEnduser;
        
        
        Account at =new Account();
        at.Name='Service';
        at.RecordTypeId=RecordTypeIdAccountEndUser;
        at.ParentId=parentEnduser.Id;
        at.Technology_Solutions__c=false;
        insert at;
        
        contact ct =new contact();
        ct.LastName='Niranjan';
        ct.AccountId=at.id;
        ct.Email='arry@gmil.com';
        insert ct;
        
        
        System_ID__c sys =new System_ID__c();
        sys.System_Name__c='test';
        sys.UNQ_Vendor__c='123411';
        sys.UNQ_Customer__c='123';
        sys.Phone__c='7889057582';
        sys.Account__c=at.id;
        insert sys;
        
        Opportunity opp= new Opportunity();
        opp.Type='Overline';
        opp.Name='Service';
        opp.StageName='On Hold';
        opp.Accountid=at.id;
        opp.Contact__c=ct.id;
        opp.CloseDate=system.today()+1;
        opp.Amount=22.0;
        opp.End_User__c=at.id;
        opp.Business_Unit1__c='Digital Imaging';
        opp.UNQ_Customer__c='123';
        opp.UNQ_Vendor__c='1234455';
        opp.UNQ_Opportunity__c='12345';
        insert opp;  
        
        Contract__c cont=new Contract__c();
        cont.UNQ_Opportunity__c='12345';
        cont.UNQ_Customer__c='123';
        cont.UNQ_Vendor__c='1234887';
        cont.UNQ_Contract__c='1234CONTRACT';
        
        cont.Opportunity__c=opp.id;
        cont.Name='test contract';
        
        cont.Amount__c=10;
        cont.Customer_Code__c=sys.id; 
        
        insert cont;
        
    }
    
    
    @isTest static  void ContractTM_M1(){
        user admin;
        user test1;
        user test2;
        Contract__c cont = [Select Id from contract__c ];
        List<User> usList = [Select Id, Email from User 
                            ];
        system.debug('uselist==='+usList);
        for(User us: usList){
            if(us.Email=='testadmin.last@test.com'){
                admin = us; 
            }else if(us.Email=='testuser1.last@test.com'){
                test1 = us; 
            }else {
                test2 = us;
            }
        }
        
        
        test.startTest();
        system.runAs(admin){
            Contract_Team__c ctm= new contract_team__c();
            ctm.Name = 'ContractTM_Test1';
            ctm.Contract__c = cont.id;
            ctm.Contract_Access__c = 'Read';
            ctm.Team_Role__c = 'Partner Admin';
            ctm.User__c = test1.Id;
            insert ctm;
            
            List<Contract__Share> cts = [SELECT AccessLevel,Id,ParentId,RowCause,UserOrGroupId
                                         FROM Contract__Share 
                                         WHERE parentId =: ctm.Contract__c];
            system.debug('cts==>'+cts);
            system.assertequals(2, cts.size());
            
            ctm.Contract_Access__c = 'Read / Write';
            update ctm;
            
            List<Contract__Share> ctsUpdated = [SELECT AccessLevel,Id,ParentId,RowCause,UserOrGroupId
                                                FROM Contract__Share 
                                                WHERE parentId =: ctm.Contract__c AND UserOrGroupId =: test1.Id];
            
            system.assertequals('Edit', ctsUpdated[0].AccessLevel);
            
            delete ctm;
            List<Contract__Share> ctsdeleted = [SELECT AccessLevel,Id,ParentId,RowCause,UserOrGroupId
                                                FROM Contract__Share 
                                                WHERE parentId =: ctm.Contract__c AND UserOrGroupId =: test1.Id];  
            system.assertequals(0, ctsdeleted.size());
            
        }
        test.stopTest();
    } */
    
}