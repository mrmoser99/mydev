/*****************************************************************************************************************
 * Dll on Demand
 * 07/01/2022 - Geetha created class for PBI 762603 and 762605
 * 07/18/2022 - MRM Taking over
 * 8/4/2022 - Added billing address override of billing address,phone and email
 * 8/9/2022 - Fixing new bugs, docusign, nulls, service fee
 * 9/7/2022 - Added method to support funding requests
 * 10/7/2022 - Lucas Lucena - BUG 844751 - Request Docs Email is Missing Billing Contact Name (first and last)
 * 10/8/2022 - Geetha added null check for payment_amount__c. Related to bug 844751
 *******************************************************************************************************************/
global without sharing class EnrollRequestDocsIncoming implements Messaging.InboundEmailHandler {

//Method to invoke Email Service and add the FILE attachments to Opportunity
global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope env){


	Boolean error = false;
	List<String> fileList = new List<String>();

	Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
	List<ContentVersion> lscv_txt = new List<ContentVersion>();
	List<ContentVersion> lscv_bnr = new List<ContentVersion>();
	List<ContentDocumentLink> lscdl_txt = new List<ContentDocumentLink>();
	List<ContentDocumentLink> lscdl_bnr = new List<ContentDocumentLink>();

	/*String emailSubject = email.subject;
	   List<String> subList = emailSubject.split(':');
	   String appNum = subList[1].trim();*/
	Id oppId;
	//Fetching application Number from the Email Subject
	String appNumber = email.subject.split(':')[1].trim();

	try{
		oppId = [Select id from Opportunity where Application_Number__c = : appNumber limit 1].id;

	}
	catch (exception e) {
		Error_Log__c el = new Error_Log__c();
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'EnrollRequestDocsIncoming';
		el.callout_name__c = 'handleInboundEmail';
		el.Method_Name__c = 'handleInboundEmail - application lookup';
		el.status__c = 'Could not find application: ' + appNumber;
		el.status_code__c = -3;
		PricingUtils.saveErrorLog(JSON.serialize(el));
		sendFollowupEmail(appNumber,fileList,'BadApp',null);
		return null;

	}
	//Below IF block is only for checking .txt attachments

	/* if no attachments write to error log */
	if (email.binaryAttachments == null && email.textAttachments == null) {
		Error_Log__c el = new Error_Log__c();
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'EnrollRequestDocsIncoming';
		el.callout_name__c = 'handleInboundEmail';
		el.Method_Name__c = 'handleInboundEmail - attachment check';
		el.status__c = 'No Attachments';
		el.status_code__c = -2;
		PricingUtils.saveErrorLog(JSON.serialize(el));
		sendFollowupEmail(appNumber,fileList,'NoFiles',null);
		return null;
	}

	if(email.textAttachments!=null) {

		for (Messaging.Inboundemail.TextAttachment tAttachment : email.textAttachments) {
			Attachment attachment = new Attachment();

			ContentVersion contentVersion = new ContentVersion();
			contentVersion.ContentLocation = 'S';         // S = Stored in Salesforce
			contentVersion.PathOnClient = tAttachment.fileName;
			contentVersion.Title =  tAttachment.fileName;
			fileList.add(contentVersion.Title);
			contentVersion.VersionData = Blob.valueOf(tAttachment.body);
			contentVersion.Document_Source__c = 'Sales Support';         //Assigning Document source for DLL On Demand
			lscv_txt.add(contentVersion);
		}

		try{
			if(lscv_txt.size() > 0) {
				insert lscv_txt;
			}

		}catch(Exception e) {
			system.debug('error = ' +e.getStackTraceString());
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - text';
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = e.getMessage();
			el.status__c = 'failure';
			el.status_code__c = -1;
			error = true;
			sendFollowupEmail(appNumber,fileList,'Fatal',el.stack_trace__c);

			PricingUtils.saveErrorLog(JSON.serialize(el));
		}
		finally{
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - text';
			el.status__c = 'Success';
			el.status_code__c = 0;

			PricingUtils.saveErrorLog(JSON.serialize(el));

		}

		for(ContentVersion cv: lscv_txt) {
			ContentVersion c = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = : cv.id];
			ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
			contentDocumentLink.ContentDocumentId = c.contentDocumentId;
			contentDocumentLink.LinkedEntityId = oppId;
			contentDocumentLink.ShareType = 'I';         // Inferred permission
			contentDocumentLink.Visibility = 'AllUsers';
			lscdl_txt.add(contentDocumentLink);
		}
		try{
			if(lscdl_txt.size() > 0) {
				insert lscdl_txt;
			}

		}catch(Exception e) {
			system.debug('error = ' +e.getStackTraceString());
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - insert';
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = e.getMessage();
			el.status__c = 'failure';
			el.status_code__c = -1;
			error = true;
			sendFollowupEmail(appNumber,fileList,'Fatal',el.stack_trace__c);

			PricingUtils.saveErrorLog(JSON.serialize(el));
		}
		finally{
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - text';
			el.status__c = 'Success';
			el.status_code__c = 0;

			PricingUtils.saveErrorLog(JSON.serialize(el));

		}
	}

	//Below IF block is for checking all binary attachments
	if(email.binaryAttachments!=null) {

		for(Messaging.Inboundemail.binaryAttachment bAttachment : email.binaryAttachments) {
			ContentVersion contentVersion = new ContentVersion();
			contentVersion.ContentLocation = 'S';         // S = Stored in Salesforce
			contentVersion.PathOnClient = bAttachment.fileName;
			contentVersion.Title =  bAttachment.fileName;
			fileList.add(contentVersion.Title);
			contentVersion.VersionData = bAttachment.body;
			contentVersion.Document_Source__c = 'Sales Support';         //Assigning Document source for DLL On Demand
			lscv_bnr.add(contentVersion);
			//insert contentVersion;
		}

		try{
			if(lscv_bnr.size() > 0) {
				insert lscv_bnr;
			}

		}catch(Exception e) {
			system.debug('error = ' +e.getStackTraceString());
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - binary';
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = e.getMessage();
			el.status__c = 'failure';
			el.status_code__c = -1;
			error=true;
			sendFollowupEmail(appNumber,fileList,'Fatal',el.stack_trace__c);

			PricingUtils.saveErrorLog(JSON.serialize(el));
		}
		finally{
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - text';
			el.status__c = 'Success';
			el.status_code__c = 0;

			PricingUtils.saveErrorLog(JSON.serialize(el));

		}

		for(ContentVersion cv: lscv_bnr) {
			ContentVersion c = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = : cv.id];
			ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
			contentDocumentLink.ContentDocumentId = c.contentDocumentId;
			contentDocumentLink.LinkedEntityId = oppId;
			contentDocumentLink.ShareType = 'I';         // Inferred permission
			contentDocumentLink.Visibility = 'AllUsers';
			//insert contentDocumentLink;
			lscdl_bnr.add(contentDocumentLink);
		}

		try{
			if(lscdl_bnr.size() > 0) {
				insert lscdl_bnr;
			}

		}catch(Exception e) {
			system.debug('error = ' +e.getStackTraceString());
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - binary insert';
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = e.getMessage();
			el.status__c = 'failure';
			el.status_code__c = -1;
			error=true;
			sendFollowupEmail(appNumber,fileList,'Fatal',el.stack_trace__c);

			PricingUtils.saveErrorLog(JSON.serialize(el));
		}
		finally{
			Error_Log__c el = new Error_Log__c();
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'EnrollRequestDocsIncoming';
			el.callout_name__c = 'handleInboundEmail';
			el.Method_Name__c = 'handleInboundEmail - text';
			el.status__c = 'Success';
			el.status_code__c = 0;

			PricingUtils.saveErrorLog(JSON.serialize(el));

		}

		if (!error)
			sendFollowupEmail(appNumber,fileList,'Success',null);

	}
	return null;
}
/****************************************************************************************************************
*
* sendSuccessEmail
*
*
****************************************************************************************************************/
@AuraEnabled

public static void sendFollowupEmail(String app, List<String> filelist,String type, String errorMsg){

	OrgwideEmailAddress owa;

	owa = [select id from OrgWideEmailAddress where displayname = 'Dll On Demand'];

	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	//set up a contact with the sales support email address
	mail.setOrgWideEmailAddressId(owa.id);

	mail.setSaveAsActivity(false);
	mail.setUseSignature(false);
	mail.setSubject('Documents Received Status Update for Application -' + app);


	List<String> toAddressList = new List<String>();
	toAddressList.add(system.label.request_docs_support_email);

	mail.setToAddresses(toAddressList);
	String body;
	if (type == 'Success') {
		body = 'The following files were successfully attached to the application: ';
		Integer i = 0;
		for (String s:fileList) {
			if (i > 0)
				body += ', ';
			body += ' ' + s + '\n';
			i++;
		}
	}

	if (type == 'BadApp') {
		body = 'The application number could not be found ' + app;
	}

	if (type == 'NoFiles') {
		body = 'No files were attached for this application number: ' + app;
	}

	if (type == 'Fatal') {
		body = errorMsg;
	}

	mail.setPlainTextBody(body);

	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });


}

/****************************************************************************************************************
*
* send docs for funding
*
*
****************************************************************************************************************/
@AuraEnabled

public static String sendDocsForFunding(Id oppId){

	OrgwideEmailAddress owa;

	owa = [select id from OrgWideEmailAddress where displayname = 'Dll On Demand'];

	Opportunity o = [select id
	                 ,Application_Number__c
	                 FROM Opportunity
	                 where id = : oppId
	];

	List<ContentDocumentLink> files = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = : oppId];
	List<ID> fileIDs = new List<ID>();
	for (ContentDocumentLink docLink : files) {
		fileIDs.add(docLink.ContentDocumentId);
	}

	List<ContentVersion> docs = [SELECT ContentDocumentId, FileExtension, Title,VersionData
	                             FROM ContentVersion WHERE ContentDocumentId IN : fileIDs
	                             and Document_Source__c = 'Partner'];



	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
	//set up a contact with the sales support email address
	mail.setOrgWideEmailAddressId(owa.id);

	List<Messaging.EmailFileAttachment> attachList = new List<Messaging.EmailFileAttachment>();

	for (ContentVersion d:docs) {
		blob fileBody = d.VersionData;
		Messaging.EmailFileAttachment ea = new Messaging.EmailFileAttachment();
		ea.setFileName(d.Title + '.' + d.FileExtension);
		ea.setBody(fileBody);
		attachList.add(ea);
	}

	mail.setFileAttachments(attachList);
	mail.setSaveAsActivity(false);
	mail.setUseSignature(false);
	mail.setSubject('Funding Request - ' + o.Application_Number__c);


	List<String> toAddressList = new List<String>();
	toAddressList.add(system.label.request_docs_support_email);

	mail.setToAddresses(toAddressList);
	String body;

	body = 'Attached are the documents for this application.';

	mail.setPlainTextBody(body);

	Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

	return 'ok';


}

/****************************************************************************************************************
*
* sendEmailforOpportunity
*
*
****************************************************************************************************************/
@AuraEnabled

public static void sendEmailforOpportunity(Id oppId){
	Opportunity o = new Opportunity();
	String body;
	OrgwideEmailAddress owa;


	try{


		owa = [select id from OrgWideEmailAddress where displayname = 'Dll On Demand'];


		o = [select id
		     ,Name
		     ,billing_address_preference__c
		     ,Application_Number__c
		     ,Partner_Sales_Rep__r.name
		     ,owner.full_name__c
		     ,owner.email
		     ,end_user__r.Name
		     ,end_user__r.BillingStreet
		     ,end_user__r.BillingCity
		     ,end_user__r.BillingState
		     ,end_user__r.BillingPostalCode
		     ,end_user__r.ShippingStreet
		     ,end_user__r.ShippingCity
		     ,end_user__r.ShippingState
		     ,end_user__r.ShippingPostalCode
		     ,end_user__r.phone
		     ,end_user__r.tax_id__c
		     ,end_user__r.email__c
		     ,amount
		     ,lease_type__c
		     ,term__c
		     ,payment_amount__c
		     ,advance_payments__c
		     ,docusign__c
		     ,document_delivery_preference__c
		     FROM Opportunity
		     where id = : oppId
		];



		List<Opportunity_Line_Item__c> l = new List<Opportunity_Line_Item__c>();
		l = [select id
		     ,name
		     ,planned_install_date__c
		     ,serial_number__c
		     ,planned_install_street__c
		     ,planned_install_city__c
		     ,planned_install_state__c
		     ,planned_zip_code__c
		     ,tax_exempt__c
		     ,Related_App_Line_Item__r.amount__c
		     from Opportunity_Line_Item__c
		     where opportunity__c = : o.id
		                            and line_item_type__c = 'Asset'
		];



		List<OpportunityContactRole> rList = new List<OpportunityContactRole>();
		rList = [SELECT
		         contactId,
		         Contact.MiddleName,
		         Contact.FirstName,
		         Contact.Email,
		         Contact.LastName,
		         Contact.Title,
		         Contact.Phone,
		         Role
		         FROM
		         OpportunityContactRole
		         where opportunityId = : o.id
		                               and role in ('Reviewer','Signer', 'Billing Contact')];




		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		//set up a contact with the sales support email address

		mail.setOrgWideEmailAddressId(owa.id);

		mail.setSaveAsActivity(false);
		mail.setUseSignature(false);
		mail.setSubject('Document Request for Application -' + o.Application_number__c);


		List<String> toAddressList = new List<String>();
		toAddressList.add(system.label.request_docs_support_email);

		mail.setToAddresses(toAddressList);

		String salesRep;
		if (o.partner_sales_Rep__c == null)
			salesRep = ' ';
		else {
			salesRep = o.partner_sales_Rep__r.name;
		}

		String address = o.end_user__r.BillingStreet + '<br/>'  + o.end_user__r.BillingCity + ',' + o.end_user__r.BillingState + ' ' +
		                 o.end_user__r.BillingPostalCode;

		address.replace('null',' ');

		String accountPhone;

		if (o.billing_address_preference__c == 'Enter new billing address') {
			address = o.end_user__r.ShippingStreet + '<br/>'  + o.end_user__r.ShippingCity + ',' + o.end_user__r.ShippingState + ' ' +
			          o.end_user__r.ShippingPostalCode;
		}
		address.replace('null', '');

		String taxId;
		if (o.end_user__r.tax_id__c == null)
			taxId = ' ';
		else {
			taxId = o.end_user__r.tax_id__c;
		}

		String email  = o.end_user__r.email__c;
		accountPhone = o.end_user__r.phone;
		if (accountPhone == null)
			accountPhone = '';


		if (o.end_user__r.email__c == null)
			email = ' ';

		// Start 1/2 - Lucas Lucena - BUG 844751 - Request Docs Email is Missing Billing Contact Name (first and last)
		String billingName;
		billingName = o.end_user__r.name;
		if(billingName == null) billingName = '';
		// End - Lucas Lucena - BUG 844751 - Request Docs Email is Missing Billing Contact Name (first and last)


		for (OpportunityContactRole ocr:rList) {
			if (ocr.role == 'Billing Contact') {
				system.debug(ocr.contact.phone);
				email = ocr.contact.email;
				accountPhone = ocr.contact.phone;
				if (email == null)
					email = '';
				// Start 2/2 - Lucas Lucena - BUG 844751 - Request Docs Email is Missing Billing Contact Name (first and last)
				billingName = ocr.contact.FirstName + ' ' + ocr.contact.LastName;
				if(billingName == null) billingName = '';
				// End - Lucas Lucena - BUG 844751 - Request Docs Email is Missing Billing Contact Name (first and last)
			}
		}




		body =
			'<html><body>';

		body += '<a href="mailto:' + system.label.Request_Docs_Email + '?subject=Application Number : ' +
		        o.application_number__c
		        + '">Click here to attach documents to this application!</a><br/><br/>';
		body +=

			'<style>table, th, td {  border:1px solid black; border-collapse: collapse;}</style>' +

			'<p style="color:blue">Customer Information</p>' +

			'<table>' +
			'<tr><td style="font-weight:bold;">Date</td><td>' + Date.today().format() + '</td></tr>'  +
			'<tr><td style="font-weight:bold;">Application Number</td><td> ' + o.Application_Number__c + '</td></tr>'  +
			'<tr><td style="font-weight:bold;">Partner Sales Rep Name</td><td>' + salesRep + '</td></tr>'  +
			'<tr><td style="font-weight:bold;">Requestor Name</td><td>' + o.Owner.Full_Name__c + '</td></tr>'  +
			'<tr><td style="font-weight:bold;">Requestor Email</td><td>' + o.Owner.Email + '</td></tr>'  +

			'<tr><td style="font-weight:bold;">Billing Address</td><td>' + address + '</td></tr>'  +

			'<tr><td style="font-weight:bold;">Account Name</td><td>' + o.end_user__r.name + '</td></tr>'  +
			'<tr><td style="font-weight:bold;">Billing Name</td><td>' + billingName + '</td></tr>'  +
			'<tr><td style="font-weight:bold;">Billing Phone</td><td>' + accountPhone + '</td></tr>'  +
			'<tr><td style="font-weight:bold;">Billing Email</td><td>' + email + '</td></tr>'  +

			'<tr><td style="font-weight:bold;">Tax ID (EIN/TIN)</td><td>' + taxId + '</td></tr>'  +
			//'<tr><td style="font-weight:bold;">Purchase Order</td><td>?</td></tr>'  +
			'</table>' +
			'<p style="color:blue">Equipment Information</p><br/>' +

			'<table >' +
			'<tr><th>Make/Model</th><th>Serial Number</th><th>Delivery Date</th><th>Address</th><th>Tax Exempt</th><th>Service Fee</th></tr>';



		for (Opportunity_Line_Item__c i:l) {
			if (i.serial_number__c == null)
				i.serial_number__c = ' ';

			body +=
				'<td>' + i.name + '</td>' +
				'<td>' + i.serial_number__c + '</td>';

			if (i.planned_install_date__c == null)
				body +=
					'<td></td>';
			else
				body +=
					'<td style="text-align:right;">' + i.planned_install_date__c.format() + '</td>';

			decimal serviceFee = 0;
			if (i.related_app_line_item__r.amount__c != null)

				serviceFee = i.related_app_line_item__r.amount__c;

			String plannedAddress = i.planned_install_street__c + ' ' +
			                        i.planned_install_city__c + ' ' +
			                        i.planned_install_state__c + ' ' +
			                        i.planned_zip_code__c;
			system.debug(plannedAddress);
			plannedAddress = plannedAddress.replace('null','');
			system.debug(plannedAddress);

			body +=
				'<td>' + plannedAddress + '</td>' +
				'<td style="text-align:center;">' + i.tax_exempt__c + '</td>'  +
				'<td style="text-align:right;">' + currency(string.valueOf(serviceFee)) + '</td>'  +

				'</tr>';

		}

		String docusign = 'No ';
		if (o.document_delivery_preference__c != null)

			if (o.document_delivery_preference__c.toLowerCase()  == 'docusign')
				docusign = 'Yes ';



		if (o.advance_payments__c == null)
			o.advance_payments__c = 0;
        //Geetha added: Bug 844751
        if(o.payment_amount__c == null)
            o.payment_amount__c = 0;

		body  += '</table>' +
		         '<p style="color:blue">Finance Information</p>' +
		         '<table>' +
		         '<tr><td style="font-weight:bold;">Equipment selling price</td><td style="text-align:right;">' + currency(string.valueOf(o.amount)) + '</td></tr>'  +
		         '<tr><td style="font-weight:bold;">Total amount financed</td><td style="text-align:right;">' + currency(string.valueOf(o.amount)) + '</td></tr>'  +
		         '<tr><td style="font-weight:bold;">End of lease option</td><td>' + o.lease_type__c + '</td></tr>'  +
		         '<tr><td style="font-weight:bold;">Term</td><td style="text-align:right;">' + o.term__c + '</td></tr>'  +
		         '<tr><td style="font-weight:bold;">Payment</td><td style="text-align:right;">' + currency(string.valueOf(o.payment_amount__c)) + '</td></tr>'  +
		         '<tr><td style="font-weight:bold;">Advanced Payments</t++0d><td style="text-align:right;">' + currency(string.valueOf(o.advance_payments__c)) + '</td></tr>'  +
		         '</table>' +

		         '<p style="color:blue">Document Preferences</p>' +
		         '<table>' +
		         '<tr><td style="font-weight:bold;">Docusign?</td><td style="text-align:center;">' + docusign + '</td></tr>'  +
		         '</table>' +

		         '<p style="color:blue">Contract Signer(s)</p>' +
		         '<table><tr><th>Name</th><th>Title</th><th>Email</th></tr>';

		for (OpportunityContactRole ocr:rList) {
			if (ocr.role == 'Signer') {
				String middle = '';
				if (ocr.contact.middleName != null)
					middle = ocr.contact.middleName;
				body += '<tr><td>' + ocr.contact.firstname + ' ' + middle  + ' ' + ocr.contact.lastName + '</td>' +
				        '<td>' + ocr.contact.title + '</td>' +
				        '<td>' + ocr.contact.email + '</td></tr>';
			}
		}



		body += '</table>' +

		        '<p style="color:blue">Contract Reviewer(s)</p>' +
		        '<table><tr><th>Name</th><th>Title</th><th>Email</th></tr>';
		for (OpportunityContactRole ocr:rList) {
			if (ocr.role == 'Reviewer') {
				String middle = '';
				if (ocr.contact.middleName != null)
					middle = ocr.contact.middleName;
				body += '<tr><td>' + ocr.contact.firstname + ' ' + middle + ' ' + ocr.contact.lastName + '</td>' +
				        '<td>' + ocr.contact.title + '</td>' +
				        '<td>' + ocr.contact.email + '</td></tr>';
			}
		}


		body +=
			'</table>';


		body +=
			'</body></html>';

		mail.setHtmlBody(body);

		o.Sub_Stage__c = 'Documents Requested';
		update o;

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

	}
	catch (Exception e) {
		Error_Log__c el = new Error_Log__c();
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'EnrollRequestDocsIncoming ';
		el.callout_name__c = 'Email Request for Docs ';
		el.Method_Name__c = 'sendEmailforOpportunity ';
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = e.getMessage();
		el.status__c = 'failure ';
		el.status_code__c = -1;
		el.request_body__c = 'Opportunity id is: ' + o.id + ':--->' + body;
		system.debug('el si: ' + el);
		PricingUtils.saveErrorLog(JSON.serialize(el));
	}

	finally{

		Error_Log__c el = new Error_Log__c();
		el.callout_name__c = 'Email Request for Docs ';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'EnrollRequestDocsIncoming ';
		el.Method_Name__c = 'sendEmailforOpportunity ';
		el.status__c = 'Email Success !';
		el.status_code__c =0;

		el.request_body__c = 'Opportunity id is:' + o.id + ' : --->' + body;
		PricingUtils.saveErrorLog(JSON.serialize(el));


	}


}
/*****************************************************************************************************
* currency class for formatting currency
*****************************************************************************************************/
static String currency(String i) {
	String s = ( Decimal.valueOf(i==null||i.trim()==' '?' 0 ':i).setScale(2) + 0.001 ).format();
	return '$ ' + s.substring(0,s.length()-1);
}
}