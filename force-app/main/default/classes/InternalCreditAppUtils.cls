public with sharing class InternalCreditAppUtils {



    /************************************************************************************************************************************************
     *
     *****************************************************************************************************************************************************/
    public static List<Quote_Line__c> getQuoteLines(ID quoteId){

        List<Quote_Line__c> qlList = new List<Quote_Line__c>();
        qlList = [SELECT
                Id,
                Equipment_Type__c,
                Annual_Hours__c,
                Asset_Type_ITA_Class__c,
                Base_Unit_Sales_Price__c,
                Battery_Included__c,
                CreatedById,
                CreatedDate,
                Total_Sales_Price_Base__c,
                CurrencyIsoCode,
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
     *  doCallOut
     *****************************************************************************************************************************************************/
    
    public static ReturnStatus doCallout(String jsonString, String method, String opportunityId){
    
    
        Boolean error=false;
        String ErrorMsg = null;
        HTTPResponse res1;
        Boolean errorLogged = false;
        ReturnStatus r = new ReturnStatus();
    
        try {
    
            PartnerPortal__mdt pp = AssetUtils.getPartnerPortalSettings();
    
            String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/Finance/financeapplication?feature=Credit-Application-Inquiry';
    
            HttpRequest reqAPI  = AssetUtils.buildHttpRequest(endpoint);
            reqAPI.setMethod('POST');
            System.debug(reqAPI);
    
            Http http1 = new Http();
    
            reqAPI.setBody(jsonString);
    
            system.debug('jsonString: ' + jsonString);
    
            res1 = http1.send(reqAPI);
    
            System.debug(res1.getStatus());
            System.debug(res1.getBody());
            
            if (res1.getStatusCode() != 200) {
                System.debug('Failed to return a positive status');
                error=true;
                ErrorMsg = 'JSONSubmitCreditAppRequest: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
                system.debug(ErrorMsg);
                throw new AuraHandledException(ErrorMsg);
            } else {
                System.debug('Positive value response');
            }
        }
        catch (Exception e) {
            System.debug(e);
            if (ErrorMsg == null)
                ErrorMsg = 'Exception in JSONSubmitCreditAppRequest:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
            error=true;
            errorLogged = true;
            System.debug(ErrorMsg);


            Error_Log__c el = new Error_Log__c();
            el.callout_name__c = 'Submit Credit App';
            String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
    
            el.recordTypeId = recordTypeID;
            el.Class_name__c = 'CreditAppUtils';
            el.Request_body__c = jsonString;
            el.Method_Name__c = method;
            el.Response_body__c = r.responseBody;
            el.status_code__c = r.responseCode;
            //el.stack_trace__c = stack;
            el.exception_message__c = r.message;
            //el.quote_id__c = opportunityId;
            insert el;
        }

        r.responseCode = res1.getStatusCode() != null ? res1.getStatusCode() : 504;
        r.responseBody = res1.getBody();

        if(error) {
            r.isSuccess = false;
            r.message = ErrorMsg;
        } else {
            r.isSuccess = true;
            r.message = 'Successfully submitted callout';
        }
        System.debug(r);

        return r;
    }
	/************************************************************************************************************************************************
	 * getOpp data for Submit Credit
	 *
	 * change log:
	 *
	 * 12/8/2022 - Created by Adam Tolbert for Internal DLL users submitting a Credit App to MOSAIC via AZURE API
	 *
	 *
	 *****************************************************************************************************************************************************/
	public static Opportunity getOpp(String oppId) {
		Opportunity o = [SELECT Id, Name,
							AccountId,
							SyncedQuoteId,
							End_User__c,
							Program__c,
							Amount,
							Term__c,
							Frequency__c,
							Lease_Type__c,
							End_User_Phone__c,
							Payment_Amount__c,
							Financial_Product_Id__c,
							Opportunity_Number__c
							FROM Opportunity WHERE Id = :oppId
						];

		return o;

	}

    
    @AuraEnabled(cacheable=true)
    public static List<Opportunity_Line_Item__c> getOpportunityLineData(Id opportunityId){
        List<Opportunity_Line_Item__c> oppLines = new List<Opportunity_Line_Item__c>();
        if(opportunityId != null) {        
            try{

                oppLines = [
                        SELECT Id, Name, External_Id__c, Related_App_Line_Item__c, Line_Item_Type__c, Amount__c, Related_Quote_Line__c
                        FROM Opportunity_Line_Item__c
                        WHERE Opportunity__c = :opportunityId
                    ];

            } catch(Exception err) {
                System.debug(err);
            }
            
        } else {
            System.debug('Passed a null opportunityId');
        }

        return oppLines;
        
    }


    /*****************************************************************************************************************************************************
	 * Update Opportunity Data from Submit Credit App
	 *
	 * change log:
	 *
	 * 12/8/2022 - Created by Adam Tolbert for Internal DLL users to persist the input data as a Quote related to the context Opportunity 
	 *
	 *
	 *****************************************************************************************************************************************************/


     @AuraEnabled(cacheable=false)
     public static Boolean updateOpportunityData(String oppId, Map<String, String> customerStory, List<Object> assets){
         Opportunity oppRecord=[SELECT Id, Name,
                                 Amount,
                                 Partner_Sales_Rep__c,
                                 Business_Structure__c,
                                 Years_in_Business__c,
                                 Customer_Story__c,
                                 Application_Date__c,
                                 Sub_Stage__c, 
                                 Application_Number__c 
                                 FROM Opportunity 
                                 WHERE Id = :oppId
                               ];
 
         System.debug(customerStory);
         System.debug(assets);
 
         Decimal quoteAmount = 0.00;
         if(customerStory.get('amount') != null && customerStory.get('amount') != '') {
             Decimal thisAmount = Decimal.valueOf(customerStory.get('amount'));
             oppRecord.Amount = thisAmount;
             quoteAmount = thisAmount;
         }
         if(customerStory.get('financialProduct') != null && customerStory.get('financialProduct') != '') {
             oppRecord.Financial_Product_Id__c = customerStory.get('financialProduct');
         }
         if(customerStory.get('salesRepId') != null && customerStory.get('salesRepId') != '') {
             oppRecord.Partner_Sales_Rep__c = customerStory.get('salesRepId');
         }
         if(customerStory.get('paymentFrequency') != null && customerStory.get('paymentFrequency') != '') {
             oppRecord.Frequency__c = customerStory.get('paymentFrequency');
         }
         if(customerStory.get('paymentAmount') != null && customerStory.get('paymentAmount') != '') {
             try {
                 oppRecord.Payment_Amount__c = Decimal.valueOf(customerStory.get('paymentAmount'));
             } catch(Exception err) {
                 System.debug(err);
             }
         }
         if(customerStory.get('financeType') != null && customerStory.get('financeType') != '') {
             oppRecord.Lease_Type__c = customerStory.get('financeType');
         }
         if(customerStory.get('financeTerm') != null && customerStory.get('financeTerm') != '') {
             oppRecord.Term__c = Integer.valueOf(customerStory.get('financeTerm'));
         }
         
         List<Asset> listOfTypedAssets = (List<Asset>) JSON.deserialize(JSON.serialize(assets), List<Asset>.class);
         Quote newQuote = new Quote();
         newQuote.OpportunityId = oppId;
         newQuote.Name = oppRecord.Name;
         newQuote.Financed_Amount__c = quoteAmount;
         insert newQuote;
 
         if(listOfTypedAssets != null && listOfTypedAssets.size() > 0) {
 
             List<Quote_Line__c> newQuoteLines = new List<Quote_Line__c>();
             for(Asset a : listOfTypedAssets) {
                 Quote_Line__c ql = new Quote_Line__c();
                 ql.Quote__c = newQuote.Id;
                 ql.Asset_Type__c = a.model.type;
                 ql.Asset_Type_ITA_Class__c = a.model.assetType;
                 ql.Mast_Type__c = a.model.masterType;
                 ql.Make__c = a.make.label;
                 ql.Make_Id__c = a.make.value;
                 ql.Model__c = a.model.label;
                 ql.Model_Id__c = a.model.value;
                 ql.Number_of_Units__c = a.numberOfUnits;
                 ql.Base_Unit_Sales_Price__c = a.unitSalesPrice;
                 newQuoteLines.add(ql);
                 System.debug(a);
 
             }
 
             insert newQuoteLines;
         }
         
         oppRecord.SyncedQuoteId = newQuote.Id;
 
         // oppRecord.Business_Structure__c=customerStory.get('businessStructure');
         // if(customerStory.get('yearsInBusiness')!=null && customerStory.get('yearsInBusiness')!=''){
         //     oppRecord.Years_in_Business__c=decimal.valueof(customerStory.get('yearsInBusiness'));
         // } else {
         //     oppRecord.Years_in_Business__c=null;
         // }
         // oppRecord.Customer_Story__c=customerStory.get('story');
 
         // if(customerStory.get('location')!=null && customerStory.get('location')!='') {
         //     oppRecord.AccountId = [SELECT Id, Originating_Site_ID__c FROM Account WHERE Originating_Site_ID__c = :customerStory.get('location') LIMIT 1].Id;
         // }
 
         // system.debug('ownershipInfo::'+ownershipInfo);
         // if(ownershipInfo!= null && ownershipInfo!= '') {
         //     oppRecord.Beneficial_Owner_Type__c = ownershipInfo;
         // }
 
         // Update the customer authorization
         // if(customerStory.get('acceptedCheckbox') == 'true'){
         //     oppRecord.Customer_Authorization__c = true;
         // } else {
         //     oppRecord.Customer_Authorization__c = false;
         // }
 
         // Update the record
         
         Database.SaveResult sr = Database.update(oppRecord);
         
         return sr.isSuccess();
     }
 
 
         
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunityData(Id opportunityId){
        return [
            SELECT Id,
                Name,
                Account.BillingCity,
                Account.BillingCountry,
                Account.BillingCounty__c,
                Account.BillingPostalCode,
                Account.BillingStreet,
                Account.Email__c,
                Account.Name,
                Account.Originating_Site_ID__c,
                Account.Phone,
                Account.Primary_Contact_Name__c,
                Account.Tax_ID__c,
                Advance_Payments__c,
                Amount,
                Application_Number__c,
                Beneficial_Owner_Type__c,
                Business_Structure__c,
                Customer_Authorization__c,
                Customer_Name__c,
                Customer_Story__c,
                End_User__c,
                End_User__r.BillingCity,
                End_User__r.BillingCountry,
                End_User__r.BillingCounty__c,
                End_User__r.BillingPostalCode,
                End_User__r.BillingStreet,
                End_User__r.Email__c,
                End_User__r.Name,
                End_User__r.Phone,
                End_User__r.Primary_Contact_Name__c,
                End_User__r.Tax_ID__c,
                Frequency__c,
                Interest_Rate__c,
                Lease_Type__c,
                Location__c,
                Nickname__c,
                Partner_Sales_Rep__c,
                Partner_Sales_Rep__r.Name,
                Partner_Status__c,
                Payment_Amount__c,
                Pre_Qualification_Application_Number__c,
                Rate_Type__c,
                Residual_Amount__c,
                Sub_Stage__c,
                Term__c,
                Type,
                Years_in_Business__c,
              Opportunity_Number__c,
              Resubmit_Comments__c
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT 1
        ]; 
    }
     /************************************************************************************************************************************************
      * getOpportunity
      *
      * change log:
      *
      * 11/2/2022 - Adam Created
      *
      *
      * @return   return JSON.serialze(Opportunity)
      *****************************************************************************************************************************************************/
 
     @AuraEnabled(cacheable=true)
     public static String getOpportunity(Id opportunityId){
         Opportunity opp = getOpportunityData(opportunityId);
         OpportunityResObject resObj = new OpportunityResObject(opp);
         return JSON.serialize(resObj);
     }
 
 
	/************************************************************************************************************************************************
	 * submit credit application from opportunity
	 *
	 * change log:
	 *
	 * 12/8/2022 - Created by Adam Tolbert for Internal DLL users submitting a Credit App to MOSAIC via AZURE API
	 *
	 *
	 *****************************************************************************************************************************************************/
	@AuraEnabled
	public static String submitCreditAppRequest(String oppId) {
	
		Boolean error=false;
		
		String jsonStr;
		ReturnStatus r = new ReturnStatus();
		String stack;
	
		String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
	
		//Now we have all the dater (your brother in law from boston)
		
		try {
	
			Opportunity opp = getOpp(oppId);
			
			// if (!Test.isRunningTest())
				// CustomerUtils.createExternalCustomer(opp.end_user__c, opp.Id);

			JSONSubmitCreditAppInternalRequest app = new JSONSubmitCreditAppInternalRequest();
	
			JSONSubmitCreditAppInternalRequest.PricingQuote pricingQuote = new JSONSubmitCreditAppInternalRequest.PricingQuote();
			pricingQuote.id = opp.Opportunity_Number__c;
			pricingQuote.url = URL.getSalesforceBaseUrl().toExternalForm() + '/' + opp.id;
	
			JSONSubmitCreditAppInternalRequest.ExternalReferences externalReferences = new JSONSubmitCreditAppInternalRequest.ExternalReferences();
			externalReferences.pricingQuote = pricingQuote;
			externalReferences.recordId = opp.Id;

			List<JSONSubmitCreditAppInternalRequest.Contacts> cList = new List<JSONSubmitCreditAppInternalRequest.Contacts>();
			JSONSubmitCreditAppInternalRequest.Contacts contacts = new JSONSubmitCreditAppInternalRequest.Contacts();
			contacts.name = UserInfo.getName();
			contacts.email = UserINfo.getUserEmail();

			List<JSONSubmitCreditAppInternalRequest.PrimaryPhoneNumber> pList = new List<JSONSubmitCreditAppInternalRequest.PrimaryPhoneNumber>();
			JSONSubmitCreditAppInternalRequest.PrimaryPhoneNumber primaryPhoneNumber = new JSONSubmitCreditAppInternalRequest.PrimaryPhoneNumber();
			if (opp.End_User_Phone__c != null && opp.End_User_Phone__c != 'Unknown') {
				primaryPhoneNumber.phone_number = opp.End_User_Phone__c;
				primaryPhoneNumber.type = 'business';
				// primaryPhoneNumber.type = null;
				pList.add(primaryPhoneNumber);
			}
	
	
			if (!pList.isEmpty())
				contacts.phoneNumbers = pList;
	
			cList.add(contacts);
	
	
			JSONSubmitCreditAppInternalRequest.Identifiers identifiers = new JSONSubmitCreditAppInternalRequest.Identifiers();
	
			System_ID__c s = [SELECT Id ,DLL_External_ID__c
								FROM System_ID__c
								WHERE Account__c = : opp.End_User__c
								AND DLL_External_Key_Source__c = 'ORACLE'
								AND (DLL_External_Key_Type__c = 'TCAPartyId'
										OR DLL_External_Key_Type__c ='TCA_PARTY_ID'
										OR DLL_External_Key_Type__c = 'TCAPartyID'
									)
								LIMIT 1
							  ];
	
			System.debug('************** tca party id : ' +  s.DLL_External_ID__c);
	
			identifiers.tcaPartyId = s.DLL_External_ID__c;
	
			// if (s.DLL_External_ID__c == null) {
			// 	error=true;
			// 	throw new AuraHandledException('TCA Party ID is required!');
			// }
	
	
			JSONSubmitCreditAppInternalRequest.Lessee lessee = new JSONSubmitCreditAppInternalRequest.Lessee();
			//lessee.address = address;
	
	
			lessee.contacts = cList;
			lessee.countryOfRegistration = 'US';
			lessee.identifiers = identifiers;
	
			JSONSubmitCreditAppInternalRequest.FinancialProduct financialProduct = new JSONSubmitCreditAppInternalRequest.FinancialProduct();
			financialProduct.id = opp.Financial_Product_Id__c;
	
			//JSONSubmitCreditAppInternalRequest.Duration duration = new JSONSubmitCreditAppInternalRequest.Duration();
			//if (opp.Term__c != null)
			//  duration.numberOfMonths = integer.valueOf(opp.Term__c);
	
			JSONSubmitCreditAppInternalRequest.Payments payments = new JSONSubmitCreditAppInternalRequest.Payments();
			JSONSubmitCreditAppInternalRequest.Rentals rentals = new JSONSubmitCreditAppInternalRequest.Rentals();
			List<JSONSubmitCreditAppInternalRequest.ConsolidatedRegulars> crList = new List<JSONSubmitCreditAppInternalRequest.ConsolidatedRegulars>();
			JSONSubmitCreditAppInternalRequest.ConsolidatedRegulars consolidatedRegulars = new JSONSubmitCreditAppInternalRequest.ConsolidatedRegulars();
			consolidatedRegulars.amount = opp.Payment_Amount__c;
			consolidatedRegulars.numberOfPayments = Integer.valueOf(opp.term__c);
			crList.add(consolidatedRegulars);
			rentals.consolidatedRegulars = crList;
			payments.rentals = rentals;

			List<JSONSubmitCreditAppInternalRequest.Assets> assetList = new List<JSONSubmitCreditAppInternalRequest.Assets>();

			List<Quote_Line__c> tempList = getQuoteLines(opp.SyncedQuoteId);
			List<Quote_Line__c> qlAccList =  new List<Quote_Line__c>();
			List<Quote_Line__c> qlList =  new List<Quote_Line__c>();
	
			for(Quote_Line__c t:tempList)
				if (t.related_asset__c == null)
					qlList.add(t);                 //asset
				else
					qlAccList.add(t);              //accessories
	
			Map<ID, List<Quote_Line__c> > qAccListMap = new Map<ID, List<Quote_Line__c> >();
	
			for (Quote_Line__c t2:qlAccList) {
				List<Quote_Line__c> tList = new List<Quote_Line__c>();
	
				if (qAccListMap.get(t2.related_asset__c) == null) {
					tList.add(t2);
					qAccListMap.put(t2.related_asset__c,tList);
				}
				else {
					tList = qAccListMap.get(t2.related_asset__c);
					tList.add(t2);
					qAccListMap.put(t2.related_asset__c,tList);
				}
			}
	
			for (Quote_Line__c ql:qlList) {
	
				JSONSubmitCreditAppInternalRequest.Structure structure = new JSONSubmitCreditAppInternalRequest.Structure();
				structure.masterType = ql.Mast_Type__c;        //may be able to remove        //ql.master_type__c;
				structure.category = ql.Asset_Type_ITA_Class__c;
				structure.brand =  ql.Make__c;                //'brand';
				structure.model =  ql.Model__c;                //'b';
				structure.type =  ql.Asset_Type__c;
	
				JSONSubmitCreditAppInternalRequest.Finance_Z finance_Z = new JSONSubmitCreditAppInternalRequest.Finance_Z();
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
	
	
				JSONSubmitCreditAppInternalRequest.ResidualValue residualValue = new JSONSubmitCreditAppInternalRequest.ResidualValue();
	
				JSONSubmitCreditAppInternalRequest.Adjustments adjustments = new JSONSubmitCreditAppInternalRequest.Adjustments();
				adjustments.industrialBattery = ql.Battery_Included__c;
				adjustments.mastType = ql.Mast_Type__c;
				adjustments.operatingEnvironment = ql.Operating_Environment__c;
				adjustments.operatingHoursPerYear = String.valueOf(ql.Annual_Hours__c);
	
	
				residualValue.adjustments = adjustments;
	
				finance_Z.residualValue = residualValue;
	
				JSONSubmitCreditAppInternalRequest.Identifiers_Z identifiers_z = new JSONSubmitCreditAppInternalRequest.Identifiers_Z();
				identifiers_z.structure = structure;
	
				JSONSubmitCreditAppInternalRequest.Catalog catalog = new JSONSubmitCreditAppInternalRequest.Catalog();
				catalog.identifiers = identifiers_z;
	
				JSONSubmitCreditAppInternalRequest.Assets asset = new JSONSubmitCreditAppInternalRequest.Assets();
				asset.catalog = catalog;
	
				// if (opp.asset_type__c == 'New')
				asset.condition = 'new';
				// else
				// 	asset.condition = 'used';
	
				asset.finance = finance_Z;
				asset.catalog = catalog;
	
	
				assetList.add(asset);
			}
		
			List<JSONSubmitCreditAppInternalRequest.Proposals> proposals = new List<JSONSubmitCreditAppInternalRequest.Proposals>();
	
			JSONSubmitCreditAppInternalRequest.Finance finance = new JSONSubmitCreditAppInternalRequest.Finance();
	
			finance.paymentFrequency  = opp.Frequency__c != null ? opp.Frequency__c.toLowerCase() : null;
			finance.paymentTiming = 'in-arrears';
			finance.purchaseOption = opp.Lease_Type__c;
			finance.numberOfMonths = Integer.valueOf(opp.Term__c);
			finance.financeAmount = opp.Amount;

	
			finance.numberOfMonths = opp.Term__c != null ? Integer.valueOf(opp.Term__c) : null;
	
			JSONSubmitCreditAppInternalRequest.Proposals proposal = new JSONSubmitCreditAppInternalRequest.Proposals();
			if(opp.Payment_Amount__c != null && opp.Payment_Amount__c != 0) {
				proposal.payments = payments;				
			}
			proposal.isPreferred = true;
			proposal.finance = finance;
			proposal.externalReferences = externalReferences;
			proposal.financialProduct = financialProduct;
			proposal.description = opp.Name;
			//proposal.duration = duration;
	
			proposal.assets = assetList;
	
			proposals.add(proposal);

	
			JSONSubmitCreditAppInternalRequest.Data data = new JSONSubmitCreditAppInternalRequest.Data();
			data.externalReference = 'DLL.' + opp.id;
			data.lessee = lessee;
			data.proposals = proposals;
	
			jsonStr = '{ "data": ' +  JSON.serialize(data,true) + ' }';
	
			System.debug('JSON is: ' + jsonStr);
	
			r = doCallout(jsonStr, 'method', oppId);
			
			System.debug(r.isSuccess);
			System.debug(r.responseCode);
			System.debug(r.responseBody);

			if (r.responseCode != 200) {
				System.debug(r.message);
				error=true;
				opp.Sub_Stage__c = 'Application Error';
				update opp;

                JSONSubmitCreditAppBadRequest.error errorResponseObj = new JSONSubmitCreditAppBadRequest.error();

                if(r.responseCode == 401) {
					JSONSubmitCreditAppBadRequest.error authErrorResponse = (JSONSubmitCreditAppBadRequest.error)System.JSON.deserialize(r.responseBody,JSONSubmitCreditAppBadRequest.error.class);
					System.debug(authErrorResponse);
					System.debug(authErrorResponse.details);
					System.debug(authErrorResponse.details[0].detail);
                    errorResponseObj = authErrorResponse;
                } else if(r.responseCode == 400 || r.responseCode == 404 || r.responseCode == 500) {
					System.debug('Processing response code value of ' + r.responseCode);
					JSONSubmitCreditAppBadRequest creditErrorResponse = (JSONSubmitCreditAppBadRequest)System.JSON.deserialize(r.responseBody,JSONSubmitCreditAppBadRequest.class);
					System.debug(creditErrorResponse);
					System.debug(creditErrorResponse.error);
					System.debug(creditErrorResponse.error.details);
					System.debug(creditErrorResponse.error.details[0].detail);
                    errorResponseObj = creditErrorResponse.error;
				} else if(r.responseCode == 504) {
                    r.message = '504 Request Timed Out';
                } else {
					System.debug('Uncaught response code value of ' + r.responseCode);
				}

                if(errorResponseObj.details != null && errorResponseObj.details.size() > 0) {
                    System.debug('Throwing custom error details');
                    r.message = r.responseCode + ' ' + errorResponseObj.details[0].detail;
                } else {
                    System.debug('Couldnt detect anticipated custom error message on ' + r.responseCode + ' error response');
                    r.message = 'HTTP Status - ' + r.responseCode + ': ' +  (errorResponseObj.title != null ? errorResponseObj.title : r.message);
                }


				throw new AuraHandledException(r.message);

			} else {
				// Opportunity o = [select id from Opportunity where id = : opp.OpportunityId];

				JSONSubmitCreditAppInternalRequest creditResponse = (JSONSubmitCreditAppInternalRequest)System.JSON.deserialize(r.responseBody,JSONSubmitCreditAppInternalRequest.class);
	
				/*
					externalReference": "DOD.0Q00m000000BMykCAG",
				   "id": "1.NA.MOSAIC.500-50311994",
				   "status": "assessment",
				   "creationDate": "2022-06-03T18:55:41Z",
				   "modificationDate": ""
				 */
	
				String applicationId = creditResponse.data.id;
				opp.Application_Number__c = applicationId.mid(applicationId.lastIndexOf('.')+1,12);
				// opp.stagename = 'Assessment';
				if (creditResponse.data.status == 'assessment') {
					opp.Sub_Stage__c = 'Application Submitted';
				}
				else {
					opp.Sub_Stage__c = creditResponse.data.status;
				}

				opp.Application_Date__c = Date.today();
	
				update opp;
				
	
			}
	
		}
		catch (Exception e) {
			error=true;
			System.debug('r error is: ' + r.message);
			System.debug('e: ' + e);
			System.debug(e);
			if(r.message == null) {
				r.message = e.getMessage();
			}			
			stack = e.getStackTraceString();

		}
		finally {

			// Error_Log__c e = new Error_Log__c();
			// e.Callout_Name__c = 'Submit Credit App Request';
			// e.RecordTypeId = recordTypeID;
			// e.Class_Name__c = 'CreditAppUtils';
			// e.Request_Body__c = jsonStr;
			// e.Method_Name__c = 'submitCreditAppRequest';
			// e.Response_Body__c = r.responseBody;
			// e.Status_Code__c = r.responseCode;
			// e.Stack_Trace__c = stack;
			// e.Exception_Message__c = r.message;
			// e.Quote_Id__c = oppId;
			// insert e;
		}
		if(error) {
			throw new AuraHandledException(r.message);
		} else {
			return JSON.serialize(r);
		}

	}

    /************************************************************************************************************************************************
     *   MISC
     *****************************************************************************************************************************************************/

     public class ReturnStatus {
        public Boolean isSuccess;
        public String message;
        public Integer responseCode;
        public String responseBody;
    }
    


    public class PicklistValue {
        String label {get;set;}
        String value {get;set;}
    }
   
    public class OppLineResObject {
        public String value;
        public String label;
        public String opportunityId;
        OppLineResObject(Opportunity_Line_Item__c line) {
            this.value = line.Id;
            this.label = line.Name;
            this.opportunityId = line.Opportunity__c;
        }

    }

    public class OpportunityResObject {

        public String value;
        public String label;
        public String accountId;
        public String accountName;
        public String accountSiteId;
        public String endUserId;
    
        OpportunityResObject(Opportunity opp) {
            this.value = opp.Id;
            this.label = opp.Name;
            this.accountId = opp.AccountId;
            this.accountName = opp.Account.Name;
            this.accountSiteId = opp.Account.Originating_Site_ID__c;
            this.endUserId = opp.End_User__c;
        }
    
    }


    public class Asset {
        String sectionName {get;set;}
        String assetHeading {get;set;}
        String assetNo {get;set;}
        Boolean isFirst {get;set;}
        PicklistValue make {get;set;}
        PicklistValue assetType {get;set;}
        Model model {get;set;}
        String mastTypeValue {get;set;}
        Decimal numberOfUnits {get;set;}
        Decimal unitSalesPrice {get;set;}
        String assetId {get;set;}
        String quoteId {get;set;}
    }

    public class Model {
        String type;
        String assetType;
        String brand;
        String label;
        String masterType;
        String modelId;
        String value;   
    }


    
}