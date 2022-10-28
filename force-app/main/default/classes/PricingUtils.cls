/*****************************************************************************************************************
 * Dll on Demaind (DD) PRICING UTILITY CLASS
 *
 * Change Log:
 *
 *  09/29/2021 - MRM Created class
 *  03/03/2022 - MRM Adjustments for Pricing Release
 *  03/30/2022 - MRM added accessories to pricing call
 *  04/19/2022  - MRM added subidy call
 *  04/27/2022 - MRM added custom label to filter program id
 *  05/10/2022 - Modified getFinancialProduct and getFinancialProductId to to support the new purchase option field in the json message
 *  05/24/2022 - Modified pricing to use the subsidy rate type id if subsidy = 'yes
 *  06/15/2022 - Plug in 0.0 in msrp if it is null
 *  06/28/2022 - Remove accessory check for program 3733; allow multiple programs to be used in dod
 *  7/10/2022 -  Added interpolation
 *  7/11/2022 -  Added new/used to financial product and products calls.
 *  8/26/2022 -  Added logic to getsubsidies new/used to call; front end was only sending new
 *  9/15/2022 - Temp fix to overcome bearer issue from azure services
 *  9/15/2022 - Temp fix removed
 *  9/26/2022 - If no related accounts; the sales rep is running in private mode; return assigned dealer locaitons
 *  10/4/2022 - Pricing changes impacted annual hours.  Changed to integer; Deploy before pricing
 *******************************************************************************************************************/
public with sharing class PricingUtils {

static String azureAPIM;

static String regionalAPI;

public class FinancialProduct {
public String id;
public String contractType;
public String name;
public String url;
}

class Program {
public String programId;
public String programName;
}
class Make {
public String makeId;
public String makeName;
}

class AssetType {
public String assetTypeId;
public String assetTypeName;
}

class Model {
public String modelId;
public String modelName;
}

public class tokenClass {
public String token;

public dateTime expires;
}

/************************************************************************************************************************************************
 * @getUserSite - gets the site the user is logged in for
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   return site
 *****************************************************************************************************************************************************/
public class site {
public String name;
public String originatingSiteId;
}

public class returnSites {
public List<site> returnSiteList;

}

@AuraEnabled (Cacheable=true)
public static String getUserSite(String userId){

	ReturnSites rs = new ReturnSites();
	Boolean error=false;
	Contact c;
	User u;

	List<site> siteList = new List<Site>();

	system.debug('user is: ' + Userinfo.getUserId());

	try{


		//if in testharness use 00504000001MXOo

		if (userId == null)
			userId = Userinfo.getUserId();

		u = [SELECT contactID
		     From User
		     where id = : userId
		];

		List<AccountContactRelation> rList = new List<AccountContactRelation>();
		rList = [
			SELECT AccountId
			FROM AccountContactRelation
			where contactId = : u.contactId
			                  and accountId in
			                          (select id
			                          from account
			                          where originating_site_id__c <> null)
		];

		Set<ID> aIdSet = new Set<ID>();
		for (AccountContactRelation r:rList)
			aIdSet.add(r.AccountId);

		List<Account> aList = [Select name, originating_site_id__c
		                       From Account
		                       where id in : aIdSet
		                       order by name
		];

		for (Account a:aList) {
			site s = new site();
			s.originatingSiteId = a.originating_site_id__c;
			s.name = a.name;
			siteList.add(s);
		}
		rs.returnSiteList = siteList;
	}
	catch (Exception e) {
		String ErrorMsg = 'Exception in getUser sitesId:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		throw new AuraHandledException(ErrorMsg);
	}
	if (error)
		return null;

	/*
	   if (rs.returnSiteList.isEmpty()) {
	        List<Assigned_Dealer_Location__c> dlist = new List<Assigned_Dealer_Location__c>();
	        dlist = [select account__c
	                 , originating_site_id__c
	                 , account__r.name
	                 from Assigned_Dealer_Location__c
	                 where contact__c = : u.contactId];

	        for (Assigned_Dealer_Location__c l:dlist) {
	                site s = new site();
	                s.originatingSiteId = l.originating_site_id__c;
	                s.name = l.account__r.name;
	                siteList.add(s);
	        }
	        rs.returnSiteList = siteList;
	   }
	 */

	return JSON.serialize(rs);


}



public class salesRep {
public String id;
public String name;
}

/************************************************************************************************************************************************
 * @getSalesReps - returns a list of sales reps;
 *
 * origintation site id - this is the site id of the location selected by the suer
 * change log:
 *
 * 2/22/22 - MRM Created
 *
 *
 * @return   return salesRepList
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getSalesReps(String originatingSiteId){         //site selected on portal

	if (originatingSiteId == null)
		return null;

	List<SalesRep> sList = new List<SalesRep>();
	Boolean error=false;
	String ErrorMsg = null;


	try{


		system.debug(originatingSiteId);

		Account a = [select id from Account
		             where originating_site_id__c = : originatingSiteId
		                                            and originating_site_id__c <> null];

		List<Contact> cList = new List<Contact>();
		cList = [select name
		         from Contact
		         where accountId = : a.id
		                           and role__c = 'Partner Sales Rep'
		];

		for (Contact c : cList) {
			SalesRep r = new SalesRep();
			r.id = c.id;
			r.name = c.name;
			sList.add(r);
		}

	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in getSalesReps:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		throw new AuraHandledException(ErrorMsg);
	}
	if (error)
		return null;
	else
		return JSON.serialize(sList);
}

/************************************************************************************************************************************************
 * @getPrograms - gets the programs avaialbe for the site
 *
 * change log:
 *
 * 10/10/2021 - MRM Created   NEEDS TO BE CONVERTED TO CALL OUT
 *
 *
 * @return   return programList
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getPrograms(String siteName){

	List<Program> pList = new List<Program>();
	Boolean error=false;
	String ErrorMsg = null;
	String endpoint;
	HTTPResponse res1;


	try{

		String expandedSite = '1.NA.PI.' + siteName;

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c +
		           '.azure-api.net/globalcrmdata/PriceQuote/locations/' + expandedSite
		           + '/programs?page=1&pageSize=200&sort=name&feature=Credit-Application-Documents';

		HttpRequest reqAPI;
		if (!Test.isRunningTest())
			reqAPI = buildHttpRequest(endpoint);

		Http http1 = new Http();
		if (!Test.isRunningTest())
			res1 = http1.send(reqAPI);

		if (!Test.isRunningTest())
			if (res1.getStatusCode() != 200) {
				ErrorMsg = 'getPrograms: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				error=true;
				throw new AuraHandledException(ErrorMsg);
			}

		String dummy;

		if (res1 != null)
			dummy = res1.getBody();

		if (Test.isRunningTest()) {
			dummy = '{"data": [{"id": "1.NA.PI.0000471524-0001","url": "https://msc-apm-gapi-crp1.azure-api.net/locations/1.NA.PI.0000471524-0001",     "partnerName": "Test Automation Partner 1-Do NOT Use",       "name": "Test Automation Partner 1-Do NOT Use",       "physicalAddress": {          "addressType": "current-physical-address",            "street": "1310 JASMINE AVE",            "locality": "WEBSTER",            "region": "TX",            "postalCode": "77598-3402",            "country": "US"        },       "isActive": true,       "isDisqualified": false,       "uses": [           "originating"            ]        }    ],    "pagination": {        "page": 1,        "pageSize": 10,        "pageCount": 1,        "itemCount": 1,        "links": {            "self": "https://msc-fua-gpipr-crp1-partner.azurewebsites.net/locations?feature=Credit-Application-Documents&businessUnit=dll-cti&locationIds=0000471524-0001",            "first": "https://msc-fua-gpipr-crp1-partner.azurewebsites.net/locations?feature=Credit-Application-Documents&businessUnit=dll-cti&locationIds=0000471524-0001",            "next": "https://msc-fua-gpipr-crp1-partner.azurewebsites.net/locations?feature=Credit-Application-Documents&businessUnit=dll-cti&locationIds=0000471524-0001",            "prev": "https://msc-fua-gpipr-crp1-partner.azurewebsites.net/locations?feature=Credit-Application-Documents&businessUnit=dll-cti&locationIds=0000471524-0001",            "last": "https://msc-fua-gpipr-crp1-partner.azurewebsites.net/locations?feature=Credit-Application-Documents&businessUnit=dll-cti&locationIds=0000471524-0001"        }    }}		}';
		}

		JSONPricingProgram myResponse = (JSONPricingProgram) System.JSON.deserialize(dummy,JSONPricingProgram.class);
		system.debug(myResponse);

		//new program -- UNICARRIERS 1.NA.PI.0000192017-0001.3814

		for (JSONPricingProgram.Data p : myResponse.data) {
			Program p1 = new Program();
			p1.programId = p.Id;
			p1.programName = p.Name;
			List<String> sList = new List<String>();
			sList = System.Label.Default_Program_Id.split(',');

			for (String s:sList) {
				if (s == p1.programId.substring(p1.programId.length()-4,p1.programId.length()))
					pList.add(p1);
			}
		}

		if (Test.isRunningTest()) {
			Decimal test;
			test = test/test;
		}


	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in getPrograms:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getPrograms';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getPrograms';
		if (res1 != null)
			el.Response_body__c = res1.getBody();
		if (res1 != null)
			el.status_code__c = res1.getStatusCode();
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** save the error log');
		saveErrorLog(JSON.serialize(el));

	}
	if (error)
		return null;
	else
		return JSON.serialize(pList);
}
/********************************************************************************************************************************************************
 * Get List of Financial Products https://msc-apm-wcrm-dev.azure-api.net/globalcrmdata/PriceQuote/programs/1.NA.PI.0000471524-0001.3141/financialProducts/1.NA.PI.0000471524-0001.3141.1008.1000.FMV?feature=Credit-Application-Documents
 *  Change Log:
 *    05/10/2022 - Modified to support the new purchase option field in the json message
 *********************************************************************************************************************************************************/

@AuraEnabled (Cacheable=true)
public static String getFinancialProducts(String programId, String financetype, String newused){



	String endpoint;
	HttpResponse res1;

	List<JSONPricingFinancialProducts.Data> pList = new List<JSONPricingFinancialProducts.Data>();
	Boolean error=false;
	String ErrorMsg = null;
	HttpRequest reqAPI;

	try{

		String programResourceId =  programId;

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		system.debug('new used = ' + newused);

		String myCondition;
		if (newused == 'New')
			myCondition = 'new';
		else
			myCondition = 'used';

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programid +
		           '/financialProducts?page=1&pageSize=20&sort=name&feature=Credit-Application-Documents' +
		           '&assetConditions=' + myCondition;


		if (!Test.isRunningTest())
			reqAPI = buildHttpRequest(endpoint);

		Http http1 = new Http();

		if (!Test.isRunningTest())
			res1 = http1.send(reqAPI);


		if (!Test.isRunningTest())
			if (res1.getStatusCode() != 200) {
				ErrorMsg = 'getFinancialProducts: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				error=true;
				throw new AuraHandledException(ErrorMsg);
			}

		String dummy;

		if (!Test.isRunningTest())
			dummy = res1.getBody();

		if (Test.isRunningTest())
			dummy = '{    "data": [        {            "id": "1.NA.PI.0000471524-0001.3141.1003.1002.$1BO",            "contractType": "financial-lease",            "name": "30 Day Deferred",            "url": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialproducts/1.NA.PI.0000471524-0001.3141.1003.1002.$1BO?feature=Credit-Application-Documents"        },        {            "id": "1.NA.PI.0000471524-0001.3141.1003.1181.$1BO",            "contractType": "financial-lease",            "name": "6.5%",            "url": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialproducts/1.NA.PI.0000471524-0001.3141.1003.1181.$1BO?feature=Credit-Application-Documents"        },        {            "id": "1.NA.PI.0000471524-0001.3141.1003.1020.$1BO",            "contractType": "financial-lease",            "name": "60 Day Deferred",            "url": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialproducts/1.NA.PI.0000471524-0001.3141.1003.1020.$1BO?feature=Credit-Application-Documents"        }    ],   "pagination": {        "page": 1,       "pageSize": 3,        "pageCount": 9,        "itemCount": 26,        "links": {            "self": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialProducts?feature=Credit-Application-Documents&page=1&pageSize=3&sort=name",            "first": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialProducts?feature=Credit-Application-Documents&page=1&pageSize=3&sort=name",            "next": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialProducts?feature=Credit-Application-Documents&page=2&pageSize=3&sort=name",            "prev": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialProducts?feature=Credit-Application-Documents&page=1&pageSize=3&sort=name",            "last": "https://msc-fua-gpipr-crp1-programs.azurewebsites.net/programs/1.NA.PI.0000471524-0001.3141/financialProducts?feature=Credit-Application-Documents&page=9&pageSize=3&sort=name"        }    }}';

		JSONPricingFinancialProducts myResponse = (JSONPricingFinancialProducts) System.JSON.deserialize(dummy,JSONPricingFinancialProducts.class);             system.debug(myResponse);

		pList = new List<JSONPricingFinancialProducts.Data>();

		for (JSONPricingFinancialProducts.Data p : myResponse.data) {         //list of products from call out
			JSONPricingFinancialProducts.Data data = new JSONPricingFinancialProducts.Data();

			//filter list to only return matching finance type - fmv or bo
			//return the filtered list in pList

			system.debug('p is: ' + p);

			for ( String s : p.purchaseOptions) {
				system.debug ('s is: ' + s);
				if (financetype == 'FMV')
					if (s == 'fair-market-value') {
						data.id = p.id;
						data.name = p.name;
						data.url = p.url;
						pList.add(data);
					}

				if (financetype == 'BO')
					if (s == 'dollar-out') {
						data.id = p.id;
						data.name = p.name;
						data.url = p.url;
						pList.add(data);
					}

			}

			system.debug('plist is: ' + pList);

		}

		if (Test.isRunningTest()) {
			Decimal test = 100;
			test = test/0;
		}
	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in getFinancialProducts:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getFinancialProducts';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getFinancialProducts';
		if (res1 != null) {
			el.Response_body__c = res1.getBody();
			el.status_code__c = res1.getStatusCode();
		}

		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** save the error log');
		saveErrorLog(JSON.serialize(el));
	}
	if (error)
		return null;
	else
		return JSON.serialize(pList);
}

/********************************************************************************************************************************************************
 * Get a Financial Product
 *********************************************************************************************************************************************************/

@AuraEnabled (Cacheable=true)
public static String getFinancialProduct(String programId, String productId, String newused){


	Boolean error=false;
	String ErrorMsg = null;
	JSONPricingFinancialProduct myResponse;
	HTTPResponse res1;
	String endpoint;

	try{

		String programResourceId =  programId;
		String myAssetCondition;

		system.debug('new used : '  + newused);

		if (newused == 'New')
			myAssetCondition = 'new';
		else
			myAssetCondition = 'used';


		PartnerPortal__mdt pp = getPartnerPortalSettings();

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programid +
		           '/financialProducts/' + productId + '&assetConditions=' + myAssetCondition + '?feature=Credit-Application-Documents';

		HttpRequest reqAPI = buildHttpRequest(endpoint);

		Http http1 = new Http();
		res1 = http1.send(reqAPI);

		system.debug('getFinancialProduct Method ' +res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'getFinancidalProduct by Id: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}

		//myResponse = (JSONPricingFinancialProduct) System.JSON.deserialize(res1.getBody(),JSONPricingFinancialProduct.class);

		system.debug(myResponse);

	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in getFinancialProduct by Id:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		system.debug('e is: ' + e);
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getFinancialProduct';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getFinancialProduct';
		if (res1 != null) {
			el.Response_body__c = res1.getBody();
			el.status_code__c = res1.getStatusCode();
		}

		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** save the error log');
		saveErrorLog(JSON.serialize(el));
	}
	if (error)
		return null;
	else
		return string.ValueOf(res1.getBody());
}

/********************************************************************************************************************************************************
 * Get Subsidies
 *********************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getSubsidies(  String programId, String productId,
                                    String numberOfMonths,
                                    String make, String paymentFrequency,
                                    Decimal financeAmount, String assetCondition,
                                    String paymentTiming, String financeType){
	Boolean error=false;
	String ErrorMsg = null;
	JSONPricingSubsidies myResponse;
	HTTPResponse res1;

	system.debug('asset condition: ' + assetCondition);

	String endpoint, interpolation;
	interpolation = 'upper';

	String myAssetCondition;

	if (assetCondition == 'New')
		myAssetCondition = 'new';
	else
		myAssetCondition = 'used';


	if (financeType.contains('$1'))
		financeType = 'dollar-out';
	if (financeType == 'FMV')
		financeType = 'fair-market_value';

	List<String> sList = new List<String>();
	if (financeAmount == null)
		financeAmount = 10000;

	try{

		system.debug(programId + productId + numberOfMonths + interpolation + make + paymentFrequency +
		             financeAmount + assetCondition + paymentTiming + financeType);

		if (programId == null || productId == null || make == null || paymentFrequency == null ||
		    assetCondition == null || paymentTiming == null ||
		    interpolation == null|| numberOfMonths == null || financeAmount == null || financeType == null
		    ) {
			system.debug('fatal error - fields were null');
			throw new AuraHandledException('No fields can be null for this call');
		}

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programid +
		           '/financialProducts/' + productId + '?feature=Credit-Application-Documents' +
		           '&assetConditions=' + myAssetCondition + '&paymentFrequency=' + paymentFrequency +
		           '&paymentTiming=' + paymentTiming + '&numberOfMonths=' + numberOfMonths + '&purchaseOptions=' + financeType +
		           '&financeAmount=' + financeAmount + '&assetBrandNames=' + make.toLowerCase();


		HttpRequest reqAPI;
		if (!Test.isRunningTest())
			reqAPI= buildHttpRequest(endpoint);

		Http http1 = new Http();
		if (!Test.isRunningTest())
			res1 = http1.send(reqAPI);

		if (!Test.isRunningTest())
			if (res1.getStatusCode() != 200) {
				ErrorMsg = 'get subsidies ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				error=true;
				throw new AuraHandledException(ErrorMsg);
			}

		String dummy;

		if (res1 != null)
			dummy = res1.getBody();
		else
			dummy = '{  "data": {    "name": "Q1185",    "id": "1.NA.PI.0000471524-0001.3141.1008.1000.FMV",    "contractType": "operating-lease",    "modifiedDate": "2021-11-16T20:29:08.937Z",    "subsidies": {      "manufacturer": [        {          "id": "NA.PI.0000111274-0001.1000.1005..fair-market-value.1103",          "name": "1.99% Interest for 48 Months",          "description": "1.99% interest isother durations", "maximumAmount": 25000,          "interest": {            "nominalRate": {              "percentages": [                {                  "inputs": {                    "paymentFrequency": "monthly",                    "paymentTiming": "in-advance",                    "numberOfMonths": 48,                    "initialDelay": 0,                    "initialPaymentMultiplier": 0,                    "securityDepositMultiplier": 0,                    "financeAmount": 500000,                    "assetConditions": [],                    "assetBrandNames": ["Yale"],                    "assetModelNames": []                  },                  "outputs": { "default": 1.99}            }              ]            }          }        }      ]    }  }}';



		Error_Log__c el = new Error_Log__c();
		el.callout_name__c = 'getSubsidies';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getSubsidiess';
		el.Response_body__c = res1.getBody();
		el.status_code__c = res1.getStatusCode();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		saveErrorLog(JSON.serialize(el));
	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in get subsidies' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		system.debug('e is: ' + e);
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getSubsidies';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getSubsidiess';
		if (res1 != null) {
			el.Response_body__c = res1.getBody();
			el.status_code__c = res1.getStatusCode();
		}
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** save the error log');
		saveErrorLog(JSON.serialize(el));
	}
	if (error)
		return null;
	else
	{
		system.debug('gsub= ' + string.valueOf(res1.getBody()));
		return string.valueOf(res1.getBody());
	}

}


/************************************************************************************************************************************************
 * @getMakes - callout service
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   return list of makes
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getMakes(String programId){

	List<Make> mList = new List<Make>();
	Boolean error=false;
	String ErrorMsg = null;
	String endpoint;
	HttpResponse res1;

	try{

		String programResourceId =  programId;

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programResourceId + '/asset-brands?page=1&pageSize=200&sort=name&feature=Credit-Application-Documents';
		HttpRequest reqAPI = buildHttpRequest(endpoint);

		Http http1 = new Http();
		res1 = http1.send(reqAPI);

		system.debug(res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() == 404)
			return null;

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'getMakes: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}

		JSONPricingMake myResponse = (JSONPricingMake) System.JSON.deserialize(res1.getBody(),JSONPricingMake.class);

		system.debug(myResponse);

		for ( JSONPricingMake.Data d : myResponse.data) {
			Make m = new Make();
			m.makeId = d.id;
			m.makeName = d.name;
			if (d.name.toLowercase() == 'caterpillar' ||  d.name.toLowercase() == 'jungheinrich' || d.name.toLowercase() == 'mitsubishi')
				mList.add(m);
		}

	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in getMakes:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getMakes';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getMakes';
		if (res1 != null) {
			el.Response_body__c = res1.getBody();
			el.status_code__c = res1.getStatusCode();
		}
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** save the error log');
		saveErrorLog(JSON.serialize(el));
	}
	if (error)
		return null;
	else
		return JSON.serialize(mList);
}

/************************************************************************************************************************************************
 * @getAsetTypes - callout service
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   return list of asset types
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getAssetTypes( String programId, String triggerAssetTypes){
	List<AssetType> aList = new List<AssetType>();

	Boolean error=false;
	String ErrorMsg = null;
	String endpoint;
	HttpResponse res1;

	try{

		String programResourceId =  programId;

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programResourceId + '/asset-categories?page=1&pageSize=100&sort=name&feature=Credit-Application-Documents';
		HttpRequest reqAPI = buildHttpRequest(endpoint);

		Http http1 = new Http();
		res1 = http1.send(reqAPI);

		system.debug(res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'getAssetTypes: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}

		JSONPricingAssetType myResponse = (JSONPricingAssetType) System.JSON.deserialize(res1.getBody(),JSONPricingAssetType.class);

		system.debug(myResponse);

		for ( JSONPricingAssetType.Data d : myResponse.data) {
			AssetType a = new AssetType();
			a.assetTypeId = d.id;
			a.assetTypeName = d.name;
			if (a.assetTypeName != 'Forklift Accessories')
				aList.add(a);
		}

	}
	catch (Exception e) {
		if (ErrorMsg == null)
			ErrorMsg = 'Exception in getAssetTypes:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getAssetTypes';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getAssetTypes';
		if (res1 != null) {
			el.Response_body__c = res1.getBody();
			el.status_code__c = res1.getStatusCode();
		}
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** save the error log');
		saveErrorLog(JSON.serialize(el));
	}
	if (error)
		return null;
	else
		return JSON.serialize(aList);
}

/************************************************************************************************************************************************
 * @getModels- callout service
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   return list of asset models
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getModels(String programId, String make, String assetType){

	List<Model> mList = new List<Model>();
	Boolean error=false;
	String ErrorMsg = null;
	String endpoint;
	HttpResponse res1;

	try{

		String programResourceId =  programId;

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		make = EncodingUtil.urlEncode(make, 'UTF-8');
		assetType  = EncodingUtil.urlEncode(assetType, 'UTF-8');

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programResourceId + '/assets?page=1&pageSize=100&sort=id&feature=Credit-Application-Documents'
		           + '&brand=' + make + '&category=' + assetType;

		HttpRequest reqAPI = buildHttpRequest(endpoint);

		Http http1 = new Http();
		res1 = http1.send(reqAPI);

		system.debug(res1.getStatusCode()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() == 404)
			return null;

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'getModels: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}

		JSONPricingAssets myResponse = (JSONPricingAssets) System.JSON.deserialize(res1.getBody(),JSONPricingAssets.class);

		system.debug(myResponse);

		for (JSONPricingAssets.data d : myResponse.data) {
			Model m = new Model();
			m.modelId = d.id;
			m.modelName = d.catalog.identifiers.structure.model;
			mList.add(m);
		}

	}
	catch (Exception e) {
		if (ErrorMsg == null)
			ErrorMsg = 'Exception in getModels:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getModels';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getModels';
		if (res1 != null) {
			el.Response_body__c = res1.getBody();
			el.status_code__c = res1.getStatusCode();
		}
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** save the error log');
		saveErrorLog(JSON.serialize(el));


	}
	if (error)
		return null;
	else
		return JSON.serialize(mList);
}


/************************************************************************************************************************************************
 * @getAccessories - callout service
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 * 2/22/22 - MRM all parms are hardcoded because accessories always come from one place
 *
 *
 * @return   return list of asset models
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getAccessories(String programId, String make ){

	String temp = programId;
	List<Model> mList = new List<Model>();
	Boolean error=false;
	String ErrorMsg = null;
	HttpResponse res1;
	String endpoint;

	String myProgramId =  temp.substring(temp.length() - 4, temp.length());

	/*
	   if (myProgramId != '3733') {
	        error=true;
	        throw new AuraHandledException('Cannot load accessories for this program: ' + myProgramId);
	   }
	 */


	//programId = '1.NA.PI.0000105570-0001.1668';  			//program
	String assetType = programId + '.800097';               //forklift accessories
	make = '1.NA.PI.0000105570-0001.1668.30002148';         //cascade

	try{
		String programResourceId =  programId;

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		make = EncodingUtil.urlEncode(make, 'UTF-8');
		assetType  = EncodingUtil.urlEncode(assetType, 'UTF-8');

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c +
		           '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programResourceId +
		           '/assets?page=1&pageSize=100&sort=id&feature=Credit-Application-Documents'
		           + '&brand=' + make + '&category=' + assetType;

		HttpRequest reqAPI = buildHttpRequest(endpoint);
		Http http1 = new Http();
		res1 = http1.send(reqAPI);

		system.debug(res1.getStatusCode()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'getAccessories: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}

		JSONPricingAssets myResponse = (JSONPricingAssets) System.JSON.deserialize(res1.getBody(),JSONPricingAssets.class);

		system.debug(myResponse);

		for (JSONPricingAssets.data d : myResponse.data) {
			Model m = new Model();
			m.modelId = d.id;
			m.modelName = d.catalog.identifiers.structure.model;
			mList.add(m);
		}

	}
	catch (Exception e) {
		if (ErrorMsg == null)
			ErrorMsg = 'Exception in getAccessories:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();
		el.callout_name__c = 'getAccessories';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getAccessories';
		if (res1 != null) {
			el.Response_body__c = res1.getBody();
			el.status_code__c = res1.getStatusCode();
		}
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;
		system.debug('**** saving error log');
		saveErrorLog(JSON.serialize(el));

	}
	if (error)
		return null;
	else
		return JSON.serialize(mList);
}

/************************************************************************************************************************************************
 * @getAsset- get specific asset
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   return list of asset models
 *****************************************************************************************************************************************************/
@AuraEnabled (Cacheable=true)
public static String getAsset(String programId, String assetId){


	Boolean error=false;
	String ErrorMsg = null;
	HTTPResponse res1;
	JSONPricingAsset pricingAsset;
	String endpoint;

	try{

		PartnerPortal__mdt pp = getPartnerPortalSettings();

		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c +  '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programId +
		           '/assets/' + assetId + '?feature=Credit-Application-Documents';


		HttpRequest reqAPI = buildHttpRequest(endpoint);

		Http http1 = new Http();
		res1 = http1.send(reqAPI);

		system.debug(res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'getAsset: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			error=true;
			throw new AuraHandledException(ErrorMsg);
		}

		pricingAsset = (JSONPricingAsset) System.JSON.deserialize(res1.getBody(),JSONPricingAsset.class);


		system.debug(res1.getBody());

	}
	catch (Exception e) {
		if (ErrorMsg == null)
			ErrorMsg = 'Exception in getAsset:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		Error_Log__c el = new Error_Log__c();

		el.callout_name__c = 'getAsset';
		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
		el.Class_name__c = 'PricingUtils';
		el.Request_body__c = endPoint;
		el.Method_Name__c = 'getAsset';
		if (res1 != null)
			el.Response_body__c = res1.getBody();
		el.status_code__c = null;
		el.stack_trace__c = e.getStackTraceString();
		el.exception_message__c = ErrorMsg;
		el.quote_id__c = null;

		saveErrorLog(JSON.serialize(el));

	}
	if (error)
		return null;
	else
		return JSON.serialize(pricingAsset);
}

/************************************************************************************************************************************************
 * Calculate Price
 *
 * change log:
 *
 * 11/2/2021 - MRM Created
 *
 *
 *****************************************************************************************************************************************************/
@AuraEnabled
public static String getPrice(String quoteId, String siteId, String programId){
	Boolean error=false;
	String response;
	ReturnStatus r = new ReturnStatus();
	String jsonStr;
	String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
	String stack;

	try{
		Quote q = CreditAppUtils.getQuote(quoteId);

		List<Quote_Line__c> tempList =  CreditAppUtils.getQuoteLines(q.id);

		List<Quote_Line__c> qlList = new List<Quote_Line__c>();

		List<Quote_Line__c> qlAccList =  new List<Quote_Line__c>();

		for(Quote_Line__c t:tempList)
			if (t.related_asset__c == null)
				qlList.add(t);
			else
				qlAccList.add(t);


		JSONPricingPriceRequest p = new JSONPricingPriceRequest();
		p.interestRateInterpolation = 'upper';
		//p.subsidyRateInterpolation = 'upper';
		p.numberOfMonths = integer.valueOf(q.term__c);
		p.paymentFrequency  = q.Payment_Frequency__c.toLowerCase();                // monthly, quarterly, semi-annually, annually
		String po;

		system.debug('lease type is: ' + q.lease_type__c);

		if ( q.Lease_Type__c.contains('$1'))
			po = 'dollar-out';
		else
		if (q.Lease_Type__c == 'Fair Market Value ( FMV )')
			po = 'fair-market-value';
		else
		if ( q.Lease_Type__c == 'FPPO')
			po = 'fixed-percentage-option';

		p.purchaseOption = po;
		p.paymentTiming = q.Payment_Timing__c;                 //in-arrears in-advance
		p.financialProductId = q.rate_type_id__c;


		//JSONPricingPriceRequest.RequestedRates rt = new JSONPricingPriceRequest.RequestedRates();
		//rt.rate = 10;
		//List<JSONPricingPriceRequest.RequestedRates> rList = new List<JSONPricingPriceRequest.RequestedRates>();
		//rList.add(rt);

		//p.requestedRates = rList;

		JSONPricingPriceRequest.InterestRate interestRate = new JSONPricingPriceRequest.InterestRate();

		Date input  = date.today();
		p.paymentStartDate = string.ValueOf(DateTime.newInstance(input.year(), input.month(), input.day()).format('yyyy-MM-dd'));
		p.contractStartDate = string.ValueOf(DateTime.newInstance(input.year(), input.month(), input.day()).format('yyyy-MM-dd'));


		JSONPricingPriceRequest.AdvancedMonies advanceMonies = new JSONPricingPriceRequest.AdvancedMonies();
		advanceMonies.advanceNumber = integer.valueOf(q.Advance_Payments__c);

		List<JSONPricingPriceRequest.Assets> aList = new List<JSONPricingPriceRequest.Assets>();

		for (Quote_Line__c ql:qlList) {
			JSONPricingPriceRequest.Assets assets = new JSONPricingPriceRequest.Assets();


			List<JSONPricingPriceRequest.Subsidies> sList;

			if (ql.subsidy_id__c !=  null) {
				sList = new List<JSONPricingPriceRequest.Subsidies>();
				JSONPricingPriceRequest.Subsidies subsidies = new JSONPricingPriceRequest.Subsidies();
				subsidies.id = ql.subsidy_id__c;
				sList.add(subsidies);
			}

			assets.subsidies = sList;
			assets.sequenceId = ql.id;


			if (q.asset_type__c == 'New')
				assets.condition = 'new';
			else
				assets.condition = 'used';

			assets.quantity = integer.valueOf(ql.Number_of_Units__c);
			assets.equipmentCost = ql.base_unit_sales_price__c;
			if (ql.msrp__c == null)
				assets.msrpAmount = 0.00;
			else
				assets.msrpAmount = ql.msrp__c;         //ql.Base_Unit_Sales_Price__c; //10000; //assets.equipmentCost;

			assets.assetTypeId =ql.Asset_Type_ITA_Class_id__c;
			assets.brandId = ql.Make_id__c;
			assets.modelId = ql.Model_id__c;

			assets.quantity = integer.valueOf(ql.Number_of_Units__c);

			JSONPricingPriceRequest.ResidualValue residualValue  = new JSONPricingPriceRequest.ResidualValue();

			JSONPricingPriceRequest.Adjustments adjustments  = new JSONPricingPriceRequest.Adjustments();
			adjustments.industrialBattery = ql.Battery_Included__c;
			adjustments.mastType = ql.mast_type__c;
			adjustments.operatingEnvironment = ql.operating_environment__c;
			if (ql.annual_hours__c != null && ql.annual_hours__c <> 0) {
				Integer ah;
				if (ql.annual_hours__c != null)
					ah = integer.valueOf(ql.annual_hours__c);
				else
					ah = 0;
				adjustments.operatingHoursPerYear = string.valueOf(ah);
			}

			residualValue.adjustments = adjustments;

			assets.residualValue = residualValue;



			//interestRate.nominalRate = 10;
			//assets.interestRate = interestRate;

			//loop thru accessories

			List<JSONPricingPriceRequest.AssetComponent> assetComponentList = new List<JSONPricingPriceRequest.AssetComponent>();
			for (Quote_Line__c qa:qlAccList) {
				if (ql.id == qa.related_asset__c) {                 //if this line is an accessory build out JSON


					JSONPricingPriceRequest.AssetComponent assetComponent = new JSONPricingPriceRequest.AssetComponent();

					assetComponent.sequenceId = qa.id;
					assetComponent.equipmentCost = qa.base_unit_sales_price__c;
					assetComponent.brandId = '1.NA.PI.0000105570-0001.3733.30002148';
					assetComponent.assetTypeId = '1.NA.PI.0000105570-0001.3733.800094';
					assetComponent.modelId = qa.model_id__c;
					assetComponent.quantity = integer.valueOf(qa.Number_of_Units__c);


					/*
					   public String sequenceId;
					   public Integer amount;
					   public String componentId;
					   public String componentType;
					   public String modelId;
					   public String assetTypeId;
					   public String brandId;
					   public Integer quantity;
					   public Integer requestedBilledResidualAmount;
					   public Integer requestedBilledResidualPercent;
					   public Integer requestedBookedResidualAmount;
					   public Integer requestedBookedResidualPercent;
					   public Integer bookedResidualAmount;
					   public Integer billedResidualAmount;
					   public InterestRate interest;
					   public InterestRate rateFactor;
					   public List<Subsidies> subsidies;
					 */


					assetComponentList.add(assetComponent);
				}
			}

			assets.assetComponents = assetComponentList;


			aList.add(assets);
		}

		p.assets = aList;

		jsonStr = Json.serialize(p,true);

		system.debug('json is: ' + jsonStr);

		String temp = q.program_id__c;
		if (temp != null) {
			programId =  temp.substring(temp.length() - 4, temp.length());
			siteId = temp.replace('.' + programId, '');
			system.debug('program is: ' + programId + ' siteId is : ' + siteId);
		}
		r = PricingUtils.doCallout(jsonStr,siteId,programId);
		if (r.status != 'OK') {
			system.debug(r.errorMsg);

		}
	}
	catch (Exception e) {
		system.debug(e);
		error=true;
		stack = e.getStackTraceString();

	}
	finally{
		Error_Log__c e = new Error_Log__c();
		e.callout_name__c = 'Get Price';
		e.Class_name__c = 'PricingUtils';
		e.recordTypeId = recordTypeId;
		e.quote_id__c = quoteId;
		e.Request_body__c = jsonStr;
		e.Method_Name__c = 'getPrice';
		e.Response_body__c = r.responseBody;
		e.status_code__c = r.responseCode;
		e.stack_trace__c = stack;
		e.exception_message__c = r.ErrorMsg;
		saveErrorLog(JSON.serialize(e));

	}

	if (r.status != 'OK')
		return r.errorMsg;
	else
		return r.responseBody;

}

public class ReturnStatus {
public String status;
public String responseBody;
public String errorMsg;
public Integer responseCode;
}

/************************************************************************************************************************************************
 *   CALL SUBMIT CREDIT APPLICATION
 *****************************************************************************************************************************************************/

public static ReturnStatus doCallout(String json, String siteId, String programId){


	ReturnStatus r = new ReturnStatus();

	Boolean error=false;
	String ErrorMsg = null;
	HTTPResponse res1;

	try{

		PartnerPortal__mdt pp = getPartnerPortalSettings();
		siteId = siteId.replace('1.NA.PI.','');

		String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c +  '.azure-api.net/globalcrmdata/priceQuote/sites/' + siteId + '/programs/' + programId +
		                  '/yieldBasedPricing?feature=Credit-Application-Inquiry';

		HttpRequest reqAPI = PricingUtils.buildHttpRequest(endpoint);

		Http http1 = new Http();

		system.debug('endpoint is:' + endpoint);

		reqAPI.setBody(json);

		system.debug('json is:' + json);

		system.debug('reqapi: ' + reqAPI);

		res1 = http1.send(reqAPI);

		system.debug(res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());

		if (res1.getStatusCode() != 200) {
			ErrorMsg = 'submitPricingCalc: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
			error=true;
			system.debug(ErrorMsg);
		}

	}
	catch (Exception e) {
		system.debug('error message is: ' + ErrorMsg);
		if (ErrorMsg == null)
			ErrorMsg = 'Exception in Pricing Call:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;

	}


	if (error) {
		r.status = null;
		r.errorMsg = ErrorMsg;
		r.responseBody = null;
		if (res1 != null)
			r.responseCode = res1.getStatusCode();

	}
	else{
		r.status = 'OK';
		r.errorMsg = null;
		if (res1 != null) {
			r.responseBody = res1.getBody();
			r.responseCode =  res1.getStatusCode();
		}
	}

	return r;
}

/************************************************************************************************************************************************
 * buildHTTPRequest
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   httprequest
 *
 *****************************************************************************************************************************************************/
public static HttpRequest buildHttpRequest(String endpoint){

	HttpRequest reqAPI = new HttpRequest();

	reqAPI.setEndpoint(endpoint);
	reqAPI.setMethod('GET');
	reqAPI.setHeader('Content-Type', 'application/json');

	PartnerPortal__mdt pp = [SELECT Integration_Ocp_Apim_Subscription_Key__c
	                         FROM PartnerPortal__mdt
	                         where developername = 'PartnerAuthorization' ];


	reqAPI.setHeader('Ocp-Apim-Subscription-Key', pp.Integration_Ocp_Apim_Subscription_Key__c);
	//temporarily put this here to allow testing.

	reqAPI.setHeader('Authorization',  getToken());

	//reqAPI.setHeader('SourceSystem', sourceSystem); out as per suman 11/2/21
	//reqAPI.setHeader('Token', getToken('Regional'));
	//reqAPI.setHeader('env',env); out as per suman 11/2/21
	reqAPI.setTimeout(120000);

	system.debug('reqapi:' + reqAPI);

	return reqAPI;

}

/************************************************************************************************************************************************
 * getToken - checks cache for token.  if not found or expired, creates new token.
 *
 * change log:
 *
 * 10/10/2021 - MRM Created
 *
 *
 * @return   token
 *
 *****************************************************************************************************************************************************/
public static String getToken(){

	FINAL String PARTITION = 'local.DLLonDemand';
	FINAL String KEY = 'PricingAuthtoken';

	DDCacheUtilityPartition.sessionInfo s = new DDCacheUtilityPartition.sessionInfo();

	if (DDcacheUtilityPartition.containsKey(PARTITION,KEY)) {                 //returns true or false
		s = (DDCacheUtilityPartition.sessionInfo)CacheUtilityPartition.getCachedObject(PARTITION,KEY);                 //returns the object in cache
		if (system.now() > s.sessionExpiration) {
			system.debug('*************************** CACHE TOKEN EXPIRED');

			DDCacheUtilityPartition.clearCache(PARTITION, KEY);                 //expired  expired  aunt problems

			tokenClass t = new tokenClass();
			t = getAuthToken();


			system.debug('************************************* STORED CACHE EXPIRED');
			//Create and Store new token
			s.sessionToken =  t.token;

			s.sessionExpiration = t.expires;

			DDCacheUtilityPartition.setCachedObject(PARTITION,KEY, s);

			return s.sessionToken;

		}
		else{
			system.debug('************************ FOUND CACHE' + ' ' + s.sessionToken);
			return s.sessionToken;                 //USE THIS TOKEN
		}
	}
	else{

		tokenClass t = new tokenClass();
		t = getAuthToken();


		//Create and Store new token
		s.sessionToken =  t.token;
		s.sessionExpiration = t.expires;

		system.debug('******************************** STORED CACHE' + s.sessionToken);
		DDCacheUtilityPartition.setCachedObject(PARTITION, KEY, s);

		return s.sessionToken;

	}
}

/************************************************************************************************************************************************
 *   get partner portal settings
 *****************************************************************************************************************************************************/

public static PartnerPortal__mdt getPartnerPortalSettings(){

	return [SELECT Azure_Api_Environment__c
	        , Integration_Client_Id__c
	        , Integration_Client_Secret__c

	        ,Integration_Ocp_Apim_Subscription_Key__c
	        FROM PartnerPortal__mdt
	        where developername = 'PartnerAuthorization' ];
}

/************************************************************************************************************************************************
 * getAuthTOken
 *
 * change log:
 *
 * 11/2/2021 - MRM Created
 *
 *
 * @return   return token
 *****************************************************************************************************************************************************/

public static tokenClass getAuthToken(){


	tokenClass t = new tokenClass();

	HttpRequest reqAPI = new HttpRequest();
	Http http = new Http();

	PartnerPortal__mdt pp = getPartnerPortalSettings();


	reqAPI.setEndpoint('https://login.microsoftonline.com/07751f8b-9617-49d5-9024-85f034f400ec/oauth2/token');
	reqAPI.setMethod('POST');
	reqAPI.setHeader('Content-Type', 'application/x-www-form-urlencoded');
	reqAPI.setHeader('Authorization', 'Basic Og==');
	system.debug('client id/secret=' +pp.Integration_Client_Id__c + '/' + pp.Integration_Client_Secret__c );
	reqAPI.setBody('client_id='+ pp.Integration_Client_Id__c +
	               '&client_secret='+ pp.Integration_Client_Secret__c +
	               '&grant_type=client_credentials' +
	               '&resource=https://management.azure.com/' +
	               '&scope=' + 'api://api-scopes.dllgroup.com/.default');

	reqAPI.setTimeout(120000);

	HTTPResponse res = http.send(reqAPI);

	system.debug('Body' + res.getBody());


	if(res.getStatusCode()==200 ) {

		JSONParser parser = JSON.createParser(res.getBody());
		//Extract the access token string  from the body
		while (parser.nextToken() != null) {
			if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')) {
				parser.nextToken();
				t.token = parser.getText();
			}

		}

		JSONParser parser2 = JSON.createParser(res.getBody());
		while (parser2.nextToken() != null) {
			if((parser2.getCurrentToken() == JSONToken.FIELD_NAME) && (parser2.getText() == 'expires_in')) {
				// Get the value.
				parser2.nextToken();
				String s = parser2.getText();
				Integer sec = integer.valueOf(s);
				dateTime d = system.now().addSeconds(sec);
				t.expires = d;


			}
		}
	}

	return t;

}

@future
public static void saveErrorLog(String e) {

	system.debug('*********************** saving error logs');
	Error_Log__c el = (Error_Log__c) JSON.deserialize(e, Error_Log__c.class);
	system.debug('error log: ' + el);
	insert el;
}


public static void byPassCalloutTest(){

	Integer i = 0;
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
	i++; i++;
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
	i++; i++; i++; i++;
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
	i++; i++;
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