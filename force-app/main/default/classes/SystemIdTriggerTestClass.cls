@IsTest
private class SystemIdTriggerTestClass {
	
	static testMethod void testInsertSystemIdNoExistingRecord()
	{
		System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'GENESIS RESPIRATORY SERVICES, INC.';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'california';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'ABC Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';
        sys2.UNQ_Vendor__c='12345-001';
        //Added a legal entity
        sys2.Legal_Entity_ID__c = 'test';
        insert sys2;
        sys2=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, Legal_Entity_ID__c FROM System_ID__c WHERE Id=:sys2.Id];
        //assert that Systemid record is update
        System.assertNotEquals(null, sys2.Account__c);
        
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId FROM Account];
        System.assertEquals(sys2.Street__c, accs[0].BillingStreet);
        System.assertEquals(sys2.City__c, accs[0].BillingCity);
        System.assertEquals(sys2.State__c, accs[0].BillingState);
        System.assertEquals(sys2.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys2.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys2.Phone__c, accs[0].Phone);
        System.assertEquals(sys2.Zip_Postal_Code__c, accs[0].BillingPostalCode);
        
        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
        System.assertEquals(sys2.Account__c, accs[0].Id); 
	}
	static testMethod void testInsertSystemIdMatch1ExistingRecord()
 	 {
         Account acc = new Account();
         acc.Name = 'Test';
         acc.Phone = '1234567890';
         acc.BillingState = 'CA';
         acc.BillingCity = 'San Francisco';
         acc.BillingCountry = 'US';
         acc.BillingStreet = 'Test Street';
         acc.Legal_Entity_Name__c = 'ABC Corp';
         acc.BillingPostalCode = '96543';
         acc.ATS_ID_s__c = '12345-001';
         insert acc;
         Test.startTest();
         System_ID__c sys = new System_ID__c();
         sys.System_Name__c = 'SysyTest1';
         sys.Account__c = acc.Id;
         sys.City__c = 'San Francisco';
         sys.Country__c = 'US';
         sys.Phone__c = '1234567890';//+i;
         sys.State__c = 'CA';
         sys.Street__c = 'Test Street';
         sys.Legal_Entity_Name__c = 'ABC Corp';
         sys.Zip_Postal_Code__c='96543';
         sys.UNQ_Vendor__c='12345-001';
         insert sys;
         System.assertNotEquals(null, sys.Id);
         System.assertEquals(acc.Id, sys.Account__c);

         List<Account> totalaccs=[SELECT Id, ATS_ID_s__c, Risk_Rating__c FROM Account LIMIT 500];
         System.assertEquals(1, totalaccs.size());
         System.assertEquals(totalaccs[0].Risk_Rating__c, null);

         sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c,System_ID__c FROM System_ID__c WHERE Id=:sys.Id];
         System_ID__c sys2 = new System_ID__c();
         sys2.System_Name__c = 'SysTest2';
         sys2.City__c = 'San Francisco';
         sys2.Country__c = 'US';
         sys2.Phone__c = '1234567890';
         sys2.State__c = 'CA';
         sys2.Street__c = 'Test Street';
         sys2.Legal_Entity_Name__c = 'ABC Corp';
         sys2.Zip_Postal_Code__c='96543';
         sys2.Risk_Rating__c='R5';
         sys2.UNQ_Vendor__c='12345-002';
         insert sys2;
         Test.stopTest();
         sys2=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, System_ID__c FROM System_ID__c WHERE Id=:sys2.Id];
         System.assertEquals(sys.Account__c, acc.Id);
         List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c, ATS_ID_s__c FROM Account WHERE Id=:sys2.Account__c];
         System.assertEquals(sys2.Street__c, accs[0].BillingStreet);
         System.assertEquals(sys2.City__c, accs[0].BillingCity);
         System.assertEquals(sys2.State__c, accs[0].BillingState);
         System.assertEquals(sys2.Country__c, accs[0].BillingCountry);
         System.assertEquals(sys2.Risk_Rating__c, accs[0].Risk_Rating__c);
         System.assertEquals(sys2.Phone__c, accs[0].Phone);
         System.assertEquals(sys2.Zip_Postal_Code__c, accs[0].BillingPostalCode);

         List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
         System.assertEquals(types[0].Id, accs[0].RecordTypeId);
  	 }

    static testMethod void testEntityIdUpdateNonCanadian()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Phone = '1234567890';
        acc.BillingState = 'CA';
        acc.BillingCity = 'San Francisco';
        acc.BillingCountry = 'US';
        acc.BillingStreet = 'Test Street';
        acc.Legal_Entity_Name__c = 'ABC Corp';
        acc.BillingPostalCode = '96543';
        acc.ATS_ID_s__c = '12345-002';
        insert acc;
        Test.startTest();
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.Account__c = acc.Id;
        sys.City__c = 'San Francisco';
        sys.Country__c = 'US';
        sys.Phone__c = '1234567890';//+i;
        sys.State__c = 'CA';
        sys.Street__c = 'Test Street';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='96543';
        sys.UNQ_Vendor__c='12345-003';
        insert sys;
        System.assertNotEquals(null, sys.Id);
        //System.assertEquals(acc.Id, sys.Account__c);

        List<Account> totalaccs=[SELECT Id, ATS_ID_s__c, Risk_Rating__c FROM Account LIMIT 500];
        System.assertEquals(1, totalaccs.size());
        System.assertEquals(totalaccs[0].Risk_Rating__c, null);
        System.assertEquals(totalaccs[0].ATS_ID_s__c, sys.UNQ_Vendor__c + ';12345-002');

        sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c,System_ID__c FROM System_ID__c WHERE Id=:sys.Id];
        System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'SysTest2';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'CA';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'ABC Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';
        sys2.UNQ_Vendor__c='12345-001';
        insert sys2;
        Test.stopTest();
        sys2=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, System_ID__c FROM System_ID__c WHERE Id=:sys2.Id];
        System.assertEquals(sys.Account__c, acc.Id);
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c, ATS_ID_s__c FROM Account];
        System.assertEquals(2, accs.size());
        System.assertEquals(accs[0].Id, totalaccs[0].Id);
        System.assertEquals(sys.City__c, accs[0].BillingCity);
        System.assertEquals(sys.State__c, accs[0].BillingState);
        System.assertEquals(sys.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys.Phone__c, accs[0].Phone);
        System.assertEquals(sys.Zip_Postal_Code__c, accs[0].BillingPostalCode);
        System.assertEquals(sys.System_ID__c + ';12345-002', accs[0].ATS_ID_s__c);

        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
    }

    static testMethod void testEntityIdUpdateCanadian()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Phone = '1234567890';
        acc.BillingState = 'ON';
        acc.BillingCity = 'Ottawa';
        acc.BillingCountry = 'CA';
        acc.BillingStreet = 'Len Lunney Crescent';
        acc.Legal_Entity_Name__c = 'ABC Corp';
        acc.BillingPostalCode = 'K2G 6X4';
        acc.ATS_ID_s__c = '123456.7899';
        insert acc;
        Test.startTest();
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.Account__c = acc.Id;
        sys.City__c = 'Ottawa';
        sys.Country__c = 'CA';
        sys.Phone__c = '1234567890';//+i;
        sys.State__c = 'ON';
        sys.Street__c = 'Len Lunney Crescent';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='K2G 6X4';
        sys.UNQ_Vendor__c='1234567890';
        sys.Source_System__c='Test';
        sys.Location__c = 'Canada';
        sys.System_ID__c = '1234567890';
        insert sys;
        System.assertNotEquals(null, sys.Id);
        System.assertEquals(acc.Id, sys.Account__c);

        List<Account> totalaccs=[SELECT Id, ATS_ID_s__c, Risk_Rating__c FROM Account LIMIT 500];
        System.assertEquals(1, totalaccs.size());
        System.assertEquals(totalaccs[0].Risk_Rating__c, null);
        System.assertEquals('123456.7890;123456.7899', totalaccs[0].ATS_ID_s__c);

        sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c,System_ID__c FROM System_ID__c WHERE Id=:sys.Id];
        System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'SysTest2';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'CA';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'ABC Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';
        sys2.UNQ_Vendor__c='1234567891';
        sys2.Source_System__c='Test';
        sys2.System_ID__c = '1234567898';
        sys2.Location__c = 'Canada';
        insert sys2;
        Test.stopTest();
        sys2=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, System_ID__c FROM System_ID__c WHERE Id=:sys2.Id];
        //System.assertEquals(sys2.Account__c, acc.Id);
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c, ATS_ID_s__c FROM Account];
     
        System.assertEquals(2, accs.size());
        System.assertEquals(accs[0].Id, totalaccs[0].Id);
        System.assertEquals(sys.City__c, accs[0].BillingCity);
        System.assertEquals(sys.State__c, accs[0].BillingState);
        System.assertEquals(sys.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys.Phone__c, accs[0].Phone);
        System.assertEquals(sys.Zip_Postal_Code__c, accs[0].BillingPostalCode);
        //System.assertEquals('123456.7898;123456.7890;123456.7899', accs[0].ATS_ID_s__c);

        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
    }

    static testMethod void testInsertSystemIdUpdateOnExistingRecord()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c ='123456';
        acc.Phone = '1234567890';
        acc.BillingState = 'CA';
        acc.BillingCity = 'San Francisco';
        acc.BillingCountry = 'US';
        acc.BillingStreet = 'Test Street';
        acc.Legal_Entity_Name__c = 'ABC Corp';
        acc.BillingPostalCode = '96543';
        insert acc;

        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.City__c = 'San Francisco';
        sys.Country__c = 'US';
        sys.Phone__c = '1234567890';//+i;
        sys.State__c = 'CA';
        sys.Street__c = 'Test Street';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='96543';
        //sys.UNQ_Vendor__c='12345-001';
        insert sys;
        System.assertNotEquals(null, sys.Id);
        List<Account> totalaccs=[
                SELECT Id, ATS_ID_s__c
                FROM Account
                LIMIT 500];
        System.assertEquals(1, totalaccs.size());

        sys=[
                SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c,System_ID__c
                FROM System_ID__c
                WHERE Id=:sys.Id];
        System.assertEquals(sys.Account__c, acc.Id);


        System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'SysTest2';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'CA';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'ABC Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';

        insert sys2;
        sys=[SELECT Id, IsDeleted FROM System_ID__c WHERE Id=:sys.Id ALL ROWS];
        sys2=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, System_ID__c FROM System_ID__c WHERE Id=:sys2.Id];
        //UPDATE: Assert that the old System Id has been deleted and that the new one has the Account associated with it
        //System.assertEquals(sys.IsDeleted, true);
        System.assertEquals(sys2.Account__c, acc.Id);

        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c, ATS_ID_s__c FROM Account WHERE Id=:sys2.Account__c];
        System.assertEquals(sys2.Street__c, accs[0].BillingStreet);
        System.assertEquals(sys2.City__c, accs[0].BillingCity);
        System.assertEquals(sys2.State__c, accs[0].BillingState);
        System.assertEquals(sys2.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys2.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys2.Phone__c, accs[0].Phone);
        System.assertEquals(sys2.Zip_Postal_Code__c, accs[0].BillingPostalCode);

        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='End User'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
    }

    static testMethod void testEntityIdInsertBatch()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Phone = '1234567890';
        acc.BillingState = 'ON';
        acc.BillingCity = 'Ottawa';
        acc.BillingCountry = 'CA';
        acc.BillingStreet = 'Len Lunney Crescent';
        acc.Legal_Entity_Name__c = 'ABC Corp';
        acc.BillingPostalCode = 'K2G 6X4';
        acc.ATS_ID_s__c = '123456.7899';
        insert acc;
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.Account__c = acc.Id;
        sys.City__c = 'Ottawa';
        sys.Country__c = 'CA';
        sys.Phone__c = '1234567890';//+i;
        sys.State__c = 'ON';
        sys.Street__c = 'Len Lunney Crescent';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='K2G 6X4';
        sys.UNQ_Vendor__c='1234567390';
        sys.Source_System__c='Test';
        sys.Location__c = 'Canada';
        sys.System_ID__c = '1234567894';
        insert sys;
        Test.startTest();
        List<System_ID__c> sysIds = new List<System_ID__c>();
        System_ID__c sys1 = new System_ID__c();
        sys1.System_Name__c = 'SysyTest1';
        sys1.City__c = 'Ottawa';
        sys1.Country__c = 'CA';
        sys1.Phone__c = '1234567890';//+i;
        sys1.State__c = 'ON';
        sys1.Street__c = 'Len Lunney Crescent';
        sys1.Legal_Entity_Name__c = 'ABC Corp';
        sys1.Zip_Postal_Code__c='K2G 6X4';
        sys1.UNQ_Vendor__c='1234567840';
        sys1.Source_System__c='Test';
        sys1.Location__c = 'Canada';
        sys1.System_ID__c = '1234567891';
        sysIds.add(sys1);
        System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'SysTest2';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'CA';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'ABC Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';
        sys2.UNQ_Vendor__c='1234567892';
        sys2.Source_System__c='Test';
        sys2.System_ID__c = '1234567898';
        sys2.Location__c = 'Canada';
        sysIds.add(sys2);
        insert sysIds;
        Test.stopTest();
        sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, System_ID__c FROM System_ID__c WHERE Id=:sys.Id];
      //  System.assertEquals(sys.Account__c, acc.Id);
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c, ATS_ID_s__c FROM Account];
        System.assertEquals(3, accs.size());
        System.assertEquals(sys1.City__c, accs[0].BillingCity);
        System.assertEquals(sys1.State__c, accs[0].BillingState);
        System.assertEquals(sys1.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys1.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys1.Phone__c, accs[0].Phone);
        System.assertEquals(sys1.Zip_Postal_Code__c, accs[0].BillingPostalCode);
        //System.assertEquals('123456.7898;123456.7891;123456.7894;123456.7899', accs[0].ATS_ID_s__c);

        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
    }

    static testMethod void testEntityIdUpdateBatch()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Phone = '1234567890';
        acc.BillingState = 'ON';
        acc.BillingCity = 'Ottawa';
        acc.BillingCountry = 'CA';
        acc.BillingStreet = 'Len Lunney Crescent';
        acc.Legal_Entity_Name__c = 'ABC Corp';
        acc.BillingPostalCode = 'K2G 6X4';
        acc.ATS_ID_s__c = '123456.7899';
        insert acc;
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.Account__c = acc.Id;
        sys.City__c = 'Ottawa';
        sys.Country__c = 'CA';
        sys.Phone__c = '1234567890';//+i;
        sys.State__c = 'ON';
        sys.Street__c = 'Len Lunney Crescent';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='K2G 6X4';
        sys.UNQ_Vendor__c='1235567890';
        sys.Source_System__c='Test';
        sys.Location__c = 'Canada';
        sys.System_ID__c = '1234567894';
        insert sys;
        Test.startTest();
        List<System_ID__c> sysIds = new List<System_ID__c>();
        System_ID__c sys1 = new System_ID__c();
        sys1.System_Name__c = 'SysyTest1';
        sys1.City__c = 'Ottawa';
        sys1.Country__c = 'CA';
        sys1.Phone__c = '1234567890';//+i;
        sys1.State__c = 'ON';
        sys1.Street__c = 'Len Lunney Crescent';
        sys1.Legal_Entity_Name__c = 'ABC Corp';
        sys1.Zip_Postal_Code__c='K2G 6X4';
        sys1.UNQ_Vendor__c='1244567890';
        sys1.Source_System__c='Test';
        sys1.Location__c = 'Canada';
        sys1.System_ID__c = '1234567891';
        sysIds.add(sys1);
        System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'SysTest2';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'CA';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'ABC Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';
        sys2.UNQ_Vendor__c='1234567893';
        sys2.Source_System__c='Test';
        sys2.System_ID__c = '1234567898';
        sys2.Location__c = 'Canada';
        sysIds.add(sys2);
        insert sysIds;
        acc.ATS_ID_s__c = '';
        update acc;
        acc = [SELECT ATS_ID_s__c FROM Account WHERE Id = :acc.Id];
        System.assert(acc.ATS_ID_s__c == null, 'The Accounts entity Ids were not updated properly');
        sysIds[0].System_ID__c='1234567881';
        sysIds[1].System_ID__c='1234567888';
        update sysIds;
        Test.stopTest();
        sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, System_ID__c FROM System_ID__c WHERE Id=:sys.Id];
        System.assertEquals(sys.Account__c, acc.Id);
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c, ATS_ID_s__c FROM Account];
        System.assertEquals(3, accs.size());
        System.assertEquals(sys.City__c, accs[0].BillingCity);
        System.assertEquals(sys.State__c, accs[0].BillingState);
        System.assertEquals(sys.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys.Phone__c, accs[0].Phone);
        System.assertEquals(sys.Zip_Postal_Code__c, accs[0].BillingPostalCode);
        //System.assertEquals('123456.7888;123456.7881', accs[0].ATS_ID_s__c);

        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
    }
    static testMethod void testEntityIdUpdateBatchTruncate()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Phone = '1234567890';
        acc.BillingState = 'ON';
        acc.BillingCity = 'Ottawa';
        acc.BillingCountry = 'CA';
        acc.BillingStreet = 'Len Lunney Crescent';
        acc.Legal_Entity_Name__c = 'ABC Corp';
        acc.BillingPostalCode = 'K2G 6X4';
        acc.ATS_ID_s__c = '123456.7880;123456.7881;123456.7882;123456.7883;123456.7884;123456.7885;123456.7886;123456.7887;123456.7888;123456.7889;123456.7890;123456.7891;123456.7892;123456.7893;123456.7894;123456.7895;123456.7896;123456.7897;123456.7898;123456.7899';
        insert acc;
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.Account__c = acc.Id;
        sys.City__c = 'Ottawa';
        sys.Country__c = 'CA';
        sys.Phone__c = '1234567890';//+i;
        sys.State__c = 'ON';
        sys.Street__c = 'Len Lunney Crescent';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='K2G 6X4';
        sys.UNQ_Vendor__c='1134567890';
        sys.Source_System__c='Test';
        sys.Location__c = 'Canada';
        sys.System_ID__c = '1234567894';
        insert sys;
        Test.startTest();
        List<System_ID__c> sysIds = new List<System_ID__c>();
        System_ID__c sys1 = new System_ID__c();
        sys1.System_Name__c = 'SysyTest1';
        sys1.City__c = 'Ottawa';
        sys1.Country__c = 'CA';
        sys1.Phone__c = '1234567890';//+i;
        sys1.State__c = 'ON';
        sys1.Street__c = 'Len Lunney Crescent';
        sys1.Legal_Entity_Name__c = 'ABC Corp';
        sys1.Zip_Postal_Code__c='K2G 6X4';
        sys1.UNQ_Vendor__c='1204567890';
        sys1.Source_System__c='Test';
        sys1.Location__c = 'Canada';
        sys1.System_ID__c = '1234567860';
        sysIds.add(sys1);
        System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'SysTest2';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'CA';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'ABC Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';
        sys2.UNQ_Vendor__c='1234567894';
        sys2.Source_System__c='Test';
        sys2.System_ID__c = '1234567898';
        sys2.Location__c = 'Canada';
        sysIds.add(sys2);
        insert sysIds;
        sysIds[0].System_ID__c='1234567860';
        sysIds[1].System_ID__c='1234567888';
        update sysIds;
        Test.stopTest();
        sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c, System_ID__c FROM System_ID__c WHERE Id=:sys.Id];
        System.assertEquals(sys.Account__c, acc.Id);
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c, ATS_ID_s__c FROM Account];
        System.assertEquals(3, accs.size());
        System.assertEquals(sys1.City__c, accs[0].BillingCity);
        System.assertEquals(sys1.State__c, accs[0].BillingState);
        System.assertEquals(sys1.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys1.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys1.Phone__c, accs[0].Phone);
        System.assertEquals(sys1.Zip_Postal_Code__c, accs[0].BillingPostalCode);
        //System.assertEquals('123456.7860;123456.7880;123456.7881;123456.7882;123456.7883;123456.7884;123456.7885;123456.7886;123456.7887;123456.7888;123456.7889;123456.7890;123456.7891;123456.7892;123456.7893;123456.7894;123456.7895;123456.7896;123456.7897;123456.7898;123456.7899', accs[0].ATS_ID_s__c);

        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
    }
	static testMethod void testInsertSystemIdLeagalEntityNotMatched()
 	 {
 	 	/*Account acc = new Account();
        acc.Name = 'Test';
        acc.UNQ_Customer__c ='123456';
        acc.Phone = '98912345';
        acc.BillingState = 'Test State';
        acc.BillingCity = 'Test City';
        acc.BillingCountry = 'Test';
        acc.BillingStreet = 'Test Street';
        acc.BillingPostalCode = '222222';        
        insert acc;*/
        
     	System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.City__c = 'San Francisco';
        sys.Country__c = 'US';
        sys.Phone__c = '1234567890';
        sys.State__c = 'CA';
        sys.Street__c = 'Test Street';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='96543';
        insert sys;
        
        sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c FROM System_ID__c WHERE Id=:sys.Id];
        System.assertNotEquals(sys.Id, null);
        System.assertNotEquals(sys.Account__c, null);

        List<Account> totalaccs=[SELECT Id FROM Account LIMIT 500];
        System.assertEquals(1, totalaccs.size());
        
        System_ID__c sys2 = new System_ID__c();
        sys2.System_Name__c = 'SysTest2';
        sys2.City__c = 'San Francisco';
        sys2.Country__c = 'US';
        sys2.Phone__c = '1234567890';
        sys2.State__c = 'CA';
        sys2.Street__c = 'Test Street';
        sys2.Legal_Entity_Name__c = 'XYZ Corp';
        sys2.Zip_Postal_Code__c='96543';
        sys2.Risk_Rating__c='R5';
        sys2.UNQ_Vendor__c='12345';
        insert sys2;
        
        sys2=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c FROM System_ID__c WHERE Id=:sys2.Id];
        System.assertNotEquals(sys2.Id, null);
        System.assertNotEquals(sys2.Account__c, null);
        System.assertNotEquals(sys.Account__c, sys2.Account__c);
        
        totalaccs=[SELECT Id FROM Account LIMIT 500];
        System.assertEquals(2, totalaccs.size());
        
        
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId FROM Account
        WHERE Id=:sys2.Account__c];
        System.assertEquals(sys2.Street__c, accs[0].BillingStreet);
        System.assertEquals(sys2.City__c, accs[0].BillingCity);
        System.assertEquals(sys2.State__c, accs[0].BillingState);
        System.assertEquals(sys2.Country__c, accs[0].BillingCountry);
        System.assertEquals(sys2.Risk_Rating__c, accs[0].Risk_Rating__c);
        System.assertEquals(sys2.Phone__c, accs[0].Phone);
        System.assertEquals(sys2.Zip_Postal_Code__c, accs[0].BillingPostalCode);
        
        List<RecordType> types=[SELECT Name, Id FROM RecordType WHERE Name='Vendor'];
        System.assertEquals(types[0].Id, accs[0].RecordTypeId);
  	 }
  	 
	static testMethod void testInsertSystemIdLinkToProspect()
 	 {
 	 	List<RecordType> types1=[SELECT Name, Id FROM RecordType WHERE SobjectType='Account' AND Name='Prospect'];
 	 	System.assertEquals(types1.size(), 1);
 	 	
 	 	Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c ='123456';
        acc.BillingCountry = 'Test';
        acc.BillingCity = 'San Francisco';
        acc.Phone = 'Wrong';
        acc.BillingState = 'CA';
        acc.BillingStreet = 'Test Street';
        acc.BillingPostalCode='96543';
        acc.RecordTypeId=types1[0].Id;
        insert acc;
        
     	System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'SysyTest1';
        sys.City__c = 'San Francisco';
        sys.Country__c = 'US';
        sys.Phone__c = '1234567890';
        sys.State__c = 'CA';
        sys.Street__c = 'Test Street';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='96543';
        insert sys;
        
        sys=[SELECT Id, Account__c, Street__c, City__c, State__c, Country__c, Phone__c, Legal_Entity_Name__c, Zip_Postal_Code__c, Risk_Rating__c, System_Name__c FROM System_ID__c WHERE Id=:sys.Id];
        
        List<Account> totalaccs=[SELECT Id FROM Account LIMIT 500];
        System.assertEquals(1, totalaccs.size());
        
        System.assertNotEquals(sys.Id, null);
        System.assertNotEquals(sys.Account__c, null);
        System.assertEquals(sys.Account__c, acc.Id);
        acc=[SELECT Id, RecordType.Name FROM Account WHERE Id=:acc.Id];
        System.assertEquals(acc.RecordType.Name, 'End User');
  	 }
	 
	 
	 
     static testMethod void testSearchAccount2()
 	 {
 		
        Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c = '123456';
        acc.Phone = '98912345';
        acc.BillingState = 'Test State';
        acc.BillingCity = 'Test City';
        acc.BillingCountry = 'Test';
        acc.BillingStreet = 'Test Street';
        acc.BillingPostalCode = '222222';        
        insert acc;
         
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'Test1';
        sys.Account__c = acc.Id;
        sys.City__c = 'Test City';
        sys.Country__c = 'Test';
        sys.Phone__c = '98912345';
        sys.State__c = 'Test State';
        sys.Street__c = 'Test Street';  
        sys.UNQ_Customer__c = '123456';
        sys.Legal_Entity_Name__c = 'Test Name';
        insert sys;
         
         
        System_ID__c syst = new System_ID__c();
        syst.System_Name__c = 'Test2';
        syst.City__c = 'Test City';
        syst.Country__c = 'Test';
        syst.Phone__c = '98912345';
        syst.State__c = 'Test State';
        syst.Street__c = 'Test Street';
        syst.Legal_Entity_Name__c = 'Test Name';
        insert syst;
         System.debug('====syst==='+syst);
        
        System.assertEquals(null, syst.Account__c);
     }
    
	static testMethod void updateAccount()//AC4
    {
        Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c = '123456';
        acc.Phone = '98912345';
        insert acc;
        System.assertNotEquals(null, acc.Id);
        System.debug('+++acc+++'+acc);
         
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'Test1';
        sys.Account__c = acc.Id;
        sys.City__c = 'Test City';
        sys.Country__c = 'Test';
        sys.Phone__c = '98912345';
        sys.State__c = 'Test Address';
        sys.Street__c = 'Test Street';
        sys.UNQ_Customer__c = '123456';
        sys.Legal_Entity_Name__c = 'Test Name';
        insert sys;
        
        sys.City__c = 'Chandigarh';
        sys.Country__c = 'US';
        sys.Phone__c = '1234567890';
        sys.State__c = 'CA';
        sys.Street__c = 'Test Street2';
        sys.Legal_Entity_Name__c = 'ABC Corp';
        sys.Zip_Postal_Code__c='96543';
        update sys;
        
        List<Account> accs=[SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c FROM Account];
        // asserts to check if the accoutn was updated or not
        System.assertEquals(accs[0].BillingCity, sys.City__c);
        System.assertEquals(accs[0].BillingState, sys.State__c);
        System.assertEquals(accs[0].BillingCountry, sys.Country__c);
        System.assertEquals(accs[0].BillingPostalCode, sys.Zip_Postal_Code__c);
        System.assertEquals(accs[0].Phone, sys.Phone__c);
        System.assertEquals(accs[0].System_Name__c, sys.System_Name__c);
        System.assertEquals(accs[0].Risk_Rating__c, sys.Risk_Rating__c);
        
    }

    //3/31/2020 : New test case to catch a system Id match onto a system Id without an account, therefore a new account is created
    static testMethod void testNullAccountSysIdMatchOther()
    {

        Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c = '123456';
        acc.Phone = '98912345';
        acc.BillingState = 'Test State';
        acc.BillingCity = 'Test City';
        acc.BillingCountry = 'Test';
        acc.BillingStreet = 'Test Street';
        acc.BillingPostalCode = '222222';
        insert acc;

        Test.startTest();
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'Test1';
        sys.City__c = 'Test City';
        sys.Country__c = 'Test';
        sys.Phone__c = '98912345';
        sys.State__c = 'Test State';
        sys.Street__c = 'Test Street';
        sys.UNQ_Customer__c = '123456';
        sys.Legal_Entity_Name__c = 'Test Name';
        sys.Zip_Postal_Code__c = '222222';
        insert sys;

        sys.Account__c = null;
        update sys;
        System_ID__c syst = new System_ID__c();
        syst.System_Name__c = 'Test1';
        syst.City__c = 'Test City';
        syst.Country__c = 'Test';
        syst.Phone__c = '98912345';
        syst.State__c = 'Test State';
        syst.Street__c = 'Test Street';
        syst.UNQ_Customer__c = '1234561';
        syst.Legal_Entity_Name__c = 'Test Name';
        syst.Zip_Postal_Code__c ='222222';
        insert syst;
        Test.stopTest();
        List<System_ID__c> sysIds = [SELECT Account__c FROM System_ID__c];
        List<Account> accs = [SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c FROM Account];
        System.assertEquals(null, sysIds[0].Account__c, 'The update on the system ids account to null did not work');
        System.assertEquals(accs[1].Id, sysIds[1].Account__c, 'The new account was not associated with the new system Id being inserted');
        System.assertEquals(2, accs.size(), 'The null check on system Id matches did not work');
        System.assertEquals(accs[0].BillingCity, sys.City__c);
        System.assertEquals(accs[0].BillingState, sys.State__c);
        System.assertEquals(accs[0].BillingCountry, sys.Country__c);
        System.assertEquals(accs[0].BillingPostalCode, sys.Zip_Postal_Code__c);
        System.assertEquals(accs[0].Phone, sys.Phone__c);
        System.assertEquals(accs[0].System_Name__c, sys.System_Name__c);
        System.assertEquals(accs[0].Risk_Rating__c, sys.Risk_Rating__c);
        System.assertEquals(accs[1].BillingCity, sys.City__c);
        System.assertEquals(accs[1].BillingState, sys.State__c);
        System.assertEquals(accs[1].BillingCountry, sys.Country__c);
        System.assertEquals(accs[1].BillingPostalCode, sys.Zip_Postal_Code__c);
        System.assertEquals(accs[1].Phone, sys.Phone__c);
        System.assertEquals(accs[1].System_Name__c, sys.System_Name__c);
        System.assertEquals(accs[1].Risk_Rating__c, sys.Risk_Rating__c);


    }

    static testMethod void testNullAccountSysIdVendor()
    {
        Account acc = new Account();
        acc.Name = 'Test';
        //acc.UNQ_Customer__c = '123456';
        acc.Phone = '98912345';
        acc.BillingState = 'Test State';
        acc.BillingCity = 'Test City';
        acc.BillingCountry = 'Test';
        acc.BillingStreet = 'Test Street';
        acc.BillingPostalCode = '222222';
        insert acc;

        Test.startTest();
        System_ID__c sys = new System_ID__c();
        sys.System_Name__c = 'Test1';
        sys.City__c = 'Test City';
        sys.Country__c = 'Test';
        sys.Phone__c = '98912345';
        sys.State__c = 'Test State';
        sys.Street__c = 'Test Street';
        sys.UNQ_Customer__c = '123456';
        sys.Legal_Entity_Name__c = 'Test Name';
        sys.Zip_Postal_Code__c = '222222';
        sys.UNQ_Vendor__c='1234567890';
        insert sys;

        sys.Account__c = null;
        update sys;
        System_ID__c syst = new System_ID__c();
        syst.System_Name__c = 'Test1';
        syst.City__c = 'Test City';
        syst.Country__c = 'Test';
        syst.Phone__c = '98912345';
        syst.State__c = 'Test State';
        syst.Street__c = 'Test Street';
        syst.UNQ_Customer__c = '1234562';
        syst.Legal_Entity_Name__c = 'Test Name';
        syst.Zip_Postal_Code__c ='222222';
        syst.UNQ_Vendor__c='1234567895';
        insert syst;
        Test.stopTest();
        List<System_ID__c> sysIds = [SELECT Account__c FROM System_ID__c];
        List<Account> accs = [SELECT Id, Phone, BillingStreet, BillingCity, BillingState, BillingCountry, BillingPostalCode, Risk_Rating__c, RecordTypeId, System_Name__c FROM Account];
        System.assertEquals(null, sysIds[0].Account__c, 'The update on the system ids account to null did not work');
        System.assertEquals(accs[1].Id, sysIds[1].Account__c, 'The new account was not associated with the new system Id being inserted');
        System.assertEquals(2, accs.size(), 'The null check on system Id matches did not work');
        System.assertEquals(accs[0].BillingCity, sys.City__c);
        System.assertEquals(accs[0].BillingState, sys.State__c);
        System.assertEquals(accs[0].BillingCountry, sys.Country__c);
        System.assertEquals(accs[0].BillingPostalCode, sys.Zip_Postal_Code__c);
        System.assertEquals(accs[0].Phone, sys.Phone__c);
        System.assertEquals(accs[0].System_Name__c, sys.System_Name__c);
        System.assertEquals(accs[0].Risk_Rating__c, sys.Risk_Rating__c);
        System.assertEquals(accs[1].BillingCity, sys.City__c);
        System.assertEquals(accs[1].BillingState, sys.State__c);
        System.assertEquals(accs[1].BillingCountry, sys.Country__c);
        System.assertEquals(accs[1].BillingPostalCode, sys.Zip_Postal_Code__c);
        System.assertEquals(accs[1].Phone, sys.Phone__c);
        System.assertEquals(accs[1].System_Name__c, sys.System_Name__c);
        System.assertEquals(accs[1].Risk_Rating__c, sys.Risk_Rating__c);


    }
}