/**
 * Class implements REST webservice for getting information about offers
 * Example: https://host/services/apexrest/offer/a0w02000000QbwHAAS
 * 
 * Version 1.0 @author Alexander Kondral @date 2020-12-15 
 * Version 1.1 @author Elena Sokolova @date 2021-05-21  
 * Version 1.2 @author Neha Tyagi @date 2021-07-13 (Insurance wrapper) 
 * Version 1.3 @author Neha Tyagi @date 2021-08-24 (Insurance/Residual Group) 
 */
@RestResource(urlMapping='/offer/*')
global with sharing class OfferWebService {
    
    /**
    * Method is a custom REST API call.
    * It’s annotated with @HttpGet and is invoked for a GET request.
    * Sets blob response (contains Offer data)
    */
    @HttpGet
    global static void getOfferById() {
        // Get access to the request
        RestRequest request = RestContext.request;
        // Represents an object used to pass data from an Apex RESTful Web service method to an HTTP response
        RestResponse response = RestContext.response;
        Id applicableOfferId;
        OfferWrapper offerWrapper;
        String jsonString;
        try {
            // get the applicable offer Id from the end of the URL
            applicableOfferId = (Id) request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        } catch (Exception ex) {
            response.statusCode = 500;
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(ex, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, null, true); 
            return;
        }
        // check the applicable offer Id, get offer info and set response body
        if (String.isNotEmpty(applicableOfferId) ){//&& applicableOfferId.getSobjectType() == Schema.Applicable_Offer__c.sObjectType) {
            
            List<Applicable_Offer__c> applicableOffersList = new WoSSelector().getApplicableOffers(applicableOfferId);
            if (applicableOffersList.isEmpty()) {
                response.statusCode = 404;
                return;
            }
            
            try {
                offerWrapper = new OfferWrapper(applicableOffersList[0]);
                Boolean suppressApexObjectNulls = true;
                jsonString = JSON.serialize(offerWrapper,suppressApexObjectNulls);
            } catch (Exception ex) {
                response.statusCode = 500;
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(ex, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, applicableOfferId, true); 
                return;
            }
            if (String.isNotEmpty(jsonString)) {
                jsonString = jsonString.replace('default_s', 'default').replace('group_s', 'group');
                response.addHeader('Content-Type', 'application/json');
                // set reponse body
                response.responseBody = Blob.valueOf(jsonString);
                response.statusCode = 200;
                return;
            }
        }
        response.statusCode = 404;
    }
    
    /**
    * Wrapper class for response body
    */
    global class OfferWrapper {
        global Id id;
        global String name;
        global Date validFrom;
        global Date validUntil;
        global NetDepositWrapper netDeposit;
        global List<String> paymentFrequencies;
        global List<String> paymentTimings;
        global List<RateWrapper> rates;
        global List<PaymentProfileWrapper> paymentProfiles;
        global List<AssetWrapper> assets;
        global List<Cashflow> cashflows;
        
        /**
        * Constructor gets and sets all value for current wrapper class with id used for response body
        */
        global OfferWrapper(Applicable_Offer__c applicableOffer) {
            this.id = applicableOffer.Offer__r.Id;
            this.name = applicableOffer.Offer__r.Name;
            this.validFrom = applicableOffer.Offer__r.Valid_From__c;
            this.validUntil = applicableOffer.Offer__r.Valid_Until__c;
            
            Program__c programDetails = new WoSSelector().getProgramDetails(applicableOffer.Offer__r.Program__c);
          	this.netDeposit = new NetDepositWrapper(programDetails.Allowed_Minimum_Deposit__c,programDetails.Allowed_Maximum_Deposit__c,'finance-amount','finance-amount','finance-amount', new Downpayment());
            
            String paymentFrequencies = applicableOffer.Offer__r.Selectable_Payment_Frequency__c;
            if (String.isNotEmpty(paymentFrequencies)) {
                this.paymentFrequencies = paymentFrequencies.split(';');
            }
            String paymentTimings = applicableOffer.Offer__r.Selectable_Payment_Timing__c;
            if (String.isNotEmpty(paymentTimings)) {
                this.paymentTimings = paymentTimings.split(';');
            }
            List<Id> ratesIds = new List<Id>{
                applicableOffer.Offer__r.Base_Rate_Fixed__c,
                    applicableOffer.Offer__r.Base_Rate_Variable__c
                    };
                        populateRates(ratesIds);
            populateMarginMatrix(applicableOffer.Account__r.Margin_Matrix__c);
            
            this.paymentProfiles = new List<PaymentProfileWrapper>{new PaymentProfileWrapper()};
                
            Id assetProgramId = applicableOffer.Offer__r.Program__r.Asset_Program__c;
            List<Asset_Program_Detail__c> assetProgramDetails = new WoSSelector().getAssetProgramDetails(assetProgramId);
            this.assets = new List<AssetWrapper>();
            
            this.cashflows = new List<Cashflow>();
            
            for (Asset_Program_Detail__c assetProgramDetailItem : assetProgramDetails) {
                if (assetProgramDetailItem.Product__r.Family == Constants.MAINTENANCE_PRODUCT_TYPE) {
                    List<Group_s> groupsMaintenance = new List<Group_s>();
                    List<Lookup> lookups = new List<Lookup>();
                    lookups.add(
                        new Lookup(new Outputs(false, 1, 999999999, 1))
                    );
                    groupsMaintenance.add(new Group_s(
                        'maintenance', assetProgramDetailItem.Product__r.Name, 'lookup', 'upper', true, lookups
                    ));
                    this.cashflows.add(new Cashflow(groupsMaintenance));
                }
                this.assets.add(new AssetWrapper(assetProgramDetailItem.Product__c));
            }
            
            List<Group_s> groupsInsurance  = findProductsInsurance(assetProgramId);
            this.cashflows.add(new Cashflow(groupsInsurance));
            
            List<Group_s> groupsResidual = findProductsResidual(applicableOffer.id, assetProgramId);
            this.cashflows.add(new Cashflow(groupsResidual));
        }
        
        /*
        * Method gets Rates and Rate Line Items for for "rates"=>"lookups" object in the response
        * with type 'cost-of-funds'
        */
        private void populateRates(List<Id> ratesIds) {
            this.rates = new List<RateWrapper>();
            if (!ratesIds.isEmpty()) {
                List<Rate__c> ratesList = new WoSSelector().getRatesByIds(ratesIds);
                	this.rates.add(new OfferRateWrapper(ratesList));
                
            }
            
        }
        
        /**
        * Method gets Margin Matrix and Margin Matrix Items for "rates"=>"lookups" object in the response
        * with type 'margin'
        */     
        private void populateMarginMatrix(Id marginMatrixId) {
            if (String.isNotEmpty(marginMatrixId)) {
                List<Margin_Matrix__c> marginMatrices = new WoSSelector().getMarginMatrixById(marginMatrixId);
                for (Margin_Matrix__c marginMatrix : marginMatrices) {
                    this.rates.add(new OfferMarginWrapper(marginMatrix));
                }   
            }
        }
        
        /*
        *Name: findProductsInsurance
        *Purpose: To find the related product insurance of the applicable offer
        */
        private List<Group_s> findProductsInsurance(Id assetProgramId){

            List<Group_s> groupsInsurance = new List<Group_s>();
            List<Asset_Program_Detail__c> assetProgramDetailsList = new WoSSelector().getAssetProgramDetails(assetProgramId);  

            if (!assetProgramDetailsList.isEmpty()) {
                groupsInsurance.add(new Group_s(
                        'insurance',null, 'asset', null, null, null));
            }

            return groupsInsurance;
        }
        
        /*
        * Name: findProductsResidual
        * Purpose: To find the related product RV of the applicable offer
        */
        private List<Group_s> findProductsResidual(Id applicableOfferId,Id assetProgramId){

            List<Group_s> groupsResidual = new List<Group_s>();
            groupsResidual.add(new Group_s('residual',null, 'asset', null, null, null));
            return groupsResidual;
       
        }
    }
    
    /*
     * Wrapper Class for Net Deposit.(Used for Downpayment)
     */
    global class NetDepositWrapper {
        global Decimal min;
        global Decimal max;
        global String minPercentageOf;
		global String maxPercentageOf;
        global String defaultPercentageOf;
        global DownPayment downPayment;
        global NetDepositWrapper(Decimal min,Decimal max,String minPercentageOf,String maxPercentageOf,String defaultPercentageOf,DownPayment downPayment){
            this.min = min;
            this.max = max;
			this.minPercentageOf = minPercentageOf;
			this.maxPercentageOf = maxPercentageOf;
            this.defaultPercentageOf = defaultPercentageOf;
            this.downPayment = downPayment;
        }
    }
    
    global class DownPayment{
        global Decimal min;
        global Decimal max;
        global String minPercentageOf;
		global String maxPercentageOf;
        global String defaultPercentageOf;
    }
    
     global virtual class RateWrapper {
        global Id id;
        global String name;
        global String rateType;
        global String compoundingFrequency;
    }
    global virtual class OfferRateWrapper extends RateWrapper {
        global List<RateLineItemWrapper> lookups;
        private List<RateLineItemWrapper> lookup;
        global OfferRateWrapper(List<Rate__c> rateList) {
            this.id = rateList[0].Id;
            this.rateType = 'cost-of-funds'; //hardocoded as api team needs this value in the response
            this.compoundingFrequency = 'periodic'; //hardocoded as api team needs this value in the response
            this.lookups = new List<RateLineItemWrapper>();
            for(Rate__c rate : rateList){
                  for (Rate_Line_Item__c lineItem : rate.Rate_Line_Items__r) {
                    if (rate.Rate_Type__c == Constants.VARIABLE_RATE_TYPE ) {
                        this.lookups.add(new VariableRateLineItemWrapper(lineItem, rate));
                    } else {
                        this.lookups.add(new FixedRateLineItemWrapper(lineItem, rate));
                    }
                    
                }  
            }  
        }
    }
    
    
    global virtual class OfferMarginWrapper extends RateWrapper {
        global List<MarginLineItemWrapper> lookups;
        
        global OfferMarginWrapper(Margin_Matrix__c marginMatrix) {
            this.id = marginMatrix.Id;
            this.name = marginMatrix.Name;
            this.rateType = 'margin'; //hardocoded as api team needs this value in the response
            this.compoundingFrequency = 'periodic'; //hardocoded as api team needs this value in the response
            this.lookups = new List<MarginLineItemWrapper>();
            for (Margin_Matrix_Item__c lineItem : marginMatrix.Margin_Matrix_Items__r) {
                this.lookups.add(new MarginLineItemWrapper(lineItem));
            }
        }
    }
    global abstract class RateLineItemWrapper {
        
    }

    global class FixedRateLineItemWrapper extends RateLineItemWrapper {
        global FixedRateInputWrapper inputs = new FixedRateInputWrapper();
        global Map<String, Decimal> outputs = new Map<String, Decimal>();
        
        global FixedRateLineItemWrapper(Rate_Line_Item__c lineItem, Rate__c parentRate) {
            Decimal rateValue = lineItem.Rate_Value__c + parentRate.Cost_Of_Funds__c;
            this.outputs.put('default', rateValue);
            this.inputs.numberOfMonths = lineItem.Term__r.Term_Value__c;
            this.inputs.variable = false;
        }
    }
    global class VariableRateLineItemWrapper extends RateLineItemWrapper {
        global VariableRateInputWrapper inputs = new VariableRateInputWrapper();
        global Map<String, Decimal> outputs = new Map<String, Decimal>();
        
        global VariableRateLineItemWrapper(Rate_Line_Item__c lineItem, Rate__c parentRate) {
            Decimal rateValue = lineItem.Rate_Value__c + parentRate.Cost_Of_Funds__c;
            this.outputs.put('default', rateValue);
            this.inputs.paymentFrequency = lineItem.Term__r.Alias__c;
            this.inputs.variable = true;
        }
    }
    global class FixedRateInputWrapper {
        global Decimal numberOfMonths;
        global Boolean variable;
    }
    global class VariableRateInputWrapper {
        global String paymentFrequency;
        global Boolean variable;
    }
     
    global class MarginLineItemWrapper {
        global MarginInputWrapper inputs = new MarginInputWrapper();
        global Map<String, Decimal> outputs = new Map<String, Decimal>();
        
        global MarginLineItemWrapper(Margin_Matrix_Item__c lineItem) {
            this.inputs.numberOfMonths = lineItem.Term__r.Term_Value__c;
            this.inputs.financeAmount = lineItem.Financial_amount__c;
            this.outputs.put('discountRate', lineItem.Value__c);
        }
    }
    global class MarginInputWrapper {
        global Decimal financeAmount;
        global Decimal numberOfMonths;
    }
    global class PaymentProfileWrapper {
        global String id = 'id'; //hardocoded as api team needs this value in the response
        global String name = 'name'; //hardocoded as api team needs this value in the response
        global String profileType = 'number-of-months'; //hardocoded as api team needs this value in the response
        global String interpolation = 'interpolation'; //hardocoded as api team needs this value in the response
        global PaymentProfileInputWrapper inputs = new PaymentProfileInputWrapper();
        global PaymentProfileOutputWrapper outputs = new PaymentProfileOutputWrapper();
        global List<PaymentProfilePatternWrapper> paymentPattern = new List<PaymentProfilePatternWrapper>{new PaymentProfilePatternWrapper()};
            }
    global class PaymentProfileInputWrapper {
        global String paymentFrequency = 'monthly';  //hardocoded as api team needs this value in the response
        global Integer numberOfMonths = 10;  //hardocoded as api team needs this value in the response
    }
    global class PaymentProfileOutputWrapper {
        global String default_s = '20'; //hardocoded as api team needs this value in the response
        global List<String> options = new List<String>{'option1'};
            }
    global class PaymentProfilePatternWrapper {
        global String month = 'january'; //hardocoded as api team needs this value in the response
        global Integer paymentNumber = 0;
        global Integer numberOfPayments = 0;
        global Integer notApplicableForMonthsAtStart = 0;
        global String paymentType = 'regular'; //hardocoded as api team needs this value in the response
        global Integer value = 0;
        global String valuePercentageOf = 'sale-price'; //hardocoded as api team needs this value in the response
    }
    global class AssetWrapper {
        global Id modelId;
        global AssetWrapper(Id modelId){
            this.modelId = modelId;
        }
    }
    global class Cashflow {
        global List<Group_s> group_s;
        
        global Cashflow(List<Group_s> group_s) {
            this.group_s = group_s;
        }
    }
    global class Group_s {
        global String cashflowType;
        global String id;
        global String source;
        global String interpolation;
        global Boolean excludeFromAPR;
        global List<Lookup> lookups;
        
        global Group_s(String cashflowType, String id, String source, String interpolation, Boolean excludeFromAPR, List<Lookup> lookups) {
            this.cashflowType = cashflowType;
            this.id = id;
            this.source = source;
            this.interpolation = interpolation;
            this.excludeFromAPR = excludeFromAPR;
            this.lookups = lookups;
        }
    }
    global class Lookup {
        global Outputs outputs;
        public Map<String, Decimal> inputs;
        global Lookup(Outputs outputs) {
            this.outputs = outputs;
        }
    }
    global class Outputs {
        global Boolean annual;
        global Double default_s;
        global Double max;
        global Double min;
        public string defaultPercentageOf; 
        
        
        global Outputs(Boolean annual, Double default_s, Double max, Double min) {
            this.annual = annual;
            this.default_s = default_s;
            this.max = max;
            this.min = min;
        }
    }
    public class AssetProgramDetailWrapper {
        public Asset_Program_Detail__c assetProgramDetail;
        public Id RVMatrixId;
        
        public AssetProgramDetailWrapper(Asset_Program_Detail__c assetProgramDetail, Id RVMatrixId) {
            this.assetProgramDetail = assetProgramDetail;
            this.RVMatrixId = RVMatrixId;            
        }
    }
    /**
    * Inner class-selector
    */
    public without sharing class WoSSelector {
        
        /**
        * Method gets Applicable Offer record by Id
        * 
        * @return List<Applicable_Offer__c> contains one record with Applicable Offer info
        */
        private List<Applicable_Offer__c> getApplicableOffers(Id id) {
            return [
                SELECT  Offer__r.Id, Offer__r.Name, Offer__r.Valid_From__c, Offer__r.Valid_Until__c,
                Offer__r.Selectable_Payment_Frequency__c, Offer__r.Selectable_Payment_Timing__c,
                Account__r.Margin_Matrix__c, Offer__r.Base_Rate_Fixed__c, Offer__r.Base_Rate_Variable__c,
                Offer__r.Program__r.Asset_Program__c,Account__c,Offer__r.Program__c
                FROM    Applicable_Offer__c
                WHERE   Id = :id
                LIMIT   1
            ];
        }
        
        private Program__c getProgramDetails(Id programId){
            return [
                SELECT  Id, Allowed_Maximum_Deposit__c, Allowed_Minimum_Deposit__c
                FROM    Program__c 
                WHERE   Id =: programId 
				LIMIT 1
            ];
        }
        
        private List<Rate__c> getRatesByIds(List<Id> ratesIds) {
            return [
                SELECT  Id, Name, CurrencyIsoCode, Rate_Type__c,
                Cost_Of_Funds__c, Region__r.Name, (
                    SELECT  Id, CurrencyIsoCode, Term__r.Alias__c,
                    Term__r.Term_Value__c, Term__r.Term_Dimension__c, Rate_Value__c
                    FROM    Rate_Line_Items__r order by Term__r.Term_Value__c asc
                )
                FROM    Rate__c
                WHERE   Id IN :ratesIds
            ];
        }
        private List<Margin_Matrix__c> getMarginMatrixById(Id marginMatrixId) {
            return [
                SELECT  Id, Name, CurrencyIsoCode, (
                    SELECT  Id, Name, Term__r.Alias__c,
                    Term__r.Term_Value__c, Term__r.Term_Dimension__c,
                    Value__c, Financial_amount__c
                    FROM    Margin_Matrix_Items__r 
                    ORDER BY Term__r.Term_Value__c, Financial_amount__c asc nulls last 
                )
                FROM    Margin_Matrix__c
                WHERE   Id = :marginMatrixId
                LIMIT   1
            ];
        }
        /**
        * Name: getAssetProgramDetails
        * Purpose: SOQL to get asset program details
        */
        private List<Asset_Program_Detail__c> getAssetProgramDetails(id assetProgramId){
            return [
                SELECT  Id,Product__c,
                Product__r.name,Insurance__c,
                Product__r.Family
                FROM    Asset_Program_Detail__c 
                WHERE   Asset_Program__c=: assetProgramId 
            ];
        }
    }
}