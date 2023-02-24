public with sharing class AssetUtils {

	static String azureAPIM;
	
	static String regionalAPI;
	
	static Boolean recallOnServerErrorFlag = false;
	
	public class FinancialProduct {
		public String id;
		public String contractType;
		public String name;
		public String url;
	}
	
	public class Program {
		public String programId;
		public String programName;
	}
	public class Make {
		public String makeId;
		public String makeName;
	}
	
	public class AssetType {
		public String assetTypeId;
		public String assetTypeName;
	}
	
	public class Model {
		public String modelId;
		public String modelName;
	}
	
	public class Token {
		public String token;
		public dateTime expires;
	}	

	public class ErrorResponse {
		public String status;
		public String title;
		public String type;
		public List<Detail> details;
	}

	public class Detail {
		public String detail;
        public String type;
	}
    
    public class ReturnStatus {
        public String status;
        public String responseBody;
        public String errorMsg;
        public Integer responseCode;
	}

	
	public class Site {
		public String name;
		public String originatingSiteId;
	}
	
    public class returnSites {
        public List<site> returnSiteList;

    }
    
	
	/************************************************************************************************************************************************
	 * @getAllPrograms - gets the programs avaialbe for the site without passing through an additional static filter
	 *
	 * change log:
	 *
	 * 01/05/2023 - ATolbert created to enhance functionality of getPrograms
	 *
	 *
	 * @return   return JSON.serialize(List<Program>);
	 *****************************************************************************************************************************************************/

	@AuraEnabled (Cacheable=true)
	public static String getPrograms(String siteName){
	
		List<Program> pList = new List<Program>();
		Boolean error=false;
		String ErrorMsg = null;
		String endpoint;
		HTTPResponse res1;
	
		if(siteName == null) return null;
	
		try{
            System.debug('AssetUtils.getPrograms running');
			String expandedSite = '1.NA.PI.' + siteName;
	
			PartnerPortal__mdt pp = getPartnerPortalSettings();
	
			endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c +
					   '.azure-api.net/globalcrmdata/PriceQuote/locations/' + expandedSite
					   + '/programs?page=1&pageSize=200&sort=name&feature=Credit-Application-Documents';
				
			HttpRequest reqAPI;
			reqAPI = buildHttpRequest(endpoint);
	
			Http http1 = new Http();
			res1 = http1.send(reqAPI);

			if (res1.getStatusCode() != 200) {
				ErrorMsg = 'getPrograms: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				error=true;
				if(res1.getStatusCode() == 400) {
					ErrorResponse errResObj = (ErrorResponse)JSON.deserializeStrict(res1.getBody(), ErrorResponse.class); 
					if(errResObj != null && errResObj.details != null && errResObj.details.size() > 0) {
						ErrorMsg = errResObj.details[0].detail;
					} else {
						ErrorMsg = 'getPrograms states bad request ' + expandedSite;
					}
				} else if(res1.getStatusCode() == 404) {
					ErrorMsg = 'getPrograms failed to locate any programs related to the vendor ' + expandedSite;
				} else if(res1.getStatusCode() == 500) {
					
					if(!recallOnServerErrorFlag) {
						recallOnServerErrorFlag = true;
						String secondAttemptValue = getPrograms(siteName);
						System.debug('secondAttemptValue');
						System.debug(secondAttemptValue);
					} else {
						ErrorMsg = 'getPrograms: is still throwing a 500 Internal server error despite having already reattempted the call';
					}
				} else {
					System.debug('Uncaught ' + res1.getStatusCode() + ' status code on the getPrograms call');
				}

				throw new AuraHandledException(ErrorMsg);
			}
	
			String dummy;

			if (res1 != null)
				dummy = res1.getBody();
	
		
			JSONPricingProgram myResponse = (JSONPricingProgram) System.JSON.deserialize(dummy,JSONPricingProgram.class);
			System.debug(myResponse);	
	
			for (JSONPricingProgram.Data p : myResponse.data) {
				Program p1 = new Program();
				p1.programId = p.Id;
				p1.programName = p.Name;
				System.debug(p1);						
				pList.add(p1);
			}

		}
		catch (Exception e) {
			System.debug(e);
			if(ErrorMsg == null)
				ErrorMsg = e.getTypeName() + ' in getPrograms: ' + e.getMessage() + '. ' + e.getStackTraceString();
			error=true;
			Error_Log__c el = new Error_Log__c();
	
			el.callout_name__c = 'getPrograms';
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'AssetUtils';
			el.Request_body__c = endPoint;
			el.Method_Name__c = 'getPrograms';
			if (res1 != null)
				el.Response_body__c = res1.getBody();
			if (res1 != null)
				el.status_code__c = res1.getStatusCode();
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = ErrorMsg;
			el.quote_id__c = null;
			System.debug('**** save the error log');
			saveErrorLog(JSON.serialize(el));
	
		}	

		if (error) {
			throw new AuraHandledException(ErrorMsg);
		} else {
			return JSON.serialize(pList);
		}
		
	}

 
	/************************************************************************************************************************************************
	 * @getAllFinancialProducts - gets the financial products available for the program without using a financeType nor a new/used condition
	 *
	 * change log:
	 *
	 * 01/05/2023 - ATolbert created to enhance functionality of getPrograms
	 *
	 *
	 * @return   return JSON.serialize(List<JSONFinancialProducts.Data>);
	 *****************************************************************************************************************************************************/
	
	@AuraEnabled (Cacheable=true)
	public static String getFinancialProducts(String programId, String financeType, String newused){
	
		String endpoint;
		HttpResponse res1;
	
		List<JSONFinancialProducts.Data> pList = new List<JSONFinancialProducts.Data>();
		Boolean error=false;
		String ErrorMsg = null;
		HttpRequest reqAPI;
	
		if(programId == null) return null;
	
		try{
	
			String programResourceId =  programId;
	
			PartnerPortal__mdt pp = getPartnerPortalSettings();

			System.debug('new used = ' + newused);

			String myCondition;
			if (newused == 'New')
				myCondition = 'new';
			else
				myCondition = 'used';
	
			endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programid +
					   '/financialProducts?page=1&pageSize=200&sort=name&feature=Credit-Application-Documents';
					   
			if(newused != null) {
				endpoint += '&assetConditions=' + myCondition;
			}
				
			reqAPI = buildHttpRequest(endpoint);
	
			Http http1 = new Http();	
			res1 = http1.send(reqAPI);
	
			System.debug(res1);


			if (res1.getStatusCode() != 200) {

				error=true;
				if(res1.getStatusCode() == 400) {
					ErrorResponse errResObj = (ErrorResponse)JSON.deserializeStrict(res1.getBody(), ErrorResponse.class); 
					if(errResObj != null && errResObj.details != null && errResObj.details.size() > 0) {
						ErrorMsg = errResObj.details[0].detail;
					} else {
						ErrorMsg = 'getFinancialProducts states bad request ' + programResourceId;
					}
				} else if(res1.getStatusCode() == 404) {
					ErrorMsg = 'getFinancialProducts failed to locate any products related to the program ' + programResourceId;
				} else if(res1.getStatusCode() == 500) {
					
					if(!recallOnServerErrorFlag) {
						recallOnServerErrorFlag = true;
						String secondAttemptValue = getFinancialProducts(programId, financetype, newused);
						System.debug('secondAttemptValue');
						System.debug(secondAttemptValue);
					} else {
						ErrorMsg = 'getFinancialProducts: is still throwing a 500 Internal server error despite having already reattempted the call';
					}
				} else {
					System.debug('Uncaught ' + res1.getStatusCode() + ' status code on the getFinancialProducts call');
					ErrorMsg = 'getFinancialProducts: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				}

				throw new AuraHandledException(ErrorMsg);
			}

            System.debug(res1.getBody());

			String bodyString = res1.getBody();
            System.debug(bodyString);

			JSONFinancialProducts myResponse = (JSONFinancialProducts) System.JSON.deserialize(bodyString,JSONFinancialProducts.class);             
            System.debug(myResponse);
            if(myResponse.pagination != null && myResponse.pagination.itemCount == 0) {
                error= true;
                ErrorMsg = 'getFinancialProducts returned no products available for the program ' + programId;
                throw new AuraHandledException(ErrorMsg);
            }
            
			Map<String, String> financeTypeMap = new Map<String, String>{
				'FMV' => 'fair-market-value',
				'BO' => 'dollar-out'
			};
			if(financeTypeMap.containsKey(financetype)) {
				financetype = financeTypeMap.get(financetype);
			}
            System.debug(financeType);

			for (JSONFinancialProducts.Data p : myResponse.data) {         //list of products from call out
				JSONFinancialProducts.Data data = new JSONFinancialProducts.Data();
                System.debug(p);
				if(financetype != null) {
					for (String ft : p.purchaseOptions) {
						if (ft == financeType) {
							data.id = p.id;
							data.name = p.name;
							data.url = p.url;
                            data.purchaseOptions = p.purchaseOptions;
							pList.add(data);
						}
					}
				} else {
					
					data.id = p.id;
					data.name = p.name;
					data.url = p.url;
					data.purchaseOptions = p.purchaseOptions;
					pList.add(data);
				}
					
	
			}
	
		}
		catch (Exception e) {
			if(ErrorMsg == null)
				ErrorMsg = e.getTypeName() + ' in getFinancialProducts: ' + e.getMessage() + '. ' + e.getStackTraceString();
			error=true;
			Error_Log__c el = new Error_Log__c();
	
			el.callout_name__c = 'getFinancialProducts';
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'AssetUtils';
			el.Request_body__c = endPoint;
			el.Method_Name__c = 'getFinancialProducts';
			if (res1 != null) {
				el.Response_body__c = res1.getBody();
				el.status_code__c = res1.getStatusCode();
			}
	
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = ErrorMsg;
			el.quote_id__c = null;
			System.debug('**** save the error log');
			saveErrorLog(JSON.serialize(el));
		}

		if (error) {
			throw new AuraHandledException(ErrorMsg);
		} else {
			return JSON.serialize(pList);
		}

	}

 
	/************************************************************************************************************************************************
	 * @getFinancialProductInfo - gets the financial product information without defaulting a newused value if missing
	 *
	 * change log:
	 *
	 * 01/05/2023 - ATolbert created to enhance functionality of getFinancialProduct
	 *
	 *
	 * @return   return JSON.serialize(JSONFinancialProduct);
	 *****************************************************************************************************************************************************/

	@AuraEnabled (Cacheable=true)
	public static String getFinancialProduct(String programId, String productId, String newused){
	
	
		Boolean error=false;
		String ErrorMsg = null;
		JSONFinancialProduct myResponse;
		HTTPResponse res1;
		String endpoint;
	
		if(programId == null || productId == null) return null;
	
		try{
	
			String programResourceId =  programId;
			String myAssetCondition;	
	
			PartnerPortal__mdt pp = getPartnerPortalSettings();
	
			endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programid +
					   '/financialProducts/' + productId + '?feature=Credit-Application-Documents';
			
			if(newused != null) {
				if (newused.toLowerCase() == 'new') {
					endpoint += '&assetConditions=new';
				}
				else {
					endpoint += '&assetConditions=used';
				}
			}

			HttpRequest reqAPI = buildHttpRequest(endpoint);
	
			Http http1 = new Http();
			res1 = http1.send(reqAPI);
	
			System.debug('getFinancialProduct Method ' +res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());

			if (res1.getStatusCode() != 200) {

				error=true;
				if(res1.getStatusCode() == 400) {
					ErrorResponse errResObj = (ErrorResponse)JSON.deserializeStrict(res1.getBody(), ErrorResponse.class); 
					if(errResObj != null && errResObj.details != null && errResObj.details.size() > 0) {
						ErrorMsg = errResObj.details[0].detail;
					} else {
						ErrorMsg = 'getFinancialProduct states bad request ' + programResourceId;
					}
				} else if(res1.getStatusCode() == 404) {
					ErrorMsg = 'getFinancialProduct failed to locate any products related to the program ' + programResourceId;
				} else if(res1.getStatusCode() == 500) {
					
					if(!recallOnServerErrorFlag) {
						recallOnServerErrorFlag = true;
						String secondAttemptValue = getFinancialProduct(programId, productId, newused);
						System.debug('secondAttemptValue');
						System.debug(secondAttemptValue);
					} else {
						ErrorMsg = 'getFinancialProduct: is still throwing a 500 Internal server error despite having already reattempted the call';
					}
				} else {
					System.debug('Uncaught ' + res1.getStatusCode() + ' status code on the getFinancialProduct call');
					ErrorMsg = 'getFinancialProduct: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				}

				throw new AuraHandledException(ErrorMsg);
			}
	
			myResponse = (JSONFinancialProduct) System.JSON.deserialize(res1.getBody(), JSONFinancialProduct.class);             
			System.debug(myResponse);
			
		}
		catch (Exception e) {
			if(ErrorMsg == null)
				ErrorMsg = e.getTypeName() + ' in getFinancialProduct: ' + e.getMessage() + '-' + e.getStackTraceString();
			error=true;
			System.debug('e is: ' + e);
			Error_Log__c el = new Error_Log__c();
	
			el.callout_name__c = 'getFinancialProduct';
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'AssetUtils';
			el.Request_body__c = endPoint;
			el.Method_Name__c = 'getFinancialProduct';
			if (res1 != null) {
				el.Response_body__c = res1.getBody();
				el.status_code__c = res1.getStatusCode();
			}
	
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = ErrorMsg;
			el.quote_id__c = null;
			System.debug('**** save the error log');
			saveErrorLog(JSON.serialize(el));
		}

		if (error) {
			throw new AuraHandledException(ErrorMsg);
		} else {
			return JSON.serialize(myResponse);
		}
	}
	

	// /************************************************************************************************************************************************
	//  * @getAsset- get specific asset
	//  *
	//  * change log:
	//  *
	//  * 01/05/2023 - ATolbert created to enhance functionality of getAsset
	//  *
	//  *
	//  * @return   return list of asset models
	//  *****************************************************************************************************************************************************/
	// @AuraEnabled (Cacheable=true)
	// public static String getAsset(String programId, String assetId){
	
	
	// 	Boolean error=false;
	// 	String ErrorMsg = null;
	// 	HTTPResponse res1;
	// 	JSONPricingAsset pricingAsset;
	// 	String endpoint;
	
	// 	if(programId == null || assetId == null) return null;
	
	// 	try{
	
	// 		PartnerPortal__mdt pp = getPartnerPortalSettings();
	
	// 		endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c +  '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programId +
	// 				   '/assets/' + assetId + '?feature=Credit-Application-Documents';
	
	
	// 		HttpRequest reqAPI = buildHttpRequest(endpoint);
	
	// 		Http http1 = new Http();
	// 		res1 = http1.send(reqAPI);
	
	// 		System.debug(res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());
	
	// 		if (res1.getStatusCode() != 200) {
	// 			ErrorMsg = 'getAsset: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
	// 			error=true;
	// 			throw new AuraHandledException(ErrorMsg);
	// 		}
	
	// 		pricingAsset = (JSONPricingAsset) System.JSON.deserialize(res1.getBody(),JSONPricingAsset.class);
	
	
	// 		System.debug(res1.getBody());
	
	// 	}
	// 	catch (Exception e) {
	// 		if (ErrorMsg == null)
	// 			ErrorMsg = 'Exception in getAsset: ' + e.getMessage() + '-' + e.getStackTraceString();
	// 		error=true;
	// 		Error_Log__c el = new Error_Log__c();
	
	// 		el.callout_name__c = 'getAsset';
	// 		el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
	// 		el.Class_name__c = 'AssetUtils';
	// 		el.Request_body__c = endPoint;
	// 		el.Method_Name__c = 'getAsset';
	// 		if (res1 != null)
	// 			el.Response_body__c = res1.getBody();
	// 		el.status_code__c = null;
	// 		el.stack_trace__c = e.getStackTraceString();
	// 		el.exception_message__c = ErrorMsg;
	// 		el.quote_id__c = null;
	
	// 		saveErrorLog(JSON.serialize(el));
	
	// 	}
	// 	if (error) {
	// 		throw new AuraHandledException(ErrorMsg);
	// 	} else {
	// 		return JSON.serialize(pricingAsset);
	// 	}
		
	// }
	
	/************************************************************************************************************************************************
	 * @getMakes - callout service 
	 *
	 * change log:
	 *
	 * 01/05/2023 - ATolbert created to enhance functionality of getMakes

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
	
		if(programId == null) return null;
	 
		try{
	
			String programResourceId =  programId;
	
			PartnerPortal__mdt pp = getPartnerPortalSettings();
	
			endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programResourceId + '/asset-brands?pageSize=10000&sort=name&feature=Credit-Application-Documents';
						
			HttpRequest reqAPI = buildHttpRequest(endpoint);
	
			Http http1 = new Http();
			res1 = http1.send(reqAPI);
	
			System.debug(res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody());
	
			if (res1.getStatusCode() == 404)
				return null;
	
			if (res1.getStatusCode() != 200) {
				ErrorMsg = 'getMakes: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				error=true;

				if(res1.getStatusCode() == 400) {
					ErrorResponse errResObj = (ErrorResponse)JSON.deserializeStrict(res1.getBody(), ErrorResponse.class); 
					if(errResObj != null && errResObj.details != null && errResObj.details.size() > 0) {
						ErrorMsg = errResObj.details[0].detail;
					} else {
						ErrorMsg = 'getMakes states bad request ' + programResourceId;
					}
				} else if(res1.getStatusCode() == 404) {
					ErrorMsg = 'getMakes failed to locate any products with Id of ' + programResourceId;
				} else {
					System.debug('Uncaught Status code of ' + res1.getStatusCode());
				}
				
				throw new AuraHandledException(ErrorMsg);
			}
	
			JSONPricingMake myResponse = (JSONPricingMake) System.JSON.deserialize(res1.getBody(),JSONPricingMake.class);
	
			System.debug(myResponse);
	
			for ( JSONPricingMake.Data d : myResponse.data) {
				Make m = new Make();
				m.makeId = d.id;
				m.makeName = d.name;
				// if (d.name.toLowercase() == 'caterpillar' ||  d.name.toLowercase() == 'jungheinrich' || d.name.toLowercase() == 'mitsubishi')
				mList.add(m);
			}
	
		}
		catch (Exception e) {
			if(ErrorMsg == null)
				ErrorMsg = e.getTypeName() + ' in getMakes: ' + e.getMessage() + '-' + e.getStackTraceString();
			error=true;
			Error_Log__c el = new Error_Log__c();
	
			el.callout_name__c = 'getMakes';
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'AssetUtils';
			el.Request_body__c = endPoint;
			el.Method_Name__c = 'getMakes';
			if (res1 != null) {
				el.Response_body__c = res1.getBody();
				el.status_code__c = res1.getStatusCode();
			}
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = ErrorMsg;
			el.quote_id__c = null;
			System.debug('**** save the error log');
			saveErrorLog(JSON.serialize(el));
		}
		if (error) {
			throw new AuraHandledException(ErrorMsg);
		} else {
			return JSON.serialize(mList);
		}
	}

	/************************************************************************************************************************************************
	 * @getModels - gets a list of all Models related to  a program that uses a required make and optional assetType value
	 *
	 * change log:
	 *
	 * 01/05/2023 - ATolbert created to enhance functionality of getModels	 
	 *  
	 *
	 * @return   return JSON.serialize(List<JSONPricingAssets.data>)T
	 *****************************************************************************************************************************************************/
	@AuraEnabled (Cacheable=true)
	public static String getModels(String programId, String make, String assetType){
	
		List<JSONPricingAssets.data> resModelObjects = new List<JSONPricingAssets.data>(); 
		Boolean error=false;
		String ErrorMsg = null;
		String endpoint;
		HttpResponse res1;
	
		if(programId == null || make == null) return null;
	
		try{
	
			String programResourceId =  programId;
	
			PartnerPortal__mdt pp = getPartnerPortalSettings();
	
			make = EncodingUtil.urlEncode(make, 'UTF-8');
	
			endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/PriceQuote/programs/' + programResourceId + '/assets?page=1&pageSize=100&sort=id&feature=Credit-Application-Documents'
					   + '&brand=' + make;
					   
			if(assetType != null) {
				assetType = EncodingUtil.urlEncode(assetType, 'UTF-8');
				endpoint += '&category=' + assetType;
			}
		
			HttpRequest reqAPI = buildHttpRequest(endpoint);
	
			Http http1 = new Http();
			res1 = http1.send(reqAPI);
	
			System.debug(res1.getStatusCode()  + '  ' + res1.getStatusCode() + res1.getBody());
	
			if (res1.getStatusCode() != 200) {
				ErrorMsg = 'getModels: ' + res1.getStatus()  + '-' + res1.getStatusCode() + res1.getBody();
				error=true;

				if(res1.getStatusCode() == 400) {
					ErrorResponse errResObj = (ErrorResponse)JSON.deserializeStrict(res1.getBody(), ErrorResponse.class); 
					if(errResObj != null && errResObj.details != null && errResObj.details.size() > 0) {
						ErrorMsg = errResObj.details[0].detail;
					} else {
						ErrorMsg = 'getModels states bad request ' + make;
					}
				} else if(res1.getStatusCode() == 404) {
					ErrorMsg = 'getModels failed to locate any models related to the make ' + make;
				} else {
					System.debug('Uncaught ' + res1.getStatusCode() + ' status code on the get models call');
				}

				throw new AuraHandledException(ErrorMsg);
			}
	
			JSONPricingAssets myResponse = (JSONPricingAssets) System.JSON.deserialize(res1.getBody(),JSONPricingAssets.class);
	
			System.debug(myResponse);

			for (JSONPricingAssets.data d : myResponse.data) {
				resModelObjects.add(d);		
			}
		}
		catch (Exception e) {
			if (ErrorMsg == null)
				ErrorMsg = e.getTypeName() + ' in getModels: ' + e.getMessage() + '-' + e.getStackTraceString();
			error=true;
			Error_Log__c el = new Error_Log__c();
	
			el.callout_name__c = 'getModels';
			el.recordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			el.Class_name__c = 'AssetUtils';
			el.Request_body__c = endPoint;
			el.Method_Name__c = 'getModels';
			if (res1 != null) {
				el.Response_body__c = res1.getBody();
				el.status_code__c = res1.getStatusCode();
			}
			el.stack_trace__c = e.getStackTraceString();
			el.exception_message__c = ErrorMsg;
			el.quote_id__c = null;
			System.debug('**** save the error log');
			saveErrorLog(JSON.serialize(el));
	
	
		}
		if (error) {
			throw new AuraHandledException(ErrorMsg);
		}
		else {
			return JSON.serialize(resModelObjects);
		}
		
	}
	
	
	
	/************************************************************************************************************************************************
	 * buildHTTPRequest
	 *
	 * change log:
	 *
	 * 01/05/2023 - ATolbert created to facilitate the construction of formatted HTTP Requests
	 *
	 *
	 * @return   HttpRequest
	 *****************************************************************************************************************************************************/
	public static HttpRequest buildHttpRequest(String endpoint){
	
		HttpRequest reqAPI = new HttpRequest();
	
		reqAPI.setEndpoint(endpoint);
		reqAPI.setMethod('GET');
		reqAPI.setHeader('Content-Type', 'application/json');
	
		PartnerPortal__mdt pp = getPartnerPortalSettings();
	
		reqAPI.setHeader('Ocp-Apim-Subscription-Key', pp.Integration_Ocp_Apim_Subscription_Key__c);
		reqAPI.setHeader('Authorization', getToken());
		reqAPI.setTimeout(30000);
	
		System.debug('reqapi:' + reqAPI);
	
		
		return reqAPI;
	
	}


    /************************************************************************************************************************************************
     * getToken - checks cache for token.  if not found or expired, creates new token.
     *
     * change log:
     *
	 * 01/05/2023 - ATolbert created to facilitate the fetching/requesting of potentially cached API accessToken value
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

                Token t = new Token();
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

            Token t = new Token();
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
     * getAuthTOken
     *
     * change log:
     *
	 * 01/05/2023 - ATolbert created to facilitate the creation of a new API accessToken value
     *
     *
     * @return   return Token
     *****************************************************************************************************************************************************/

    public static Token getAuthToken(){


        Token t = new Token();

        HttpRequest reqAPI = new HttpRequest();
        Http http = new Http();

        PartnerPortal__mdt pp = AssetUtils.getPartnerPortalSettings();


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

        if(Test.isRunningTest()) {
            t.token = 'notARealTokenValue';
            t.expires = System.now().addSeconds(20000);
        } else if(res.getStatusCode()==200 ) {

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

	/************************************************************************************************************************************************
	 *   get partner portal settings
	 *****************************************************************************************************************************************************/
	
	public static PartnerPortal__mdt getPartnerPortalSettings() {
	
		return [SELECT Azure_Api_Environment__c
				, Integration_Client_Id__c
				, Integration_Client_Secret__c
				,Integration_Ocp_Apim_Subscription_Key__c
				FROM PartnerPortal__mdt
				WHERE developername = 'PartnerAuthorization' ];
        }
	
	
	@future
	public static void saveErrorLog(String e) {
	
		System.debug('*********************** saving error logs');
		Error_Log__c el = (Error_Log__c) JSON.deserialize(e, Error_Log__c.class);
		System.debug('error log: ' + el);
		insert el;
	}
	

}