/**
 * Helper class for Calculation API.
 * 
 * Version 1.0 @author Neha Tyagi @date 2021-12-02
 */

public class CalculationAPIHelper {
    //public static double totalItadFees = 0.0;
    
    /*
    *Name: createCalloutParams
    *Purpose: to create callout Params for Calculation API.
     */
    public static Map<String, Object> createCalloutParams(CalculationInputWrapper wrapper) {
        Map<String, Object> params = new Map<String, Object>();
        //Map<string,integer> productNameToQuantityMap = new Map<string,integer>();
        //double totalItadFees = 0.0;
     
        params.put('paymentOrFinance', wrapper.calculate);
        params.put('paymentFrequency', wrapper.paymentFrequency.toLowerCase());
        params.put('paymentTiming', wrapper.paymentTiming);
        params.put('interest', wrapper.interest);
        if (wrapper.amount != null) {
            params.put('amount', wrapper.amount);
        }

        params.put('downPayment', string.isNotblank(wrapper.downPayment) ? wrapper.downPayment : '0.0');
        
        params.put('terms', wrapper.numberOfMonths);
        
        List<Map<String, Object>> assets = new List<Map<String, Object>>();
        Program__c program;
        
        if (wrapper.assets!=null) {
            for (CalculationInputAssetWrapper assetWrapper : wrapper.assets) {
                Map<String, Object> asset = new Map<String, Object>();
                asset.put('modelName', assetWrapper.productName);
                asset.put('quantity', assetWrapper.quantity.intValue());
                asset.put('salePrice', assetWrapper.price);
               
                //Send updated RV and Insurance to lacs and check response its with in boundries or not                
                // send RV only for Purchase option is yes                
                if( wrapper.isPurchaseOptionApplicable  &&  !String.isEmpty(assetWrapper.residualValueAmount) ){
                    asset.put('residualValue', Double.valueOf(assetWrapper.residualValueAmount ));                   
                }
                // send Insurance 
                if( wrapper.isInsuranceApplicable &&  !String.isEmpty(assetWrapper.insuranceAmount)){
                    asset.put('insuranceAmt', Double.valueOf(assetWrapper.insuranceAmount  ));  
                    // asset.put('assetId', assetWrapper.rvValue  );  
                }
                
                assets.add(asset);
                string prodName = (String) asset.get('modelName');
                //productNameToQuantityMap.put(prodName.toLowerCase(),(Integer) asset.get('quantity'));
            }
        }else {
            program = new WoSSelector().getProgramById(wrapper.programId);
            Asset_Program_Detail__c assetProgramDetail = new WoSSelector().getAssetDetailsForQuickCalProduct(program.Asset_Program__c,TRUE);
            Map<String, Object> asset = new Map<String, Object>();
            asset.put('modelName', assetProgramDetail.Product__r.Name);
            asset.put('quantity', 1);
            if (wrapper.calculate == 'payments' && wrapper.amount != null) {
                asset.put('salePrice', wrapper.amount); // workaround to support: quick calculation (calculate: payments) scenario
            } else {
                asset.put('salePrice', 1);
                asset.put('residualValue', 0.0);
                asset.put('insuranceId', assetProgramDetail.id +''+ assetProgramDetail.Insurance__c);
            }
            assets.add(asset);
        }
        params.put('assets', assets);
        params.put('programId', wrapper.programId);
        params.put('financialproductId', wrapper.financialProductId);
        params.put('itadLevel', wrapper.itadLevel);
        //params.put('isPurchaseOption', wrapper.isPurchaseOption);
                
        List<Map<String, Object>> maintenanceList = new List<Map<String, Object>>();
       
        if (wrapper.maintenance!=null) {
            for (CalculationInputAssetWrapper maintenanceItem : wrapper.maintenance) {
              
                Map<String, Object> maintenance = new Map<String, Object>();
                maintenance.put('id', maintenanceItem.productName);
                maintenance.put('amount', maintenanceItem.price * (Integer) maintenanceItem.quantity * 12);
                maintenanceList.add(maintenance);
            }
            params.put('maintenance', maintenanceList); 
        }else if (wrapper.calculate != 'payments'){ // workaround to support: quick calculation (calculate: finance-amount) scenario
            Map<String, Object> maintenance = new Map<String, Object>();
            maintenance.put('id',new WoSSelector().getAssetDetailsForQuickCalProduct((program !=null ? program : new WoSSelector().getProgramById(wrapper.programId))
                                                                                      .Asset_Program__c,false).Product__r.Name);
            maintenance.put('amount', 1);
            maintenanceList.add(maintenance);
          	params.put('maintenance', maintenanceList); 
        }       
        return params;
    }
    
    /*
    *Name: getITADFees
    *Purpose: to calculate the ITAD Fess for products.
     */ 
    public static double getITADFees(CalculationInputWrapper wrapper) {
        
        Map<string,integer> productNameToQuantityMap = new Map<string,integer>();
        double totalItadFees = 0.0;
        
        if (wrapper.assets!=null) {
            for (CalculationInputAssetWrapper assetWrapper : wrapper.assets) {
                 string prodName = (String) assetWrapper.productName;
                productNameToQuantityMap.put(prodName.toLowerCase(),assetWrapper.quantity.intValue());
            }
        }
        
        //get ITAD calculation value
        List<CalculationRequestBodyWrapper.FeesWrapperClass> itadFees = ((CalculationRequestBodyWrapper.findItadApplicableInOffer((Id) wrapper.programId,(Id) wrapper.financialProductId, productNameToQuantityMap,(String) wrapper.itadLevel)) != null 
                                                                        ? (CalculationRequestBodyWrapper.findItadApplicableInOffer((Id) wrapper.programId,(Id)wrapper.financialProductId, productNameToQuantityMap,(String) wrapper.itadLevel)) 
                                                                        : new List<CalculationRequestBodyWrapper.FeesWrapperClass>());
        //find total ITAD amount     
        for(CalculationRequestBodyWrapper.FeesWrapperClass eachItad : itadFees){
            totalItadFees += eachItad.amount; //adding total itad fee
            
        }   
        
        return totalItadFees;
    }
    
    /*
    *Name: createHeaderParams
    *Purpose: to create header Params for Calculation API.
     */ 
    public static Map<String, String> createHeaderParams(CalculationInputWrapper wrapper) {
        
        Map<String, String> headerParams = new Map<String, String>();
        headerParams.put('programId', wrapper.financialProductId);
        headerParams.put('financialproductId', wrapper.financialProductId); 
        
        return headerParams;
    }
    
    /*
    *Name: createURLParams
    *Purpose: to create URL Params for Calculation API.
     */ 
     public static Map<String, String> createURLParams(CalculationInputWrapper wrapper) {
        
        Map<String, String> urlParams = new Map<String, String>();
        urlParams.put('calculation_options', 'assetCalculations');
        
        return urlParams;
    }
    
    
    /***
    Name: getCalcOutputWrapper
    Purpose: method processes CalculationResponseBodyWrapper response, creates and returns CalculationOutputWrapper
    **/
    public static CalculationAPIHelper.CalculationOutputWrapper getCalcOutputWrapper(CalculationResponseBodyWrapper response, CalculationAPIHelper.CalculationInputWrapper wrapper, Double totalItadFees) {
        CalculationAPIHelper.CalculationOutputWrapper wr = new CalculationAPIHelper.CalculationOutputWrapper();
        
        wr.financeAmount = response.financeCalculation.financeAmount; 
        //if itad fee exist then add itad fee dividing by terms, to rental amount else only rental amount
        wr.rentalAmount = totalItadFees != 0.0 && wrapper.numberOfMonths != 0 
                                            ? (totalItadFees/wrapper.numberOfMonths + response.consolidatedPayments[0].amount) 
                                            : response.consolidatedPayments[0].amount;
        wr.nominalInterestRate = response.financeCalculation.rates.nominalInterestRate;
        wr.calculate = response.financeInput.calculate;
        wr.paymentFrequency = response.financeInput.financeStructure.paymentFrequency;
        wr.term = response.financeInput.financeStructure.numberOfMonths;
        wr.numberOfPayments = response.financeInput.financeStructure.numberOfPayments;
        wr.futureValue = response.financeCalculation.futureValue;
        
        Double monthlyAmount = 0;
        Double totalMaintenance = 0;
        //List<CalculationResponseBodyWrapper.InsurancePayment> monthlyPayments = new List<CalculationResponseBodyWrapper.InsurancePayment>();
        //Iterate this loop only time for maintenance is not null
        for (CalculationResponseBodyWrapper.ScheduledPayment payment : response.payments) {
            
            //Maintenace always is there irrespective of user select maintenace in UI or not(default External Maintenace with amount 1)
            if(payment.maintenance != null){
                //Iterate this loop for sumup maintenance amount in single sheduled payment
                for (CalculationResponseBodyWrapper.MaintenancePayment maintenance :payment.maintenance) {
                    //Ignore dafault maintenance amount if it is less than 1 
                    if(maintenance.amount >= 1){
                         totalMaintenance += maintenance.amount;
                    }
                 }
                if (payment.insurances != null) { 
                      //Iterate this loop for sumup insurance amount in single sheduled payment
                     for (CalculationResponseBodyWrapper.InsurancePayment paymentItem : payment.insurances) {
                         monthlyAmount += paymentItem.amount;
                     }               
                }
            break;  //exit the outer loop(scheduled payment) after sumup the maintenance amount in single scheduled payment
            }  
        }
        
        //add Maintenance amount to rental amount
        wr.rentalAmount += totalMaintenance;
        wr.accumulatedService = response?.paymentCalculation?.maintenance?.amount;
        
        List<CalculationResponseBodyWrapper.CalculationMaintenance> calcMaintenance = new List<CalculationResponseBodyWrapper.CalculationMaintenance>();
        calcMaintenance = response?.financeInput?.maintenance;
        List<CalculationResponseBodyWrapper.CalculationAssetResponse> calcAssets =  response.financeInput.assets;
        List<CalculationAPIHelper.MaintenanceDataWrapper> maintenaceData = new List<CalculationAPIHelper.MaintenanceDataWrapper>();
        List<CalculationAPIHelper.AssetDataWrapper> assetsData = new List<CalculationAPIHelper.AssetDataWrapper>();
        List<CalculationResponseBodyWrapper.CalculationPerAssetResponse> assetCalculations = new List<CalculationResponseBodyWrapper.CalculationPerAssetResponse>();
        assetCalculations = response?.assetCalculations;
        List< CalculationAPIHelper.AssetCalculationWrapper> assetCalData = new List< CalculationAPIHelper.AssetCalculationWrapper>();
        
        if(calcMaintenance != null){
                for (CalculationResponseBodyWrapper.CalculationMaintenance maintenaceItem : calcMaintenance) {
                CalculationAPIHelper.MaintenanceDataWrapper maintenance = new CalculationAPIHelper.MaintenanceDataWrapper();
                maintenance.id = maintenaceItem.id;
                maintenance.amount = maintenaceItem.amount;
                // calculation periodic maintenace amount based on paymentFrequency (Monthly- /12, quarterly- /4, semi-annual- /2, annually- /1) 
                maintenance.periodicAmount = wr.paymentFrequency == Constants.MONTHLY_PAYMENT_FREQUENCY ? maintenaceItem.amount/12 : 
                                             wr.paymentFrequency == Constants.QUARTERLY_PAYMENT_FREQUENCY ?  maintenaceItem.amount/4 :
                                             wr.paymentFrequency == Constants.SEMI_ANNUALLY_PAYMENT_FREQUENCY ? maintenaceItem.amount/2 :
                                             wr.paymentFrequency == Constants.ANNUALLY_PAYMENT_FREQUENCY ? maintenaceItem.amount : 0.0;
                maintenaceData.add(maintenance);
            }  
        }

        for (CalculationResponseBodyWrapper.CalculationAssetResponse assetItem : calcAssets) {
            CalculationAPIHelper.AssetDataWrapper asset = new CalculationAPIHelper.AssetDataWrapper();
            asset.productName = assetItem.modelIdentifier.modelName;
            asset.quantity = assetItem.quantity;
            asset.salePrice = assetItem.salePrice;
            asset.residualValue = assetItem.residualValue.value != 0 ? assetItem.residualValue.value : null;
            asset.insuranceAmount = (assetItem.insurances != null && assetItem.insurances.size() > 0) ? assetItem.insurances[0].amount : null;
            asset.assetModelId = assetItem.residualValue.id.left(18);
            assetsData.add(asset);
        }
        
        // Double totalRVAmount = 0 ;
        //store asset Calculation details per asset
        if(assetCalculations != null){           
            for (CalculationResponseBodyWrapper.CalculationPerAssetResponse assetCalItem : assetCalculations) {
                CalculationAPIHelper.AssetCalculationWrapper assetCal = new CalculationAPIHelper.AssetCalculationWrapper();
                assetCal.productName = assetCalItem.modelIdentifier.modelName;
                assetCal.quantity = assetCalItem.quantity;
                assetCal.salePrice = assetCalItem.salePrice;
                assetCal.financeAmount = assetCalItem.financeCalculation.financeAmount;
                assetCal.periodicAmount = assetCalItem.consolidatedPayments[0].amount;
                assetCal.residualValue = assetCalItem.residualValue.value != 0 ? assetCalItem.residualValue.value : null;
                assetCal.insuranceAmount = (assetCalItem.insurances != null && assetCalItem.insurances.size() > 0) ? assetCalItem.insurances[0].amount : null;
                assetCalData.add(assetCal);
                
            } 
        }       

        /*for (CalculationResponseBodyWrapper.InsurancePayment paymentItem : monthlyPayments) {
            monthlyAmount += paymentItem.amount;
        }*/
       
        wr.maintenance = maintenaceData;
        wr.assets = assetsData;
        wr.insurancePayments = Integer.valueOf((Decimal.valueOf(monthlyAmount)).round(System.RoundingMode.HALF_UP));
        wr.assetCalculations = assetCalData;
        //wr.totalResidualValueAmount = totalRVAmount;        
        //wr.futureValue = response.financeCalculation.futureValue;
        return wr;
    }
    

    /**
     * Inner class-selector
     */
    public without sharing class WoSSelector {
        
         private Program__c getProgramById(Id programId) {
            return [SELECT Asset_Program__c FROM Program__c WHERE Id = :programId];
        }
        
        private Asset_Program_Detail__c getAssetDetailsForQuickCalProduct(Id assetProgramId,Boolean isQuick_RVApp) {
            String prodFamily= Constants.MAINTENANCE_PRODUCT_TYPE;
            String queryString = 'SELECT  Product__r.Name, Insurance__c FROM Asset_Program_Detail__c where Asset_Program__c = :assetProgramId ';
            if(isQuick_RVApp){
                queryString =queryString+' and Quick_Calculation_Product__c =TRUE and Is_RV_Applicable__c =FALSE ';
            }else{
                queryString =queryString+' and Product__r.family =:prodFamily';
                
            }
            
            queryString =queryString+' LIMIT 1 ';
            
            return Database.query(queryString); 
        }
        
    }
     public class CalculationInputWrapper {

         @AuraEnabled
         public String calculate;
         @AuraEnabled
         public Integer numberOfMonths;
         @AuraEnabled
         public Double amount;
         @AuraEnabled
         public String paymentFrequency;
         @AuraEnabled
         public String interest;
         @AuraEnabled
         public String paymentTiming;
         @AuraEnabled
         public String programId;
         @AuraEnabled
         public String financialProductId;
         @AuraEnabled
         public string downPayment;
         @AuraEnabled
         public string itadLevel;
         @AuraEnabled
         public List<CalculationInputAssetWrapper> assets;
         @AuraEnabled
         public List<CalculationInputAssetWrapper> maintenance;
         
         @AuraEnabled
         public Boolean isInsuranceApplicable;
         @AuraEnabled
         public Boolean isPurchaseOptionApplicable;
    }

    public class CalculationInputAssetWrapper {

        @AuraEnabled
        public String productName;
        @AuraEnabled
        public Double quantity;
        @AuraEnabled
        public Double price;
        
        @AuraEnabled
        public String residualValueAmount;
        
        @AuraEnabled
        public String insuranceAmount;
    } 
    
        
    
    public class CalculationOutputWrapper {

        @AuraEnabled
        public Double financeAmount;
        @AuraEnabled
        public String paymentFrequency;
        @AuraEnabled
        public Integer term;
        @AuraEnabled
        public Integer statusCode;
        @AuraEnabled
        public Integer insurancePayments;
        @AuraEnabled
        public Double rentalAmount;
        @AuraEnabled
        public Double nominalInterestRate;
        @AuraEnabled
        public String calculate;
        @AuraEnabled
        public String errorMessage = '';
        @AuraEnabled
        public List<MaintenanceDataWrapper> maintenance;
        @AuraEnabled
        public List<AssetDataWrapper> assets;
        @AuraEnabled
        public List<AssetCalculationWrapper> assetCalculations;
        @AuraEnabled
        public Double accumulatedService;
        @AuraEnabled
        public Double futureValue;
        @AuraEnabled
        public Integer numberOfPayments;
        
        //@AuraEnabled
        //public Double totalResidualValueAmount;
    }

    public class MaintenanceDataWrapper {
        @AuraEnabled
        public Double amount;
        @AuraEnabled
        public String id;
        @AuraEnabled
        public Double periodicAmount;
    }

    public class AssetDataWrapper {
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public Integer quantity;
        @AuraEnabled
        public Double salePrice;
        @AuraEnabled
        public Double residualValue;
        @AuraEnabled
        public Double insuranceAmount;
        @AuraEnabled
        public String assetModelId;
    }
    
       public class AssetCalculationWrapper {
        @AuraEnabled
        public String productName;
        @AuraEnabled
        public Integer quantity;
        @AuraEnabled
        public Double salePrice;
        @AuraEnabled
        public Double financeAmount;
        @AuraEnabled
        public Double periodicAmount;
        @AuraEnabled
        public Double residualValue;
        @AuraEnabled
        public Double insuranceAmount;           
        
    }
    
}