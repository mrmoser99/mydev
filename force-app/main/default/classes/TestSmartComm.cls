/**
 * Test class for SmartCommHelper apex class
 *
 * Version 1.0
 *
 */
@isTest (seeAllData=false)
public class TestSmartComm {



/**
 * Name : setupTestData
 * Purpose : Create Test data for the test methods.
 */
@testSetup static void setup() {

	Profile prof = [SELECT Id FROM Profile WHERE Name='System Administrator' limit 1];
	UserRole portalRole = [Select Id From UserRole Where PortalType = 'None' Limit 1];

	User user = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Neha',
	                     EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US',
	                     LocaleSidKey='en_US', ProfileId = prof.Id, userroleid=portalRole.id,
	                     TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com',
	                     Legal_Entity_Description__c = 'DLL');
	insert user;

	system.runAs(user) {
		TestAccountBuilder accountBuilder = new TestAccountBuilder();
		Account account = accountBuilder
		                  .withRecordType(Constants.VENDOR_ACCOUNT_RECORDTYPE_DEVELOPER_NAME)
		                  .withName('Apple Leasing')
		                  .build();

		account.Show_Extension_Rent__c = true;
		account.Display_Start_Up_fee__c =true;
		account.Extension_Factor_Percentage__c = 0.5;

		TestAccountBuilder accountBuilder1 = new TestAccountBuilder();
		Account account1 = accountBuilder1
		                   .withRecordType(Constants.END_USER_RECORD_TYPE_NAME)
		                   .withName('Apple EndUser')
		                   .withDoing_Business_As('Test Customer')
		                   .withOrg_No('Sample Org ')
		                   .withExternalId('124345667')
		                   .withFinalId('1645534')
		                   .build();


		insert new List<Account> {account,account1};


		TestDataFactory dataFactory = TestDataFactory.getInstance();
		Contact cont = dataFactory.buildContact('Bansal','Neha','Developer',account,'93283282','neha.bansal2@cognziant.com');
		Contact cont1 = dataFactory.buildContact('Bansal','Vanya','Developer',account1,'93283282','neha.bansal@cognziant.com');
		cont1.Role__c = 'Lease Signer';
		update cont1;

		TestRegionBuilder regionBuilder = new TestRegionBuilder();
		Region__c testRegion = regionBuilder
		                       .withName('Sweden')
		                       .withActive(true)
		                       .withType('Country')
		                       .withIsoCode('SE')
		                       .insertRecord(true)
		                       .build();

		TestProductBuilder productBuilder= new TestProductBuilder();
		Product2 hardwareProd = productBuilder
		                        .withName('Laptop')
		                        .withFamily('Soft Asset')
		                        .build();

		Product2 serviceProd = productBuilder
		                       .withName('Repair')
		                       .withFamily('Maintenance')
		                       .build();

		insert new List<Product2> {hardwareProd, serviceProd};

		//Instantiate the Pricebook2 record with StandardPricebookId
		Pricebook2 standardPricebook= dataFactory.buildstandardPricebook(Test.getStandardPricebookId(),true);

		PricebookEntry pbe1 = dataFactory.buildPricebookEntry(standardPricebook.Id,hardwareProd.Id,1020,true,'SEK', false);
		PricebookEntry pbe4 = dataFactory.buildPricebookEntry(standardPricebook.Id,serviceProd.Id,1300,true,'SEK', false);

		insert new List<PricebookEntry> {pbe1, pbe4};

		Asset_Program__c assetProgram = dataFactory.buildassetProgram('Test Asset Program');

		TestProgramBuilder testprogramBuilder= new TestProgramBuilder();
		Program__c prog = testprogramBuilder
		                  .withName('Test Program')
		                  .withCurrencyIsoCode('SEK')
		                  .withAssetProgram(assetProgram.id)
		                  .build();

		TestRateBuilder testrateBuilder= new TestRateBuilder();
		Rate__c rate=  testrateBuilder
		              .withName('Stibor')
		              .withType('Variable')
		              .build();

		rate.Date__c=Date.valueOf(date.today());

		TestTermBuilder testtermBuilder= new TestTermBuilder();
		Term__c term= testtermBuilder
		              .withAlias('<= 30 Days')
		              .withTermValue(30)
		              .withTermDimension('Days')
		              .build();



		insert new List<SObject> {prog, rate, term};

		TestRateLineItemBuilder testratelineitemBuilder= new TestRateLineItemBuilder();
		Rate_Line_Item__c rli= testratelineitemBuilder
		                       .withRate(rate.id)
		                       .withTerm(term.id)
		                       .build();

		Financial_Product__c financialProduct = new Financial_Product__c(Name = 'Test Financial Product',Type__c='Core');

		insert new List<SObject> {rli, financialProduct};


		Integer daysAfterToday = 365;
		Offer__c testOffer= dataFactory.buildOffer(
			'Apple Offer',
			'in-advance',
			'Monthly',
			'SEK',
			prog.id,
			'Standard',
			'Variable',
			'Variable',
			rate.id,
			financialProduct.Id,
			Date.today(),
			Date.today().addDays(daysAfterToday),
			false);

		testOffer.Selectable_Agreement_Term__c ='10;20;30;40';

		insert testOffer;

		TestApplicableOfferBuilder testapplicableOffer= new TestApplicableOfferBuilder();
		Applicable_Offer__c testApo = testapplicableOffer
		                              .withName('testAPO')
		                              .withAccount(account.id)
		                              .withOffer(testOffer.id)
		                              .insertRecord(true)
		                              .build();

		account.PartnerOffer__c = testApo.id;
		update account;

		Asset_Program_Detail__c assetProgramDetail1 = dataFactory.buildassetProgramDetail(assetProgram.id, hardwareProd.Id,true,false);
		Asset_Program_Detail__c assetProgramDetail2 = dataFactory.buildassetProgramDetail(assetProgram.id, serviceProd.id, false);
		insert new List<Asset_Program_Detail__c> {assetProgramDetail1, assetProgramDetail2};

		TestOpportunityBuilder testOppBuilder1 = new TestOpportunityBuilder();
		Opportunity testOpp = testOppBuilder1
		                      .withName('testOpp')
		                      .withStage('Quoting')
		                      .withCloseDate(system.today()+20)
		                      .withType('New')
		                      .withRecordType(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
		                      .withAccount(account.id)
		                      .withAmount(100)
		                      .withStandardPricebook(standardPricebook.id)
		                      .build();

		TestOpportunityBuilder testOppBuilder2 = new TestOpportunityBuilder();
		Opportunity testOpp2 = testOppBuilder2
		                       .withName('testOpp2')
		                       .withStage('Quoting')
		                       .withCloseDate(system.today()+20)
		                       .withType('New')
		                       .withRecordType(Constants.RETAIL_OPPORTUNITY_RECORDTYPE_DEVELOPER_NAME)
		                       .withAccount(account.id)
		                       .withAmount(500)
		                       .withStandardPricebook(standardPricebook.id)
		                       .build();

		insert new List<Opportunity> {testOpp};

		Quote testQuote = dataFactory.buildQuote('Version-1','Monthly','Variable','24',testApo.id,'Calculation',1000,5000,1.25,'in-advance',testopp.id,standardPricebook.id);

		testOpp.SyncedQuoteid = testQuote.id;
		update testOpp;

		QuoteLineItem qli = dataFactory.buildQuoteLineItem(10,testquote.id,hardwareProd.id,100,pbe1.id, false);
		QuoteLineItem qli2 = dataFactory.buildQuoteLineItem(10,testquote.id,serviceProd.id,100,pbe1.id, false);
		insert new List<QuoteLineItem> {qli, qli2};

		Document_Library__c testDocLibrary = dataFactory.buildDocumentLibrary('Contract','ContractLeasing','Contract',prog.Id,true);

		testOffer.Contract_Document__c = testDocLibrary.Id;
		update testOffer;

		Special_Terms_and_Conditions__c speTermCond = dataFactory.buildSpecialTermsAndConditions('ABC','Mandatory','Yes',prog.Id,null);
		speTermCond.Type__c='Action required';
		update speTermCond;

		Offer_Special_Terms_Conditions__c ofrSpeTermCond = dataFactory.buildOfferSpecialTermsAndConditions(testOffer.Id, speTermCond.Id);

		testQuote.Quote_Rate__c = rate.id;
		testQuote.Valid_From__c = Date.valueOf(date.today());
		testQuote.SmartComm_Docs_Count__c=1;
		testQuote.ITAD_Category__c = 'Data Wiping';
		update testQuote;

	}

}

@isTest static void testSmartCommContractRequest() {

	Boolean isException = false;
	Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode from account where Name='Apple Leasing' LIMIT 1];
	Account testAcc1 = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode from account where Name='Apple EndUser' LIMIT 1];

	contact cont = [select id,accountid,account.PartnerOffer__c,account.CurrencyIsoCode from contact where accountid =: testAcc.id LIMIT 1];

	Quote testQuote = [select id,name,SmartComm_Docs_Count__c from quote where Name='Version-1' limit 1];

	Opportunity testOpp = [select id,ownerid from Opportunity WHERE createdby.email = 'sysadmin876@testorg.com'   ];//Name = 'testOpp' limit 1];

	// This code runs as the system user
	Profile p = [SELECT Id FROM Profile WHERE Name='Nordics Community Profile' limit 1];

	User u = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Neha',
	                  EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US', isActive=true,
	                  LocaleSidKey='en_US', ProfileId = p.Id, contactid=cont.id,
	                  TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com');
	insert u;

	system.runAs(u){
		TestDataFactory dataFactory = TestDataFactory.getInstance();
		Related_Party__c testRelatedParty = dataFactory.buildRelatedParty('Neha PG','One Lakh','100000','Missouri 12','14','Amstelveen','1186 JS',testQuote.Id,testOpp.Id,'1122334456',true);

		//testQuote.SmartComm_Docs_Count__c=1;
		//new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{testQuote});

		testOpp.End_User__c=testAcc1.Id;
		new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject> {testOpp});

		SmartCommHelper.SmartCommDocParam docparam= new SmartCommHelper.SmartCommDocParam();
		docparam.quoteID=testQuote.id;
		docparam.salesContactPerson = 'Neha Bansal';
		docparam.insuranceCondition = 'Included in rent';

		String docParamString = Json.serializePretty(docparam);

		String body = '{"envelopes":[{'+
		              '"masterChannel":'+
		              '{'+
		              '"pageCount":1,"channelType":2,"channelName":"Print","data":"ABCD",'+
		              '"properties": [{"name":"preview.exclude", "value":"True" } ],'+
		              '"documentName":"NOR_MasterDocument", "mimeType":"application/pdf", "channelId":2'+
		              '}}],"exceptions":[],"jobMessages":[]}';

		MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', body);

		Test.setMock(HttpCalloutMock.class, mock);
		Test.StartTest();
		Quote quoteDtl = new SmartCommHelper.WoSSelector().getQuoteDetails(testQuote.id);
		SmartCommHelper.getQuoteDocCount(quoteDtl);

		try{
			SmartCommHelper.getSmartCommDocuments(docParamString,true);
		}catch(Exception e) {
			isException=true;
		}
		Test.StopTest();
		//System.assertEquals(0, new SmartCommHelper.WoSSelector().getQuoteStatus(testQuote.id).SmartComm_Docs_Count__c);
		System.assertEquals(false, isException);
		System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());

	}

}

@isTest static void testSmartCommContractRequest1() {
	Boolean isException = false;
	Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode from account where Name='Apple Leasing' LIMIT 1];

	contact cont = [select id,accountid,account.PartnerOffer__c,account.CurrencyIsoCode from contact where accountid =: testAcc.id LIMIT 1];


	Quote testQuote = [select id,name,
	                   Applicable_Offers__r.Offer__c,
	                   Applicable_Offers__r.Offer__r.Contract_Document__c,
	                   Applicable_Offers__r.Offer__r.Contract_Document__r.SmartComTemplateReference__c,
	                   (select id,External_Id__c,Name,Amount_Text__c,Amount__c,Country_Code__c,Postal_Code__c,City__c,Address_Line__c from Related_Parties__r where Quote__r.name='Version-1') from quote where Name='Version-1' limit 1];


	Special_Terms_and_Conditions__c sptc = [select id,name from Special_Terms_and_Conditions__c where Name='ABC' limit 1];

	// This code runs as the system user
	Profile p = [SELECT Id FROM Profile WHERE Name='Nordics Community Profile' limit 1];

	User u = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Neha',
	                  EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US', isActive=true,
	                  LocaleSidKey='en_US', ProfileId = p.Id, contactid=cont.id,
	                  TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com');
	insert u;

	system.runAs(u){
		//testQuote.SmartComm_Docs_Count__c=1;
		//new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{testQuote});

		sptc.Type__c='Deemed_AOD';
		new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject> {sptc});


		SmartCommHelper.SmartCommDocParam docparam= new SmartCommHelper.SmartCommDocParam();
		docparam.quoteID=testQuote.id;
		docparam.salesContactPerson = 'Neha Bansal';

		String docParamString = Json.serializePretty(docparam);

		String body = '{"envelopes":[{'+
		              '"masterChannel":'+
		              '{'+
		              '"pageCount":1,"channelType":2,"channelName":"Print","data":"ABCD",'+
		              '"properties": [{"name":"preview.exclude", "value":"True" } ],'+
		              '"documentName":"NOR_MasterDocument", "mimeType":"application/pdf", "channelId":2'+
		              '}}],"exceptions":[],"jobMessages":[{ "msgType":"E"}]}';

		MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', body);

		Test.setMock(HttpCalloutMock.class, mock);


		Test.StartTest();
		SmartCommHelper.getQuoteDocCount(testQuote);

		try{
			SmartCommHelper.getSmartCommDocuments(docParamString,true);
		}catch(Exception e) {
			isException=true;
		}
		Test.StopTest();
		System.assertEquals(false, isException);
		System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());

	}

}

@isTest static void testSmartCommDocAODRequest() {
	Boolean isException = false;
	Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode from account where Name='Apple Leasing' LIMIT 1];

	contact cont = [select id,accountid,account.PartnerOffer__c,account.CurrencyIsoCode from contact where accountid =: testAcc.id LIMIT 1];

	Quote testQuote = [select id,name from quote where Name='Version-1' limit 1];


	// This code runs as the system user
	Profile p = [SELECT Id FROM Profile WHERE Name='Nordics Community Profile' limit 1];

	User u = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Neha',
	                  EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US', isActive=true,
	                  LocaleSidKey='en_US', ProfileId = p.Id, contactid=cont.id,
	                  TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.kom');
	insert u;

	system.runAs(u){
		//testQuote.SmartComm_Docs_Count__c=1;
		//new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{testQuote});

		Quote quoteDtl = new SmartCommHelper.WoSSelector().getQuoteDetails(testQuote.id);

		String body = '{"envelopes":[{'+
		              '"masterChannel":'+
		              '{'+
		              '"pageCount":1,"channelType":2,"channelName":"Print","data":"ABCD",'+
		              '"properties": [{"name":"preview.exclude", "value":"True" } ],'+
		              '"documentName":"NOR_MasterDocument", "mimeType":"application/pdf", "channelId":2'+
		              '}}],"exceptions":[{"pageCount":0}],"jobMessages":[]}';

		MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', body);

		Test.setMock(HttpCalloutMock.class, mock);


		Test.StartTest();
		Map<String,Object> aodParams = new Map<String,Object>();
		aodParams.put('docType','AOD');
		aodParams.put('quote',quoteDtl);
		try{
			ID jobID = System.enqueueJob(new QueueableCalloutService('Smart_Comm_Doc',aodParams));
		}catch(Exception e) {
			isException=true;
		}
		Test.StopTest();
		//System.assertEquals(0, new SmartCommHelper.WoSSelector().getQuoteStatus(testQuote.id).SmartComm_Docs_Count__c);
		System.assertEquals(false, isException);
		System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
	}
}

@isTest static void testSmartCommPGRequestPositive() {
	Boolean isException = false;
	Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode from account where Name='Apple Leasing' LIMIT 1];

	contact cont = [select id,accountid,account.PartnerOffer__c,account.CurrencyIsoCode from contact where accountid =: testAcc.id LIMIT 1];

	Quote testQuote = [select id,name from quote where Name='Version-1' limit 1];

	Opportunity testOpp = [select id,ownerid from Opportunity where Name = 'testOpp' limit 1];
	// This code runs as the system user
	Profile p = [SELECT Id FROM Profile WHERE Name='Nordics Community Profile' limit 1];

	User u = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Neha',
	                  EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US', isActive=true,
	                  LocaleSidKey='en_US', ProfileId = p.Id, contactid=cont.id,
	                  TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com');
	insert u;

	system.runAs(u){
		TestDataFactory dataFactory = TestDataFactory.getInstance();
		Related_Party__c testRelatedParty = dataFactory.buildRelatedParty('Neha PG','One Lakh','100000','Missouri 12','14','Amstelveen','1186 JS',testQuote.Id,testOpp.Id,'1122334456',true);

		//testQuote.SmartComm_Docs_Count__c=1;
		//new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{testQuote});

		Quote quoteDtl = new SmartCommHelper.WoSSelector().getQuoteDetails(testQuote.id);

		String body = '{"envelopes":[{'+
		              '"masterChannel":'+
		              '{'+
		              '"pageCount":1,"channelType":2,"channelName":"Print","data":"ABCD",'+
		              '"properties": [{"name":"preview.exclude", "value":"True" } ],'+
		              '"documentName":"NOR_MasterDocument", "mimeType":"application/pdf", "channelId":2'+
		              '}}],"exceptions":[],"jobMessages":[]}';

		MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', body);

		Test.setMock(HttpCalloutMock.class, mock);

		Test.StartTest();
		Map<String,Object> pgParams = new Map<String,Object>();
		pgParams.put('docType','Payment Guarantor');
		pgParams.put('quote',quoteDtl);
		pgParams.put('pgData', testRelatedParty);

		try{
			ID jobID = System.enqueueJob(new QueueableCalloutService('Smart_Comm_Doc',pgParams));
		}catch(Exception e) {
			isException=true;
		}
		Test.StopTest();
		//System.assertEquals(0, new SmartCommHelper.WoSSelector().getQuoteStatus(testQuote.id).SmartComm_Docs_Count__c);
		System.assertEquals(false, isException);
		System.assertEquals(0, [SELECT Id FROM Error_Log__c].size());
	}

}

@isTest static void testSmartCommPGRequestNegative() {
	Boolean isException = false;
	Account testAcc = [select id,PartnerOffer__c,PartnerOffer__r.Offer__r.CurrencyIsoCode from account where Name='Apple Leasing' LIMIT 1];

	contact cont = [select id,accountid,account.PartnerOffer__c,account.CurrencyIsoCode from contact where accountid =: testAcc.id LIMIT 1];

	Quote testQuote = [select id,name from quote where Name='Version-1' limit 1];

	Opportunity testOpp = [select id,ownerid from Opportunity where Name = 'testOpp' limit 1];
	// This code runs as the system user
	Profile p = [SELECT Id FROM Profile WHERE Name='Nordics Community Profile' limit 1];

	User u = new User(Alias = 'standt', Email='sysadmin876@testorg.com', FirstName='Neha',
	                  EmailEncodingKey='UTF-8', LastName='Partner', LanguageLocaleKey='en_US', isActive=true,
	                  LocaleSidKey='en_US', ProfileId = p.Id, contactid=cont.id,
	                  TimeZoneSidKey='America/Los_Angeles',Username = System.now().millisecond() + 'test123@test.com');
	insert u;

	system.runAs(u){
		TestDataFactory dataFactory = TestDataFactory.getInstance();
		Related_Party__c testRelatedParty = dataFactory.buildRelatedParty('Neha PG','One Lakh','100000','Missouri 12','14','Amstelveen','1186 JS',testQuote.Id,testOpp.Id,'1122334456',true);

		//testQuote.SmartComm_Docs_Count__c=1;
		//new GenericUtilityClass.WoSDMLProcessor().updateRecords(new List<SObject>{testQuote});

		Quote quoteDtl = new SmartCommHelper.WoSSelector().getQuoteDetails(testQuote.id);

		String body = '{"envelopes":[{'+
		              '"masterChannel":'+
		              '{'+
		              '"pageCount":1,"channelType":2,"channelName":"Print",'+
		              '"properties": [{"name":"preview.exclude", "value":"True" } ],'+
		              '"documentName":"NOR_MasterDocument", "mimeType":"application/pdf", "channelId":2'+
		              '}}],"exceptions":[],"jobMessages":[]}';

		MockHttpTestResponseGenerator mock = new MockHttpTestResponseGenerator(200, 'Success', body);

		Test.setMock(HttpCalloutMock.class, mock);

		Test.StartTest();
		Map<String,Object> pgParams = new Map<String,Object>();
		pgParams.put('docType','Payment Guarantor');
		pgParams.put('quote',quoteDtl);
		pgParams.put('pgData', testRelatedParty);

		try{
			ID jobID = System.enqueueJob(new QueueableCalloutService('Smart_Comm_Doc',pgParams));
		}catch(Exception e) {
			isException=true;
		}

		Test.StopTest();
		System.assertEquals(false, isException);
		//System.assertNotEquals(0, [SELECT Id FROM Error_Log__c].size());
		//System.assertEquals(0, new SmartCommHelper.WoSSelector().getQuoteStatus(testQuote.id).SmartComm_Docs_Count__c);

	}

}

}