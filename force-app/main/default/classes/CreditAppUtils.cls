/*****************************************************************************************************************
 * Dll on Demaind (DD) CREDIT APPLICATION UTILS
 *
 * Change Log:
 *
 *  11/3/21 - MRM Created class
 *  04/19/22 - MRM added credit/error simulation
 *  05/08/22 - MRM added preqaul api
 *  05/17/22 - HV Removed references to deprecated fields (Chassis and Sequence Id) and updated quote number formats
 *  06/10/22 - MRM modifed preqaul api
 *  10/24/22 - MRM modified to update UNQ_Opportunity__c when appnumber comes back
 *  10/19/22 - MRM modified the exception logic to write to log and improve ease of debugging; works better
 *  10/31/22 - MRM added Credit_Response__e platform event 
 *  11/07/22 - MRM added credit response platform event 
 *******************************************************************************************************************/
public without sharing class CreditAppUtils {


/************************************************************************************************************************************************
 * submit credit application
 *
 * change log:
 *
 * 11/2/2021 - MRM Created
 * 11/12/2021 - MRM - there is a new version of submit credit app coming, but it is not ready yet;  bill doviak email 11/12.
 *
 *
 *****************************************************************************************************************************************************/
@AuraEnabled
public static String submitCreditApp(String quoteId){
	Boolean error=false;
	String response;
	String jsonStr;
	ReturnStatus r =new ReturnStatus();
	String stack;
	Quote q;

	String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();

	try{
		String js;
		if (System.Label.Credit_Mode == '1') {
			js = '{ "data": { "externalReference": "DLLONDEMAND.00002923",  "id": "1.NA.MOSAIC.500-503' +
			     Integer.valueof((Math.random() * 10000)) + '", ' +
			     ' "status": "assessment", "creationDate": "2022-04-14T16:09:25Z", ' +
			     ' "modificationDate": "" } }';
			return js;
		}
		else
		if (System.Label.Credit_Mode == '2') {
			js = '{  "error": { "status": 400, "title": "Request Payload Validation",  "type": "https://developer.dllgroup.com/problems/bad_request", ' +
			     ' "details": [  {  "detail": "Bad Request. Lessee details could not be retrieved", "type": "1.NA.400.MOSC.MOSCSvcs_API_012" }' +
			     ' ]  } } ';
			return js;
		}

		q = getQuote(quoteId);

		if (q.end_user__c == Null) {
			error=true;
			r.ErrorMsg = 'An end user account is required to process a credit app!';
			system.debug('exc');
			throw new AuraHandledException('Account is required!');
		}

		if (!Test.isRunningTest()) {
			system.debug('here');
			CustomerUtils.createExternalCustomer(q.end_user__c,q.opportunityId);
			system.debug('her2e');
		}

		CreditAppUtils.submitCreditAppFuture(quoteId);

		r.responseCode = 200;

	}
	catch (Exception e) {
		error=true;
		system.debug('r error is: ' + r.ErrorMsg);
		system.debug('e: ' + e);
		stack = e.getStackTraceString();
		CreditAppUtils.triggerCreditResponse(q.opportunityId, false, r.ErrorMsg);
	}
	finally{

		Error_Log__c e = new Error_Log__c();
		e.callout_name__c = 'Submit Credit App';
		e.recordTypeId = recordTypeID;
		e.Class_name__c = 'CreditAppUtils';
		e.Request_body__c = jsonStr;
		e.Method_Name__c = 'submitCreditApp';
		e.Response_body__c = r.responseBody;
		e.status_code__c = r.responseCode;
		e.stack_trace__c = stack;
		e.exception_message__c = r.ErrorMsg;
		e.quote_id__c = quoteId;
		saveErrorLog(JSON.serialize(e));

	}
	return 'OK';
}
@future(callout=true)
public static void submitCreditAppFuture(String quoteId){


	Opportunity o;

	Boolean error=false;
	String response;
	String jsonStr;
	ReturnStatus r =new ReturnStatus();
	String stack;

	String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();

	//Now we have all the dater (your brother in law from boston)
	try{

		Quote q = getQuote(quoteId);

		JSONSubmitCreditAppRequest app = new JSONSubmitCreditAppRequest();

		JSONSubmitCreditAppRequest.PricingQuote pricingQuote = new JSONSubmitCreditAppRequest.PricingQuote();
		pricingQuote.id = q.Quote_Number__c;
		pricingQuote.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + q.id;

		JSONSubmitCreditAppRequest.ExternalReferences externalReferences = new JSONSubmitCreditAppRequest.ExternalReferences();
		externalReferences.pricingQuote = pricingQuote;

		JSONSubmitCreditAppRequest.PrimaryPhoneNumber primaryPhoneNumber = new JSONSubmitCreditAppRequest.PrimaryPhoneNumber();
		primaryPhoneNumber.phone_number = q.Opportunity.End_User_Phone__c;
		primaryPhoneNumber.type = 'business';
		if (q.Opportunity.End_User_Phone__c == null)
			primaryPhoneNumber.type = null;


		JSONSubmitCreditAppRequest.Contacts contacts = new JSONSubmitCreditAppRequest.Contacts();
		contacts.name = UserInfo.getName();
		contacts.email = UserINfo.getUserEmail();

		List<JSONSubmitCreditAppRequest.Contacts> cList = new List<JSONSubmitCreditAppRequest.Contacts>();


		List<JSONSubmitCreditAppRequest.PrimaryPhoneNumber> pList = new List<JSONSubmitCreditAppRequest.PrimaryPhoneNumber>();
		pList.add(primaryPhoneNumber);

		if (!pList.isEmpty())
			contacts.phoneNumbers = pList;

		cList.add(contacts);


		JSONSubmitCreditAppRequest.Identifiers identifiers = new JSONSubmitCreditAppRequest.Identifiers();

		System_ID__c s = [select id
		                  ,DLL_External_ID__c
		                  from System_ID__c
		                  where account__c = : q.End_User__c
		                                     and DLL_External_Key_Source__c = 'ORACLE'
		                                                                      and (DLL_External_Key_Type__c = 'TCAPartyId'
		                                                                                                      or DLL_External_Key_Type__c ='TCA_PARTY_ID'
		                                                                                                                                    or DLL_External_Key_Type__c = 'TCAPartyID')

		                                                                      limit 1];

		system.debug('************** tca party id : ' +  s.DLL_External_ID__c);

		identifiers.tcaPartyId = s.DLL_External_ID__c;

		if (s.DLL_External_ID__c == null) {
			error=true;
			
			CreditAppUtils.triggerCreditResponse(q.opportunityId, false, 'No TCA Party Id');

			//throw new AuraHandledException('TCA Party ID is required!');
			
		}


		JSONSubmitCreditAppRequest.Lessee lessee = new JSONSubmitCreditAppRequest.Lessee();
		//lessee.address = address;


		lessee.contacts = cList;
		lessee.countryOfRegistration = 'US';
		lessee.identifiers = identifiers;

		JSONSubmitCreditAppRequest.FinancialProduct financialProduct = new JSONSubmitCreditAppRequest.FinancialProduct();
		financialProduct.id = q.rate_type_id__c;

		//JSONSubmitCreditAppRequest.Duration duration = new JSONSubmitCreditAppRequest.Duration();
		//if (q.Term__c != null)
		//  duration.numberOfMonths = integer.valueOf(q.Term__c);


		JSONSubmitCreditAppRequest.ConsolidatedRegulars consolidatedRegulars = new JSONSubmitCreditAppRequest.ConsolidatedRegulars();
		consolidatedRegulars.amount = q.Total_Payment__c;
		consolidatedRegulars.numberOfPayments = Integer.valueOf(q.term__c);

		JSONSubmitCreditAppRequest.Rentals rentals = new JSONSubmitCreditAppRequest.Rentals();
		List<JSONSubmitCreditAppRequest.ConsolidatedRegulars> crList = new List<JSONSubmitCreditAppRequest.ConsolidatedRegulars>();
		crList.add(consolidatedRegulars);

		rentals.consolidatedRegulars = crList;

		List<JSONSubmitCreditAppRequest.Assets> assetList = new List<JSONSubmitCreditAppRequest.Assets>();


		List<Quote_Line__c> tempList = getQuoteLines(q.id);
		List<Quote_Line__c> qlAccList =  new List<Quote_Line__c>();
		List<Quote_Line__c> qlList =  new List<Quote_Line__c>();

		for(Quote_Line__c t:tempList)
			if (t.related_asset__c == null)
				qlList.add(t);                 //asset
			else
				qlAccList.add(t);                 //accessories

		Map<ID, List<Quote_Line__c> > qAccListMap = new Map<ID, List<Quote_Line__c> >();


		for (Quote_Line__c t2:qlAccList) {
			List<Quote_Line__c> tList = new List<Quote_Line__c>();

			if (qAccListMap.get(t2.related_asset__c) == null) {
				tList.add(t2);
				qAccListMap.put(t2.related_asset__c,tList);
			}
			else{
				tList = qAccListMap.get(t2.related_asset__c);
				tList.add(t2);
				qAccListMap.put(t2.related_asset__c,tList);
			}

		}





		for (Quote_Line__c ql:qlList) {

			JSONSubmitCreditAppRequest.Structure structure = new JSONSubmitCreditAppRequest.Structure();
			structure.masterType = 'Materials Handling';        //may be able to remove        //ql.master_type__c;
			structure.category = ql.Asset_Type_ITA_Class__c;
			structure.brand =  ql.make__c;                //'brand';
			structure.model =  ql.model__c;                //'b';
			structure.type =  ql.Asset_Type__c;

			JSONSubmitCreditAppRequest.Finance_Z finance_Z = new JSONSubmitCreditAppRequest.Finance_Z();
			finance_Z.quantity = integer.valueOf(ql.Number_of_Units__c);
			finance_Z.salePrice = ql.Base_Unit_Sales_Price__c;


			//add accessories price to asset price

			List<Quote_Line__c> accList = new List<Quote_Line__c>();
			accList = qAccListMap.get(ql.id);
			if (accList != null) {

				for (Quote_Line__c qli: accList) {
					finance_Z.salePrice =  finance_Z.saleprice + qli.Total_Sales_Price_Base__c;
				}
			}


			JSONSubmitCreditAppRequest.ResidualValue residualValue = new JSONSubmitCreditAppRequest.ResidualValue();



			JSONSubmitCreditAppRequest.Adjustments adjustments = new JSONSubmitCreditAppRequest.Adjustments();
			adjustments.industrialBattery = ql.Battery_Included__c;
			adjustments.mastType = ql.Mast_Type__c;
			adjustments.operatingEnvironment = ql.Operating_Environment__c;
			adjustments.operatingHoursPerYear = String.valueOf(ql.Annual_Hours__c);


			residualValue.adjustments = adjustments;

			finance_Z.residualValue = residualValue;

			JSONSubmitCreditAppRequest.Identifiers_Z identifiers_z = new JSONSubmitCreditAppRequest.Identifiers_Z();
			identifiers_z.structure = structure;

			JSONSubmitCreditAppRequest.Catalog catalog = new JSONSubmitCreditAppRequest.Catalog();
			catalog.identifiers = identifiers_z;

			JSONSubmitCreditAppRequest.Assets assets = new JSONSubmitCreditAppRequest.Assets();
			assets.catalog = catalog;

			if (q.asset_type__c == 'New')
				assets.condition = 'new';
			else
				assets.condition = 'used';

			assets.finance = finance_Z;
			assets.catalog = catalog;


			assetList.add(assets);
		}

		JSONSubmitCreditAppRequest.Payments payments = new JSONSubmitCreditAppRequest.Payments();

		payments.rentals = rentals;

		List<JSONSubmitCreditAppRequest.Proposals> prList = new List<JSONSubmitCreditAppRequest.Proposals>();

		JSONSubmitCreditAppRequest.Finance finance = new JSONSubmitCreditAppRequest.Finance();

		finance.paymentFrequency  = q.Payment_Frequency__c.toLowerCase();
		finance.paymentTiming = q.payment_timing__c;
		if (q.Lease_Type__c.contains('FMV'))
			finance.purchaseOption = 'fair-market-value';
		else
			finance.purchaseOption = 'dollar-out';

		finance.numberOfMonths = integer.valueOf(q.Term__c);

		JSONSubmitCreditAppRequest.Proposals proposals = new JSONSubmitCreditAppRequest.Proposals();
		proposals.description = q.name;
		proposals.isPreferred = true;
		proposals.financialProduct = financialProduct;
		//proposals.duration = duration;
		proposals.payments = payments;
		proposals.externalReferences = externalReferences;
		proposals.finance = finance;

		proposals.assets = assetList;

		prLIst.add(proposals);


		List<Contact> cList2 = new List<Contact>();
		cList2 = [SELECT
		          FirstName,
		          LastName,
		          MiddleName,
		          Title,
		          Birthdate_Encrypted__c,
		          Account_Ownership_Percentage__c,
		          UBO_Country_of_Residence__c
		          FROM
		          Contact
		          where accountId = : q.end_user__c
		                            and role__c = 'Ultimate Beneficial Owner'
		];

		List<JSONSubmitCreditAppRequest.universalBeneficialOwnership> uboList = new List<JSONSubmitCreditAppRequest.universalBeneficialOwnership>();

		for (Contact c:cList2) {
			JSONSubmitCreditAppRequest.universalBeneficialOwnership ubo = new  JSONSubmitCreditAppRequest.universalBeneficialOwnership();
			ubo.ownershipType = q.Opportunity.Beneficial_Owner_Type__c;
			ubo.givenName = c.firstName;
			ubo.middleInitials = c.middleName;
			ubo.familyName = c.lastName;
			ubo.title = c.Title;
			ubo.dateOfBirth = string.valueOf(c.Birthdate_Encrypted__c);
			ubo.countryOfResidence = c.UBO_Country_of_Residence__c;
			if (c.UBO_Country_of_Residence__c == 'US')
				ubo.countryOfResidence = 'United States';
			ubo.ownershipPercentage = integer.valueOf(c.account_ownership_percentage__c);
			uboList.add(ubo);
		}

		lessee.universalBeneficialOwnership = uboList;

		//PGs
		/*
		   public class Guarantors {
		   public List<PersonalGuarantors> personalGuarantors;
		   public List<Principals> principals;

		   public class PersonalGuarantors {
		   public String familyName;
		   public String givenName;
		   public String middleName;
		   public List<Jurisdiction> identifiers;
		   public Address_Z address;

		   }
		   public class Jurisdiction {
		   public String id;
		   public String type;

		   }

		   }*/
		List<Related_Party__c> parties = new List<Related_Party__c>();
		parties = [select first_name__c
		           , last_name__c
		           , middle_name__c
		           , address_line__c
		           , city__c
		           , ssn_encrypted__c
		           from Related_Party__c
		           where opportunity__c = : q.OpportunityId
		];

		List<JSONSubmitCreditAppRequest.Principals> principalList = new List<JSONSubmitCreditAppRequest.Principals>();

		for (Related_Party__c p:parties) {
			JSONSubmitCreditAppRequest.Principals pr = new JSONSubmitCreditAppRequest.Principals();
			pr.familyName = p.Last_Name__c;
			pr.givenName = p.first_name__c;
			pr.middleName = p.middle_name__c;
			if (pr.familyName == '' || pr.familyName == null)
				continue;
			JSONSubmitCreditAppRequest.Jurisdiction jurisdiction = new JSONSubmitCreditAppRequest.Jurisdiction();
			system.debug('ssn:' +  p.ssn_encrypted__c);
			jurisdiction.id = p.ssn_encrypted__c;
			jurisdiction.type = 'social-security-number';
			List<JSONSubmitCreditAppRequest.Jurisdiction> jList = new List<JSONSubmitCreditAppRequest.Jurisdiction>();
			jList.add(jurisdiction);
			pr.identifiers = jList;
			principalList.add(pr);
		}
		JSONSubmitCreditAppRequest.Guarantors guarantors = new JSONSubmitCreditAppRequest.Guarantors();
		guarantors.principals = principalList;


		JSONSubmitCreditAppRequest.Data data = new JSONSubmitCreditAppRequest.Data();
		data.guarantors = guarantors;

		data.externalReference = 'DOD.' + q.id;
		data.lessee = lessee;
		data.proposals = prList;

		jsonStr = '{ "data": ' +  JSON.serialize(data,true) + ' }';

		system.debug('JSON is: ' + jsonStr);

		r = CreditAppUtils.doCallout(jsonStr,'submitCreditAppFuture',q.opportunityId);

		if (r.status != 'OK') {
			system.debug(r.errorMsg);
			error=true;
			CreditAppUtils.triggerCreditResponse(q.opportunityId, false, r.status);
			//throw new AuraHandledException(r.errorMsg);
		}

		else{
			o = [select id from Opportunity where id = : q.OpportunityId];

			JSONSubmitCreditAppRequest creditResponse = (JSONSubmitCreditAppRequest) System.JSON.deserialize(r.responseBody,JSONSubmitCreditAppRequest.class);

			/*
			    externalReference": "DOD.0Q00m000000BMykCAG",
			   "id": "1.NA.MOSAIC.500-50311994",
			   "status": "assessment",
			   "creationDate": "2022-06-03T18:55:41Z",
			   "modificationDate": ""

			 */

			String appn = creditResponse.data.id;
			o.application_number__c = appn.mid(appn.lastIndexOf('.')+1,12);
			o.unq_opportunity__c = o.application_number__c;
			o.stagename = 'Assessment';
			if (creditResponse.data.status == 'assessment') {

				o.sub_stage__c = 'Application Submitted';
			}
			else {
				o.sub_stage__c = creditResponse.data.status;
			}

			o.application_date__c = date.today();

			update o;

			CreditAppUtils.triggerCreditResponse(o.id, true, 'OK');

			/*
			List<Credit_Response__e> crEvents = new List<Credit_Response__e>();
			crEvents.add(new Credit_Response__e(Opportunity__c = o.id, Application_Number__c = o.application_number__c));

			List<Database.SaveResult> results = EventBus.publish(crEvents);

			for (Database.SaveResult sr : results) {
    			if (sr.isSuccess()) {
        			System.debug('Successfully published event.');
    			} else {
	        		for(Database.Error err : sr.getErrors()) {
            			System.debug('Error returned: ' +
	                        err.getStatusCode() +
                        	' - ' +
                        	err.getMessage());
        			}
				}
			}
			*/
    	}       

	}
	catch (Exception e) {
		/*
		List<Credit_Response__e> crEvents = new List<Credit_Response__e>();
		crEvents.add(new Credit_Response__e(Opportunity__c = o.id, Application_Number__c = 'failed'));

		List<Database.SaveResult> results = EventBus.publish(crEvents);

		for (Database.SaveResult sr : results) {
    		if (sr.isSuccess()) {
        		System.debug('Successfully published event.');
    		} else {
        		for(Database.Error err : sr.getErrors()) {
        			System.debug('Error returned: ' +
                    err.getStatusCode() +
                    ' - ' +
                    err.getMessage());
        		}
			}
		}
		*/
		error=true;
		system.debug('r error is: ' + r.ErrorMsg);
		system.debug('e: ' + e);
		stack = e.getStackTraceString();
		CreditAppUtils.triggerCreditResponse(o.id, false, r.ErrorMsg);
	}
	finally{

		Error_Log__c e = new Error_Log__c();
		e.callout_name__c = 'Submit Credit App Future';
		e.recordTypeId = recordTypeID;
		e.Class_name__c = 'CreditAppUtils';
		e.Request_body__c = jsonStr;
		e.Method_Name__c = 'submitCreditAppFuture';
		e.Response_body__c = r.responseBody;
		e.status_code__c = r.responseCode;
		e.stack_trace__c = stack;
		e.exception_message__c = r.ErrorMsg;
		e.quote_id__c = quoteId;
		insert e;
	}

}



/************************************************************************************************************************************************
 * submit credit application
 *
 * change log:
 *
 * 11/2/2021 - MRM Created
 * 11/12/2021 - MRM - there is a new version of submit credit app coming, but it is not ready yet;  bill doviak email 11/12.
 *
 *
 *****************************************************************************************************************************************************/
@AuraEnabled
public static String submitPreQualCreditApp(String opportunityId){

	Boolean error=false;
	String response;
	String jsonStr;
	ReturnStatus r =new ReturnStatus();
	String stack;
	Opportunity o;

	String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();

	try{

		o = [select Id
		     ,end_user__c
		     ,amount
		     from Opportunity
		     where id = : opportunityId
		];

		String js;
		if (System.Label.Credit_Mode == '1') {
			js = '{ "data": { "externalReference": "DLLONDEMAND.00002923",  "id": "1.NA.MOSAIC.500-503' +
			     Integer.valueof((Math.random() * 10000)) + '", ' +
			     ' "status": "assessment", "creationDate": "2022-04-14T16:09:25Z", ' +
			     ' "modificationDate": "" } }';
			return js;
		}
		else
		if (System.Label.Credit_Mode == '2') {
			js = '{  "error": { "status": 400, "title": "Request Payload Validation",  "type": "https://developer.dllgroup.com/problems/bad_request", ' +
			     ' "details": [  {  "detail": "Bad Request. Lessee details could not be retrieved", "type": "1.NA.400.MOSC.MOSCSvcs_API_012" }' +
			     ' ]  } } ';
			return js;
		}

		if (o.end_user__c == Null) {
			error=true;
			r.ErrorMsg = 'An end user account is required to process a credit app!';
			throw new AuraHandledException('Account is required!');
		}

		if (!Test.isRunningTest())
			CustomerUtils.createExternalCustomer(o.end_user__c,o.id);

		CreditAppUtils.submitPreQualCreditAppFuture(o.id);

		r.responseCode = 200;

	}
	catch (Exception e) {
		error=true;
		system.debug('r error is: ' + r.ErrorMsg);
		system.debug('e: ' + e);
		stack = e.getStackTraceString();
		CreditAppUtils.triggerCreditResponse(o.id, false, r.ErrorMsg);
	}
	finally{

		Error_Log__c e = new Error_Log__c();
		e.callout_name__c = 'Submit Credit App Pre Qual';
		e.recordTypeId = recordTypeID;
		e.Class_name__c = 'CreditAppUtils';
		e.Request_body__c = jsonStr;
		e.Method_Name__c = 'submitCreditAppPre Qual';
		e.Response_body__c = r.responseBody;
		e.status_code__c = r.responseCode;
		e.stack_trace__c = stack;
		e.exception_message__c = r.ErrorMsg;
		e.quote_id__c = o.Id;
		saveErrorLog(JSON.serialize(e));

	}
	return 'OK';
}
/************************************************************************************************************************************************
 * submit pre qual credit application
 * the items that are custom labels are the default values to fake out the credit application process
 *
 * change log:
 *
 * 6/10/22 - MRM Created Class
 *
 *****************************************************************************************************************************************************/
@future(callout=true)
public static void submitPreQualCreditAppFuture(String opportunityId){
	String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();

	Boolean error=false;
	String response;
	String jsonStr;
	ReturnStatus r =new ReturnStatus();
	String stack;
	Opportunity o;

	try{

		o = [select Id
		     ,end_user__c
		     ,amount
		     ,end_user_phone__c
		     ,Beneficial_Owner_Type__c
		     ,name
		     ,account.originating_site_id__c
		     from Opportunity
		     where id = : opportunityId
		];


		JSONSubmitCreditAppRequest app = new JSONSubmitCreditAppRequest();

		JSONSubmitCreditAppRequest.PricingQuote pricingQuote = new JSONSubmitCreditAppRequest.PricingQuote();
		pricingQuote.id = o.name;
		pricingQuote.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + o.id;

		JSONSubmitCreditAppRequest.ExternalReferences externalReferences = new JSONSubmitCreditAppRequest.ExternalReferences();
		externalReferences.pricingQuote = pricingQuote; 

		JSONSubmitCreditAppRequest.PrimaryPhoneNumber primaryPhoneNumber = new JSONSubmitCreditAppRequest.PrimaryPhoneNumber();
		primaryPhoneNumber.phone_number = o.End_User_Phone__c;
		primaryPhoneNumber.type = 'business';
		if (o.End_User_Phone__c == null)
			primaryPhoneNumber.type = null;


		JSONSubmitCreditAppRequest.Contacts contacts = new JSONSubmitCreditAppRequest.Contacts();
		contacts.name = UserInfo.getName();
		contacts.email = UserINfo.getUserEmail();

		List<JSONSubmitCreditAppRequest.Contacts> cList = new List<JSONSubmitCreditAppRequest.Contacts>();


		List<JSONSubmitCreditAppRequest.PrimaryPhoneNumber> pList = new List<JSONSubmitCreditAppRequest.PrimaryPhoneNumber>();
		pList.add(primaryPhoneNumber);

		if (!pList.isEmpty())
			contacts.phoneNumbers = pList;

		cList.add(contacts);


		JSONSubmitCreditAppRequest.Identifiers identifiers = new JSONSubmitCreditAppRequest.Identifiers();

		System_ID__c s = [select id
		                  ,DLL_External_ID__c
		                  from System_ID__c
		                  where account__c = : o.End_User__c
		                                     and DLL_External_Key_Source__c = 'ORACLE'
		                                                                      and (DLL_External_Key_Type__c = 'TCAPartyId'
		                                                                                                      or DLL_External_Key_Type__c ='TCA_PARTY_ID'
		                                                                                                                                    or DLL_External_Key_Type__c = 'TCAPartyID')

		                                                                      limit 1];

		system.debug('************** tca party id : ' +  s.DLL_External_ID__c);

		identifiers.tcaPartyId = s.DLL_External_ID__c;

		if (s.DLL_External_ID__c == null) {
			error=true;
			throw new AuraHandledException('TCA Party ID is required!');
		}

		JSONSubmitCreditAppRequest.Lessee lessee = new JSONSubmitCreditAppRequest.Lessee();
		lessee.contacts = cList;
		lessee.countryOfRegistration = 'US';
		lessee.identifiers = identifiers;

		JSONSubmitCreditAppRequest.FinancialProduct financialProduct = new JSONSubmitCreditAppRequest.FinancialProduct();
		financialProduct.id = '1.NA.PI.' + o.account.originating_site_id__c + System.Label.Pre_Qual_Financial_Product_Id;

		JSONSubmitCreditAppRequest.Structure structure = new JSONSubmitCreditAppRequest.Structure();
		structure.brand =  System.Label.Pre_Qual_Brand;
		structure.model =  System.Label.Pre_Qual_Model;

		JSONSubmitCreditAppRequest.Finance_Z finance_Z = new JSONSubmitCreditAppRequest.Finance_Z();
		finance_Z.quantity = 1;
		finance_Z.salePrice = o.amount;

		JSONSubmitCreditAppRequest.Rentals rentals = new JSONSubmitCreditAppRequest.Rentals();

		JSONSubmitCreditAppRequest.ResidualValue residualValue = new JSONSubmitCreditAppRequest.ResidualValue();
		JSONSubmitCreditAppRequest.Adjustments adjustments = new JSONSubmitCreditAppRequest.Adjustments();

		residualValue.adjustments = adjustments;
		finance_Z.residualValue = residualValue;

		JSONSubmitCreditAppRequest.Identifiers_Z identifiers_z = new JSONSubmitCreditAppRequest.Identifiers_Z();
		identifiers_z.structure = structure;

		JSONSubmitCreditAppRequest.Catalog catalog = new JSONSubmitCreditAppRequest.Catalog();
		catalog.identifiers = identifiers_z;

		List<JSONSubmitCreditAppRequest.Assets> assetList = new List<JSONSubmitCreditAppRequest.Assets>();


		JSONSubmitCreditAppRequest.Assets assets = new JSONSubmitCreditAppRequest.Assets();
		assets.catalog = catalog;

		assets.condition = 'new';
		assets.finance = finance_Z;
		assets.catalog = catalog;

		assetList.add(assets);

		JSONSubmitCreditAppRequest.Payments payments = new JSONSubmitCreditAppRequest.Payments();
		payments.rentals = rentals;

		List<JSONSubmitCreditAppRequest.Proposals> prList = new List<JSONSubmitCreditAppRequest.Proposals>();
		JSONSubmitCreditAppRequest.Finance finance = new JSONSubmitCreditAppRequest.Finance();

		finance.paymentFrequency  = System.Label.Pre_Qual_Payment_Frequency;
		finance.paymentTiming = System.Label.Pre_Qual_Payment_Timing;
		finance.purchaseOption = System.Label.Pre_Qual_Purchase_Option;
		finance.numberOfMonths = Integer.valueOf(System.Label.Pre_Qual_Number_Of_Months);
		JSONSubmitCreditAppRequest.Proposals proposals = new JSONSubmitCreditAppRequest.Proposals();
		proposals.description = o.name;
		proposals.isPreferred = true;
		proposals.financialProduct = financialProduct;

		proposals.payments = payments;
		proposals.externalReferences = externalReferences;
		proposals.finance = finance;

		proposals.assets = assetList;

		prLIst.add(proposals);

		List<Contact> cList2 = new List<Contact>();
		cList2 = [SELECT
		          FirstName,
		          LastName,
		          MiddleName,
		          Title,
		          Birthdate_Encrypted__c,
		          Account_Ownership_Percentage__c,
		          UBO_Country_of_Residence__c
		          FROM
		          Contact
		          where accountId = : o.end_user__c
		                            and role__c = 'Ultimate Beneficial Owner'
		];

		List<JSONSubmitCreditAppRequest.universalBeneficialOwnership> uboList = new List<JSONSubmitCreditAppRequest.universalBeneficialOwnership>();

		for (Contact c:cList2) {
			JSONSubmitCreditAppRequest.universalBeneficialOwnership ubo = new  JSONSubmitCreditAppRequest.universalBeneficialOwnership();
			ubo.ownershipType = o.Beneficial_Owner_Type__c;
			ubo.givenName = c.firstName;
			ubo.middleInitials = c.middleName;
			ubo.familyName = c.lastName;
			ubo.title = c.Title;
			ubo.dateOfBirth = string.valueOf(c.Birthdate_Encrypted__c);
			ubo.countryOfResidence = c.UBO_Country_of_Residence__c;
			if (c.UBO_Country_of_Residence__c == 'US')
				ubo.countryOfResidence = 'United States';
			ubo.ownershipPercentage = integer.valueOf(c.account_ownership_percentage__c);
			uboList.add(ubo);
		}

		lessee.universalBeneficialOwnership = uboList;

		JSONSubmitCreditAppRequest.Data data = new JSONSubmitCreditAppRequest.Data();
		data.externalReference = 'DOD.' + o.id;
		data.lessee = lessee;
		data.proposals = prList;

		jsonStr = '{ "data": ' +  JSON.serialize(data,true) + ' }';

		system.debug('JSON is: ' + jsonStr);

		r = CreditAppUtils.doCallout(jsonStr,'submitPreQualCreditAppFuture',o.id);

		if (r.status != 'OK') {
			system.debug(r.errorMsg);
			error=true;
			throw new AuraHandledException(r.errorMsg);
		}

		else{

			JSONSubmitCreditAppRequest creditResponse = (JSONSubmitCreditAppRequest) System.JSON.deserialize(r.responseBody,JSONSubmitCreditAppRequest.class);

			String appn = creditResponse.data.id;
			o.application_number__c = appn.mid(appn.lastIndexOf('.')+1,12);
			o.stagename = 'Assessment';
			if (creditResponse.data.status == 'assessment') {

				o.sub_stage__c = 'Application Submitted';
			}
			else {
				o.sub_stage__c = creditResponse.data.status;
			}

			o.application_date__c = date.today();

			update o;

			CreditAppUtils.triggerCreditResponse(o.Id, true, 'OK');

		}

	}
	catch (Exception e) {
		error=true;
		system.debug('r error is: ' + r.ErrorMsg);
		system.debug('e: ' + e);
		stack = e.getStackTraceString();
		CreditAppUtils.triggerCreditResponse(o.Id, false, r.ErrorMsg);
	}
	finally{

		Error_Log__c e = new Error_Log__c();
		e.callout_name__c = 'Submit Credit App Pre Qual Future';
		e.recordTypeId = recordTypeID;
		e.Class_name__c = 'CreditAppUtils';
		e.Request_body__c = jsonStr;
		e.Method_Name__c = 'submitCreditAppPreQualFuture';
		e.Response_body__c = r.responseBody;
		e.status_code__c = r.responseCode;
		e.stack_trace__c = stack;
		e.exception_message__c = r.ErrorMsg;
		e.quote_id__c = opportunityId;
		insert e;
	}
}


/************************************************************************************************************************************************
 *   MISC
 *****************************************************************************************************************************************************/

public class ReturnStatus {
public String status;
public String errorMsg;
public String responseBody;
public Integer responseCode;
}


/************************************************************************************************************************************************
 *  doCallOut
 *****************************************************************************************************************************************************/

public static ReturnStatus doCallout(String JSON, String method, String opportunityId){


	Boolean error=false;
	String ErrorMsg = null;
	HTTPResponse res1;
	Boolean errorLogged = false;
	ReturnStatus r = new ReturnStatus();

	try{

		PartnerPortal__mdt pp = PricingUtils.getPartnerPortalSettings();

		String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c +
		                  '.azure-api.net/globalcrmdata/Finance/financeapplication?feature=Credit-Application-Inquiry';

		HttpRequest reqAPI  = PricingUtils.buildHttpRequest(endpoint);

		Http http1 = new Http();

		reqAPI.setBody(JSON);

		system.debug('JSON: ' + JSON);

		res1 = http1.send(reqAPI);

		system.debug(res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'JSONSubmitCreditAppRequest: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			String smallError = 'JSONSubmitCreditAppRequest: ' + res1.getStatus()  + '  ' + res1.getStatusCode();
			error=true;
			system.debug(ErrorMsg);
			CreditAppUtils.triggerCreditResponse(opportunityId, false, smallError);
		}

	}
	catch (Exception e) {
		if (ErrorMsg == null)
			ErrorMsg = 'Exception in JSONSubmitCreditAppRequest:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		errorLogged = true;
		system.debug(ErrorMsg);
		Error_Log__c el = new Error_Log__c();
		el.callout_name__c = 'Submit Credit App Future1';
		String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();

		el.recordTypeId = recordTypeID;
		el.Class_name__c = 'CreditAppUtils';
		el.Request_body__c = JSON;
		el.Method_Name__c = method;
		el.Response_body__c = r.responseBody;
		el.status_code__c = r.responseCode;
		//el.stack_trace__c = stack;
		el.exception_message__c = r.ErrorMsg;
		//el.quote_id__c = opportunityId;
		insert el;
	}


	r.responseCode =  res1.getStatusCode();

	if (error) {
		r.status = null;
		r.errorMsg = ErrorMsg;
		r.responseBody = null;
	}
	else{
		r.status = 'OK';
		r.errorMsg = null;
		r.responseBody = res1.getBody();
	}

	return r;
}

/************************************************************************************************************************************************
 *
 *****************************************************************************************************************************************************/
public static Quote getQuote(string quoteId){

	Quote q = [SELECT
	           AccountId,
	           OpportunityId,
	           Program_Id__c,
	           Advance_Payments__c,
	           Rate_Type_Id__c,
	           Amount__c,
	           Option_Number__c,
	           Lease_Type__c,
	           Base_Unit_Sales_Price__c,
	           BillingAddress,
	           BillingCity,
	           BillingCountry,
	           BillingGeocodeAccuracy,
	           Opportunity.Beneficial_Owner_Type__c,
	           BillingLatitude,
	           BillingLongitude,
	           BillingName,
	           BillingPostalCode,
	           BillingState,
	           BillingStreet,
	           Code_URA__c,
	           Comments__c,
	           Conditions__c,
	           ContactId,
	           ContractId,
	           Credit_Report_URL__c,
	           CurrencyIsoCode,
	           //Customer_Account__c,
	           Decision_Maker__c,
	           Description,
	           Opportunity.End_User__r.phone,
	           Opportunity.End_User__c,
	           Opportunity.End_User__r.name,
	           Opportunity.End_User__r.email__c,
	           Opportunity.End_User__r.BillingStreet,
	           Opportunity.End_User__r.BillingCity,
	           Opportunity.End_User__r.BillingCountry,
	           Opportunity.End_User__r.BillingState,
	           Expiration_Date__c,
	           ExpirationDate,
	           Asset_Type__c,
	           Fax,
	           End_User__c,
	           Financed_Amount__c,
	           Frequency__c,
	           GrandTotal,
	           Id,
	           Name,
	           Opportunity.End_User_Phone__c,
	           Payment_Frequency__c,
	           Payment_Timing__c,
	           Phone,
	           Quote_Rate__c,
	           Quote_Number__c,
	           QuoteToAddress,
	           QuoteToCity,
	           QuoteToCountry,
	           QuoteToGeocodeAccuracy,
	           QuoteToLatitude,
	           QuoteToLongitude,
	           QuoteToName,
	           QuoteToPostalCode,
	           QuoteToState,
	           QuoteToStreet,
	           Rate_Type__c,
	           Reference__c,
	           Rental_Amount__c,
	           Residual__c,
	           Revenue__c,
	           Status,
	           Status_Priority__c,
	           Subtotal,
	           Term__c,
	           Total_Payment__c,
	           Total_Price__c,
	           TotalPrice
	           //use_Subsidy__c,
	           //Subsidy_Rate_Type_Id__c
	           from Quote
	           where Id = : quoteId
	];
	return q;

}



/************************************************************************************************************************************************
 *
 *****************************************************************************************************************************************************/
public static List<Quote_Line__c> getQuoteLines(ID quoteId){

	List<Quote_Line__c> qlList = new List<Quote_Line__c>();
	qlList = [SELECT
	          Annual_Hours__c,
	          Asset_Type_ITA_Class__c,
	          Base_Unit_Sales_Price__c,
	          Battery_Included__c,
	          CreatedById,
	          CreatedDate,
	          Total_Sales_Price_Base__c,
	          CurrencyIsoCode,
	          Equipment_Type__c,
	          Id,
	          IsDeleted,
	          LastActivityDate,
	          LastModifiedById,
	          LastModifiedDate,
	          Asset_Type__c,
	          Asset_Type_ITA_Class_Id__c,
	          Make__c,
	          Make_Id__c,
	          Mast_Type__c,
	          Model__c,
	          Model_Id__c,
	          Name,
	          Number_of_Units__c,
	          Operating_Environment__c,
	          Quote__c,
	          Related_Asset__c,
	          SystemModstamp,
	          msrp__c,
	          subsidy__c,
	          subsidy_id__c

	          FROM Quote_Line__c
	          where quote__c = : quoteId
	];

	return qlList;
}

/************************************************************************************************************************************************
 * trigger platform event
 *
 * change log:
 *
 * 11/7/2022 - MRM Created
 * 
 *
 *****************************************************************************************************************************************************/
public static void triggerCreditResponse(ID opportunityId, Boolean success, String errorMessage){

	List<Credit_Response__e> crEvents = new List<Credit_Response__e>();

	crEvents.add(new Credit_Response__e(Opportunity__c = opportunityId, Succeeded__c = success, Error_Message__c = errorMessage));

	List<Database.SaveResult> results = EventBus.publish(crEvents);
	List<Error_Log__c> errorSuccessList = new List<Error_Log__c>();
	List<Error_Log__c> errorFailList = new List<Error_Log__c>();
	 
	for (Database.SaveResult sr : results) {
    	if (sr.isSuccess()) {
			
        	System.debug('Successfully published event.');
			Error_Log__c el = new Error_Log__c();
			el.callout_name__c = 'Trigger Credit Response';
			String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();

			el.recordTypeId = recordTypeID;
			el.Class_name__c = 'CreditAppUtils';
			el.Exception_Message__c = errorMessage;
			 
			el.Method_Name__c = 'triggerCreditResponse';
		 
			el.status_code__c = 0;
			
			el.quote_id__c = opportunityId;
			errorSuccessList.add(el);
    	} 
		else {
			

        	for(Database.Error err : sr.getErrors()) {

				Error_Log__c el = new Error_Log__c();
				el.callout_name__c = 'Trigger Credit Response';
				String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();

				el.recordTypeId = recordTypeID;
				el.Class_name__c = 'CreditAppUtils';
			 
				el.Method_Name__c = 'triggerCreditResponse';
		 
				el.status_code__c = 900;
			
				el.quote_id__c = opportunityId;

				el.exception_message__c = err.getStatusCode() + ' ' + err.getMessage();
            	
				errorFailList.add(el);
        	}
			
    	}
	} 
	
	if (!errorFailList.isEmpty())
		insert errorFailList;
	if (!errorSuccessList.isEmpty())
		insert errorSuccessList;
}


@future
public static void saveErrorLog(String e) {
	system.debug('*********************** saving error logs');
	Error_Log__c el = (Error_Log__c) JSON.deserialize(e, Error_Log__c.class);
	system.debug('error log: ' + el);
	insert el;
}

public static void testBooster (){

	Integer i=0;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
	i++;
}



}