@isTest
private class UsertriggerTest {
    
    @testSetup static void setup() {
        Account acc1 =new Account();
        acc1.Name='level-1-account';
        acc1.RecordTypeId=Schema.SObjectType.account.getRecordTypeInfosByName().get('Legal Entity').getRecordTypeId();
        insert acc1;  
        
        Account acc2 =new Account();
        acc2.Name='level-2-account';
        acc2.RecordTypeId=Schema.SObjectType.account.getRecordTypeInfosByName().get('Party').getRecordTypeId();
        acc2.ParentId=acc1.Id;
        insert acc2;  
        
        Account acc3 =new Account();
        acc3.Name='level-3-account';
        acc3.RecordTypeId=Schema.SObjectType.account.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        acc3.ParentId=acc2.Id;
        insert acc3;  
        
        //tie 2 contacts to the same account, only the first time will create external account hierarchy record
        Contact c1 = New Contact(LastName = 'Test1', AccountID = acc1.id, Department = 'DLL-1');
		insert c1;
        Contact c2 = New Contact(LastName = 'Test2', AccountID = acc1.id, Department = 'DLL-2');
		insert c2;
        
        Contact c3 = New Contact(LastName = 'Test3', AccountID = acc2.id);
		insert c3;
        
        Contact c4 = New Contact(LastName = 'Test4', AccountID = acc3.id);
		insert c4;
        
    }
    
    @isTest static void testMethod1(){    
                
        Account acc1 = [Select id From Account where Name = 'level-1-account'];
        Account acc2 = [Select id From Account where Name = 'level-2-account'];
        Account acc3 = [Select id From Account where Name = 'level-3-account'];
        
        Contact c1 = [SELECT Id,LastName FROM Contact WHERE AccountID = :acc1.Id AND Department = 'DLL-1'];  
        Contact c2 = [SELECT Id,LastName FROM Contact WHERE AccountID = :acc1.Id AND Department = 'DLL-2'];
        Contact c3 = [SELECT Id,LastName FROM Contact WHERE AccountID = :acc2.Id];  
        Contact c4 = [SELECT Id,LastName FROM Contact WHERE AccountID = :acc3.Id];
        
        Test.startTest();
        
        User newUser1 = createPartnerUser(c1.id,c1.LastName);
        User newUser2 = createPartnerUser(c2.id,c2.LastName);
        User newUser3 = createPartnerUser(c3.id,c3.LastName);
        User newUser4 = createPartnerUser(c4.id,c4.LastName);
        
        Test.stopTest();   
        
        system.debug('newUser1:'+newUser1);
        
        acc1 = [Select isPartner From Account where Name = 'level-1-account'];
		system.assert(acc1.isPartner,true);
        acc2 = [Select isPartner From Account where Name = 'level-2-account'];
		system.assert(acc2.isPartner,true);
        acc3 = [Select isPartner From Account where Name = 'level-3-account'];
		system.assert(acc3.isPartner,true);
        
        ExternalAccountHierarchy externalAcc1 = [Select Id,Name,AccountId,ParentId From ExternalAccountHierarchy WHERE AccountId = :acc1.id];
        system.assertEquals ('level-1-account',externalAcc1.Name);
        system.assertEquals (acc1.Id,externalAcc1.AccountId);
        system.assertEquals (null,externalAcc1.ParentId);
        ExternalAccountHierarchy externalAcc2 = [Select Id,Name,AccountId,ParentId From ExternalAccountHierarchy WHERE AccountId = :acc2.id];
        system.assertEquals ('level-2-account',externalAcc2.Name);
        system.assertEquals (acc2.Id,externalAcc2.AccountId);
        system.assertEquals (externalAcc1.Id,externalAcc2.ParentId);
        ExternalAccountHierarchy externalAcc3 = [Select Id,Name,AccountId,ParentId From ExternalAccountHierarchy WHERE AccountId = :acc3.id];
        system.assertEquals ('level-3-account',externalAcc3.Name);
        system.assertEquals (acc3.Id,externalAcc3.AccountId);
        system.assertEquals (externalAcc2.Id,externalAcc3.ParentId);
    }

	private static user createPartnerUser(ID cId, String Name){
    	Profile p = [SELECT Id,Name from Profile where Name Like 'Partner%' LIMIT 1];

    	user u = New User(
        	UserName = 'test_' + math.random() + '@test.com',
        	FirstName = 'Test-First',
        	LastName = Name,
        	Alias = 'test',
        	email = 'test' + math.random() + '@test.com',
        	CommunityNickName = string.valueOf(math.random()).substring(0,6),
        	ProfileID = p.id,
        	TimeZoneSidKey = 'America/New_York', 
        	LocaleSidKey = 'en_US', 
        	EmailEncodingKey = 'UTF-8', 
        	LanguageLocaleKey = 'en_US',
            Business_Unit__c = 'Other',
        	ContactID = cId
        	);

    		insert u; 
    		return u;
	}

}