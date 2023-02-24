/*********************************************************************************************************
 * Create Quote Opportunity Controller
 *
 * change log:
 * 11-17-2021 - Ivy Lu
 * 7/11/2022 - MRM Added logic that a quote option can't be in a credit app without a valid payment amount
 * 10/11/2022 - MRM added temp logic to experiment with appeals
 * 10/21/2022 - Geetha added logic for not storing Yes/No for Subsidy Id(instead store blank if Subsidy is No)PBI:882069
 * 02/01/2023 : PBI 930611 - Sharing rules Field population :Dibyendu
 * 01/19/2023 : MRM add application number to return values
 * 01/27/2023 : MRM Added isAppeal and include in credit app in save logic 
 * 02/06/2023 - MRM Added display quote number to appeals page
 *********************************************************************************************************/


public with sharing class CreateQuoteOpportunity {

public class quoteOpportunityWrapper {
@AuraEnabled
public Opportunity newOpp { get; set; }
@AuraEnabled
public List<quoteOpportunityLineItem> quoteOpportunityLineItems { get; set; }

public quoteOpportunityWrapper() {
	this.newOpp = new Opportunity();
	this.quoteOpportunityLineItems = new List<quoteOpportunityLineItem>();
}
}

public class quoteOpportunityLineItem {
@AuraEnabled
public Quote quote { get; set; }
@AuraEnabled
public List<Quote_Line__c> quoteLines { get; set; }

public quoteOpportunityLineItem() {
	this.quote = new Quote();
	this.quoteLines = new List<Quote_Line__c>();
}

public quoteOpportunityLineItem(Quote quote, List<Quote_Line__c> quoteLines) {
	this.quote = quote;
	this.quoteLines = quoteLines;
}

public quoteOpportunityLineItem(Quote quote) {
	this.quote = quote;
}
}

//The first time when user create a quote, the system will create an opportunity and
//multiple quote options and related quote line items(assets and accessories)
@AuraEnabled
public static quoteOpportunityWrapper CreateQuoteOpportunity(String jsonInput) {

	Map<String, Object> jsonInputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);
	system.debug('jsonInputMap_createqOpp ' +jsonInputMap);
	//get opportunity and quote information(quote options)
	String nickName = (String) jsonInputMap.get('nickname');
	String location = (String)(jsonInputMap.get('location'));
	String programName = (String) (jsonInputMap.get('program'));
	String programId = (String) (jsonInputMap.get('programId'));
	String salesRep = (String) (jsonInputMap.get('salesRep'));
	String rateType = (String) (jsonInputMap.get('rateType'));
	String rateTypeId = (String) (jsonInputMap.get('rateTypeId'));
	String financeTermList = (String) (jsonInputMap.get('financeTerm'));
	String financeType = (String) (jsonInputMap.get('financeType'));
	String paymentFrequency = (String) (jsonInputMap.get('paymentFrequency'));
	String advPayments = (String) (jsonInputMap.get('advPayments'));
	String assetType = (String) (jsonInputMap.get('assetTypeQuote'));
	String comments = (String) (jsonInputMap.get('comments'));

	if (String.isBlank(salesRep) || (salesRep.length() == 0)) {
		salesRep = null;
	}

	List<String> lstFinanceTerm = new List<String>();

	if (!String.isBlank(financeTermList)) {
		//get multiple finance terms to create quote options
		lstFinanceTerm = financeTermList.split(',');
	}

	List<Object> jsonAssets = (List<Object>) jsonInputMap.get('assets');

	//insert opportunity
	System.debug('start create quote opp');
	Opportunity newOpp = new Opportunity();
	newOpp.RecordTypeId = [select Id from RecordType where DeveloperName = 'Retail' AND sObjectType = 'Opportunity' limit 1].Id;
	newOpp.Nickname__c = nickName;
	newOpp.AccountId = [SELECT Id, Originating_Site_ID__c from Account where Originating_Site_ID__c = : location Limit 1].Id;
	//Start Of Change for PBI 930611-Sharing Rule Field Population
    newOpp.Business_Unit1__c = [select id,label,Business_Unit__c from Contact_Support__mdt where label='Contact Support DLL CTI' Limit 1].Business_Unit__c;
    newOpp.Business_Unit_Description__c = System.Label.CTI_BUSINESS_UNIT;
    newOpp.Legal_Entity_Description__c = 'DLL';
    //End Of Start Of Change for PBI 930611 - -Sharing Rule Field Population
    newOpp.CloseDate = System.today() + 30;
	newOpp.StageName = 'Quoting';
	newOpp.Sub_Stage__c = 'Quoting & Proposal';
	newOpp.ForecastCategoryName = 'Omitted';
	newOpp.Amount = 0;
	newOpp.CurrencyIsoCode = 'USD';
	//newOpp.Location__c = location;
	if (lstFinanceTerm.size() == 0) {
		newOpp.Sub_Stage__c = 'Quote Draft';
	}
	System.debug('newOpp before insert:' + newOpp);
	try {
		insert newOpp;
	} catch (DmlException e) {
		System.debug('The following exception has occurred: ' + e.getMessage());
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}
	System.debug('newOpp after insert:' + newOpp);
	System.debug('end create quote opp');

	//insert quote options
	List<Quote> quoteList = new List<Quote>();
	Quote newQuote = new Quote();
	newQuote.Rate_Type__c = rateType;
	newQuote.Rate_Type_Id__c = rateTypeId;
	if (lstFinanceTerm.size() != 0) {
		newQuote.Term__c = lstFinanceTerm[0];
	}
	//newQuote.Finance_Term_Month__c = lstFinanceTerm[i];
	newQuote.Lease_Type__c = financeType;
	newQuote.Payment_Frequency__c = paymentFrequency;
	newQuote.Advance_Payments__c = advPayments;
	newQuote.OpportunityId = newOpp.Id;
	newQuote.Name = nickName;
	newQuote.Partner_Sales_Rep__c = salesRep;
	newQuote.Program__c = programName;
	newQuote.Program_ID__c = programId;
	newQuote.Option_Number__c = 1;
	newQuote.Comments__c = comments;
	newQuote.Asset_Type__c = assetType;
	newQuote.Created_Date__c = Date.today();
	newQuote.Location_Id__c = location;
	if (advPayments == '0') {
		newQuote.Payment_Timing__c = 'in-arrears';
	} else {
		newQuote.Payment_Timing__c = 'in-advance';
	}
	quoteList.add(newQuote);
	try {
		insert quoteList;
		//newOpp.SyncedQuoteId = quoteList.get(0).Id;
		//update newOpp;
	} catch (DmlException e) {
		System.debug('The following exception has occurred: ' + e.getMessage());
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}
	System.debug('newQuote after insert:' + quoteList);

	/*if (lstFinanceTerm.size() == 0) {
	    quoteOpportunityWrapper quoteWrapper = new quoteOpportunityWrapper();
	    quoteWrapper = QueryQuoteOpportunity(newOpp.Id);

	    return quoteWrapper;
	   }*/

	Map<String, Quote_Line__c> relatedAssetToAssetId = new Map<String, Quote_Line__c>();
	Map<String, Id> relatedAssetToQuoteId = new Map<String, Id>();

	Decimal sequenceIdCount = 0;

	//insert quote line items(assets and accessories)
	//List<Object> jsonAssets = (List<Object>) jsonInputMap.get('assets');
	List<Quote_Line__c> assetList = new List<Quote_Line__c>();
	if ((quoteList.size() > 0) && (jsonAssets != null)) {
		for (Quote q : quoteList) {
			for (Object obj : jsonAssets) {
				sequenceIdCount++;
				Map < String, Object > assetMap = (Map < String, Object >) obj;
				Quote_Line__c asset = new Quote_Line__c(
					Quote__c = q.Id,
					Make__c = (String) (assetMap.get('make')),
					Make_Id__c = (String) (assetMap.get('makeId')),
					Asset_Type_ITA_Class__c = (String) (assetMap.get('assetType')),
					Asset_Type_ITA_Class_Id__c = (String) (assetMap.get('assetTypeId')),
					Model__c = (String) (assetMap.get('model')),
					Model_Id__c = (String) (assetMap.get('modelId')),
					Mast_Type__c = (String) (assetMap.get('mastType')),
					Base_Unit_Sales_Price__c = assetMap.get('unitSalesPrice') == null ? 0 : Decimal.valueOf((String) assetMap.get('unitSalesPrice')),
					Number_of_Units__c = assetMap.get('numberOfUnits') == null ? 0 : Decimal.valueOf((String) assetMap.get('numberOfUnits')),
					Annual_Hours__c = assetMap.get('annualHours') == null ? 0 : Decimal.valueOf((String) assetMap.get('annualHours')),
					Operating_Environment__c = (String) (assetMap.get('assetOperating')),
					Battery_Included__c = (String) (assetMap.get('batteryIncluded')),
					Subsidy__c = (String) (assetMap.get('subsidyName')),
					Subsidy_ID__c = (String) (assetMap.get('subsidy')),
                    //PBI:882069:Geetha
					//Subsidy_ID__c = (String) ((assetMap.get('subsidy') == 'Yes') ? (assetMap.get('subsidy')): '' ),
					MSRP__c = assetMap.get('msrp') == null ? 0 : Decimal.valueOf((String) assetMap.get('msrp')),
					Asset_Type__c = (String) (assetMap.get('type'))
					);
				asset.Name = asset.Make__c + ' ' + asset.Model__c;
				relatedAssetToAssetId.put(String.valueOf(assetMap.get('assetNo')), asset);
				relatedAssetToQuoteId.put(String.valueOf(assetMap.get('assetNo')), asset.Quote__c);
				assetList.add(asset);
			}
		}
		try {
			insert assetList;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('newQuoteLine after insert:' + assetList);
	}

	List<Object> jsonAccessories = (List<Object>) jsonInputMap.get('accessories');
	List<Quote_Line__c> accessoriesList = new List<Quote_Line__c>();
	system.debug('jsonAccessories_createqOpp '+jsonAccessories);
	if ((quoteList.size() > 0) && (jsonAccessories != null)) {

		for (Object obj : jsonAccessories) {
			Map < String, Object > accessoryMap = (Map < String, Object >) obj;
			String relatedAssetId = null;
			Quote_Line__c relatedAssetObj = relatedAssetToAssetId.get(String.valueOf(accessoryMap.get('relatedAsset')));
			if (relatedAssetObj != null) {
				relatedAssetId = relatedAssetObj.Id;
			} else {
				continue;
			}
			sequenceIdCount++;
			Quote_Line__c accessory = new Quote_Line__c(
				Quote__c = relatedAssetToQuoteId.get(String.valueOf(accessoryMap.get('relatedAsset'))),
				Related_Asset__c = relatedAssetId,
				Model__c = String.valueOf(accessoryMap.get('model')),
				Model_Id__c = String.valueOf(accessoryMap.get('modelId')),
				Equipment_Type__c = 'Add-On',
				Number_of_Units__c = accessoryMap.get('noOfUnits') == null ? 0 : Decimal.valueOf((String) accessoryMap.get('noOfUnits')),
				Base_Unit_Sales_Price__c = accessoryMap.get('unitSalesPrice') == null ? 0 : Decimal.valueOf((String) accessoryMap.get('unitSalesPrice'))
				);
			accessory.Name = accessory.Model__c;
			if (!String.isBlank(accessory.Quote__c)) {
				accessoriesList.add(accessory);
			}
		}

		/*if (accessoriesList.isEmpty()) {
		    AuraHandledException ex = new AuraHandledException('No Accessories Found');
		    throw ex;
		   }*/

		try {
			if (!accessoriesList.isEmpty()) {
				insert accessoriesList;
			}
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('newQuoteLineAccessories after insert:' + accessoriesList);
	} /*else {
		AuraHandledException ex = new AuraHandledException('No Accessories Found at all');
		throw ex;
		}*/

	quoteOpportunityWrapper quoteWrapper = new quoteOpportunityWrapper();
	quoteWrapper = QueryQuoteOpportunity(newOpp.Id);

	return quoteWrapper;
}

//The user can clone an existing quote option
@AuraEnabled
public static quoteOpportunityWrapper CloneQuoteOption(String jsonInput) {

	Map<String, Object> jsonInputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);

	//get opportunity and quote option information
	String oppId = (String) jsonInputMap.get('oppId');
	system.debug('oppId:' + oppId);
	Decimal maxQuoteOptionNum;
	try {
		AggregateResult[] groupedResults = [SELECT MAX(Option_Number__c) maxNum FROM Quote WHERE OpportunityId = : oppId];
		maxQuoteOptionNum = (Decimal) groupedResults[0].get('maxNum');
		system.debug('maxQuoteOptionNum:' + maxQuoteOptionNum);
	} catch (QueryException e) {
		System.debug('exception happened:' + e.getmessage());
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}

	Decimal newQuoteOptionNum = 1;

	if (maxQuoteOptionNum != null) {
		newQuoteOptionNum = maxQuoteOptionNum + 1;
	}

	Opportunity existingOpp;

	if (!String.isBlank(oppId)) {
		try {
			existingOpp = [SELECT Id, Sub_Stage__c FROM Opportunity WHERE Id = : oppId];

			if (existingOpp.Sub_Stage__c == 'Quote Draft') {
				existingOpp.Sub_Stage__c = 'Quoting & Proposal';
				update existingOpp;
			}
		} catch (QueryException ex) {
			System.debug('invalid Opportunity Id provided.');
		} catch (DmlException exc) {
			System.debug('Unable to update opportunity');
		}
	}

	String salesRep = (String) (jsonInputMap.get('salesRep'));

	if (String.isBlank(salesRep) || (salesRep.length() == 0)) {
		salesRep = null;
	}

	String advPayments = (String) (jsonInputMap.get('advPayments'));
	String paymentTiming;

	if (advPayments == '0') {
		paymentTiming = 'in-arrears';
	} else {
		paymentTiming = 'in-advance';
	}

	//Insert new quote option
	Quote newQuote = new Quote(
		Rate_Type__c = (String) (jsonInputMap.get('rateType')),
		Rate_Type_Id__c = (String) (jsonInputMap.get('rateTypeId')),
		Term__c = (String) (jsonInputMap.get('financeTerm')),
		//Finance_Term_Month__c = (String) (jsonInputMap.get('financeTerm')),
		Lease_Type__c = (String) (jsonInputMap.get('financeType')),
		Payment_Frequency__c = (String) (jsonInputMap.get('paymentFrequency')),
		Advance_Payments__c = (String) (jsonInputMap.get('advPayments')),
		OpportunityId = oppId,
		Name = (String) jsonInputMap.get('nickname'),
		Partner_Sales_Rep__c = salesRep,
		Program__c = (String) (jsonInputMap.get('program')),
		Program_ID__c = (String) (jsonInputMap.get('programId')),
		Comments__c = (String) (jsonInputMap.get('comments')),
		Location_ID__c = (String) (jsonInputMap.get('location')),
		Payment_Timing__c = paymentTiming,
		Asset_Type__c = (String) (jsonInputMap.get('assetTypeQuote')),
		Option_Number__c = newQuoteOptionNum,
		Created_Date__c = Date.today(),
		Is_Appeal__c = (Boolean) (jsonInputMap.get('isappeal')),
		Current_Credit_App_Selection__c= (Boolean) (jsonInputMap.get('includeinapp'))
		);
	try {
		insert newQuote;
		//if ((existingOpp != null) && (String.isBlank(existingOpp.SyncedQuoteId))) {
		//existingOpp.SyncedQuoteId = newQuote.Id;
		//update existingOpp;
		//}
	} catch (DmlException e) {
		System.debug('The following exception has occurred: ' + e.getMessage());
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}
	system.debug('insert newQuote:' + newQuote);

	Map<String, Quote_Line__c> relatedAssetToAssetId = new Map<String, Quote_Line__c>();
	Map<String, Id> relatedAssetToQuoteId = new Map<String, Id>();

	Decimal sequenceIdCount = 0;

	//insert quote line items(assets and accessories)
	List<Quote_Line__c> assetList = new List<Quote_Line__c>();
	List<Object> jsonAssets = (List<Object>) jsonInputMap.get('assets');
	if (jsonAssets != null) {
		for (Object obj : jsonAssets) {
			sequenceIdCount++;
			Map < String, Object > assetMap = (Map < String, Object >) obj;
			Quote_Line__c asset = new Quote_Line__c(
				Quote__c = newQuote.Id,
				Make__c = (String) (assetMap.get('make')),
				Asset_Type_ITA_Class__c = (String) (assetMap.get('assetType')),
				Model__c = (String) (assetMap.get('model')),
				Mast_Type__c = (String) (assetMap.get('mastType')),
				Base_Unit_Sales_Price__c = assetMap.get('unitSalesPrice') == null ? 0 : Decimal.valueOf((String) assetMap.get('unitSalesPrice')),
				Number_of_Units__c = assetMap.get('numberOfUnits') == null ? 0 : Decimal.valueOf((String) assetMap.get('numberOfUnits')),
				Annual_Hours__c = assetMap.get('annualHours') == null ? 0 : Decimal.valueOf((String) assetMap.get('annualHours')),
				Operating_Environment__c = (String) (assetMap.get('assetOperating')),
				Battery_Included__c = (String) (assetMap.get('batteryIncluded')),
				Make_Id__c = (String) (assetMap.get('makeId')),
				Asset_Type_ITA_Class_Id__c = (String) (assetMap.get('assetTypeId')),
				Subsidy__c = (String) (assetMap.get('subsidyName')),
				//PBI:882069:Geetha
                Subsidy_ID__c = (String) ((assetMap.get('subsidy') == 'Yes') ? (assetMap.get('subsidy')): '' ),
				Model_Id__c = (String) (assetMap.get('modelId')),
				MSRP__c = assetMap.get('msrp') == null ? 0 : Decimal.valueOf((String) assetMap.get('msrp')),
				Asset_Type__c = (String) (assetMap.get('type'))
				);
			asset.Name = asset.Make__c + ' ' + asset.Model__c;
			relatedAssetToAssetId.put(String.valueOf(assetMap.get('assetNo')), asset);
			relatedAssetToQuoteId.put(String.valueOf(assetMap.get('assetNo')), asset.Quote__c);
			assetList.add(asset);
		}
		try {
			insert assetList;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
	}

	List<Object> jsonAccessories = (List<Object>) jsonInputMap.get('accessories');
	List<Quote_Line__c> accessoriesList = new List<Quote_Line__c>();

	if ((jsonAccessories != null)) {
		for (Object obj : jsonAccessories) {
			Map < String, Object > accessoryMap = (Map < String, Object >) obj;
			String relatedAssetId = null;
			Quote_Line__c relatedAssetObj = relatedAssetToAssetId.get(String.valueOf(accessoryMap.get('relatedAsset')));
			if (relatedAssetObj != null) {
				relatedAssetId = relatedAssetObj.Id;
			} else {
				continue;
			}
			sequenceIdCount++;
			Quote_Line__c accessory = new Quote_Line__c(
				Quote__c = relatedAssetToQuoteId.get(String.valueOf(accessoryMap.get('relatedAsset'))),
				Related_Asset__c = relatedAssetId,
				Model__c = String.valueOf(accessoryMap.get('model')),
				Model_Id__c = String.valueOf(accessoryMap.get('modelId')),
				Equipment_Type__c = 'Add-On',
				Number_of_Units__c = accessoryMap.get('noOfUnits') == null ? 0 : Decimal.valueOf(String.valueOf(accessoryMap.get('noOfUnits'))),
				Base_Unit_Sales_Price__c = accessoryMap.get('unitSalesPrice') == null ? 0 : Decimal.valueOf(String.valueOf(accessoryMap.get('unitSalesPrice')))
				);
			accessory.Name = accessory.Model__c;
			if (!String.isBlank(accessory.Quote__c)) {
				accessoriesList.add(accessory);
			}
		}

		/*if (accessoriesList.isEmpty()) {
		    AuraHandledException ex = new AuraHandledException('No Accessories Found');
		    throw ex;
		   }*/

		try {
			if (!accessoriesList.isEmpty()) {
				insert accessoriesList;
			}
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('newQuoteLineAccessories after insert:' + accessoriesList);
	} /*else {
		AuraHandledException ex = new AuraHandledException('No Accessories Found at all');
		throw ex;
		}*/

	quoteOpportunityWrapper quoteWrapper = new quoteOpportunityWrapper();
	quoteWrapper = QueryQuoteOpportunity(oppId);
	return quoteWrapper;
}

//The user can edit details in quote option, including quote line items(assets and accessories)
@AuraEnabled
public static quoteOpportunityWrapper EditQuoteOption(String jsonInput) {

	Boolean nickNameChanged = false;
	Boolean financeStructureChanged = false;

	Map<String, Object> jsonInputMap = (Map<String, Object>) JSON.deserializeUntyped(jsonInput);

	//get opportunity and quote option information
	String quoteOptionId = (String) jsonInputMap.get('Id');
	String nickName = (String) jsonInputMap.get('nickname');
	//String location = (String)(jsonInputMap.get('location'));
	String programName = (String) (jsonInputMap.get('program'));
	String programId = (String) (jsonInputMap.get('programId'));
	String salesRep = (String) (jsonInputMap.get('salesRep'));
	String rateType = (String) (jsonInputMap.get('rateType'));
	String rateTypeId = (String) (jsonInputMap.get('rateTypeId'));
	String financeTerm = (String) (jsonInputMap.get('financeTerm'));
	String financeType = (String) (jsonInputMap.get('financeType'));
	String paymentFrequency = (String) (jsonInputMap.get('paymentFrequency'));
	String advPayments = (String) (jsonInputMap.get('advPayments'));
	String comments = (String) (jsonInputMap.get('comments'));
	system.debug('quoteOptionId:' + quoteOptionId);

	//query quote option information
	Quote updatedQuote = new Quote();
	try {
		updatedQuote = [
			SELECT Id,Option_Number__c,Rate_Type__c, Rate_Type_Id__c,Term__c, Comments__c,
			Lease_Type__c,Payment_Frequency__c,Advance_Payments__c,OpportunityId,Name,Partner_Sales_Rep__c,Program__c,Program_ID__c
			FROM Quote
			WHERE Id = : quoteOptionId
		];
	} catch (QueryException e) {
		System.debug('exception happened:' + e.getmessage());
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}

	if (!String.isBlank(updatedQuote.OpportunityId)) {
		try {
			Opportunity existingOpp = [SELECT Id, Sub_Stage__c FROM Opportunity WHERE Id = : updatedQuote.OpportunityId];

			if (existingOpp.Sub_Stage__c == 'Quote Draft') {
				existingOpp.Sub_Stage__c = 'Quoting & Proposal';
				update existingOpp;
			}
		} catch (QueryException ex) {
			System.debug('invalid Opportunity Id provided.');
		} catch (DmlException exc) {
			System.debug('Unable to update opportunity');
		}
	}

	String paymentTiming;

	if (advPayments == '0') {
		paymentTiming = 'in-arrears';
	} else {
		paymentTiming = 'in-advance';
	}

	//if financial structure changed, update quote option
	If ((updatedQuote.Rate_Type__c != rateType) ||
	    (updatedQuote.Term__c != financeTerm) || (updatedQuote.Lease_Type__c != financeType) ||
	    (updatedQuote.Payment_Frequency__c != paymentFrequency) || (updatedQuote.Advance_Payments__c != advPayments)) {
		financeStructureChanged = true;
		updatedQuote.Rate_Type__c = rateType;
		updatedQuote.Rate_Type_Id__c = rateTypeId;
		updatedQuote.Term__c = financeTerm;
		//updatedQuote.Finance_Term_Month__c = financeTerm;
		updatedQuote.Lease_Type__c = financeType;
		updatedQuote.Payment_Frequency__c = paymentFrequency;
		updatedQuote.Advance_Payments__c = advPayments;
		updatedQuote.Payment_Timing__c = paymentTiming;
	}

	//If nickname is changed, update opportunity nickname and all quote options' name
	Opportunity updatedOpp = new Opportunity();
	List<Quote> updatedQuoteList = new List<Quote>();
	If ((String.isNotBlank(nickName)) && (updatedQuote.Name != nickName)) {
		nickNameChanged = true;
		//update opportunity nickname
		try {
			updatedOpp = [SELECT Id,Nickname__c FROM Opportunity WHERE Id = : updatedQuote.OpportunityId];
		} catch (QueryException e) {
			System.debug('exception happened:' + e.getmessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		updatedOpp.Nickname__c = nickName;
		try {
			update updatedOpp;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		//update quote options' name
		try {
			updatedQuoteList = [
				SELECT Id,Option_Number__c,Rate_Type__c, Rate_Type_Id__c, Term__c,
				Lease_Type__c,Payment_Frequency__c,Advance_Payments__c,OpportunityId,Name,Partner_Sales_Rep__c,Program__c,Program_ID__c
				FROM Quote
				WHERE OpportunityId = : updatedQuote.OpportunityId
			];
		} catch (QueryException e) {
			System.debug('exception happened:' + e.getmessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		if (updatedQuoteList.size() > 0) {
			for (quote q : updatedQuoteList) {
				q.Name = nickName;
			}
		}
	}

	Boolean commentsChanged = false;
	Boolean salesRepChanged = false;

	if (updatedQuote.Comments__c != comments) {
		commentsChanged = true;
		updatedQuote.Comments__c = comments;
	}

	if ((String.isBlank(salesRep) || (salesRep.length() == 0)) || (updatedQuote.Partner_Sales_Rep__c != salesRep)) {
		salesRepChanged = true;
		if (String.isBlank(salesRep) || (salesRep.length() == 0)) {
			updatedQuote.Partner_Sales_Rep__c = null;
		} else {
			updatedQuote.Partner_Sales_Rep__c = (Id) salesRep;
		}
	}

	//update quote options based on changed information
	if ((financeStructureChanged == true) && (nickNameChanged == true)) {
		for (quote q : updatedQuoteList) {
			if (q.Id.equals(updatedQuote.Id)) {
				q.Rate_Type__c = updatedQuote.Rate_Type__c;
				q.Rate_Type_Id__c = updatedQuote.Rate_Type_Id__c;
				q.Term__c = updatedQuote.Term__c;
				//q.Finance_Term_Month__c = updatedQuote.Term__c;
				q.Lease_Type__c = updatedQuote.Lease_Type__c;
				q.Payment_Frequency__c = updatedQuote.Payment_Frequency__c;
				q.Advance_Payments__c = updatedQuote.Advance_Payments__c;
				q.Payment_Timing__c = updatedQuote.Payment_Timing__c;
			}
		}
		try {
			System.debug('Test should get here.');
			update updatedQuoteList;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
	} else {
		if ((financeStructureChanged == true) && (nickNameChanged == false)) {
			try {
				update updatedQuote;
			} catch (DmlException e) {
				System.debug('The following exception has occurred: ' + e.getMessage());
				AuraHandledException ex = new AuraHandledException(e.getMessage());
				throw ex;
			}
		} else {
			if ((financeStructureChanged == false) && (nickNameChanged == true)) {
				try {
					System.debug('Test should get here.');
					update updatedQuoteList;
				} catch (DmlException e) {
					System.debug('The following exception has occurred: ' + e.getMessage());
					AuraHandledException ex = new AuraHandledException(e.getMessage());
					throw ex;
				}
			}
		}
	}

	if (((financeStructureChanged == false) || (nickNameChanged == true)) && ((commentsChanged == true) || (salesRepChanged == true))) {
		try {
			updatedQuote.Name = nickName;
			update updatedQuote;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
	}

	Map<String, Quote_Line__c> relatedAssetToAssetId = new Map<String, Quote_Line__c>();
	Map<String, Id> relatedAssetToQuoteId = new Map<String, Id>();

	//handle asset change(new,modify,delete)
	List<Quote_Line__c> newAssetList = new List<Quote_Line__c>();
	List<Quote_Line__c> updateAssetList = new List<Quote_Line__c>();
	List<Quote_Line__c> deleteAssetList = new List<Quote_Line__c>();
	List<Id> deleteAssetsId = new List<Id>();
	List<Object> jsonAssets = (List<Object>) jsonInputMap.get('assets');
	List<Object> jsonDeletedAssets = (List<Object>) jsonInputMap.get('deleteAssets');

	Decimal sequenceIdCount = 0;

	if (jsonAssets != null) {
		for (Object obj : jsonAssets) {
			Map < String, Object > assetMap = (Map < String, Object >) obj;
			String assetId = (String) (assetMap.get('Id'));
			String make = (String) (assetMap.get('make'));
			String makeId = (String) (assetMap.get('makeId'));
			String assetType = (String) (assetMap.get('assetType'));
			String assetTypeId = (String) (assetMap.get('assetTypeId'));
			String model = (String) (assetMap.get('model'));
			String modelId = (String) (assetMap.get('modelId'));
			String mastType = (String) (assetMap.get('mastType'));
			Decimal baseUnitSalesPrice = assetMap.get('unitSalesPrice') == null ? 0 : Decimal.valueOf((String) assetMap.get('unitSalesPrice'));
			Decimal unitsNum = assetMap.get('numberOfUnits') == null ? 0 : Decimal.valueOf((String) assetMap.get('numberOfUnits'));
			Decimal annualHour = assetMap.get('annualHours') == null ? 0 : Decimal.valueOf((String) assetMap.get('annualHours'));
			String operationEnv = (String) (assetMap.get('assetOperating'));
			String batteryIncluded = (String) (assetMap.get('batteryIncluded'));
			String quoteLineType = (String) (assetMap.get('type'));
			Decimal msrp = assetMap.get('msrp') == null ? 0 : Decimal.valueOf((String) assetMap.get('msrp'));
			String subsidy = (String) (assetMap.get('subsidyName'));
			String subsidyId = (String) (assetMap.get('subsidy'));
			//PBI:882069:Geetha
            //String subsidyId = (String) ((assetMap.get('subsidy') == 'Yes') ? (assetMap.get('subsidy')): '' );

			if (String.isBlank(assetId)) {
				sequenceIdCount++;
				Quote_Line__c newAsset = new Quote_Line__c(
					Quote__c = quoteOptionId,
					Make__c = make,
					Make_Id__c = makeId,
					Asset_Type_ITA_Class__c = assetType,
					Asset_Type_ITA_Class_Id__c = assetTypeId,
					Model__c = model,
					Model_Id__c = modelId,
					Mast_Type__c = mastType,
					Base_Unit_Sales_Price__c = baseUnitSalesPrice,
					Number_of_Units__c = unitsNum,
					Annual_Hours__c = annualHour,
					Operating_Environment__c = operationEnv,
					Battery_Included__c = batteryIncluded,
					Asset_Type__c = quoteLineType,
					MSRP__c = msrp,
					Subsidy__c = subsidy,
					Subsidy_ID__c = subsidyId
					);
				newAsset.Name = newAsset.Make__c + ' ' + newAsset.Model__c;
				relatedAssetToAssetId.put(String.valueOf(assetMap.get('assetNo')), newAsset);
				relatedAssetToQuoteId.put(String.valueOf(assetMap.get('assetNo')), newAsset.Quote__c);
				newAssetList.add(newAsset);
			} else {
				Quote_Line__c updatedAsset = [
					SELECT Quote__c,Make__c,Make_Id__c,Asset_Type_ITA_Class__c, Asset_Type_ITA_Class_Id__c,Model__c, Model_Id__c, Mast_Type__c,
					Base_Unit_Sales_Price__c,Number_of_Units__c,Annual_Hours__c,Operating_Environment__c,Battery_Included__c, Subsidy__c, Subsidy_ID__c
					FROM Quote_Line__c
					WHERE Id = : assetId
				];
				relatedAssetToAssetId.put(String.valueOf(assetMap.get('assetNo')), updatedAsset);
				relatedAssetToQuoteId.put(String.valueOf(assetMap.get('assetNo')), updatedAsset.Quote__c);
				System.debug('updatedAsset: ' + updatedAsset);
				If ((updatedAsset.Make__c != make) || (updatedAsset.Asset_Type_ITA_Class__c != assetType) ||
				    (updatedAsset.Model__c != model) || (updatedAsset.Mast_Type__c != mastType) ||
				    (updatedAsset.Base_Unit_Sales_Price__c != baseUnitSalesPrice) || (updatedAsset.Number_of_Units__c != unitsNum) ||
				    (updatedAsset.Annual_Hours__c != annualHour) || (updatedAsset.Operating_Environment__c != operationEnv) ||
				    (updatedAsset.Battery_Included__c != batteryIncluded) || (updatedAsset.Subsidy_ID__c != subsidyId)) {
					updatedAsset.Make__c = make;
					updatedAsset.Make_Id__c = makeId;
					updatedAsset.Asset_Type_ITA_Class__c = assetType;
					updatedAsset.Asset_Type_ITA_Class_Id__c = assetTypeId;
					updatedAsset.Model__c = model;
					updatedAsset.Model_Id__c = modelId;
					updatedAsset.Mast_Type__c = mastType;
					updatedAsset.Base_Unit_Sales_Price__c = baseUnitSalesPrice;
					updatedAsset.Number_of_Units__c = unitsNum;
					updatedAsset.Annual_Hours__c = annualHour;
					updatedAsset.Operating_Environment__c = operationEnv;
					updatedAsset.Battery_Included__c = batteryIncluded;
					updatedAsset.Subsidy__c = subsidy;
					updatedAsset.Subsidy_ID__c = subsidyId;
					updatedAsset.Asset_Type__c = quoteLineType;
					updatedAsset.MSRP__c = msrp;
					updatedAsset.Name = make + ' ' + model;
				}
				sequenceIdCount++;
				updateAssetList.add(updatedAsset);
				System.debug('updateAssetList: ' + updateAssetList);
			}
		}
	}

	if (jsonDeletedAssets != null) {
		for (Object obj : jsonDeletedAssets) {
			Map < String, Object > assetMap = (Map < String, Object >) obj;
			String assetId = (String) (assetMap.get('Id'));
			deleteAssetsId.add(assetId);
			System.debug('deleteAssetsId: ' + deleteAssetsId);
		}
	}

	if (newAssetList.size() > 0) {
		try {
			System.debug('before insert');
			insert newAssetList;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('after insert');
	}

	List<Object> jsonAccessories = (List<Object>) jsonInputMap.get('accessories');
	List<Quote_Line__c> accessoriesList = new List<Quote_Line__c>();
	List<Quote_Line__c> accessoriesListUpdate = new List<Quote_Line__c>();

	if ((jsonAccessories != null)) {
		for (Object obj : jsonAccessories) {
			Map < String, Object > accessoryMap = (Map < String, Object >) obj;
			String assetId = (String) (accessoryMap.get('Id'));
			Decimal noOfUnits = accessoryMap.get('noOfUnits') == null ? 0 : Decimal.valueOf(String.valueOf(accessoryMap.get('noOfUnits')));
			Decimal basePrice = accessoryMap.get('unitSalesPrice') == null ? 0 : Decimal.valueOf(String.valueOf(accessoryMap.get('unitSalesPrice')));
			String model = (String) (accessoryMap.get('model'));
			String modelId = (String) (accessoryMap.get('modelId'));
			String relatedAssetId = null;
			Quote_Line__c relatedAssetObj = relatedAssetToAssetId.get(String.valueOf(accessoryMap.get('relatedAsset')));
			if (relatedAssetObj != null) {
				relatedAssetId = relatedAssetObj.Id;
			} else {
				continue;
			}
			if (String.isBlank(assetId)) {
				sequenceIdCount++;
				Quote_Line__c accessory = new Quote_Line__c(
					Quote__c = relatedAssetToQuoteId.get(String.valueOf(accessoryMap.get('relatedAsset'))),
					Related_Asset__c = relatedAssetId,
					Model__c = String.valueOf(accessoryMap.get('model')),
					Model_Id__c = String.valueOf(accessoryMap.get('modelId')),
					Equipment_Type__c = 'Add-On',
					Number_of_Units__c = accessoryMap.get('noOfUnits') == null ? 0 : Decimal.valueOf((String) accessoryMap.get('noOfUnits')),
					Base_Unit_Sales_Price__c = accessoryMap.get('unitSalesPrice') == null ? 0 : Decimal.valueOf((String) accessoryMap.get('unitSalesPrice'))
					);
				accessory.Name = accessory.Model__c;
				if (!String.isBlank(accessory.Quote__c)) {
					accessoriesList.add(accessory);
				}
			} else {
				Quote_Line__c updatedAsset = [
					SELECT Model__c, Model_Id__c, Equipment_Type__c, Number_of_Units__c, Base_Unit_Sales_Price__c, Quote__c, Related_Asset__c
					FROM Quote_Line__c
					WHERE Id = : assetId
				];
				System.debug('updatedAsset: ' + updatedAsset);
				If ((updatedAsset.Related_Asset__c != relatedAssetId) ||
				    (updatedAsset.Model__c != model) || (updatedAsset.Model_Id__c != modelId) ||
				    (updatedAsset.Base_Unit_Sales_Price__c != basePrice) || (updatedAsset.Number_of_Units__c != noOfUnits)) {
					updatedAsset.Related_Asset__c = relatedAssetId;
					updatedAsset.Base_Unit_Sales_Price__c = basePrice;
					updatedAsset.Number_of_Units__c = noOfUnits;
					updatedAsset.Model__c = model;
					updatedAsset.Model_Id__c = modelId;
					updatedAsset.Name = model;
				}
				sequenceIdCount++;
				accessoriesListUpdate.add(updatedAsset);
				System.debug('updateAssetList: ' + updateAssetList);
			}
		}

		/*if (accessoriesList.isEmpty()) {
		    AuraHandledException ex = new AuraHandledException('No Accessories Found');
		    throw ex;
		   }*/

		try {
			if (!accessoriesList.isEmpty()) {
				insert accessoriesList;
			}
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('newQuoteLineAccessories after insert:' + accessoriesList);

		try {
			if (!accessoriesListUpdate.isEmpty()) {
				update accessoriesListUpdate;
			}
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('updatedQuoteLineAccessories after insert:' + accessoriesListUpdate);
	} /*else {
		AuraHandledException ex = new AuraHandledException('No Accessories Found at all');
		throw ex;
		}*/

	System.debug('updateAssetList.size(): ' + updateAssetList.size());
	if (updateAssetList.size() > 0) {
		try {
			System.debug('before update');
			update updateAssetList;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('after update');
	}

	if (deleteAssetsId.size() > 0) {
		try {
			System.debug('before delete');
			deleteAssetList = [SELECT Id FROM Quote_Line__c WHERE Id IN : deleteAssetsId];
			delete deleteAssetList;
		} catch (DmlException e) {
			System.debug('The following exception has occurred: ' + e.getMessage());
			AuraHandledException ex = new AuraHandledException(e.getMessage());
			throw ex;
		}
		System.debug('after delete');
	}

	quoteOpportunityWrapper quoteWrapper = new quoteOpportunityWrapper();
	quoteWrapper = QueryQuoteOpportunity(updatedQuote.OpportunityId);
	return quoteWrapper;
}

//The user can delete quote option
@AuraEnabled
public static quoteOpportunityWrapper DeleteQuoteOption(String quoteOptionId) {

	//get quote option information
	Quote deleteQuote = new Quote();
	try {
		deleteQuote = [
			SELECT Id,Option_Number__c,Rate_Type__c,Rate_Type_Id__c, Term__c,
			Lease_Type__c,Payment_Frequency__c,Advance_Payments__c,OpportunityId,Name,Partner_Sales_Rep__c,Program__c,Program_ID__c
			FROM Quote
			WHERE Id = : quoteOptionId
		];
		system.debug('deleteQuote: ' + deleteQuote);
	} catch (QueryException e) {
		System.debug('exception happened:' + e.getmessage());
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}
	try {
		delete deleteQuote;
	} catch (DmlException e) {
		System.debug('The following exception has occurred: ' + e.getMessage());
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}

	quoteOpportunityWrapper quoteWrapper = new quoteOpportunityWrapper();
	quoteWrapper = QueryQuoteOpportunity(deleteQuote.OpportunityId);
	return quoteWrapper;
}

@AuraEnabled
public static void saveQuotePricingDataBackToServer(String quoteString) {
	//Map<String, Object> jsonInputMap = (Quote) JSON.deserialize(quoteString, Quote.class);

	Quote quoteToUpdate = (Quote) JSON.deserialize(quoteString, Quote.class);

	//String interest = (String) jsonInputMap.get('Interest__c');

	//quoteToUpdate.Id = (Id) jsonInputMap.get('Id');
	//quoteToUpdate.Total_Price__c = Decimal.valueOf((String)jsonInputMap.get('Total_Price__c'));
	//quoteToUpdate.Interest__c = interest;
	//quoteToUpdate.Total_Payment__c = (Decimal) jsonInputMap.get('Total_Payment__c');

	update quoteToUpdate;
}

@AuraEnabled
public static void saveQuoteLinePricingDataBackToServer(String quoteString) {
	//Map<String, Object> jsonInputMap = (Quote) JSON.deserialize(quoteString, Quote.class);

	List<Quote_Line__c> quoteLineToUpdate = (List<Quote_Line__c>) JSON.deserialize(quoteString, List<Quote_Line__c>.class);

	//String interest = (String) jsonInputMap.get('Interest__c');

	//quoteToUpdate.Id = (Id) jsonInputMap.get('Id');
	//quoteToUpdate.Total_Price__c = Decimal.valueOf((String)jsonInputMap.get('Total_Price__c'));
	//quoteToUpdate.Interest__c = interest;
	//quoteToUpdate.Total_Payment__c = (Decimal) jsonInputMap.get('Total_Payment__c');

	update quoteLineToUpdate;
}

@AuraEnabled
public static void saveCustomerCommentsToOpp(String comments, String oppId) {
	Id oppIdForComments = (Id) oppId;
	Opportunity oppForUpdate = new Opportunity();
	oppForUpdate.Id = oppIdForComments;
	oppForUpdate.Comments__c = comments;

	update oppForUpdate;
}

@AuraEnabled
public static void markQuoteOptionAsPrimary(String quoteId, String oppId) {
	Id oppIdQuotes = (Id) oppId;
	Id quoteIdToMakeTrue = (Id) quoteId;
	List<Quote> quotesFound;
	try {
		quotesFound = [SELECT Id, Is_Primary__c FROM Quote WHERE Id != : quoteIdToMakeTrue AND OpportunityId = : oppIdQuotes];
	} catch (QueryException e) {
		System.debug('Error in getting related quotes for Primary quote.');
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}
	List<Quote> quotesToUpdate = new List<Quote>();
	for (Quote q : quotesFound) {
		if (q.Is_Primary__c) {
			Quote qToAdd = new Quote();
			qToAdd.Is_Primary__c = false;
			qToAdd.Id = q.Id;
			quotesToUpdate.add(qToAdd);
		}
	}
	Quote quotePrimary = new Quote();
	quotePrimary.Is_Primary__c = true;
	quotePrimary.Id = quoteIdToMakeTrue;
	quotesToUpdate.add(quotePrimary);
	update quotesToUpdate;
}

@AuraEnabled
public static String markQuoteOptionAsCreditAppSelection(String quoteId, String oppId) {
	Id oppIdQuotes = (Id) oppId;
	Id quoteIdToMakeTrue = (Id) quoteId;
	List<Quote> quotesFound;
	Quote q1;

	try {
		system.debug('in mark');
		q1 = [select Total_Payment__c
		      from Quote
		      where id = : quoteId
		];
		if (q1.total_payment__c == null || q1.total_payment__c == 0) {
			return 'NoPayment';
		}

		quotesFound = [SELECT Id, Current_Credit_App_Selection__c, Total_Payment__c
		               FROM Quote
		               WHERE Id != : quoteIdToMakeTrue AND OpportunityId = : oppIdQuotes];
	} catch (QueryException e) {
		System.debug('Error in getting related quotes for Primary quote.');
		AuraHandledException ex = new AuraHandledException(e.getMessage());
		throw ex;
	}
	List<Quote> quotesToUpdate = new List<Quote>();
	for (Quote q : quotesFound) {
		if (q.Current_Credit_App_Selection__c) {
			Quote qToAdd = new Quote();
			qToAdd.Current_Credit_App_Selection__c = false;
			qToAdd.Id = q.Id;
			quotesToUpdate.add(qToAdd);
		}
	}
	Quote quotePrimary = new Quote();
	quotePrimary.Current_Credit_App_Selection__c = true;
	quotePrimary.Id = quoteIdToMakeTrue;
	quotesToUpdate.add(quotePrimary);
	update quotesToUpdate;
	return 'OK';
}

@AuraEnabled
public static void setProposalForQuote(String quoteId, String trueOrFalse) {
	Quote quoteToUpdate = new Quote();
	quoteToUpdate.Id = quoteId;
	quoteToUpdate.Include_In_Proposal__c = Boolean.valueOf(trueOrFalse);

	update quoteToUpdate;
}

public class salesRep {
public String id;
public String name;
public String osid;
}

@AuraEnabled
public static String getSalesRepsFromReturnedOSID(String osidJSON) {
	Map<String, Object> jsonInputMap = (Map<String, Object>) JSON.deserializeUntyped(osidJSON);
	List<Object> osidObjects = (List<Object>) jsonInputMap.get('osidArray');
	List<String> osidStrings = new List<String>();

	for (Object obj : osidObjects) {
		osidStrings.add((String) obj);
	}

	List<SalesRep> sList = new List<SalesRep>();
	Boolean error=false;
	String ErrorMsg = null;

	try{

		List<Account> a = [select id, Originating_Site_ID__c from Account
		                   where originating_site_id__c IN : osidStrings
		                   and originating_site_id__c <> null];

		List<Id> accIds = new List<Id>();

		for (Account acc : a) {
			accIds.add(acc.Id);
		}

		List<Contact> cList = new List<Contact>();
		cList = [select name, AccountId
		         from Contact
		         where accountId IN : accIds
		         and role__c = 'Partner Sales Rep'
		];

		for (Contact c : cList) {
			SalesRep r = new SalesRep();
			r.id = c.id;
			r.name = c.name;
			for (Account acc : a) {
				if (acc.Id == c.AccountId) {
					r.osid = acc.Originating_Site_ID__c;
					break;
				}
			}
			sList.add(r);
		}

	}
	catch (Exception e) {
		if(ErrorMsg == null)
			ErrorMsg = 'Exception in getSalesRepsFromReturnedOSID:' + string.valueOf(e) + '-' + e.getMessage() + '-' + e.getStackTraceString() + '-' + e.getLineNumber();
		error=true;
		throw new AuraHandledException(ErrorMsg);
	}
	if (error)
		return null;
	else
		return JSON.serialize(sList);
}

//query opportunity,quote options and quote line items based on opportunity Id
@AuraEnabled
public static quoteOpportunityWrapper QueryQuoteOpportunity(String oppId) {

	quoteOpportunityWrapper quoteWrapper = new quoteOpportunityWrapper();

	//query opportunity
	quoteWrapper.newOpp = [
		Select
		Id,Application_Number__c , Display_Quote_Number__c,Quote_Count__c, Opportunity_Number__c,Nickname__c,AccountId,CloseDate,StageName,Sub_Stage__c, Comments__c,
		ForecastCategoryName,Amount,CurrencyIsoCode, Location__c, Account.Name
		FROM Opportunity
		WHERE Id = : oppId
	];
	system.debug('query opp:' + quoteWrapper.newOpp);

	//query the quote list and all related quote line items
	Map <Id, Quote> quotes = new Map<Id, Quote>([
							    SELECT Id,Option_Number__c,Rate_Type__c,Rate_Type_Id__c, Term__c, Comments__c, Interest__c, Total_Payment__c, Is_Primary__c, Amount__c, Include_In_Proposal__c, Asset_Type__c, Current_Credit_App_Selection__c,
							    Lease_Type__c,Payment_Frequency__c,Advance_Payments__c,OpportunityId,Name,Partner_Sales_Rep__c, Partner_Sales_Rep__r.Name, Program__c,Program_ID__c, Location_ID__c, Residual__c
							    FROM Quote
							    WHERE OpportunityId = : oppId
	                                            ]);
	List <Quote_Line__c> quoteLineItems = [
		SELECT Id, Quote__c,Make__c,Make_Id__c,Asset_Type_ITA_Class__c, Asset_Type_ITA_Class_Id__c,Model__c, Model_Id__c, Mast_Type__c, Related_Asset__c, Equipment_Type__c, Payment_Amount__c, MSRP__c,
		Base_Unit_Sales_Price__c,Number_of_Units__c,Annual_Hours__c,Operating_Environment__c,Battery_Included__c, Subsidy__c, Subsidy_ID__c, Booked_Residual_Amount__c, Total_Sales_Price_Base__c
		FROM Quote_Line__c
		WHERE Quote__c IN : quotes.keySet()
	];
	List<Quote> selectQuotes = [SELECT Id, Option_Number__c FROM Quote WHERE OpportunityId = : oppId];
	List<quoteOpportunityLineItem> quoteOpportunityLineItems = new List<quoteOpportunityLineItem>();

	system.debug('query quote num:' + selectQuotes.size());
	system.debug('query quote:' + quotes);
	system.debug('query quoteLineItems:' + quoteLineItems);

	If ((selectQuotes.size() > 0) && (quoteLineItems.size() > 0)) {
		//Create a map to order quote and quote line
		Map<Id, List<Quote_Line__c> > quoteLinesByQuoteIdMap = new Map<Id, List<Quote_Line__c> >();
		for (Quote_Line__c ql : quoteLineItems) {
			if (quoteLinesByQuoteIdMap.get(ql.Quote__c) != null) {
				quoteLinesByQuoteIdMap.get(ql.Quote__c).add(ql);
			} else {
				quoteLinesByQuoteIdMap.put(ql.Quote__c, new List<Quote_Line__c> {
						ql
					});
			}
		}
		//traverse through all quote line items and assign to the right quote based on quote Id
		for (Id id : quoteLinesByQuoteIdMap.keySet()) {
			quoteOpportunityLineItems.add(new quoteOpportunityLineItem(quotes.get(id), quoteLinesByQuoteIdMap.get(id)));
		}
		System.debug('quoteLinesByQuoteIdMapSize:' + quoteLinesByQuoteIdMap.keySet().size());
	} else if ((selectQuotes.size() > 0) && (quoteLineItems.size() == 0)) {
		for (quote q : selectQuotes) {
			quoteOpportunityLineItems.add(new quoteOpportunityLineItem(q));
		}
	}

	//Send back the opportunity, and a custom object that is a quote and a list of quote items.
	quoteWrapper.quoteOpportunityLineItems = quoteOpportunityLineItems;
	return quoteWrapper;
}

@AuraEnabled
public static quoteOpportunityWrapper QueryQuoteOpportunityTemp(String oppId) {

	quoteOpportunityWrapper quoteWrapper = new quoteOpportunityWrapper();

	//query opportunity
	quoteWrapper.newOpp = [
		Select
		Id,Opportunity_Number__c,Nickname__c,AccountId,CloseDate,StageName,Sub_Stage__c, Comments__c,
		ForecastCategoryName,Amount,CurrencyIsoCode, Location__c, Account.Name
		FROM Opportunity
		WHERE Id = : oppId
	];
	system.debug('query opp:' + quoteWrapper.newOpp);

	//query the quote list and all related quote line items
	Map <Id, Quote> quotes = new Map<Id, Quote>([
							    SELECT Id,Option_Number__c,Rate_Type__c,Rate_Type_Id__c, Term__c, Comments__c, Interest__c, Total_Payment__c, Is_Primary__c, Amount__c, Include_In_Proposal__c, Asset_Type__c, Current_Credit_App_Selection__c,
							    Lease_Type__c,Payment_Frequency__c,Advance_Payments__c,OpportunityId,Name,Partner_Sales_Rep__c, Partner_Sales_Rep__r.Name, Program__c,Program_ID__c, Location_ID__c, Residual__c
							    FROM Quote
							    WHERE OpportunityId = : oppId
							                          and Is_Primary__c = true
	                                            ]);
	List <Quote_Line__c> quoteLineItems = [
		SELECT Id, Quote__c,Make__c,Make_Id__c,Asset_Type_ITA_Class__c, Asset_Type_ITA_Class_Id__c,Model__c, Model_Id__c, Mast_Type__c, Related_Asset__c, Equipment_Type__c, Payment_Amount__c, MSRP__c,
		Base_Unit_Sales_Price__c,Number_of_Units__c,Annual_Hours__c,Operating_Environment__c,Battery_Included__c, Subsidy__c, Subsidy_ID__c, Booked_Residual_Amount__c, Total_Sales_Price_Base__c
		FROM Quote_Line__c
		WHERE Quote__c IN : quotes.keySet()
	];
	List<Quote> selectQuotes = [SELECT Id, Option_Number__c FROM Quote WHERE OpportunityId = : oppId];
	List<quoteOpportunityLineItem> quoteOpportunityLineItems = new List<quoteOpportunityLineItem>();

	system.debug('query quote num:' + selectQuotes.size());
	system.debug('query quote:' + quotes);
	system.debug('query quoteLineItems:' + quoteLineItems);

	If ((selectQuotes.size() > 0) && (quoteLineItems.size() > 0)) {
		//Create a map to order quote and quote line
		Map<Id, List<Quote_Line__c> > quoteLinesByQuoteIdMap = new Map<Id, List<Quote_Line__c> >();
		for (Quote_Line__c ql : quoteLineItems) {
			if (quoteLinesByQuoteIdMap.get(ql.Quote__c) != null) {
				quoteLinesByQuoteIdMap.get(ql.Quote__c).add(ql);
			} else {
				quoteLinesByQuoteIdMap.put(ql.Quote__c, new List<Quote_Line__c> {
						ql
					});
			}
		}
		//traverse through all quote line items and assign to the right quote based on quote Id
		for (Id id : quoteLinesByQuoteIdMap.keySet()) {
			quoteOpportunityLineItems.add(new quoteOpportunityLineItem(quotes.get(id), quoteLinesByQuoteIdMap.get(id)));
		}
		System.debug('quoteLinesByQuoteIdMapSize:' + quoteLinesByQuoteIdMap.keySet().size());
	} else if ((selectQuotes.size() > 0) && (quoteLineItems.size() == 0)) {
		for (quote q : selectQuotes) {
			quoteOpportunityLineItems.add(new quoteOpportunityLineItem(q));
		}
	}

	//Send back the opportunity, and a custom object that is a quote and a list of quote items.
	quoteWrapper.quoteOpportunityLineItems = quoteOpportunityLineItems;
	return quoteWrapper;
}
}