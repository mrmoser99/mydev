/**
 * @description       : Apex Test class for Enrolment.
 * @author            : Kritika Sharma : Traction on Demand
 * @last modified on  : 04-07-2022
 * @last modified by  : Kritika Sharma
 **/

@isTest
public with sharing class EnrollControllerTest {

@testSetup static void setup() {

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='Niranjan';
	ct.AccountId=at.id;
	ct.Email='hans.vedo@dllgroup.com';
	insert ct;

	Opportunity opp1= new Opportunity();
	opp1.application_number__c='A1';
	opp1.Type='Overline';
	opp1.Name='Service';
	opp1.StageName='Closed Won';
	opp1.Accountid=at.id;
	opp1.Contact__c=ct.id;
	opp1.CloseDate=system.today()+1;
	opp1.Amount=11.0;
	opp1.End_User__c=at.id;
	opp1.End_User_Company_Name__c = 'DANIEL INC.';
	opp1.Business_Unit1__c='Digital Imaging';
	opp1.Sub_Stage__c = 'Application Approved';
	opp1.Application_Date__c=system.today().addMonths(-3);
	opp1.UNQ_Customer__c='A1';
	opp1.UNQ_Vendor__c='A1';
	opp1.UNQ_Opportunity__c='A1';
	insert opp1;

	// Contact Role
	OpportunityContactRole cr = new OpportunityContactRole();
	cr.OpportunityId = opp1.Id;
	cr.ContactId = ct.Id;
	cr.Role = 'Signer';
	insert cr;

	cr = new OpportunityContactRole();
	cr.OpportunityId = opp1.Id;
	cr.ContactId = ct.Id;
	cr.Role = 'Billing Contact';
	insert cr;

	cr = new OpportunityContactRole();
	cr.OpportunityId = opp1.Id;
	cr.ContactId = ct.Id;
	cr.Role = 'Reviewer';
	insert cr;

	// Asset 1
	Opportunity_Line_Item__c oppLine = new Opportunity_Line_Item__c();
	oppLine.Line_Item_Type__c = 'Asset';
	oppline.Name = 'Test 1';
	oppLine.Opportunity__c = opp1.Id;
	oppLine.Planned_Install_City__c = 'Test';
	oppLine.Planned_Install_State__c = 'Test';
	oppLine.Planned_Install_Street__c = 'Test';
	oppLine.Planned_ZIP_Code__c = 'Test';
	insert oppLine;

	// Asset 2
	oppLine = new Opportunity_Line_Item__c();
	oppLine.Line_Item_Type__c = 'Asset';
	oppline.Name = 'Test 2';
	oppLine.Opportunity__c = opp1.Id;
	oppLine.Planned_Install_City__c = 'Test';
	oppLine.Planned_Install_State__c = 'Test';
	oppLine.Planned_Install_Street__c = 'Test';
	oppLine.Planned_ZIP_Code__c = 'Test';
	insert oppLine;

	// Asset 2
	oppLine = new Opportunity_Line_Item__c();
	oppLine.Line_Item_Type__c = 'Asset';
	oppline.Name = 'Test 3';
	oppLine.Opportunity__c = opp1.Id;
	oppLine.Planned_Install_City__c = 'Test';
	oppLine.Planned_Install_State__c = 'Test';
	oppLine.Planned_Install_Street__c = 'Test';
	oppLine.Planned_ZIP_Code__c = 'Test';
	insert oppLine;

	// Fees
	oppLine = new Opportunity_Line_Item__c();
	oppLine.Line_Item_Type__c = 'Fee';
	oppline.Name = 'Test';
	oppLine.Opportunity__c = opp1.Id;
	oppLine.Amount__c = 20;
	insert oppLine;

	// Fees
	oppLine = new Opportunity_Line_Item__c();
	oppLine.Line_Item_Type__c = 'Fee';
	oppline.Name = 'Test';
	oppLine.Opportunity__c = opp1.Id;
	oppLine.Amount__c = 20;
	insert oppLine;

	Quote q = new Quote();
	q.Name = 'Quote5';
	q.OpportunityId = opp1.id;
	q.Is_Primary__c = true;
	insert q;

	Quote_Line__c qLine = new Quote_Line__c();
	qLine.Quote__c = q.Id;
	qLine.Equipment_Type__c = 'Asset';
	insert qLine;

	qLine = new Quote_Line__c();
	qLine.Quote__c = q.Id;
	qLine.Equipment_Type__c = 'Add-on';
	insert qLine;

	Contract__c cont = new Contract__c();
	cont.UNQ_Opportunity__c='12345';
	cont.UNQ_Customer__c='123';
	cont.UNQ_Vendor__c='1234';
	cont.UNQ_Contract__c='1234CONTRACT';
	cont.UNQ_Program__c='Trac_Program';
	cont.Status_Text__c = 'BOOKED';
	cont.Name='test contract';
	cont.Account__c = at.id;
	cont.End_User__c = at.id;
	insert cont;

	//Insert asset
	Asset__c ast = new Asset__c();
	ast.Contract__c = cont.id;
	ast.Name = '12345';
	ast.Asset_City_Install_Address__c = 'Test';
	ast.Asset_Install_Address_Line_1__c = 'Test';
	ast.Asset_Install_Address_Line_2__c = 'Test';
	ast.Asset_Postal_Code_Install_Address__c = 'Test';
	ast.Asset_State_Install_Address__c = 'Test';
	insert ast;
}

@isTest static void testEnroll() {

	Opportunity existingOpp = [SELECT Id FROM Opportunity LIMIT 1];
	List<Opportunity_Line_Item__c> asset = [
		SELECT Id, Amount__c
		FROM Opportunity_Line_Item__c
		WHERE Opportunity__c = : existingOpp.Id
		                       AND Line_Item_Type__c = 'Asset'
	];
	List<Opportunity_Line_Item__c> serviceFees = [
		SELECT Id, Amount__c
		FROM Opportunity_Line_Item__c
		WHERE Opportunity__c = : existingOpp.Id
		                       AND Line_Item_Type__c = 'Fee'
	];

	// Asset Records
	List<Map<String, String> > assetRecords = new List<Map<String, String> >();

	// New fee
	Map<String, String> record = new Map<String, String>();
	record.put('name', 'Test');
	record.put('id', asset[0].Id);
	record.put('opportunity', existingOpp.Id);
	record.put('assetLocation', 'Test, Test, Test, Test');
	record.put('deliveryDate', '2022-07-26');
	record.put('serviceFee', '100');
	//record.put('serviceFeeId', '');
	record.put('taxExempt', 'true');
	record.put('serialNumber', 'Test');
	assetRecords.add(record);

	// Existing fee with amount
	record = new Map<String, String>();
	record.put('name', 'Test');
	record.put('id', asset[1].Id);
	record.put('opportunity', existingOpp.Id);
	record.put('assetLocation', 'Test, Test, Test, Test');
	record.put('deliveryDate', '2022-07-26');
	record.put('serviceFee', '100');
	record.put('serviceFeeId', serviceFees[0].Id);
	record.put('taxExempt', 'true');
	record.put('serialNumber', 'Test');
	assetRecords.add(record);

	// Existing fee without amount
	record = new Map<String, String>();
	record.put('name', 'Test');
	record.put('id', asset[2].Id);
	record.put('opportunity', existingOpp.Id);
	record.put('assetLocation', 'Test, Test, Test, Test');
	record.put('deliveryDate', '2022-07-26');
	record.put('serviceFee', '');
	record.put('serviceFeeId', serviceFees[1].Id);
	record.put('taxExempt', 'true');
	record.put('serialNumber', 'Test');
	assetRecords.add(record);

	// Signer Details
	List<Map<String, String> > signersRecords = new List<Map<String, String> >();
	List<OpportunityContactRole> ocrs = [
		SELECT Id, Role, ContactId
		FROM OpportunityContactRole
		WHERE OpportunityId = : existingOpp.Id
	];

	// Signer with UBOID
	Map<String, String> ocr = new Map<String, String>();
	ocr.put('Id', ocrs[0].Id);
	ocr.put('uboID', ocrs[0].Id);
	ocr.put('firstName', 'Test');
	ocr.put('middleName', 'Test');
	ocr.put('lastName', 'Test');
	ocr.put('titleValue', 'Test');
	ocr.put('emailValue', 'test@dllgroup.com');
	signersRecords.add(ocr);

	// Signer without UBOID
	ocr = new Map<String, String>();
	ocr.put('Id', ocrs[0].Id);
	ocr.put('firstName', 'Test');
	ocr.put('middleName', 'Test');
	ocr.put('lastName', 'Test');
	ocr.put('titleValue', 'Test');
	ocr.put('emailValue', 'test@dllgroup.com');
	signersRecords.add(ocr);

	// Signer with ContactId
	ocr = new Map<String, String>();
	ocr.put('Id', ocrs[0].ContactId);
	ocr.put('firstName', 'Test');
	ocr.put('middleName', 'Test');
	ocr.put('lastName', 'Test');
	ocr.put('titleValue', 'Test');
	ocr.put('emailValue', 'test@dllgroup.com');
	signersRecords.add(ocr);

	// Billing Address
	List<Map<String, String> > billingAddresses = new List<Map<String, String> >();
	Map<String, String> billingAddress = new Map<String, String>();
	billingAddress.put('addressLineOne', 'Test');
	billingAddress.put('addressLineTwo', 'Test');
	billingAddress.put('city', 'Test');
	billingAddress.put('state', 'Test');
	billingAddress.put('country', 'Test');
	billingAddress.put('ZIPCode', 'Test');
	billingAddresses.add(billingAddress);

	Test.startTest();
	Opportunity opp = EnrollController.getOpportunityData(existingOpp.Id);
	EnrollController.startOppEnroll(existingOpp.Id, 'Document Request Draft');
	List<Quote_Line__c> quoteLines = EnrollController.getQuoteLineAccessoryData(existingOpp.Id);
	List<Quote_Line__c> quoteLinesData = EnrollController.getQuoteLineData(existingOpp.Id);
	String customerId = EnrollController.getCustomerId('123', true);
	List<String> values = EnrollController.picklistValues('Opportunity', 'Sub_stage__c');
	EnrollController.updateStep('Review Specs', existingOpp.Id);
	List<Quote_Line__c> allQuoteLinesData = EnrollController.getAllQuoteLineData(existingOpp.Id);
	Opportunity endUser = EnrollController.getEndUserData(existingOpp.Id);
	EnrollController.getContactField(existingOpp.Id);
	Map<String, String> createPicklistValues = EnrollController.createPicklistValues('Opportunity', 'Sub_stage__c', existingOpp.Id);
	List<Opportunity_Line_Item__c> getAssetDetails = EnrollController.getAssetDetails(existingOpp.Id);
	EnrollController.getReviewerField(existingOpp.Id);
	EnrollController.updateAssetDetails(assetRecords);
	EnrollController.updateSignersDetails(signersRecords, existingOpp.Id);
	EnrollController.updateReviewersDetails(signersRecords, existingOpp.Id);
	EnrollController.getBillingContactData(existingOpp.Id);
	EnrollController.updateContactRoleData(signersRecords, existingOpp.Id);
	EnrollController.saveDocusignToOpp(existingOpp.Id, 'true');
	EnrollController.saveDocusignToOpp(existingOpp.Id, 'false');
	//EnrollController.getRelatedFilesByRecordId(existingOpp.Id);
	EnrollController.getDocusignValueFromOpp(existingOpp.Id);
	EnrollController.saveNewBillingAddress(existingOpp.Id, billingAddresses);
	EnrollControllerWithoutSharing.saveNewBillingAddress(existingOpp.Id, billingAddresses);
	Test.stopTest();
}
}