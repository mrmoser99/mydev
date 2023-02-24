public without sharing class InternalCreditAppUtils {



    /************************************************************************************************************************************************
     *  postCreditAppToAzure
     *****************************************************************************************************************************************************/
    
    public static ReturnStatus postCreditAppToAzure(String jsonString, String method, String opportunityId, Boolean isAsync) {
    
    
        Boolean error=false;
        String ErrorMsg = null;
        HTTPResponse res1;
        Boolean errorLogged = false;
        ReturnStatus r = new ReturnStatus();
    
        try {
    
            PartnerPortal__mdt pp = AssetUtils.getPartnerPortalSettings();
    
            String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/globalcrmdata/' + (isAsync ? 'submitfinanceapp' : 'Finance/financeapplication') + '?feature=Credit-Application-Inquiry';
    
            HttpRequest reqAPI  = AssetUtils.buildHttpRequest(endpoint);
            reqAPI.setMethod('POST');
            System.debug(reqAPI);
    
            Http http1 = new Http();
    
            reqAPI.setBody(jsonString);
    
            system.debug('jsonString: ' + jsonString);
    
            res1 = http1.send(reqAPI);
    
            System.debug(res1.getStatus());
            System.debug(res1.getBody());

            r.responseCode = res1 != null ? res1.getStatusCode() : 504;
            r.responseBody = res1 != null ? res1.getBody() : null;
    
            if (r.responseCode == 200 || r.responseCode == 202) {
                System.debug('Positive value response');
            } else {
                System.debug('Failed to return a positive status');
                error=true;
                ErrorMsg = 'JSONSubmitCreditAppRequest: ' + res1.getStatus()  + '  ' + res1.getStatusCode() + res1.getBody();
                system.debug(ErrorMsg);
                throw new CreditAppException(ErrorMsg);
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
    
            el.RecordTypeId = RecordTypeId;
            el.Class_Name__c = 'InternalCreditAppUtils';
            el.Request_Body__c = jsonString;
            el.Method_Name__c = method;
            el.Response_Body__c = r.responseBody;
            el.Status_Code__c = r.responseCode;
            el.Stack_Trace__c = e.getStackTraceString();
            el.Exception_Message__c = r.message;
            el.Quote_id__c = opportunityId;
            insert el;
        }

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
        Opportunity oppRecord = getOpp(oppId);
        
        try {
            Account endUser = [SELECT Id, Name ,Phone FROM Account WHERE Id = :oppRecord.End_User__c];
        
            if(endUser.Phone == null) {
                endUser.Phone = oppRecord.End_User_Phone__c;
                update endUser;
            } else {
                System.debug('End User account already has a phone number');
            }
        } catch(Exception err) {
            System.debug('Failed to update the End USer account with a phone number');
        }
        

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
        } else {
            oppRecord.Payment_Amount__c = null;
        }
        
        if(customerStory.get('financeType') != null && customerStory.get('financeType') != '') {
            oppRecord.Lease_Type__c = customerStory.get('financeType');
        }
        if(customerStory.get('financeTerm') != null && customerStory.get('financeTerm') != '') {
            oppRecord.Term__c = Integer.valueOf(customerStory.get('financeTerm'));
        }
        
        List<Asset> listOfTypedAssets = (List<Asset>)JSON.deserialize(JSON.serialize(assets), List<Asset>.class);
        Quote newQuote = new Quote();
        newQuote.OpportunityId = oppId;
        newQuote.Name = oppRecord.Name;
        newQuote.Financed_Amount__c = quoteAmount;
        newQuote.Amount__c = quoteAmount;
        newQuote.Total_Payment__c = oppRecord.Payment_Amount__c;
        newQuote.Payment_Frequency__c = oppRecord.Frequency__c;
        newQuote.Financial_Product_Id__c = oppRecord.Financial_Product_Id__c;
        newQuote.End_User__c = oppRecord.End_User__c;
        newQuote.RecordTypeId = [SELECT Id FROM RecordType WHERE Name = 'Integrated' AND SobjectType = 'Quote' LIMIT 1].Id;
        
        System.debug(newQuote);
        insert newQuote;

        if(listOfTypedAssets != null && listOfTypedAssets.size() > 0) {

            List<Quote_Line__c> newQuoteLines = new List<Quote_Line__c>();
            for(Asset a : listOfTypedAssets) {
                Quote_Line__c ql = new Quote_Line__c();
                ql.Name = a.make.label + ' ' + a.model.label;
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
 
 
    public static String constructCreditAppRequstBody(Id oppId) {
 
        try {    

            String jsonStr;
         
            Opportunity opp = getOpportunityData(oppId);
            
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
            if (opp.End_User__r.Phone != null && opp.End_User__r.Phone != '' && opp.End_User__r.Phone != 'Unknown') {
                primaryPhoneNumber.phone_number = opp.End_User__r.Phone;
                primaryPhoneNumber.type = 'business';
                pList.add(primaryPhoneNumber);
            }

            // if (!pList.isEmpty())
                contacts.phoneNumbers = pList;

            cList.add(contacts);


            JSONSubmitCreditAppInternalRequest.Identifiers identifiers = new JSONSubmitCreditAppInternalRequest.Identifiers();

            JSONSubmitCreditAppInternalRequest.Lessee lessee = new JSONSubmitCreditAppInternalRequest.Lessee();

            try {
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
                lessee.identifiers = identifiers;

            } catch(Exception err) {
                System.debug('Failed to find a TCA party Id, need to create a new customer before sending application');

                String jsonResponseString;
                if (!Test.isRunningTest()) {
                    // try {
                        jsonResponseString = createExternalCustomer(opp.End_User__c);
                    // } catch(Exception e) {
                    //     throw new AuraHandledException('Unhandled fault thrown in createExternalCustomer. ' + e.getMessage());
                    // }
                } else {
                    // Mock test response to mimic successful creation, cannot mock as the async call is also calling out later
                    jsonResponseString = '{"errorMessage":null, "salesforceId":"' + opp.End_User__c + '", "success":true, "tcaPartyId":"123456"}';
                }

                if(jsonResponseString == null) {
                    throw new CreditAppException('End User is missing a TCA Party Id, and we failed to successfully create one');
                }

                JSONCreateCustomerResponse createCustomerResObj = (JSONCreateCustomerResponse)JSON.deserializeStrict(jsonResponseString, JSONCreateCustomerResponse.class);
                System.debug('createCustomerResObj');
                System.debug(createCustomerResObj);
                if(createCustomerResObj.success == false && createCustomerResObj.tcaPartyId == '') {
                    throw new CreditAppException('End User is missing a TCA Party Id, and we failed to successfully create one');
                }
                // throw new AuraHandledException('End User is missing a TCA Party Id');
                
                //  OR...... //

                // JSONSubmitCreditAppInternalRequest.Address addr = new JSONSubmitCreditAppInternalRequest.Address();
                // addr.addressLine = opp.End_User__r.BillingStreet;
                // addr.city = opp.End_User__r.BillingCity;
                // addr.postalCode = opp.End_User__r.BillingPostalCode;
                // addr.region = opp.End_User__r.BillingState;      
                // addr.country = opp.End_User__r.BillingCountry;
                // addr.addressType = 'current-physical-address';                          

                // lessee.address = addr;

                // JSONSubmitCreditAppInternalRequest.PrimaryPhoneNumber primaryPhoneObj = new JSONSubmitCreditAppInternalRequest.PrimaryPhoneNumber();
                // primaryPhoneObj.phone_number = opp.End_User__r.Phone;
                // primaryPhoneObj.type = 'business';
                // lessee.primaryPhoneNumber = primaryPhoneObj;
                
                // lessee.name = opp.End_User__r.Name;
                // lessee.legalName = opp.End_User__r.Legal_Entity_Name__c;

                identifiers.tcaPartyId = createCustomerResObj.tcaPartyId;
                lessee.identifiers = identifiers;

            }
            
            lessee.countryOfRegistration = 'US';
            lessee.contacts = cList;


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
            if(opp.Payment_Amount__c != null && opp.Payment_Amount__c > 0) {
                proposal.payments = payments;
            } else {
                // proposal.payments =  new JSONSubmitCreditAppInternalRequest.Payments();
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

            return jsonStr;
        } catch(Exception err) {
            System.debug(err);
            System.debug(err.getMessage());
            System.debug(err.getStackTraceString());
            throw new CreditAppException(err.getMessage());
        }
    }
 
    /************************************************************************************************************************************************
	 * submit credit application asyncronously from opportunity
	 *
	 * change log:
	 *
	 * 1/15/2023 - Created by Adam Tolbert for Internal DLL users submitting a Credit App to AZURE API for asyncronous processing into MOSAIC
	 *
	 *
	 *****************************************************************************************************************************************************/

    @AuraEnabled
    public static String submitCreditAppAsync(String oppId){

		Boolean error=false;
		
		String jsonStr;
		ReturnStatus r = new ReturnStatus();
		String stack;
	
		String recordTypeID = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
			
		try {
            
            jsonStr = constructCreditAppRequstBody(oppId);
	
			System.debug('Constructed JSON: ' + jsonStr);

            if(jsonStr == null) {
                System.debug('Failed to construct the json request body properly as the construction method returned null');
                r.message = 'Failed to construct JSON Request body as expected';
                throw new AuraHandledException(r.message);
            }

			r = postCreditAppToAzure(jsonStr, 'submitCreditAppRequest', oppId, true);
			
			System.debug(r.isSuccess);
			System.debug(r.responseCode);
			System.debug(r.responseBody);
            Opportunity opp = new Opportunity(Id = oppId);

			if (r.responseCode != 202) {
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

                opp.Sub_Stage__c = 'Application Submitted';
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

		}
		finally {

			// Error_Log__c e = new Error_Log__c();
			// e.Callout_Name__c = 'Submit Credit App Async';
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
			
		try {
            
            jsonStr = constructCreditAppRequstBody(oppId);
	
			System.debug('Constructed JSON: ' + jsonStr);
            
            if(jsonStr == null) {
                System.debug('Failed to construct the json request body properly as the construction method returned null');
                r.message = 'Failed to construct JSON Request body as expected';
                throw new AuraHandledException(r.message);
            }

			r = postCreditAppToAzure(jsonStr, 'submitCreditAppRequest', oppId, false);
			
			System.debug(r.isSuccess);
			System.debug(r.responseCode);
			System.debug(r.responseBody);
            Opportunity opp = new Opportunity(Id = oppId);

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
		catch (Exception err) {
			error=true;
			System.debug('r error is: ' + r.message);
			System.debug('e: ' + err);
			System.debug(err);
			if(r.message == null) {
				r.message = err.getMessage();
			}			
			stack = err.getStackTraceString();

            Error_Log__c e = new Error_Log__c();
			e.Callout_Name__c = 'Submit Credit App Request';
			e.RecordTypeId = recordTypeID;
			e.Class_Name__c = 'InternalCreditAppUtils';
			e.Request_Body__c = jsonStr;
			e.Method_Name__c = 'submitCreditAppRequest';
			e.Response_Body__c = r.responseBody;
			e.Status_Code__c = r.responseCode;
			e.Stack_Trace__c = stack;
			e.Exception_Message__c = r.message;
			e.Quote_Id__c = oppId;
			insert e;

		}
		finally {

			// Error_Log__c e = new Error_Log__c();
			// e.Callout_Name__c = 'Submit Credit App Request';
			// e.RecordTypeId = recordTypeID;
			// e.Class_Name__c = 'InternalCreditAppUtils';
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


    public static String constructCreateCustomerRequstBody(String accountId) {


        Account a = [SELECT Id, Name, Phone, Tax_ID__c, BillingAddress, 
                    BillingCity, BillingCountry, BillingPostalCode, 
                    BillingStreet, BillingState, BillingCounty__c
            FROM Account
            Where id = : accountId
        ];

        JSONCreateCustomer c = new JSONCreateCustomer();

        JSONCreateCustomer.DataBody dataBody = new JSONCreateCustomer.DataBody();
        dataBody.sourceSystem = 'GDW_Wayne';

        JSONCreateCustomer.ExternalIdentifiers externalIdentifiers = new JSONCreateCustomer.ExternalIdentifiers();

        externalIdentifiers.identifier = a.id;
        externalIdentifiers.name = 'salesForceAccountId';

        /*
        "externalIdentifiers": [
        {
        "identifier": "100970000",
        "name": "taxNumber"
        },
        {
        "identifier": "0010m00000kPJzgAAG",
        "name": "salesFocustomerrceAccountId"
        }
        */

        List<JSONCreateCustomer.ExternalIdentifiers> eList = new List<JSONCreateCustomer.ExternalIdentifiers>();
        eList.add(externalIdentifiers);

        if (a.Tax_Id__c != null) {
            ExternalIdentifiers = new JSONCreateCustomer.ExternalIdentifiers();
            externalIdentifiers.identifier = a.Tax_Id__c;
            externalIdentifiers.name = 'EIN';
            eList.add(externalIdentifiers);
        }

        JSONCreateCustomer.Lessee lessee = new JSONCreateCustomer.Lessee();
        lessee.lesseeName = a.name;

        JSONCreateCustomer.Address address = new JSONCreateCustomer.Address();
        address.addressLine1 =  a.BillingStreet;

        address.city = a.BillingCity;
        address.region = a.BillingState;
        address.county = a.BillingCounty__c;
        address.postCode = a.BillingPostalCode;
        address.countryOfResidence = a.BillingCountry;

        if(a.Phone == null) {
            throw new CreditAppException('End User Account is missing a Phone Number, add an End User Phone to continue');
        }
        JSONCreateCustomer.Contact contact = new JSONCreateCustomer.contact();
        contact.ContactType = 'Phone';
        contact.ContactTypeValue = a.Phone;
        List<JSONCreateCustomer.Contact> cList = new List<JSONCreateCustomer.Contact>();
        cList.add(contact);

        JSONCreateCustomer.CustomerInfo customerInfo = new JSONCreateCustomer.CustomerInfo();
        customerInfo.legalEntityDescription = 'DLL';
        customerInfo.address = address;
        customerInfo.addressOverrideFlag = 'N';

        customerInfo.lessee = lessee;
        //customerInfo.salesTaxGeoCode = '100970000';
        customerInfo.businessUnit = 'Construction, Transportation & Industrial';

        customerInfo.externalIdentifiers =   eList;
        customerInfo.contact = cList;
        dataBody.customerInfo = customerInfo;
        c.dataBody = dataBody;
        String body = JSON.serialize(c, true);
        System.debug(body);
        return body;

    }

    /************************************************************************************************************************************************
     * createCustomer
     *
     * change log:
     *
     * 2/5/2023 - Adam Added Method
     *
     * Sample Call from LWC to add customer to icv/oracle.  if it has a tca party don't create external customer; just send back tca party id
     *****************************************************************************************************************************************************/
    public static String createExternalCustomer(String accountId){

        Boolean error = false;
        String stack;

        JSONCreateCustomerResponse myResponse = new JSONCreateCustomerResponse();
        String jsonStr;
        HTTPResponse res1;

        system.debug('(*********  called with: ' + accountId);

        /*
        [10:03 AM] McCann, J (John)
            DLL_External_Key_Source__c  <> ORACLE
            Call CreateIF DLL External Id = “”
            Call CreateIF DLL_External_Key_Type__c <> TCAPartyIdCall Create
        */

        try {

            try {
                System_ID__c s = [SELECT Id ,DLL_External_ID__c
                                    FROM System_ID__c
                                    WHERE Account__c = : accountId
                                    AND DLL_External_Key_Source__c = 'ORACLE'
                                    AND (DLL_External_Key_Type__c = 'TCAPartyId'
                                            OR DLL_External_Key_Type__c ='TCA_PARTY_ID'
                                            OR DLL_External_Key_Type__c = 'TCAPartyID'
                                        )
                                    LIMIT 1
                                ];			
                
                myResponse.success = true;
                myResponse.tcaPartyId = s.DLL_External_ID__c;
                myResponse.salesforceId = s.id;
                myResponse.errorMessage = 'External customer exists!';

                System.debug('myresponse:' + myResponse);

                return JSON.serialize(myResponse);

            }
            catch (QueryException e) {
                System.debug('There is genuinely no existing TCA Party Record related to the account, we can proceed with requesting creation of a new one');
            }

            jsonStr = constructCreateCustomerRequstBody(accountId);
        
            System.debug('Constructed JSON: ' + jsonStr);

            if(jsonStr == null) {
                System.debug('Failed to construct the json request body properly as the construction method returned null');
                myResponse.success = false;
                myResponse.errorMessage = 'Failed to construct JSON Request body as expected';
                throw new CreditAppException(myResponse.errorMessage);
            }


            PartnerPortal__mdt pp = AssetUtils.getPartnerPortalSettings();

            String endpoint = 'https://msc-apm-wcrm-' + pp.Azure_Api_Environment__c + '.azure-api.net/customer/create/';
            HttpRequest reqAPI = AssetUtils.buildHttpRequest(endpoint);
            reqAPI.setMethod('POST');
            reqAPI.setBody(jsonStr);

            Http http1 = new Http();
            res1 = http1.send(reqAPI);

            System.debug(res1);
            
            if (res1 != null) {

                System.debug(res1.getBody());
                myResponse = (JSONCreateCustomerResponse)JSON.deserialize(res1.getBody(),JSONCreateCustomerResponse.class);
                System.debug(myResponse);

                if (res1.getStatusCode() == 200) {
                    System.debug(myResponse);
                    if (myResponse.success == false) {
                        error = true;
                        myResponse.errorMessage = (myResponse.errorMessage != null ? myResponse.errorMessage : 'CreateCustomer Error: Failed to create a TCA Party Id as expected');
                        throw new CreditAppException(myResponse.errorMessage);
                    } else {
                        System.debug('Successfully created the customer ' + myResponse.tcaPartyId + ' and upserted a sf record ' + myResponse.salesforceId + ' with said data');
                    }
                } else if(myResponse.tcaPartyId != null && myResponse.tcaPartyId != '') {
                    System.debug('API returned an error despite having a TCA Party Id specified ' + myResponse.tcaPartyId);
                    myResponse.salesforceId = accountId;

                } else {
                    error = true;
                    myResponse.success = false;
                    myResponse.errorMessage = (myResponse.errorMessage != null ? 'Failed to create a TCA Party Id: ' + myResponse.errorMessage : 'Create Customer Failed with Unspecified Error');
                    throw new CreditAppException(myResponse.errorMessage);
                }
            } else {
                error = true;
                myResponse.success = false;
                myResponse.errorMessage = 'Failed to create a TCA Party Id: Create Customer res was null';
                throw new CreditAppException(myResponse.errorMessage);
            }
        }

        catch (Exception e) {
            System.debug(e);
            System.debug(e.getMessage());

            error = true;
            myResponse.success = false;    
            myResponse.errorMessage = (myResponse.errorMessage != null ? myResponse.errorMessage : e.getMessage());
            Error_Log__c el = new Error_Log__c();
            el.callout_name__c = 'Create Customer';
            String integrationRecordTypeId = Schema.getGlobalDescribe().get('Error_Log__c').getDescribe().getRecordTypeInfosByName().get('Integration Error Log').getRecordTypeId();
    
            el.RecordTypeId = integrationRecordTypeId;
            el.Class_Name__c = 'InternalCreditAppUtils';
            el.Request_Body__c = jsonStr;
            el.Method_Name__c = 'createExternalCustomer';
            el.Response_Body__c = res1 != null ? res1.getBody() : null;
            el.Status_Code__c = res1 != null ? res1.getStatusCode() : null;
            el.Stack_Trace__c = e.getStackTraceString();
            el.Exception_Message__c = e.getMessage();
            el.Record_Id__c = accountId;
            insert el;
            throw new CreditAppException(myResponse.errorMessage);
        }

        return JSON.serialize(myResponse);

    }


         
    @AuraEnabled(cacheable=true)
    public static Opportunity getOpportunityData(Id opportunityId){
        return [
            SELECT Id,
                Name,
                AccountId,
                SyncedQuoteId,
                Program__c,
                End_User_Phone__c,
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
                End_User__r.BillingState,
                End_User__r.Email__c,
                End_User__r.Name,
                End_User__r.Phone,
                End_User__r.Primary_Contact_Name__c,
                End_User__r.Legal_Entity_Name__c,
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
                Financial_Product_Id__c,
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
							Opportunity_Number__c,
                            Partner_Sales_Rep__c,
                            Business_Structure__c,
                            Years_in_Business__c,
                            Customer_Story__c,
                            Application_Date__c,
                            Sub_Stage__c, 
                            Application_Number__c 
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

    /************************************************************************************************************************************************
     * getQuoteLines(Id quoteId)
     *****************************************************************************************************************************************************/
    public static List<Quote_Line__c> getQuoteLines(Id quoteId){

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
     *   MISC
     *****************************************************************************************************************************************************/

     public class CreditAppException extends Exception {}

     public class ReturnStatus {
        public Boolean isSuccess;
        public String message;
        public Integer responseCode;
        public String responseBody;
    }
    
    public class PicklistValue {
        public String label {get;set;}
        public String value {get;set;}
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
        public String endUserName;
    
        OpportunityResObject(Opportunity opp) {
            this.value = opp.Id;
            this.label = opp.Name;
            this.accountId = opp.AccountId;
            this.accountName = opp.Account.Name;
            this.accountSiteId = opp.Account.Originating_Site_ID__c;
            this.endUserId = opp.End_User__c;
            this.endUserName = opp.End_User__c != null ? opp.End_User__r.Name : null;
        }
    
    }


    public class Asset {
        public String sectionName {get;set;}
        public String assetHeading {get;set;}
        public String assetNo {get;set;}
        public Boolean isFirst {get;set;}
        public PicklistValue make {get;set;}
        public PicklistValue assetType {get;set;}
        public Model model {get;set;}
        public String mastTypeValue {get;set;}
        public Integer numberOfUnits {get;set;}
        public Decimal unitSalesPrice {get;set;}
        public String assetId {get;set;}
        public String quoteId {get;set;}
    }

    public class Model {
        public String type;
        public String assetType;
        public String brand;
        public String label;
        public String masterType;
        public String modelId;
        public String value;   
    }

    
}