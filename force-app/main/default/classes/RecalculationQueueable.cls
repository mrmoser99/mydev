/*****************************************************************************************
Name: RecalculationQueueable 
===============================================================================================
Purpose: Queable class to send automatically for calculation api, submit app, credit assesment when 
approved with condition(recal).
Why Queable- because we have to enqueue multiple callouts one after another and also perform DML.
A benefit of using the Queueable interface methods is that some governor limits are 
higher than for synchronous Apex, such as heap size limits.
================================================================================================
================================================================================================
History
-------
* Version 1.0@author Anujit @date 2021-07-15 US#505177
* Version 1.2@author Neha Tyagi @date 2021-12-20 US#674023, US#505177
******************************************************************************************/

public class RecalculationQueueable implements Queueable,Database.AllowsCallouts {

    public List<Id> quoteIds; 
    public string calloutName;
    static Map<string,string> prodNameToItadProdNameMap = new Map<string,string>();
    
    public RecalculationQueueable(List<Id> quoteIds, string calloutName){
        this.quoteIds = quoteIds;  
        this.calloutName = calloutName;
    }
    
    public void execute(QueueableContext context) {
        if(calloutName == Constants.CALCULATION && this.quoteIds.size() > 0){
            createRecalculationParam(this.quoteIds[0]);
        }else if(calloutName == Constants.SUBMITAPPLICATION){
            createSubmitAppParamForRecal(this.quoteIds[0]);
        }else if(calloutName == Constants.CREDITASSESSMENT){
            createCreditAssessmentForRecal(this.quoteIds[0]);
        }
    }
       
   	/*
   	*Name: createRecalculationParam
   	*Purpose: to send for calculation api callout
   	*/
    private static void createRecalculationParam(id quoteId) {
        double totalItadFees = 0.0;
        Map<string,integer> productNameToQuantityMap = new Map<string,integer>();   
        List<QuoteLineItem> qliList = new QuoteSetupController.WosSelector().getQuoteLineDetails(string.valueOf(quoteId));
        
        List<CalculationAPIHelper.CalculationInputAssetWrapper> assets = new List<CalculationAPIHelper.CalculationInputAssetWrapper>();
        List<CalculationAPIHelper.CalculationInputAssetWrapper> maintenance = new List<CalculationAPIHelper.CalculationInputAssetWrapper>();

        for(QuoteLineItem eachQli : qliList){
            if(eachQli.Product2.family != label.Maintenance && eachQli.Product2.family != label.Deal_Page_ITAD){
                CalculationAPIHelper.CalculationInputAssetWrapper assetWrapper = new CalculationAPIHelper.CalculationInputAssetWrapper();
                assetWrapper.productName = eachQli.Product2.name;
                assetWrapper.quantity = eachQli.Quantity;
                assetWrapper.price = eachQli.UnitPrice;
                assetWrapper.residualValueAmount = eachQli.Residual_Value_Rate__c != null ? String.valueOf(eachQli.Residual_Value_Rate__c) : null;
                assetWrapper.insuranceAmount = eachQli.Insurance_Rate__c != null ? String.valueOf(eachQli.Insurance_Rate__c) : null;
                assets.add(assetWrapper);
                productNameToQuantityMap.put(eachQli.Product2.name.toLowerCase(),(Integer) eachQli.Quantity);
            } 
            else if(eachQli.Product2.family == label.Maintenance){
                CalculationAPIHelper.CalculationInputAssetWrapper maintenanceWrapper = new CalculationAPIHelper.CalculationInputAssetWrapper();
                maintenanceWrapper.productName = eachQli.Product2.name;
                maintenanceWrapper.quantity = eachQli.Quantity;
                maintenanceWrapper.price = eachQli.UnitPrice;
                maintenance.add(maintenanceWrapper);
            }
        }

        if(qliList.size() > 0){
            CalculationAPIHelper.CalculationInputWrapper calInputWrapper = new CalculationAPIHelper.CalculationInputWrapper();
            calInputWrapper.calculate = 'payments';
            calInputWrapper.numberOfMonths = qliList[0]?.Quote.Value_term__c !=null ? Integer.valueof(qliList[0]?.Quote.Value_term__c): Integer.valueof(qliList[0]?.Quote.Term__c) ;
            calInputWrapper.paymentFrequency = qliList[0]?.Quote.Frequency__c;
            calInputWrapper.paymentTiming = qliList[0]?.Quote.Payment_Timing__c;
            calInputWrapper.programId = qliList[0]?.Quote.Applicable_Offers__r.Offer__r.Program__c;
            calInputWrapper.interest = qliList[0]?.Quote.Interest__c;
            calInputWrapper.downPayment = qliList[0]?.Quote.Value_downpayment__c; 
            calInputWrapper.financialProductId = qliList[0]?.Quote.Applicable_Offers__c;
            calInputWrapper.assets = assets;
            calInputWrapper.maintenance = maintenance;
            calInputWrapper.isPurchaseOptionApplicable = true;
            calInputWrapper.isInsuranceApplicable = true;
            
            
            List<CalculationRequestBodyWrapper.FeesWrapperClass> itadFees = ((CalculationRequestBodyWrapper.findItadApplicableInOffer(qliList[0]?.Quote.Applicable_Offers__r.Offer__r.Program__c,qliList[0]?.Quote.Applicable_Offers__c,productNameToQuantityMap,qliList[0]?.Quote.ITAD_Category__c)) != null 
                                                                           ? (CalculationRequestBodyWrapper.findItadApplicableInOffer(qliList[0]?.Quote.Applicable_Offers__r.Offer__r.Program__c,qliList[0]?.Quote.Applicable_Offers__c,productNameToQuantityMap,qliList[0]?.Quote.ITAD_Category__c)) 
                                                                           : new List<CalculationRequestBodyWrapper.FeesWrapperClass>());
            //find total ITAD amount     
        	for(CalculationRequestBodyWrapper.FeesWrapperClass eachItad : itadFees){
            	totalItadFees += eachItad.amount; //adding total itad fee
            }  
            Map<string,double> itadProdNameToPriceMap = getItadCalculation(itadFees,calInputWrapper.numberOfMonths,qliList[0]?.Quote.Applicable_Offers__r.Offer__r.Program__r.Asset_Program__c);
            
            String calculationParamSerialize = JSON.serialize(calInputWrapper);
          
            CalculationAPIHelper.CalculationOutputWrapper calculationResponse = RESTCalloutHelper.sendCalloutToCalculationApi(calculationParamSerialize, false);
           
            doUpdateQuote(quoteId,calculationResponse,qliList[0],totalItadFees); //at the time of recalculation
            doUpdateQuoteLineItem(qliList,calculationResponse,itadProdNameToPriceMap);
        }      
    }
    
    /*
    *Name: doUpdateQuote
    *Purpose: update the quote with the calcualtion api response like finance amount, rental amount
    */
    private static void doUpdateQuote(id quoteId, CalculationAPIHelper.CalculationOutputWrapper calculationResponse,QuoteLineItem qliRecord,double totalItadFees){
        
        try{    
            if(quoteId != null && calculationResponse.financeAmount != null && calculationResponse.rentalAmount != null){
                update new Quote(id=quoteId,Financed_Amount__c=calculationResponse.financeAmount,
                                 Rental_Amount__c=totalItadFees != 0.0 && calculationResponse.term != 0
                                 				? (totalItadFees/calculationResponse.term + calculationResponse.rentalAmount) 
                                 				: calculationResponse.rentalAmount,
                                 term__c= !String.isEmpty(qliRecord?.quote.Value_term__c) 
                                 				? qliRecord?.quote.Value_term__c 
                                 				: String.valueof(calculationResponse.term),
                                 Downpayment__c=qliRecord?.quote.Value_downpayment__c);
            } 
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, quoteId, true);      
        }       
    } 
    
    /*
    *Name: doUpdateQuote
    *Purpose: update the quote with the calcualtion api response like finance amount, rental amount
    */
    private static void doUpdateQuoteLineItem(List<QuoteLineItem> qliList, CalculationAPIHelper.CalculationOutputWrapper calculationResponse,Map<string,double> itadProdNameToPriceMap){
      
      map<String,CalculationAPIHelper.AssetDataWrapper> assetsMap = new map<String,CalculationAPIHelper.AssetDataWrapper>();
      map<String,CalculationAPIHelper.MaintenanceDataWrapper> maintenanceMap = new map<String,CalculationAPIHelper.MaintenanceDataWrapper>();
      map<String,CalculationAPIHelper.AssetCalculationWrapper> assetCalculationsMap = new map<String,CalculationAPIHelper.AssetCalculationWrapper>();
      String prodname;
      Integer quantity;
      List<CalculationAPIHelper.AssetDataWrapper> assets = calculationResponse?.assets;
      List<CalculationAPIHelper.MaintenanceDataWrapper> maintenance = calculationResponse?.maintenance;
      List<CalculationAPIHelper.AssetCalculationWrapper> assetCalculations = calculationResponse?.assetCalculations;
      
      for(CalculationAPIHelper.AssetDataWrapper eachAssets : assets)
          assetsMap.put((eachAssets.productName).toLowerCase()+'-'+eachAssets.quantity,eachAssets);
      for(CalculationAPIHelper.MaintenanceDataWrapper eachMaintenance : maintenance)
          maintenanceMap.put((eachMaintenance.id).toLowerCase(),eachMaintenance);
      for(CalculationAPIHelper.AssetCalculationWrapper eachAssetCalculations : assetCalculations)
          assetCalculationsMap.put((eachAssetCalculations.productName).toLowerCase()+'-'+eachAssetCalculations.quantity,eachAssetCalculations);
        
      List<QuoteLineItem> updateQliList = new List<QuoteLineItem>();
        for(QuoteLineItem eachQli : qliList){
            prodname = (eachQli.Product2.name).toLowerCase();
            quantity= Integer.valueof(eachQli.Quantity);
            
            if(eachQli.Product2.family != label.Maintenance && assetCalculationsMap.containskey(prodname+'-'+quantity) && assetsMap.containskey(prodname+'-'+quantity)){
                eachQli.Financed_Amount__c = assetCalculationsMap.get(prodname+'-'+quantity).financeAmount;
                eachQli.Periodic_Amount__c = assetCalculationsMap.get(prodname+'-'+quantity).periodicAmount;
                eachQli.Insurance_Rate__c = assetsMap.get(prodname+'-'+quantity).insuranceAmount;
                
                if(!(eachQli.Quote.Applicable_Offers__r.Offer__r.RV_Type__c == Constants.PURCHASE_OPTION_RV && !eachQli.Quote.Applied_Purchase_Option__c )){
                    eachQli.Residual_Value_Rate__c = assetsMap.get(prodname+'-'+quantity).residualValue;
                }
                    
                
                    
            }
            else if(eachQli.Product2.family == label.Maintenance){
                 eachQli.Maintenance_Amount__c = maintenanceMap.get(prodname).amount;
                 eachQli.Periodic_Amount__c = maintenanceMap.get(prodname).periodicAmount; 
            }
            
            string itadProductName = (!prodNameToItadProdNameMap.isEmpty() && prodNameToItadProdNameMap.containskey(prodname) && (prodNameToItadProdNameMap.get(prodname) != null)) 
                ? prodNameToItadProdNameMap.get(prodname) : ''; 
          
            eachQli.ITAD_Fee__c = (itadProdNameToPriceMap.containskey(itadProductName.toLowerCase()) && itadProdNameToPriceMap.get(itadProductName.toLowerCase()) != null)
                                                    ? ((integer.valueof(eachQli.Quantity) * itadProdNameToPriceMap.get(itadProductName.toLowerCase())).round()) 
                                                    : 0;
            updateQliList.add(eachQli);
        }  
        update updateQliList;
        
        if(!Test.isRunningTest()){
            ID jobID = System.enqueueJob(new RecalculationQueueable(new list<id>{qliList[0].QuoteId},'submitApplication'));
            
        }
    }
    
    /*
    *Name: getItadCalculation
    *Purpose: to calculate the ITAD value
    */
    private static Map<string,double> getItadCalculation(List<CalculationRequestBodyWrapper.FeesWrapperClass> itadFees, Integer term, Id assetProgramId){
       
       Map<string,double> itadProdNameToPriceMap = new Map<string,double>();
        
       list<Asset_Program_Detail__c> assetProgDetailList = new AssetModelWebService.WosSelector().getAssetProgramDetails(assetProgramId);
       for(Asset_Program_Detail__c eachDetail : assetProgDetailList){
            if(eachDetail.ITAD_Product__c != NULL){ 
                prodNameToItadProdNameMap.put((eachDetail.Product__r.Name).toLowerCase(),eachDetail.ITAD_Product__r.Name);
            }               
        } 
        
       for(CalculationRequestBodyWrapper.FeesWrapperClass eachItad : itadFees){
            double periodicAmount = eachItad.amount/term; //find the periodic amount
            double eachItadProductPrice = periodicAmount/eachItad.quantity; //find each itad product price
            itadProdNameToPriceMap.put(eachItad.id,eachItadProductPrice);
        }
        
        return itadProdNameToPriceMap;
    }
    /*
    *Name: createSubmitAppParamForRecal
    *Purpose: to send for submit application api callout
    */
    private static void createSubmitAppParamForRecal(id quoteId){
        
        list<QuoteSetupController.ProdtoquoteCls> prodtoQuoteObjList = new list<QuoteSetupController.ProdtoquoteCls>();
        List<QuoteSetupController.ServicertoquoteCls> servicesInfoList = new list<QuoteSetupController.ServicertoquoteCls>();
        
        List<QuoteLineItem> qliList = new QuoteSetupController.WosSelector().getQuoteLineDetails(string.valueOf(quoteId));
        
        for(QuoteLineItem eachLine : qliList){
            if (eachLine.Product2.Family != Constants.ITAD_PRODUCT_TYPE && eachLine.Product2.Family != Constants.MAINTENANCE_PRODUCT_TYPE) {
                QuoteSetupController.ProdtoquoteCls prodtoQuoteObj = new QuoteSetupController.ProdtoquoteCls(
                                                                            String.valueof(eachLine.Quantity),
                                                                            String.valueof(eachLine.UnitPrice),
                                                                            String.valueof(eachLine.TotalPrice),
                                                                            eachLine.Product2.name,
                                                                            eachLine.Description,
                                                                            eachLine.Product2.Family
                                                                      );
                prodtoQuoteObjList.add(prodtoQuoteObj);
            }else if(eachLine.Product2.Family == Constants.MAINTENANCE_PRODUCT_TYPE){
                QuoteSetupController.ServicertoquoteCls serviceInfo = new QuoteSetupController.ServicertoquoteCls(
                                                                            String.valueof(eachLine.Quantity),
                                                                            String.valueof(eachLine.UnitPrice),
                                                                            String.valueof(eachLine.TotalPrice),
                                                                            eachLine.Product2.name
                                                                        );
                servicesInfoList.add(serviceInfo);
            }      
        }
        
        if(qliList.size() > 0){
            submitAppWrapperCls submitAppWrCls = new submitAppWrapperCls();
            submitAppWrCls.oppId = qliList[0].Quote.Opportunityid;
            submitAppWrCls.quoteId= qliList[0].Quoteid;
            submitAppWrCls.oppName = qliList[0].Quote.Opportunity.name;
            submitAppWrCls.oppOwner = qliList[0].Quote.Opportunity.Owner.Name;
            submitAppWrCls.programBU = qliList[0].Quote.Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name;
            submitAppWrCls.oppCreationDate = qliList[0].Quote.Opportunity.CreatedDate;
            submitAppWrCls.financialProductName = qliList[0].Quote.Applicable_Offers__r.name;
            submitAppWrCls.offerName = qliList[0].Quote.Applicable_Offers__r.Offer__r.name;
            submitAppWrCls.oppCurrency = qliList[0].Quote.CurrencyIsoCode;
            submitAppWrCls.qouteTerm = qliList[0].Quote.Term__c;
            submitAppWrCls.paymentFrequency = qliList[0].Quote.Frequency__c;
            submitAppWrCls.advanceArrear = qliList[0].Quote.Payment_Timing__c;
            submitAppWrCls.oppFinancedAmount = string.valueof(qliList[0].Quote.Financed_Amount__c);
            submitAppWrCls.nominalInterestRate = string.valueof(qliList[0].Quote.Nominal_Interest_Rate__c);
            submitAppWrCls.productInfoList = prodtoQuoteObjList;
            submitAppWrCls.serviceInfoList = servicesInfoList;
            submitAppWrCls.customerExtId = qliList[0].Quote.Opportunity.End_User__r.External_Identifier__c;
            submitAppWrCls.customerId = qliList[0].Quote.Opportunity.End_User__c;
            submitAppWrCls.customerStreet = qliList[0].Quote.Opportunity.End_User__r.BillingStreet;
            submitAppWrCls.customerCity = qliList[0].Quote.Opportunity.End_User__r.BillingCity;
            submitAppWrCls.customerPostalCode = qliList[0].Quote.Opportunity.End_User__r.BillingPostalCode;
            submitAppWrCls.customerLegalName = qliList[0].Quote.Opportunity.End_User__r.Name;
            submitAppWrCls.partnerName = qliList[0].Quote.Opportunity.Owner.name;
            submitAppWrCls.partnerEmail = qliList[0].Quote.Opportunity.Owner.email;
            
            String submitAppParamSerialize = JSON.serialize(submitAppWrCls);
           
            string submitAppResponse = RESTCalloutHelper.makeSubmitAppRequest(submitAppParamSerialize, false);

            if(!Test.isRunningTest()){
                ID jobID = System.enqueueJob(new RecalculationQueueable(new list<id>{quoteId},'creditAssessment'));
                
            }
        
        }         
    }
    
    /*
    *Name: createCreditAssessmentForRecal
    *Purpose: to send for credit assessment api callout
    */
    private static void createCreditAssessmentForRecal(id quoteId){
        
        string creditAssessmentResponse = RESTCalloutHelper.makeCreditAssessmentRequest(quoteId, false);
    }
    
    
    public class submitAppWrapperCls{
        
        public string oppId;
        public string oppName;
        public string quoteId;
        public string oppOwner;
        public string programBU;
        public datetime oppCreationDate;
        public string financialProductName;
        public string offerName;
        public string oppCurrency;
        public string qouteTerm;
        public string paymentFrequency;
        public string advanceArrear;
        public string oppFinancedAmount;
        public string nominalInterestRate;
        public list<QuoteSetupController.ProdtoquoteCls> productInfoList;
        public list<QuoteSetupController.ServicertoquoteCls> serviceInfoList;
        public string customerExtId;
        public string customerId;
        public string customerStreet;
        public string customerCity;
        public string customerPostalCode;
        public string customerLegalName;
        public string partnerName;
        public string partnerEmail;
    
    }  
      
}