/*****************************************************************************************************************
 * Dll on Demand
 * 07/14/2022 - Geetha created Test class for EnrollRequestDocsIncoming PBI 762603 and 762605
 *******************************************************************************************************************/
@isTest
public class EnrollRequestDocsIncomingTest {
public static testMethod void method0() {

	List<Opportunity> oppList = new List<Opportunity>();

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='test';
	ct.AccountId=at.id;
	ct.Email='arry@gmil.com';
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
	opp1.Sub_Stage__c='Booked';
	opp1.Application_Date__c=system.today().addMonths(-3);
	opp1.UNQ_Customer__c='A1';
	opp1.UNQ_Vendor__c='A1';
	opp1.UNQ_Opportunity__c='A1';
	opp1.Application_Number__c = '123459';
	oppList.add(opp1);

	insert opp1;
	Test.startTest();
	EnrollRequestDocsIncoming.sendDocsForFunding(opp1.id);
	Test.stopTest();
}

public static testMethod void method1() {

	List<Opportunity> oppList = new List<Opportunity>();

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='test';
	ct.AccountId=at.id;
	ct.Email='arry@gmil.com';
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
	opp1.Sub_Stage__c='Booked';
	opp1.Application_Date__c=system.today().addMonths(-3);
	opp1.UNQ_Customer__c='A1';
	opp1.UNQ_Vendor__c='A1';
	opp1.UNQ_Opportunity__c='A1';
	opp1.Application_Number__c = '123459';
	oppList.add(opp1);

	insert opp1;
	Test.startTest();
	EnrollRequestDocsIncoming.sendEmailforOpportunity(opp1.id);
	Test.stopTest();
}

public static testMethod void method2() {

	List<Opportunity> oppList = new List<Opportunity>();

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='Niranjan';
	ct.AccountId=at.id;
	ct.Email='arry@gmil.com';
	insert ct;

	Opportunity opp2= new Opportunity();
	opp2.application_number__c='A1';
	opp2.Type='Overline';
	opp2.Name='Service';
	opp2.StageName='Closed Won';
	opp2.Accountid=at.id;
	opp2.Contact__c=ct.id;
	opp2.CloseDate=system.today()+1;
	opp2.Amount=11.0;
	opp2.End_User__c=at.id;
	opp2.End_User_Company_Name__c = 'DANIEL INC.';
	opp2.Business_Unit1__c='Digital Imaging';
	opp2.Sub_Stage__c='Booked';
	opp2.Application_Date__c=system.today().addMonths(-3);
	opp2.UNQ_Customer__c='A1';
	opp2.UNQ_Vendor__c='A1';
	opp2.UNQ_Opportunity__c='A1';
	insert opp2;


	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	Messaging.InboundEmail mail = new Messaging.InboundEmail();

	mail.Subject = 'Application Number :' +opp2.Application_Number__c;
	mail.fromname = 'Geetha';
	env.fromAddress = 'geetha.bharadwaj@dllgroup.com';
	mail.plainTextBody = 'Test';

	//below code is for Document attachments
	Messaging.InboundEmail.BinaryAttachment docattachments = new Messaging.InboundEmail.BinaryAttachment();
	docattachments.body = blob.valueOf('my attachment Document');
	docattachments.fileName = 'docfile.doc';
	docattachments.mimeTypeSubType = 'text/plain';
	mail.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { docattachments };

	//below code is for Text attachments
	Messaging.InboundEmail.textAttachment txtAttachment = new Messaging.InboundEmail.textAttachment();
	txtAttachment.body = 'My text attachemnt body';
	txtAttachment.fileName = 'textfile.txt';
	txtAttachment.mimeTypeSubType = 'text/plain';
	mail.textAttachments = new Messaging.inboundEmail.TextAttachment[] { txtAttachment };


	Test.startTest();
	EnrollRequestDocsIncoming enrollreq = new EnrollRequestDocsIncoming();
	enrollreq.handleInboundEmail(mail, env);
	Test.stopTest();

}
public static testMethod void method3() {

	List<Opportunity> oppList = new List<Opportunity>();

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='Niranjan';
	ct.AccountId=at.id;
	ct.Email='arry@gmil.com';
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
	opp1.Sub_Stage__c='Booked';
	opp1.Application_Date__c=system.today().addMonths(-3);
	opp1.UNQ_Customer__c='A1';
	opp1.UNQ_Vendor__c='A1';
	opp1.UNQ_Opportunity__c='A1';
	opp1.billing_address_preference__c = 'Enter new billing address';
	insert opp1;

	Opportunity_Line_Item__c oli =  new Opportunity_Line_Item__c();
	oli.Name = 'oli1';
	oli.opportunity__c = opp1.id;
	oli.line_item_type__c = 'Asset';

	insert oli;


	Contact c1 = new Contact();
	c1.phone = '1234567891';
	c1.LastName = 'Billing Contact LN';
	c1.FirstName = 'Billing Contact FN';
	c1.MiddleName = 'Billing Contact MN';
	c1.Title = 'Mr';
	c1.Email = 'test@gmail.com';
	c1.AccountId = at.id;
	insert c1;

	OpportunityContactRole ocr1 = new OpportunityContactRole();
	ocr1.ContactId = c1.id;
	ocr1.Role = 'Billing Contact';
	ocr1.OpportunityId = opp1.id;
	insert ocr1;

	Contact c2 = new Contact();
	c2.phone = '1234567891';
	c2.LastName = 'Signer LN';
	c2.FirstName = 'Signer FN';
	c2.MiddleName = 'Signer MN';
	c2.Title = 'Mr';
	c2.Email = 'test@gmail.com';
	c2.AccountId = at.id;
	insert c2;

	OpportunityContactRole ocr2 = new OpportunityContactRole();
	ocr2.ContactId = c2.id;
	ocr2.Role = 'Signer';
	ocr2.OpportunityId = opp1.id;
	insert ocr2;

	Contact c3 = new Contact();
	c3.phone = '1234567891';
	c3.LastName = 'Reviewer LN';
	c3.FirstName = 'Reviewer FN';
	c3.MiddleName = 'Reviewer MN';
	c3.Title = 'Mr';
	c3.Email = 'test@gmail.com';
	c3.AccountId = at.id;
	insert c3;

	OpportunityContactRole ocr3 = new OpportunityContactRole();
	ocr3.ContactId = c3.id;
	ocr3.Role = 'Reviewer';
	ocr3.OpportunityId = opp1.id;
	insert ocr3;


	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	Messaging.InboundEmail mail = new Messaging.InboundEmail();

	mail.Subject = 'Application Number :' +opp1.Application_Number__c;
	mail.fromname = 'Geetha';
	env.fromAddress = 'geetha.bharadwaj@dllgroup.com';
	mail.plainTextBody = 'Test';

	//below code is for Document attachments
	Messaging.InboundEmail.BinaryAttachment docattachments = new Messaging.InboundEmail.BinaryAttachment();
	docattachments.body = blob.valueOf('my attachment Document');
	docattachments.fileName = 'docfile.doc';
	docattachments.mimeTypeSubType = 'text/plain';
	mail.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { docattachments };

	//below code is for Text attachments
	Messaging.InboundEmail.textAttachment txtAttachment = new Messaging.InboundEmail.textAttachment();
	txtAttachment.body = 'My text attachemnt body';
	txtAttachment.fileName = 'textfile.txt';
	txtAttachment.mimeTypeSubType = 'text/plain';
	mail.textAttachments = new Messaging.inboundEmail.TextAttachment[] { txtAttachment };


	Test.startTest();
	EnrollRequestDocsIncoming enrollreq = new EnrollRequestDocsIncoming();
	//enrollreq.handleInboundEmail(mail, env);
	EnrollRequestDocsIncoming.sendEmailforOpportunity(opp1.id);
	Test.stopTest();

}


public static testMethod void method4() {

	List<Opportunity> oppList = new List<Opportunity>();

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='Niranjan';
	ct.AccountId=at.id;
	ct.Email='arry@gmil.com';
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
	opp1.Sub_Stage__c='Booked';
	opp1.Application_Date__c=system.today().addMonths(-3);
	opp1.UNQ_Customer__c='A1';
	opp1.UNQ_Vendor__c='A1';
	opp1.UNQ_Opportunity__c='A1';
	opp1.Billing_Address_Preference__c = 'Enter new billing address';
	//oppList.add(opp1);
	insert opp1;

	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	Messaging.InboundEmail mail = new Messaging.InboundEmail();

	mail.Subject = 'Application Number :' +opp1.Application_Number__c;
	mail.fromname = 'Geetha';
	env.fromAddress = 'geetha.bharadwaj@dllgroup.com';
	mail.plainTextBody = 'Test';

	//below code is for Document attachments
	Messaging.InboundEmail.BinaryAttachment docattachments = new Messaging.InboundEmail.BinaryAttachment();
	docattachments.body = blob.valueOf('my attachment Document');
	docattachments.fileName = 'docfile.doc';
	docattachments.mimeTypeSubType = 'text/plain';
	mail.binaryAttachments = null;

	//below code is for Text attachments
	Messaging.InboundEmail.textAttachment txtAttachment = new Messaging.InboundEmail.textAttachment();
	txtAttachment.body = 'My text attachemnt body';
	txtAttachment.fileName = 'textfile.txt';
	txtAttachment.mimeTypeSubType = 'text/plain';
	mail.textAttachments = null;

	Test.startTest();
	EnrollRequestDocsIncoming enrollreq1 = new EnrollRequestDocsIncoming();
	enrollreq1.handleInboundEmail(mail, env);
	Test.stopTest();

}
public static testMethod void method5() {

	List<Opportunity> oppList = new List<Opportunity>();

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='Niranjan';
	ct.AccountId=at.id;
	ct.Email='arry@gmil.com';
	insert ct;

	Opportunity opp1= new Opportunity();
	//opp1.application_number__c='A1';
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
	opp1.Sub_Stage__c='Booked';
	opp1.Application_Date__c=system.today().addMonths(-3);
	opp1.UNQ_Customer__c='A1';
	opp1.UNQ_Vendor__c='A1';
	opp1.UNQ_Opportunity__c='A1';
	opp1.Billing_Address_Preference__c = 'Enter new billing address';
	//oppList.add(opp1);
	insert opp1;

	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	Messaging.InboundEmail mail = new Messaging.InboundEmail();

	mail.Subject = 'Application Number :' +opp1.Application_Number__c;
	mail.fromname = 'Geetha';
	env.fromAddress = 'geetha.bharadwaj@dllgroup.com';
	mail.plainTextBody = 'Test';

	//below code is for Document attachments
	Messaging.InboundEmail.BinaryAttachment docattachments = new Messaging.InboundEmail.BinaryAttachment();
	docattachments.body = blob.valueOf('my attachment Document');
	docattachments.fileName = 'docfile.doc';
	docattachments.mimeTypeSubType = 'text/plain';
	mail.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { docattachments };

	//below code is for Text attachments
	Messaging.InboundEmail.textAttachment txtAttachment = new Messaging.InboundEmail.textAttachment();
	txtAttachment.body = 'My text attachemnt body';
	txtAttachment.fileName = 'textfile.txt';
	txtAttachment.mimeTypeSubType = 'text/plain';
	mail.textAttachments = new Messaging.inboundEmail.TextAttachment[] { txtAttachment };

	Test.startTest();
	EnrollRequestDocsIncoming enrollreq1 = new EnrollRequestDocsIncoming();
	enrollreq1.handleInboundEmail(mail, env);
	Test.stopTest();

}
public static testMethod void method6() {

	List<Opportunity> oppList = new List<Opportunity>();

	Account at =new Account();
	at.Name='Service';
	insert at;

	contact ct =new contact();
	ct.LastName='Niranjan';
	ct.AccountId=at.id;
	ct.Email='arry@gmil.com';
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
	opp1.Sub_Stage__c='Booked';
	opp1.Application_Date__c=system.today().addMonths(-3);
	opp1.UNQ_Customer__c='A1';
	opp1.UNQ_Vendor__c='A1';
	opp1.UNQ_Opportunity__c='A1';
	opp1.billing_address_preference__c = 'Enter new billing address';
	// opp1.partner_sales_Rep__c = 'rep1';

	insert opp1;

	Opportunity_Line_Item__c oli =  new Opportunity_Line_Item__c();
	oli.Name = 'oli1';
	oli.opportunity__c = opp1.id;
	oli.line_item_type__c = 'Asset';
	oli.planned_install_date__c = system.today();

	insert oli;


	Contact c1 = new Contact();
	c1.phone = '1234567891';
	c1.LastName = 'Billing Contact LN';
	c1.FirstName = 'Billing Contact FN';
	c1.MiddleName = 'Billing Contact MN';
	c1.Title = 'Mr';
	//c1.Email = 'test@gmail.com';
	c1.AccountId = at.id;
	insert c1;

	OpportunityContactRole ocr1 = new OpportunityContactRole();
	ocr1.ContactId = c1.id;
	ocr1.Role = 'Billing Contact';
	ocr1.OpportunityId = opp1.id;
	insert ocr1;

	Contact c2 = new Contact();
	c2.phone = '1234567891';
	c2.LastName = 'Signer LN';
	c2.FirstName = 'Signer FN';
	c2.MiddleName = 'Signer MN';
	c2.Title = 'Mr';
	c2.Email = 'test@gmail.com';
	c2.AccountId = at.id;
	insert c2;

	OpportunityContactRole ocr2 = new OpportunityContactRole();
	ocr2.ContactId = c2.id;
	ocr2.Role = 'Signer';
	ocr2.OpportunityId = opp1.id;
	insert ocr2;

	Contact c3 = new Contact();
	c3.phone = '1234567891';
	c3.LastName = 'Reviewer LN';
	c3.FirstName = 'Reviewer FN';
	c3.MiddleName = 'Reviewer MN';
	c3.Title = 'Mr';
	c3.Email = 'test@gmail.com';
	c3.AccountId = at.id;
	insert c3;

	OpportunityContactRole ocr3 = new OpportunityContactRole();
	ocr3.ContactId = c3.id;
	ocr3.Role = 'Reviewer';
	ocr3.OpportunityId = opp1.id;
	insert ocr3;


	Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
	Messaging.InboundEmail mail = new Messaging.InboundEmail();

	mail.Subject = 'Application Number :' +opp1.Application_Number__c;
	mail.fromname = 'Geetha';
	env.fromAddress = 'geetha.bharadwaj@dllgroup.com';
	mail.plainTextBody = 'Test';

	//below code is for Document attachments
	Messaging.InboundEmail.BinaryAttachment docattachments = new Messaging.InboundEmail.BinaryAttachment();
	docattachments.body = blob.valueOf('my attachment Document');
	docattachments.fileName = 'docfile.doc';
	docattachments.mimeTypeSubType = 'text/plain';
	mail.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { docattachments };

	//below code is for Text attachments
	Messaging.InboundEmail.textAttachment txtAttachment = new Messaging.InboundEmail.textAttachment();
	txtAttachment.body = 'My text attachemnt body';
	txtAttachment.fileName = 'textfile.txt';
	txtAttachment.mimeTypeSubType = 'text/plain';
	mail.textAttachments = new Messaging.inboundEmail.TextAttachment[] { txtAttachment };


	Test.startTest();
	EnrollRequestDocsIncoming enrollreq = new EnrollRequestDocsIncoming();
	//enrollreq.handleInboundEmail(mail, env);
	EnrollRequestDocsIncoming.sendEmailforOpportunity(opp1.id);
	Test.stopTest();

}

}